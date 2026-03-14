import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sudoku_core/sudoku_core.dart';

class GameState extends ChangeNotifier {
  Puzzle? _puzzle;
  int? _selectedRow;
  int? _selectedCol;
  bool _isPencilMode = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isSolvedNotified = false;

  Puzzle? get puzzle => _puzzle;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get isPencilMode => _isPencilMode;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isPaused => _isPaused;
  bool get isPlaying => _puzzle != null && !_puzzle!.isSolved;
  bool get isSolved => _puzzle?.isSolved ?? false;

  /// Whether the solved state has been shown to the user.
  bool get isSolvedNotified => _isSolvedNotified;
  void markSolvedNotified() => _isSolvedNotified = true;

  Future<void> newGame(Difficulty difficulty) async {
    _timer?.cancel();
    _puzzle = null;
    _selectedRow = null;
    _selectedCol = null;
    _isPencilMode = false;
    _isPaused = false;
    _isSolvedNotified = false;
    _elapsedSeconds = 0;
    _stopwatch.reset();
    notifyListeners();

    final puzzle = await compute(_generatePuzzle, difficulty);
    if (puzzle == null) {
      // Retry once — generation rarely fails.
      final retry = await compute(_generatePuzzle, difficulty);
      if (retry == null) return;
      _puzzle = retry;
    } else {
      _puzzle = puzzle;
    }

    _stopwatch.start();
    _startTimer();
    notifyListeners();
  }

  static Puzzle? _generatePuzzle(Difficulty difficulty) {
    return PuzzleGenerator(random: Random()).generate(difficulty);
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

  void selectCell(int row, int col) {
    if (_isPaused || _puzzle == null) return;
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
    if (_puzzle == null || _selectedRow == null || _selectedCol == null) return;
    if (_isPaused || _puzzle!.isSolved) return;

    final cell = _puzzle!.board.getCell(_selectedRow!, _selectedCol!);
    if (cell.isGiven) return;

    if (_isPencilMode) {
      if (cell.isFilled) return;
      final prevCandidates = Set.of(cell.candidates);
      cell.toggleCandidate(value);
      final newCandidates = Set.of(cell.candidates);

      _puzzle!.history.push(Move(
        row: _selectedRow!,
        col: _selectedCol!,
        type: cell.candidates.contains(value)
            ? MoveType.addCandidate
            : MoveType.removeCandidate,
        previousCandidates: prevCandidates,
        newCandidates: newCandidates,
      ));
    } else {
      // If same value, treat as clear.
      if (cell.value == value) {
        clearCell();
        return;
      }

      _puzzle!.history.push(Move(
        row: _selectedRow!,
        col: _selectedCol!,
        type: MoveType.setValue,
        previousValue: cell.value,
        newValue: value,
        previousCandidates: Set.of(cell.candidates),
        newCandidates: {},
      ));
      cell.setValue(value);

      if (_puzzle!.isSolved) {
        _stopwatch.stop();
        _timer?.cancel();
      }
    }
    notifyListeners();
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
      previousCandidates: Set.of(cell.candidates),
    ));
    cell.clearValue();
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

    _selectedRow = move.row;
    _selectedCol = move.col;

    if (_puzzle!.isSolved) {
      _stopwatch.stop();
      _timer?.cancel();
    }
    notifyListeners();
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
    if (_puzzle == null || _selectedRow == null || _selectedCol == null) {
      return false;
    }
    if (row == _selectedRow && col == _selectedCol) return false;
    final selValue = _puzzle!.board.getCell(_selectedRow!, _selectedCol!).value;
    if (selValue == 0) return false;
    return _puzzle!.board.getCell(row, col).value == selValue;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
