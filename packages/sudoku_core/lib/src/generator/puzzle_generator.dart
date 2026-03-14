import 'dart:math';

import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/puzzle.dart';
import '../solver/candidate_helper.dart';
import '../solver/solve_result.dart';
import '../solver/solver_engine.dart';
import '../solver/strategies/backtracking.dart';

/// Generates Sudoku puzzles of a target difficulty.
///
/// The generator works in three stages:
/// 1. Generate a complete valid board using random fill + backtracking.
/// 2. Remove clues symmetrically while maintaining a unique solution.
/// 3. Solve step-by-step and check if difficulty matches the target.
class PuzzleGenerator {
  final Random _random;
  final Solver _solver;

  /// Maximum attempts to generate a puzzle matching the target difficulty.
  final int maxAttempts;

  PuzzleGenerator({Random? random, this.maxAttempts = 100})
      : _random = random ?? Random(),
        _solver = Solver();

  /// Generates a puzzle at the requested difficulty.
  ///
  /// Returns `null` if no puzzle matching the target difficulty could be
  /// generated within [maxAttempts].
  Puzzle? generate(Difficulty difficulty) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final solution = _generateFullBoard();
      if (solution == null) continue;

      final puzzle = _removeCluesToDifficulty(solution, difficulty);
      if (puzzle != null) return puzzle;
    }
    return null;
  }

  /// Generates multiple puzzles, optionally at different difficulties.
  ///
  /// Returns a list of exactly [count] puzzles. If a puzzle at the
  /// requested difficulty can't be generated, it retries.
  List<Puzzle> generateBatch(int count, Difficulty difficulty) {
    final puzzles = <Puzzle>[];
    while (puzzles.length < count) {
      final puzzle = generate(difficulty);
      if (puzzle != null) puzzles.add(puzzle);
    }
    return puzzles;
  }

  /// Generates a complete valid 9x9 board using randomised backtracking.
  Board? _generateFullBoard() {
    final board = Board.empty();

    // Fill diagonal boxes first — they don't constrain each other.
    for (var box = 0; box < 9; box += 4) {
      _fillBox(board, box);
    }

    computeCandidates(board);
    return _fillRemaining(board) ? board : null;
  }

  /// Fills a single 3x3 box with a random permutation of 1–9.
  void _fillBox(Board board, int box) {
    final startRow = (box ~/ 3) * 3;
    final startCol = (box % 3) * 3;
    final values = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
    var i = 0;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        board.getCell(r, c).setValue(values[i++]);
      }
    }
  }

  /// Fills remaining empty cells using randomised backtracking.
  bool _fillRemaining(Board board) {
    // Find empty cell with fewest candidates (MRV).
    int? bestRow, bestCol;
    var bestCount = 10;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;
        if (cell.candidates.isEmpty) return false;
        if (cell.candidates.length < bestCount) {
          bestCount = cell.candidates.length;
          bestRow = r;
          bestCol = c;
        }
      }
    }

    if (bestRow == null) return true; // All filled.

    final candidates = board.getCell(bestRow, bestCol!).candidates.toList()
      ..shuffle(_random);

    for (final v in candidates) {
      board.getCell(bestRow, bestCol).setValue(v);
      board.getCell(bestRow, bestCol).setCandidates({});

      // Remove from peers' candidates.
      final removedFrom = <({int row, int col, int value})>[];
      for (final peer in board.peers(bestRow, bestCol)) {
        if (peer.candidates.contains(v)) {
          peer.removeCandidate(v);
          removedFrom.add((row: peer.row, col: peer.col, value: v));
        }
      }

      if (_fillRemaining(board)) return true;

      // Undo.
      board.getCell(bestRow, bestCol).clearValue();
      computeCandidates(board);
    }

    return false;
  }

  /// Removes clues from a full board symmetrically, targeting a difficulty.
  ///
  /// Returns a [Puzzle] if the resulting board matches [target], else `null`.
  Puzzle? _removeCluesToDifficulty(Board solution, Difficulty target) {
    final board = solution.clone();

    // Build list of cell positions in pairs (180° rotational symmetry).
    final pairs = <List<({int row, int col})>>[];
    final visited = <int>{};

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final idx = r * 9 + c;
        if (visited.contains(idx)) continue;
        visited.add(idx);

        final mr = 8 - r;
        final mc = 8 - c;
        final mirrorIdx = mr * 9 + mc;

        if (mirrorIdx != idx) {
          visited.add(mirrorIdx);
          pairs.add([(row: r, col: c), (row: mr, col: mc)]);
        } else {
          // Centre cell — its own mirror.
          pairs.add([(row: r, col: c)]);
        }
      }
    }

    pairs.shuffle(_random);

    // Greedily remove pairs while maintaining unique solution.
    for (final pair in pairs) {
      // Save values.
      final saved = [
        for (final pos in pair) board.getCell(pos.row, pos.col).value,
      ];

      // Remove.
      for (final pos in pair) {
        board.getCell(pos.row, pos.col).clearValue();
      }

      // Check uniqueness.
      final testBoard = board.clone();
      computeCandidates(testBoard);
      final solutions = Backtracking.countSolutions(testBoard, limit: 2);

      if (solutions != 1) {
        // Restore — removing these breaks uniqueness.
        for (var i = 0; i < pair.length; i++) {
          board.getCell(pair[i].row, pair[i].col).setValue(saved[i]);
        }
      }
    }

    // Now solve step-by-step and check difficulty.
    final result = _solver.solve(board);
    if (!result.isSolved) return null;

    if (result.difficulty != target) return null;

    // Build the puzzle with givens marked.
    final initialBoard = _boardWithGivens(board);
    final playerBoard = initialBoard.clone();

    return Puzzle(
      initialBoard: initialBoard,
      solution: solution,
      board: playerBoard,
      difficulty: target,
    );
  }

  /// Creates a new board from [source] with filled cells marked as givens.
  Board _boardWithGivens(Board source) {
    final values = <List<int>>[];
    for (var r = 0; r < 9; r++) {
      final row = <int>[];
      for (var c = 0; c < 9; c++) {
        row.add(source.getCell(r, c).value);
      }
      values.add(row);
    }
    return Board.fromValues(values);
  }
}
