import '../../models/board.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Backtracking: Brute-force solver used as a last resort.
/// Tries candidates in empty cells recursively.
///
/// This is not a logical strategy — it's a fallback for validation
/// and for puzzles that require techniques beyond what's implemented.
class Backtracking extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Find the first empty cell.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;

        // Try each candidate.
        for (final v in cell.candidates) {
          final clone = board.clone();
          clone.getCell(r, c).setValue(v);

          // Update candidates for peers.
          for (final peer in clone.peers(r, c)) {
            peer.removeCandidate(v);
          }

          if (_solve(clone)) {
            return SolveStep(
              strategy: StrategyType.backtracking,
              placements: [Placement(r, c, v)],
              involvedCells: [(row: r, col: c)],
              description:
                  'Backtracking: place $v at R${r + 1}C${c + 1}',
            );
          }
        }

        // If no candidate works, the board is unsolvable.
        return null;
      }
    }
    return null; // board is already solved
  }

  /// Solves the board using recursive backtracking. Returns true if solvable.
  static bool _solve(Board board) {
    // Find the empty cell with fewest candidates (MRV heuristic).
    int? bestRow, bestCol;
    var bestCount = 10;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;
        if (cell.candidates.isEmpty) return false; // dead end
        if (cell.candidates.length < bestCount) {
          bestCount = cell.candidates.length;
          bestRow = r;
          bestCol = c;
        }
      }
    }

    if (bestRow == null) return true; // all cells filled

    final cell = board.getCell(bestRow, bestCol!);
    for (final v in cell.candidates.toList()) {
      final clone = board.clone();
      clone.getCell(bestRow, bestCol).setValue(v);

      for (final peer in clone.peers(bestRow, bestCol)) {
        peer.removeCandidate(v);
      }

      if (_solve(clone)) return true;
    }

    return false;
  }

  /// Public utility: check if a board has a unique solution.
  /// Returns 0 (no solution), 1 (unique), or 2 (multiple).
  static int countSolutions(Board board, {int limit = 2}) {
    var count = 0;
    _countSolutions(board.clone(), limit, (n) => count = n, () => count);
    return count;
  }

  static void _countSolutions(
    Board board,
    int limit,
    void Function(int) setCount,
    int Function() getCount,
  ) {
    // Find empty cell with fewest candidates.
    int? bestRow, bestCol;
    var bestCount = 10;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;
        if (cell.candidates.isEmpty) return;
        if (cell.candidates.length < bestCount) {
          bestCount = cell.candidates.length;
          bestRow = r;
          bestCol = c;
        }
      }
    }

    if (bestRow == null) {
      setCount(getCount() + 1);
      return;
    }

    final cell = board.getCell(bestRow, bestCol!);
    for (final v in cell.candidates.toList()) {
      if (getCount() >= limit) return;

      final clone = board.clone();
      clone.getCell(bestRow, bestCol).setValue(v);
      for (final peer in clone.peers(bestRow, bestCol)) {
        peer.removeCandidate(v);
      }
      _countSolutions(clone, limit, setCount, getCount);
    }
  }
}
