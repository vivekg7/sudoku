import 'dart:math';

import '../models/board.dart';
import '../models/cell.dart';
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
/// 2. Remove clues symmetrically, checking difficulty after each removal.
/// 3. Stop when the target difficulty is reached, or backtrack if overshot.
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
  ///
  /// Uses targeted undo instead of recomputing all candidates on backtrack.
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

    final cell = board.getCell(bestRow, bestCol!);
    final savedCandidates = cell.candidates.copy();
    final candidates = savedCandidates.toList()..shuffle(_random);

    for (final v in candidates) {
      cell.setValue(v);

      // Remove from peers' candidates, tracking which peers changed.
      final affected = <Cell>[];
      for (final peer in board.peers(bestRow, bestCol)) {
        if (peer.candidates.contains(v)) {
          peer.removeCandidate(v);
          affected.add(peer);
        }
      }

      if (_fillRemaining(board)) return true;

      // Undo: restore cell and affected peers.
      cell.clearValue();
      cell.setCandidates(savedCandidates);
      for (final peer in affected) {
        peer.addCandidate(v);
      }
    }

    return false;
  }

  /// Target given counts per difficulty. Fewer givens = harder for humans.
  static const Map<Difficulty, ({int min, int max})> _givenTargets = {
    Difficulty.beginner: (min: 40, max: 50),
    Difficulty.easy: (min: 34, max: 40),
    Difficulty.medium: (min: 29, max: 35),
    Difficulty.hard: (min: 25, max: 31),
    Difficulty.expert: (min: 22, max: 28),
    Difficulty.master: (min: 17, max: 25),
  };

  /// Removes clues from a full board symmetrically, targeting a difficulty.
  ///
  /// Removes clues one symmetric pair at a time, checking difficulty and
  /// given count after each removal. Stops when the target is reached,
  /// and backtracks if a removal overshoots.
  ///
  /// Skips the expensive `solver.solve()` call while the given count is
  /// still well above the target range (O5 optimisation).
  Puzzle? _removeCluesToDifficulty(Board solution, Difficulty target) {
    final board = solution.clone();
    final givenRange = _givenTargets[target]!;

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
          pairs.add([(row: r, col: c)]);
        }
      }
    }

    pairs.shuffle(_random);

    // Track the best board and its solve result.
    Board? bestBoard;
    SolveResult? bestResult;

    for (final pair in pairs) {
      // Count current givens.
      final currentGivens = _countFilled(board);

      // Stop if we'd go below the minimum givens for this difficulty.
      if (currentGivens - pair.length < givenRange.min) continue;

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
        continue;
      }

      // O5: Skip the expensive solve when givens are still well above the
      // target range — the puzzle is almost certainly easier than target.
      final givensAfter = currentGivens - pair.length;
      if (givensAfter > givenRange.max) continue;

      // Check if current state matches target difficulty.
      final result = _solver.solve(board);
      if (!result.isSolved) {
        // Shouldn't happen with unique solution, but restore just in case.
        for (var i = 0; i < pair.length; i++) {
          board.getCell(pair[i].row, pair[i].col).setValue(saved[i]);
        }
        continue;
      }

      if (result.difficulty == target) {
        bestBoard = board.clone();
        bestResult = result;
      } else if (result.difficulty.index > target.index) {
        // Overshot — this removal made it too hard. Restore.
        for (var i = 0; i < pair.length; i++) {
          board.getCell(pair[i].row, pair[i].col).setValue(saved[i]);
        }
      }
      // If difficulty is below target, keep removing.
    }

    // If we never hit the target during removal, check the final state.
    if (bestBoard == null) {
      final finalResult = _solver.solve(board);
      if (finalResult.isSolved && finalResult.difficulty == target) {
        bestBoard = board;
        bestResult = finalResult;
      }
    }

    if (bestBoard == null) return null;

    // Verify given count is in range.
    final finalGivens = _countFilled(bestBoard);
    if (finalGivens < givenRange.min || finalGivens > givenRange.max) {
      return null;
    }

    final initialBoard = _boardWithGivens(bestBoard);
    final playerBoard = initialBoard.clone();

    return Puzzle(
      initialBoard: initialBoard,
      solution: solution,
      board: playerBoard,
      difficulty: target,
      solveResult: bestResult,
    );
  }

  int _countFilled(Board board) {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getCell(r, c).isFilled) count++;
      }
    }
    return count;
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
