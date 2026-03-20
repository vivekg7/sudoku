import 'dart:async';

import 'package:sudoku_core/sudoku_core.dart';

import 'game_timer.dart';
import 'input_handler.dart';
import 'terminal.dart';
import 'tui_renderer.dart';

/// Interactive TUI Sudoku game with raw keyboard input and real-time updates.
class TuiGame {
  final Puzzle puzzle;
  final Terminal _terminal = Terminal();
  final InputHandler _input = InputHandler();
  final TuiRenderer _renderer = TuiRenderer();
  final GameTimer _timer = GameTimer();
  final HintGenerator _hintGen = HintGenerator();

  int _cursorRow = 0;
  int _cursorCol = 0;
  bool _noteMode = false;
  bool _showCandidates = false;
  bool _paused = false;

  // Hint state
  Hint? _currentHint;
  int _hintLayer = 0;
  final Map<HintLevel, int> _hintCounts = {};
  final Map<StrategyType, int> _hintStrategyCounts = {};

  // Status messages
  String? _statusMessage;
  Set<(int, int)> _conflictCells = {};
  Set<(int, int)> _hintCells = {};

  // Confirmation state
  _ConfirmAction? _pendingConfirm;

  // Game completion
  final Completer<void> _gameComplete = Completer<void>();
  Timer? _timerTick;

  TuiGame(this.puzzle);

