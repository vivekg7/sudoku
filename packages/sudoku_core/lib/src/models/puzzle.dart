import '../analysis/puzzle_analysis.dart';
import '../solver/solve_result.dart';
import 'board.dart';
import 'difficulty.dart';
import 'move_history.dart';

/// A complete puzzle: the initial board, its solution, difficulty, and
/// the player's current progress.
class Puzzle {
  /// The board as originally generated (givens only).
  final Board initialBoard;

  /// The unique solution.
  final Board solution;

  /// The player's current working board.
  final Board board;

  /// Difficulty level.
  final Difficulty difficulty;

  /// Move history for undo/redo.
  final MoveHistory history;

  /// Timestamp when the puzzle was created.
  final DateTime createdAt;

  /// Cached solve result from generation (avoids re-solving for hints/PDF).
  final SolveResult? solveResult;

  /// Stable ID of the quote assigned to this puzzle (see [QuoteRepository]).
  final int? quoteId;

  /// How the puzzle was completed (null if still in progress).
  CompletionType? completionType;

  Puzzle({
    required this.initialBoard,
    required this.solution,
    required this.board,
    required this.difficulty,
    this.solveResult,
    this.quoteId,
    this.completionType,
    MoveHistory? history,
    DateTime? createdAt,
  })  : history = history ?? MoveHistory(),
        createdAt = createdAt ?? DateTime.now();

  /// Whether the player has correctly solved the puzzle.
  bool get isSolved => board.isSolved;

  /// Number of empty cells remaining.
  int get emptyCellCount {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getCell(r, c).isEmpty) count++;
      }
    }
    return count;
  }

  /// Total number of cells the player needs to fill (non-givens).
  int get totalToFill {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (!initialBoard.getCell(r, c).isGiven) count++;
      }
    }
    return count;
  }
}
