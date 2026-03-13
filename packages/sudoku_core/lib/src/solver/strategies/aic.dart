import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// Alternating Inference Chain (AIC): A chain of alternating strong
/// and weak links between candidates. If the chain starts and ends
/// with strong links on the same candidate, cells seeing both
/// endpoints can have that candidate eliminated.
///
/// This is a generalised version that handles multi-candidate nodes
/// (unlike X-Chains which are single-candidate).
class AIC extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Build nodes: each (cell, candidate) pair is a node.
    // Strong link: only two places for a candidate in a house.
    // Weak link: two candidates in the same cell.
    final strongLinks = <_Node, Set<_Node>>{};
    final weakLinks = <_Node, Set<_Node>>{};

    // Strong links from conjugate pairs in houses.
    for (var i = 0; i < 9; i++) {
      _addStrongLinks(board.getRow(i), strongLinks);
      _addStrongLinks(board.getColumn(i), strongLinks);
      _addStrongLinks(board.getBox(i), strongLinks);
    }

    // Weak links within cells (bi-value gives strong, otherwise weak).
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled || cell.candidates.length < 2) continue;

        final cands = cell.candidates.toList();
        for (var a = 0; a < cands.length; a++) {
          for (var b = a + 1; b < cands.length; b++) {
            final na = _Node(r, c, cands[a]);
            final nb = _Node(r, c, cands[b]);
            if (cell.candidates.length == 2) {
              // Bi-value: strong link within cell.
              (strongLinks[na] ??= {}).add(nb);
              (strongLinks[nb] ??= {}).add(na);
            } else {
              (weakLinks[na] ??= {}).add(nb);
              (weakLinks[nb] ??= {}).add(na);
            }
          }
        }
      }
    }

    // Also add weak links between peers with the same candidate.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled) continue;
        for (final v in cell.candidates) {
          final node = _Node(r, c, v);
          for (final peer in board.peers(r, c)) {
            if (peer.isFilled || !peer.candidates.contains(v)) continue;
            final peerNode = _Node(peer.row, peer.col, v);
            (weakLinks[node] ??= {}).add(peerNode);
          }
        }
      }
    }

    // BFS for AIC: alternate strong→weak→strong→...
    // Start from strong link, end on strong link.
    // Look for chains where endpoints are the same candidate in
    // different cells → eliminate from cells seeing both.
    final allStrongNodes = strongLinks.keys.toList();

    for (final start in allStrongNodes) {
      // BFS with alternating link types.
      // State: (node, link_type_used_to_reach, depth)
      // Start with strong links from start.
      final visited = <(_Node, bool)>{};
      // (node, usedStrongToReach, depth, chain)
      final queue = <(_Node, bool, int)>[];

      // Initial: follow strong links from start.
      for (final next in strongLinks[start] ?? <_Node>{}) {
        queue.add((next, true, 1)); // reached via strong link
      }
      visited.add((start, true));

      while (queue.isNotEmpty) {
        final (current, reachedByStrong, depth) = queue.removeAt(0);
        final key = (current, reachedByStrong);
        if (visited.contains(key)) continue;
        visited.add(key);

        if (depth > 7) continue; // limit chain length

        // If reached by strong link AND same candidate as start,
        // different cell, chain length >= 3: check for eliminations.
        if (reachedByStrong &&
            current.value == start.value &&
            (current.row != start.row || current.col != start.col) &&
            depth >= 3) {
          final eliminations = <Elimination>[];
          for (var r = 0; r < 9; r++) {
            for (var c = 0; c < 9; c++) {
              if (r == start.row && c == start.col) continue;
              if (r == current.row && c == current.col) continue;
              final cell = board.getCell(r, c);
              if (cell.isFilled ||
                  !cell.candidates.contains(start.value)) {
                continue;
              }
              if (isPeer(r, c, start.row, start.col) &&
                  isPeer(r, c, current.row, current.col)) {
                eliminations.add(Elimination(r, c, start.value));
              }
            }
          }

          if (eliminations.isNotEmpty) {
            return SolveStep(
              strategy: StrategyType.alternatingInferenceChain,
              eliminations: eliminations,
              involvedCells: [
                (row: start.row, col: start.col),
                (row: current.row, col: current.col),
              ],
              description:
                  'AIC: R${start.row + 1}C${start.col + 1}(${start.value})'
                  ' → R${current.row + 1}C${current.col + 1}'
                  '(${current.value}) → eliminate ${start.value}',
            );
          }
        }

        // Alternate: if reached by strong, next must be weak; vice versa.
        if (reachedByStrong) {
          // Follow weak links.
          for (final next in weakLinks[current] ?? <_Node>{}) {
            queue.add((next, false, depth + 1));
          }
        } else {
          // Follow strong links.
          for (final next in strongLinks[current] ?? <_Node>{}) {
            queue.add((next, true, depth + 1));
          }
        }
      }
    }

    return null;
  }

  void _addStrongLinks(List<Cell> house, Map<_Node, Set<_Node>> graph) {
    for (var v = 1; v <= 9; v++) {
      final cells =
          house.where((c) => c.isEmpty && c.candidates.contains(v)).toList();
      if (cells.length != 2) continue;
      final a = _Node(cells[0].row, cells[0].col, v);
      final b = _Node(cells[1].row, cells[1].col, v);
      (graph[a] ??= {}).add(b);
      (graph[b] ??= {}).add(a);
    }
  }

}

class _Node {
  final int row;
  final int col;
  final int value;

  const _Node(this.row, this.col, this.value);

  @override
  bool operator ==(Object other) =>
      other is _Node &&
      row == other.row &&
      col == other.col &&
      value == other.value;

  @override
  int get hashCode => Object.hash(row, col, value);
}
