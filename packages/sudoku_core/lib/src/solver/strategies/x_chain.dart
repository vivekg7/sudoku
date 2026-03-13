import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// X-Chain: A chain of conjugate pairs for a single candidate.
/// If the chain has an even number of links, cells that see both
/// endpoints can have the candidate eliminated.
class XChain extends Strategy {
  @override
  SolveStep? apply(Board board) {
    for (var v = 1; v <= 9; v++) {
      // Build conjugate pair graph for value v.
      final graph = <_Pos, Set<_Pos>>{};

      for (var i = 0; i < 9; i++) {
        _addConjugatePair(board.getRow(i), v, graph);
        _addConjugatePair(board.getColumn(i), v, graph);
        _addConjugatePair(board.getBox(i), v, graph);
      }

      if (graph.length < 4) continue;

      // Find chains of even length (at least 4 nodes) using BFS from each node.
      final nodes = graph.keys.toList();
      for (final start in nodes) {
        // BFS with tracking of chain parity.
        final visited = <_Pos, int>{}; // pos → depth
        final queue = <(_Pos, int)>[(start, 0)];
        visited[start] = 0;

        while (queue.isNotEmpty) {
          final (current, depth) = queue.removeAt(0);

          for (final next in graph[current] ?? <_Pos>{}) {
            if (visited.containsKey(next)) continue;
            visited[next] = depth + 1;
            queue.add((next, depth + 1));

            // Even depth from start means same parity → chain endpoints.
            // We need odd number of links (even depth) for elimination.
            if ((depth + 1).isEven && depth + 1 >= 4) {
              // start and next are connected by an even-length chain.
              // Cells seeing both endpoints can eliminate v.
              final eliminations = <Elimination>[];
              for (var r = 0; r < 9; r++) {
                for (var c = 0; c < 9; c++) {
                  final cell = board.getCell(r, c);
                  if (cell.isFilled || !cell.candidates.contains(v)) continue;
                  final pos = _Pos(r, c);
                  if (pos == start || pos == next) continue;

                  if (isPeer(r, c, start.row, start.col) &&
                      isPeer(r, c, next.row, next.col)) {
                    eliminations.add(Elimination(r, c, v));
                  }
                }
              }

              if (eliminations.isNotEmpty) {
                // Reconstruct chain for involved cells.
                final involved = visited.keys
                    .where((p) =>
                        visited[p]! <= depth + 1 &&
                        visited[p]! >= 0)
                    .map((p) => (row: p.row, col: p.col))
                    .toList();

                return SolveStep(
                  strategy: StrategyType.xChain,
                  eliminations: eliminations,
                  involvedCells: involved,
                  description:
                      'X-Chain on $v: '
                      'R${start.row + 1}C${start.col + 1} → '
                      'R${next.row + 1}C${next.col + 1} '
                      '(${depth + 1} links)',
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  void _addConjugatePair(
      List<Cell> house, int v, Map<_Pos, Set<_Pos>> graph) {
    final cells =
        house.where((c) => c.isEmpty && c.candidates.contains(v)).toList();
    if (cells.length != 2) return;
    final a = _Pos(cells[0].row, cells[0].col);
    final b = _Pos(cells[1].row, cells[1].col);
    (graph[a] ??= {}).add(b);
    (graph[b] ??= {}).add(a);
  }

}

class _Pos {
  final int row;
  final int col;
  const _Pos(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is _Pos && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}
