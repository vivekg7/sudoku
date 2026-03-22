import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';

class GameState extends ChangeNotifier {
  Puzzle? _puzzle;
  int? _selectedRow;
  int? _selectedCol;
  int? _activeNumber;
  bool _isPencilMode = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _elapsedOffset = 0;
  bool _isPaused = false;
  bool _isSolvedNotified = false;

  // Hint state.
  final HintGenerator _hintGen = HintGenerator();
  Hint? _currentHint;
  int _hintLayer = 0; // 0 = none, 1 = nudge, 2 = strategy, 3 = answer
  DateTime? _hintShownAt;
  final Map<HintLevel, int> _hintCounts = {};
  final Map<StrategyType, int> _hintStrategyCounts = {};
  int _mistakeCount = 0;

  /// Cooldown seconds: nudge -> strategy.
  static const int _cooldownNudge = 10;

  /// Cooldown seconds: strategy -> answer.
  static const int _cooldownStrategy = 15;

  /// Maximum hint layer allowed (0 = disabled, 1 = nudge, 2 = strategy, 3 = all).
  int maxHintLayer = 3;

  /// Whether pencil notes are allowed.
  bool notesEnabled = true;

  /// Individual visual-aid toggles.
  AssistToggles assistToggles = AssistToggles.allOn;

  Puzzle? get puzzle => _puzzle;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  int? get activeNumber => _activeNumber;
  bool get isPencilMode => _isPencilMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isPaused => _isPaused;
  bool get isPlaying => _puzzle != null && !_puzzle!.isSolved;
  bool get isSolved => _puzzle?.isSolved ?? false;
  String? _error;
  String? get error => _error;

  // Hint getters.
  Hint? get currentHint => _currentHint;
  int get hintLayer => _hintLayer;
  String? get hintText {
    if (_currentHint == null || _hintLayer == 0) return null;
    return _currentHint!.textForLevel(HintLevel.values[_hintLayer - 1]);
  }

  HintLevel? get currentHintLevel =>
      _hintLayer > 0 ? HintLevel.values[_hintLayer - 1] : null;
  Map<HintLevel, int> get hintCounts => Map.unmodifiable(_hintCounts);
  Map<StrategyType, int> get hintStrategyCounts =>
      Map.unmodifiable(_hintStrategyCounts);
  int get totalHints => _hintCounts.values.fold(0, (s, c) => s + c);
  int get mistakeCount => _mistakeCount;

  /// Seconds remaining before the next hint layer can be requested.
  int get hintCooldownRemaining {
    if (_hintShownAt == null || _hintLayer == 0 || _hintLayer >= maxHintLayer) {
      return 0;
    }
    final cooldown = _hintLayer == 1 ? _cooldownNudge : _cooldownStrategy;
    final elapsed = DateTime.now().difference(_hintShownAt!).inSeconds;
    return (cooldown - elapsed).clamp(0, cooldown);
  }

  /// Whether the next hint layer would be the answer (layer 3).
  bool get nextHintIsAnswer => _hintLayer == 2 && maxHintLayer >= 3;

  /// Whether the solved state has been shown to the user.
  bool get isSolvedNotified => _isSolvedNotified;
  void markSolvedNotified() => _isSolvedNotified = true;

  Future<void> newGame(Difficulty difficulty) async {
    _timer?.cancel();
    _puzzle = null;
    _selectedRow = null;
    _selectedCol = null;
    _activeNumber = null;
    _isPencilMode = false;
    _isPaused = false;
    _isSolvedNotified = false;
    _elapsedSeconds = 0;
    _elapsedOffset = 0;
    _stopwatch.reset();
    _currentHint = null;
    _hintLayer = 0;
    _hintShownAt = null;
    _hintCounts.clear();
    _hintStrategyCounts.clear();
    _mistakeCount = 0;
    _error = null;
    notifyListeners();

    try {
      var puzzle = await compute(_generatePuzzle, difficulty);
      puzzle ??= await compute(_generatePuzzle, difficulty);
      if (puzzle == null) {
        _error = 'Failed to generate puzzle. Please try again.';
        notifyListeners();
        return;
      }
      _puzzle = puzzle;
    } catch (e) {
      _error = 'Puzzle generation error: $e';
      notifyListeners();
      return;
    }

    _stopwatch.start();
    _startTimer();
    notifyListeners();
  }

