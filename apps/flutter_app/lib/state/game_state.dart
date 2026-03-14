import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sudoku_core/sudoku_core.dart';

class GameState extends ChangeNotifier {
  Puzzle? _puzzle;
  int? _selectedRow;
  int? _selectedCol;
  int? _activeNumber;
  bool _isPencilMode = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isSolvedNotified = false;

  // Hint state.
  final HintGenerator _hintGen = HintGenerator();
  Hint? _currentHint;
  int _hintLayer = 0; // 0 = none, 1 = nudge, 2 = strategy, 3 = answer
  final Map<HintLevel, int> _hintCounts = {};
  final Map<StrategyType, int> _hintStrategyCounts = {};

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
    _stopwatch.reset();
    _currentHint = null;
    _hintLayer = 0;
    _hintCounts.clear();
    _hintStrategyCounts.clear();
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
  void resumePuzzle(Puzzle puzzle) {
    _timer?.cancel();
    _puzzle = puzzle;
    _selectedRow = null;
    _selectedCol = null;
    _activeNumber = null;
    _isPencilMode = false;
    _isPaused = false;
    _isSolvedNotified = false;
    _elapsedSeconds = 0;
    _stopwatch.reset();
    _currentHint = null;
    _hintLayer = 0;
    _hintCounts.clear();
    _hintStrategyCounts.clear();
    _stopwatch.start();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsedSeconds = _stopwatch.elapsed.inSeconds;
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
        _placeValue(row, col, _activeNumber!);
        if (remainingCount(_activeNumber!) == 0) _activeNumber = null;
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
    _puzzle!.history.push(Move(
      row: row,
      col: col,
      type: MoveType.setValue,
      previousValue: cell.value,
      newValue: value,
      previousCandidates: cell.candidates.copy(),
      newCandidates: CandidateSet(),
    ));
    cell.setValue(value);

    if (_puzzle!.isSolved) {
      _stopwatch.stop();
      _timer?.cancel();
    }
  }

  void clearCell() {
    if (_puzzle == null || _selectedRow == null || _selectedCol == null) return;
    if (_isPaused) return;

    final cell = _puzzle!.board.getCell(_selectedRow!, _selectedCol!);
    if (cell.isGiven || cell.isEmpty) return;

    _puzzle!.history.push(Move(
      row: _selectedRow!,
      col: _selectedCol!,
      type: MoveType.clearValue,
      previousValue: cell.value,
      newValue: 0,
      previousCandidates: cell.candidates.copy(),
    ));
    cell.clearValue();
    _clearHint();
    notifyListeners();
  }

  void undo() {
    if (_puzzle == null || _isPaused) return;
    final move = _puzzle!.history.undo();
    if (move == null) return;

    final cell = _puzzle!.board.getCell(move.row, move.col);
    if (move.previousValue != 0) {
      cell.setValue(move.previousValue);
    } else {
      cell.clearValue();
    }
    cell.setCandidates(move.previousCandidates);
    _clearHint();

    _selectedRow = move.row;
    _selectedCol = move.col;
    notifyListeners();
  }

  void redo() {
    if (_puzzle == null || _isPaused) return;
    final move = _puzzle!.history.redo();
    if (move == null) return;

    final cell = _puzzle!.board.getCell(move.row, move.col);
    if (move.newValue != 0) {
      cell.setValue(move.newValue);
    } else {
      cell.clearValue();
    }
    cell.setCandidates(move.newCandidates);
    _clearHint();

    _selectedRow = move.row;
    _selectedCol = move.col;

    if (_puzzle!.isSolved) {
      _stopwatch.stop();
      _timer?.cancel();
    }
    notifyListeners();
  }

  // -- Hints --

  void requestHint() {
    if (_puzzle == null || _isPaused || _puzzle!.isSolved) return;

    // If we've shown all 3 layers, generate a new hint on next press.
    if (_currentHint == null || _hintLayer >= 3) {
      _currentHint = _hintGen.generate(_puzzle!.board);
      _hintLayer = 0;

      if (_currentHint == null) return; // no hint available
    }

    _hintLayer++;
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
    if (_selectedRow == null || _selectedCol == null) return false;
    if (row == _selectedRow && col == _selectedCol) return false;
    if (row == _selectedRow || col == _selectedCol) return true;
    final selBox = (_selectedRow! ~/ 3) * 3 + _selectedCol! ~/ 3;
    final cellBox = (row ~/ 3) * 3 + col ~/ 3;
    return cellBox == selBox;
  }

  bool hasSameValueAsSelected(int row, int col) {
    if (_puzzle == null) return false;
    final cellValue = _puzzle!.board.getCell(row, col).value;
    if (cellValue == 0) return false;

    // Highlight cells matching the active number.
    if (_activeNumber != null) return cellValue == _activeNumber;

    // Highlight cells matching the selected cell's value.
    if (_selectedRow == null || _selectedCol == null) return false;
    if (row == _selectedRow && col == _selectedCol) return false;
    final selValue = _puzzle!.board.getCell(_selectedRow!, _selectedCol!).value;
    return selValue != 0 && cellValue == selValue;
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
  GameStats toGameStats() => GameStats(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        difficulty: _puzzle!.difficulty,
        solveTimeSeconds: _elapsedSeconds,
        completed: _puzzle!.isSolved,
        hintsByLevel: Map.of(_hintCounts),
        hintsByStrategy: Map.of(_hintStrategyCounts),
        playedAt: DateTime.now(),
        puzzleId: _puzzle!.initialBoard.toFlatString(),
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