  /// Runs the TUI game loop. Returns when the game is finished.
  Future<void> run() async {
    _terminal.init();
    try {
      _timer.start();
      _input.start();

      _redraw();

      _timerTick = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _onTimerTick(),
      );

      final subscription = _input.keys.listen(_onKey);

      await _gameComplete.future;

      _timerTick?.cancel();
      await subscription.cancel();
    } finally {
      await _input.stop();
      _terminal.dispose();
    }
  }

  void _onTimerTick() {
    if (!_paused && !puzzle.isSolved) {
      _redraw();
    }
  }

  void _onKey(KeyEvent event) {
    // Handle confirmation prompts first
    if (_pendingConfirm != null) {
      _handleConfirmation(event);
      return;
    }

    // When paused, only handle unpause
    if (_paused) {
      if (event is CharKey && (event.char == 'p' || event.char == ' ')) {
        _togglePause();
      }
      return;
    }

    // When solved, any key exits
    if (puzzle.isSolved) {
      _gameComplete.complete();
      return;
    }

    switch (event) {
      case ArrowKey(:final direction):
        _moveCursor(direction);
      case CharKey(:final char):
        _handleChar(char);
      case BackspaceKey():
        _clearCell();
      case EscapeKey():
        if (_noteMode) {
          _noteMode = false;
          _statusMessage = null;
          _redraw();
        }
      case UnknownKey():
        break;
    }
  }

  void _handleChar(String char) {
    // Digit input
    if (char.codeUnitAt(0) >= 0x31 && char.codeUnitAt(0) <= 0x39) {
      final value = int.parse(char);
      if (_noteMode) {
        _toggleCandidate(value);
      } else {
        _setValue(value);
      }
      return;
    }

    // Clear with 0
    if (char == '0') {
      _clearCell();
      return;
    }

    switch (char.toLowerCase()) {
      case 'w':
        _moveCursor(Direction.up);
      case 'a':
        _moveCursor(Direction.left);
      case 's':
        _moveCursor(Direction.down);
      case 'd':
        _moveCursor(Direction.right);
      case 'n':
        _noteMode = !_noteMode;
        _statusMessage = _noteMode ? 'Note mode ON - digits toggle candidates' : null;
        _redraw();
      case 'c':
        _showCandidates = !_showCandidates;
        _statusMessage = _showCandidates ? 'Showing candidates' : 'Hiding candidates';
        _redraw();
      case 'h':
        _handleHint();
      case 'u':
        _handleUndo();
      case 'r':
        _handleRedo();
      case 'p' || ' ':
        _togglePause();
      case 'q':
        _pendingConfirm = _ConfirmAction.quit;
        _redraw();
      case 'x':
        _pendingConfirm = _ConfirmAction.solve;
        _redraw();
    }
  }

  void _handleConfirmation(KeyEvent event) {
    if (event is! CharKey) {
      _pendingConfirm = null;
      _redraw();
      return;
    }

    final answer = event.char.toLowerCase();
    final action = _pendingConfirm!;
    _pendingConfirm = null;

    if (answer == 'y') {
      switch (action) {
        case _ConfirmAction.quit:
          _timer.pause();
          _gameComplete.complete();
          return;
        case _ConfirmAction.solve:
          _solvePuzzle();
          return;
        case _ConfirmAction.save:
          _saveAndQuit();
          return;
      }
    }

    _statusMessage = 'Cancelled.';
    _redraw();
  }

  void _moveCursor(Direction dir) {
    switch (dir) {
      case Direction.up:
        _cursorRow = (_cursorRow - 1 + 9) % 9;
      case Direction.down:
        _cursorRow = (_cursorRow + 1) % 9;
      case Direction.left:
        _cursorCol = (_cursorCol - 1 + 9) % 9;
      case Direction.right:
        _cursorCol = (_cursorCol + 1) % 9;
    }
    _conflictCells = {};
    _statusMessage = null;
    _redraw();
  }

  void _setValue(int value) {
    final cell = puzzle.board.getCell(_cursorRow, _cursorCol);
    if (cell.isGiven) {
      _statusMessage = 'Cannot modify a given cell.';
      _redraw();
      return;
    }

    puzzle.history.push(Move(
      row: _cursorRow,
      col: _cursorCol,
      type: MoveType.setValue,
      previousValue: cell.value,
      newValue: value,
      previousCandidates: cell.candidates.copy(),
      newCandidates: CandidateSet(),
    ));

    cell.setValue(value);
    _clearHint();

    // Check for conflicts
    _conflictCells = _findConflicts(_cursorRow, _cursorCol, value);
    if (_conflictCells.isNotEmpty) {
      _statusMessage = 'Conflict detected!';
    } else {
      _statusMessage = null;
    }

    _redraw();

    if (puzzle.isSolved) {
      _timer.pause();
      _redraw();
    }
  }

  void _clearCell() {
    final cell = puzzle.board.getCell(_cursorRow, _cursorCol);
    if (cell.isGiven) {
      _statusMessage = 'Cannot modify a given cell.';
      _redraw();
      return;
    }
    if (cell.isEmpty) return;

    puzzle.history.push(Move(
      row: _cursorRow,
      col: _cursorCol,
      type: MoveType.clearValue,
      previousValue: cell.value,
      newValue: 0,
      previousCandidates: cell.candidates.copy(),
    ));

    cell.clearValue();
    _clearHint();
    _conflictCells = {};
    _statusMessage = null;
    _redraw();
  }

  void _toggleCandidate(int value) {
    final cell = puzzle.board.getCell(_cursorRow, _cursorCol);
    if (cell.isGiven || cell.isFilled) {
      _statusMessage = 'Cannot add notes to a filled cell.';
      _redraw();
      return;
    }

    final prevCandidates = cell.candidates.copy();
    cell.toggleCandidate(value);
    final newCandidates = cell.candidates.copy();

    puzzle.history.push(Move(
      row: _cursorRow,
      col: _cursorCol,
      type: cell.candidates.contains(value)
          ? MoveType.addCandidate
          : MoveType.removeCandidate,
      previousCandidates: prevCandidates,
      newCandidates: newCandidates,
    ));

    if (!_showCandidates) _showCandidates = true;
    _statusMessage = null;
    _redraw();
  }

  void _handleUndo() {
    final move = puzzle.history.undo();
    if (move == null) {
      _statusMessage = 'Nothing to undo.';
      _redraw();
      return;
    }

    final cell = puzzle.board.getCell(move.row, move.col);
    if (move.previousValue != 0) {
      cell.setValue(move.previousValue);
    } else {
      cell.clearValue();
    }
    cell.setCandidates(move.previousCandidates);

    _cursorRow = move.row;
    _cursorCol = move.col;
    _conflictCells = {};
    _statusMessage = 'Undone.';
    _redraw();
  }

  void _handleRedo() {
    final move = puzzle.history.redo();
    if (move == null) {
      _statusMessage = 'Nothing to redo.';
      _redraw();
      return;
    }

    final cell = puzzle.board.getCell(move.row, move.col);
    if (move.newValue != 0) {
      cell.setValue(move.newValue);
    } else {
      cell.clearValue();
    }
    cell.setCandidates(move.newCandidates);

    _cursorRow = move.row;
    _cursorCol = move.col;
    _conflictCells = {};
    _statusMessage = 'Redone.';
    _redraw();
  }

  void _handleHint() {
    if (_currentHint == null || _hintLayer >= 3) {
      _currentHint = _hintGen.generate(puzzle.board);
      _hintLayer = 0;

      if (_currentHint == null) {
        _statusMessage = 'No hint available.';
        _hintCells = {};
        _redraw();
        return;
      }
    }

    _hintLayer++;
    final level = HintLevel.values[_hintLayer - 1];
    final text = _currentHint!.textForLevel(level);

    _hintCounts[level] = (_hintCounts[level] ?? 0) + 1;
    final strategy = _currentHint!.step.strategy;
    _hintStrategyCounts[strategy] = (_hintStrategyCounts[strategy] ?? 0) + 1;

    _statusMessage = 'Hint (${level.name}): $text';

    // Show involved cells on full hint
    if (_hintLayer >= 3) {
      _hintCells = _currentHint!.step.involvedCells
          .map((c) => (c.row, c.col))
          .toSet();
    } else {
      _hintCells = {};
    }

    _redraw();
  }

  void _togglePause() {
    _paused = !_paused;
    if (_paused) {
      _timer.pause();
      _statusMessage = 'Game paused. Press p or Space to resume.';
    } else {
      _timer.start();
      _statusMessage = null;
    }
    _redraw();
  }

  void _solvePuzzle() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = puzzle.board.getCell(r, c);
        if (cell.isEmpty) {
          cell.setValue(puzzle.solution.getCell(r, c).value);
        }
      }
    }
    _timer.pause();
    _statusMessage = null;
    _redraw();
  }

  void _saveAndQuit() {
    _timer.pause();
    _gameComplete.complete();
  }

  void _clearHint() {
    _currentHint = null;
    _hintLayer = 0;
    _hintCells = {};
  }

  Set<(int, int)> _findConflicts(int row, int col, int value) {
    final conflicts = <(int, int)>{};
    final board = puzzle.board;

    for (final c in board.getRow(row)) {
      if (c.col != col && c.value == value) {
        conflicts.add((row, c.col));
      }
    }
    for (final c in board.getColumn(col)) {
      if (c.row != row && c.value == value) {
        conflicts.add((c.row, col));
      }
    }
    final box = board.getBox(board.getCell(row, col).box);
    for (final c in box) {
      if ((c.row != row || c.col != col) && c.value == value) {
        conflicts.add((c.row, c.col));
      }
    }
    return conflicts;
  }

  void _redraw() {
    final state = RenderState(
      board: puzzle.board,
      cursorRow: _cursorRow,
      cursorCol: _cursorCol,
      noteMode: _noteMode,
      showCandidates: _showCandidates,
      timerText: _timer.formatted,
      difficulty: puzzle.difficulty,
      emptyCells: puzzle.emptyCellCount,
      paused: _paused,
      solved: puzzle.isSolved,
      statusMessage: _statusMessage,
      confirmPrompt: _pendingConfirm != null ? _confirmPromptText() : null,
      conflictCells: _conflictCells,
      hintCells: _hintCells,
      quoteId: puzzle.quoteId,
    );
    _renderer.renderFrame(state);
  }

  String _confirmPromptText() {
    return switch (_pendingConfirm!) {
      _ConfirmAction.quit => 'Quit game? (y/n)',
      _ConfirmAction.solve => 'Reveal solution? This ends the game. (y/n)',
      _ConfirmAction.save => 'Save game before quitting? (y/n)',
    };
  }

  /// Builds a [GameStats] from the current session.
  GameStats toGameStats() => GameStats(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        difficulty: puzzle.difficulty,
        solveTimeSeconds: _timer.elapsedSeconds,
        completed: puzzle.isSolved,
        hintsByLevel: Map.of(_hintCounts),
        hintsByStrategy: Map.of(_hintStrategyCounts),
        playedAt: DateTime.now(),
        puzzleId: puzzle.initialBoard.toFlatString(),
      );
}

enum _ConfirmAction { quit, solve, save }