  static Puzzle? _generatePuzzle(Difficulty difficulty) {
    return PuzzleGenerator(random: Random()).generate(difficulty);
  }

  /// Resume from a saved puzzle (no generation needed).
  void resumePuzzle(Puzzle puzzle, {int elapsedSeconds = 0}) {
    _timer?.cancel();
    _puzzle = puzzle;
    _selectedRow = null;
    _selectedCol = null;
    _activeNumber = null;
    _isPencilMode = false;
    _isPaused = false;
    _isSolvedNotified = false;
    _elapsedOffset = elapsedSeconds;
    _elapsedSeconds = elapsedSeconds;
    _stopwatch.reset();
    _currentHint = null;
    _hintLayer = 0;
    _hintShownAt = null;
    _hintCounts.clear();
    _hintStrategyCounts.clear();
    _mistakeCount = 0;
    _stopwatch.start();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsedSeconds = _elapsedOffset + _stopwatch.elapsed.inSeconds;
        notifyListeners();
      }
    });
  }

  void togglePause() {
    if (_puzzle == null || _puzzle!.isSolved) return;
    if (_isPaused) {
      _stopwatch.start();
      _isPaused = false;
    } else {
      _stopwatch.stop();
      _isPaused = true;
    }
    notifyListeners();
  }

  void deselect() {
    if (_selectedRow == null && _selectedCol == null) return;
    _selectedRow = null;
    _selectedCol = null;
    notifyListeners();
  }

  void selectCell(int row, int col) {
    if (_isPaused || _puzzle == null) return;

    // Number-first mode: fill empty cells with the active number.
    if (_activeNumber != null && _selectedRow == null && _selectedCol == null) {
      final cell = _puzzle!.board.getCell(row, col);
      if (!cell.isGiven && cell.isEmpty) {
        if (_isPencilMode) {
          final prevCandidates = cell.candidates.copy();
          cell.toggleCandidate(_activeNumber!);
          final newCandidates = cell.candidates.copy();
          _puzzle!.history.push(Move(
            row: row,
            col: col,
            type: cell.candidates.contains(_activeNumber!)
                ? MoveType.addCandidate
                : MoveType.removeCandidate,
            previousCandidates: prevCandidates,
            newCandidates: newCandidates,
          ));
          _clearHint();
        } else {
          _placeValue(row, col, _activeNumber!);
          if (remainingCount(_activeNumber!) == 0) _activeNumber = null;
        }
        notifyListeners();
        return;
      }
    }

    // Normal cell-first selection.
    _activeNumber = null;
    if (_selectedRow == row && _selectedCol == col) {
      _selectedRow = null;
      _selectedCol = null;
    } else {
      _selectedRow = row;
      _selectedCol = col;
    }
    notifyListeners();
  }

  void moveSelection(int dRow, int dCol) {
    if (_puzzle == null || _isPaused) return;
    final r = ((_selectedRow ?? 4) + dRow).clamp(0, 8);
    final c = ((_selectedCol ?? 4) + dCol).clamp(0, 8);
    _selectedRow = r;
    _selectedCol = c;
    notifyListeners();
  }

  void togglePencilMode() {
    if (!notesEnabled) return;
    _isPencilMode = !_isPencilMode;
    notifyListeners();
  }

  void enterValue(int value) {
    if (_puzzle == null) return;
    if (_isPaused || _puzzle!.isSolved) return;

    // No cell selected → activate/toggle number-first mode.
    if (_selectedRow == null || _selectedCol == null) {
      _activeNumber = (_activeNumber == value) ? null : value;
      notifyListeners();
      return;
    }

    // Cell selected → cell-first input.
    _activeNumber = null;
    final cell = _puzzle!.board.getCell(_selectedRow!, _selectedCol!);
    if (cell.isGiven) return;

    if (_isPencilMode) {
      if (cell.isFilled) return;
      final prevCandidates = cell.candidates.copy();
      cell.toggleCandidate(value);
      final newCandidates = cell.candidates.copy();

      _puzzle!.history.push(Move(
        row: _selectedRow!,
        col: _selectedCol!,
        type: cell.candidates.contains(value)
            ? MoveType.addCandidate
            : MoveType.removeCandidate,
        previousCandidates: prevCandidates,
        newCandidates: newCandidates,
      ));
      _clearHint();
    } else {
      // If same value, treat as clear.
      if (cell.value == value) {
        clearCell();
        return;
      }

      _placeValue(_selectedRow!, _selectedCol!, value);
    }
    notifyListeners();
  }

  /// Place a value at (row, col) with undo history. Used by both
  /// cell-first and number-first input modes.
  void _placeValue(int row, int col, int value) {
    _clearHint();
    final cell = _puzzle!.board.getCell(row, col);
    final prevValue = cell.value;
    final prevCandidates = cell.candidates.copy();
    cell.setValue(value);

    // Auto-remove the placed digit from peer candidates.
    final removedPeers = assistToggles.autoRemoveCandidates
        ? _puzzle!.board.removeCandidateFromPeers(row, col, value)
        : const <(int, int, int)>[];

    _puzzle!.history.push(Move(
      row: row,
      col: col,
      type: MoveType.setValue,
      previousValue: prevValue,
      newValue: value,
      previousCandidates: prevCandidates,
      newCandidates: CandidateSet(),
      removedPeerCandidates: removedPeers,
    ));

    // Count mistakes: check if the placed value conflicts with any peer.
    if (conflicts.contains((row, col))) {
      _mistakeCount++;
    }

    if (_puzzle!.isSolved) {
      _stopwatch.stop();
      _timer?.cancel();
    }
  }

  void clearCell() {
    if (_puzzle == null) return;
    if (_selectedRow == null || _selectedCol == null) {
      if (_activeNumber != null) {
        _activeNumber = null;
        notifyListeners();
      }
      return;
    }
    _clearCellAt(_selectedRow!, _selectedCol!);
  }

  /// Selects the cell at [row], [col] and clears its value.
  void clearCellAt(int row, int col) {
    if (_puzzle == null || _isPaused) return;
    _selectedRow = row;
    _selectedCol = col;
    _activeNumber = null;
    _clearCellAt(row, col);
  }

  void _clearCellAt(int row, int col) {
    if (_isPaused) return;

    final cell = _puzzle!.board.getCell(row, col);
    if (cell.isGiven || cell.isEmpty) return;

    _puzzle!.history.push(Move(
      row: row,
      col: col,
      type: MoveType.clearValue,
      previousValue: cell.value,
      newValue: 0,
      previousCandidates: cell.candidates.copy(),
    ));
    cell.clearValue();
    _clearHint();
    notifyListeners();
  }

  void _applyUndo(Move move) {
    final cell = _puzzle!.board.getCell(move.row, move.col);
    if (move.previousValue != 0) {
      cell.setValue(move.previousValue);
    } else {
      cell.clearValue();
    }
    cell.setCandidates(move.previousCandidates);

    // Restore candidates that were auto-removed from peers.
    for (final (r, c, v) in move.removedPeerCandidates) {
      _puzzle!.board.getCell(r, c).addCandidate(v);
    }
  }

  void _applyRedo(Move move) {
    final cell = _puzzle!.board.getCell(move.row, move.col);
    if (move.newValue != 0) {
      cell.setValue(move.newValue);
    } else {
      cell.clearValue();
    }
    cell.setCandidates(move.newCandidates);

    // Re-apply auto-removed peer candidates.
    for (final (r, c, v) in move.removedPeerCandidates) {
      _puzzle!.board.getCell(r, c).removeCandidate(v);
    }
  }

  void undo() {
    if (_puzzle == null || _isPaused) return;
    final moves = _puzzle!.history.undo();
    if (moves == null) return;

    for (final move in moves.reversed) {
      _applyUndo(move);
    }

    _clearHint();

    _selectedRow = moves.first.row;
    _selectedCol = moves.first.col;
    notifyListeners();
  }

  void redo() {
    if (_puzzle == null || _isPaused) return;
    final moves = _puzzle!.history.redo();
    if (moves == null) return;

    for (final move in moves) {
      _applyRedo(move);
    }

    _clearHint();

    _selectedRow = moves.last.row;
    _selectedCol = moves.last.col;

    if (_puzzle!.isSolved) {
      _stopwatch.stop();
      _timer?.cancel();
    }
    notifyListeners();
  }

  // -- Auto-fill notes --

  /// Fill all valid candidates in every empty cell as a single undo step.
  void autoFillAllNotes() {
    if (_puzzle == null || _isPaused || _puzzle!.isSolved) return;

    final board = _puzzle!.board;
    final moves = <Move>[];

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;

        // Compute valid candidates via peer bitmask.
        var usedBits = 0;
        for (final peer in board.peers(r, c)) {
          if (peer.isFilled) usedBits |= 1 << peer.value;
        }
        final candidateBits = 0x3FE & ~usedBits;
        final newCandidates = CandidateSet(candidateBits);
        final prevCandidates = cell.candidates.copy();

        if (newCandidates == prevCandidates) continue;

        moves.add(Move(
          row: r,
          col: c,
          type: MoveType.setCandidates,
          previousCandidates: prevCandidates,
          newCandidates: newCandidates,
        ));

        cell.setCandidates(newCandidates);
      }
    }

    if (moves.isEmpty) return;

    _puzzle!.history.pushAll(moves);
    _clearHint();
    notifyListeners();
  }

  // -- Analysis --

  /// Number of cells the player filled before analysis was triggered.
  /// Captured at the moment [analyzePuzzle] is called (before the solution
  /// fills the remaining cells).
  int _playerFilledCount = 0;
  int get playerFilledCount => _playerFilledCount;

  /// Fill all remaining cells with the solution and mark as analyzed.
  ///
  /// After calling this, the puzzle is complete and no longer interactive.
  void analyzePuzzle() {
    if (_puzzle == null) return;

    // Snapshot the player's progress before filling.
    _playerFilledCount = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final initial = _puzzle!.initialBoard.getCell(r, c);
        final current = _puzzle!.board.getCell(r, c);
        if (!initial.isGiven && current.isFilled) _playerFilledCount++;
      }
    }

    // Fill all empty cells with solution values.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = _puzzle!.board.getCell(r, c);
        if (cell.isEmpty) {
          cell.setValue(_puzzle!.solution.getCell(r, c).value);
        }
      }
    }

    _puzzle!.completionType = CompletionType.analyzed;
    _stopwatch.stop();
    _timer?.cancel();
    _isSolvedNotified = true; // Prevent solved celebration from firing.
    _clearHint();
    notifyListeners();
  }

  // -- Hints --

  void requestHint() {
    if (_puzzle == null || _isPaused || _puzzle!.isSolved) return;
    if (maxHintLayer <= 0) return; // hints disabled

    // If we've shown all allowed layers, generate a new hint on next press.
    if (_currentHint == null || _hintLayer >= maxHintLayer) {
      _currentHint = _hintGen.generate(_puzzle!.board);
      _hintLayer = 0;

      if (_currentHint == null) return; // no hint available
    }

    _hintLayer++;
    _hintShownAt = DateTime.now();
    final level = HintLevel.values[_hintLayer - 1];
    _hintCounts[level] = (_hintCounts[level] ?? 0) + 1;
    final strategy = _currentHint!.step.strategy;
    _hintStrategyCounts[strategy] =
        (_hintStrategyCounts[strategy] ?? 0) + 1;
    notifyListeners();
  }

  void dismissHint() {
    if (_currentHint == null) return;
    _clearHint();
    notifyListeners();
  }

  void _clearHint() {
    _currentHint = null;
    _hintLayer = 0;
    _hintShownAt = null;
  }

  /// Cells involved in the current hint pattern (for board highlighting).
  Set<(int, int)> get hintInvolvedCells {
    if (_currentHint == null || _hintLayer < 2) return {};
    return _currentHint!.step.involvedCells
        .map((c) => (c.row, c.col))
        .toSet();
  }

  /// Cells where a value should be placed (answer-level highlight).
  Set<(int, int)> get hintPlacementCells {
    if (_currentHint == null || _hintLayer < 3) return {};
    return _currentHint!.step.placements
        .map((p) => (p.row, p.col))
        .toSet();
  }

  // -- Computed state --

  Set<(int, int)> get conflicts {
    if (_puzzle == null) return {};
    final result = <(int, int)>{};
    final board = _puzzle!.board;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isEmpty) continue;

        for (final peer in board.getRow(r)) {
          if (peer.col != c && peer.value == cell.value) {
            result.add((r, c));
            result.add((r, peer.col));
          }
        }
        for (final peer in board.getColumn(c)) {
          if (peer.row != r && peer.value == cell.value) {
            result.add((r, c));
            result.add((peer.row, c));
          }
        }
        for (final peer in board.getBox(cell.box)) {
          if ((peer.row != r || peer.col != c) && peer.value == cell.value) {
            result.add((r, c));
            result.add((peer.row, peer.col));
          }
        }
      }
    }
    return result;
  }

  bool isSelected(int row, int col) =>
      _selectedRow == row && _selectedCol == col;

  bool isRelatedToSelected(int row, int col) {
    if (!assistToggles.highlightRelated) return false;
    if (_selectedRow == null || _selectedCol == null) return false;
    if (row == _selectedRow && col == _selectedCol) return false;
    if (row == _selectedRow || col == _selectedCol) return true;
    final selBox = (_selectedRow! ~/ 3) * 3 + _selectedCol! ~/ 3;
    final cellBox = (row ~/ 3) * 3 + col ~/ 3;
    return cellBox == selBox;
  }

  bool hasSameValueAsSelected(int row, int col) {
    if (!assistToggles.highlightSameDigit) return false;
    if (_puzzle == null) return false;
    final cell = _puzzle!.board.getCell(row, col);
    final cellValue = cell.value;

    // Highlight cells matching the active number.
    if (_activeNumber != null) {
      return cellValue == _activeNumber ||
          (cellValue == 0 && cell.candidates.contains(_activeNumber!));
    }

    // Highlight cells matching the selected cell's value.
    if (_selectedRow == null || _selectedCol == null) return false;
    if (row == _selectedRow && col == _selectedCol) return false;
    final selValue = _puzzle!.board.getCell(_selectedRow!, _selectedCol!).value;
    if (selValue == 0) return false;
    return cellValue == selValue ||
        (cellValue == 0 && cell.candidates.contains(selValue));
  }

  int remainingCount(int value) {
    if (_puzzle == null) return 9;
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (_puzzle!.board.getCell(r, c).value == value) count++;
      }
    }
    return 9 - count;
  }

  String get formattedTime {
    final mins = _elapsedSeconds ~/ 60;
    final secs = _elapsedSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Build a [GameStats] snapshot from the current session.
  GameStats toGameStats({
    required bool showTimer,
    required String boardLayout,
  }) =>
      GameStats(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        difficulty: _puzzle!.difficulty,
        solveTimeSeconds: _elapsedSeconds,
        completed: _puzzle!.isSolved &&
            _puzzle!.completionType != CompletionType.analyzed,
        hintsByLevel: Map.of(_hintCounts),
        hintsByStrategy: Map.of(_hintStrategyCounts),
        playedAt: DateTime.now(),
        puzzleId: _puzzle!.initialBoard.toFlatString(),
        assistLevel: assistToggles.statsLabel,
        assistToggles: assistToggles.toJson(),
        notesEnabled: notesEnabled,
        showTimer: showTimer,
        boardLayout: boardLayout,
        mistakeCount: _mistakeCount,
        completionType: _puzzle!.completionType?.name,
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
