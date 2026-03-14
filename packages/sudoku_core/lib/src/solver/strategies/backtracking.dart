import '../../models/board.dart';
import '../../models/cell.dart';
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
  ///
  /// Uses undo-and-restore instead of cloning — sets a value, tracks
  /// affected peers, recurses, then undoes on failure. On success the
  /// board is left in the solved state.
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
    final savedCandidates = cell.candidates.copy();

    for (final v in savedCandidates) {
      cell.setValue(v);

      // Remove v from peers' candidates, tracking which peers changed.
      final affected = <Cell>[];
      for (final peer in board.peers(bestRow, bestCol)) {
        if (peer.candidates.contains(v)) {
          peer.removeCandidate(v);
          affected.add(peer);
        }
      }

      if (_solve(board)) return true;

      // Undo: restore cell and affected peers.
      cell.clearValue();
      cell.setCandidates(savedCandidates);
      for (final peer in affected) {
        peer.addCandidate(v);
      }
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
    final savedCandidates = cell.candidates.copy();

    for (final v in savedCandidates) {
      if (getCount() >= limit) return;

      cell.setValue(v);

      final affected = <Cell>[];
      for (final peer in board.peers(bestRow, bestCol)) {
        if (peer.candidates.contains(v)) {
          peer.removeCandidate(v);
          affected.add(peer);
        }
      }

      _countSolutions(board, limit, setCount, getCount);

      // Always undo to explore other branches.
      cell.clearValue();
      cell.setCandidates(savedCandidates);
      for (final peer in affected) {
        peer.addCandidate(v);
      }
    }
  }
}
