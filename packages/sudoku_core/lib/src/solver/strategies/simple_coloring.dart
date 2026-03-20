import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// Simple Coloring (Singles Chains): For a candidate that appears in
/// exactly two cells in some houses, build a chain of alternating
/// colors. Contradictions or eliminations arise from color clashes.
class SimpleColoring extends Strategy {
  @override
  SolveStep? apply(Board board) {
    for (var v = 1; v <= 9; v++) {
      // Build conjugate pairs: houses where v appears in exactly 2 cells.
      final graph = <_CellPos, Set<_CellPos>>{};

      for (var i = 0; i < 9; i++) {
        _addConjugatePair(board.getRow(i), v, graph);
        _addConjugatePair(board.getColumn(i), v, graph);
        _addConjugatePair(board.getBox(i), v, graph);
      }

      if (graph.isEmpty) continue;

      // BFS to color each connected component independently.
      final colored = <_CellPos, int>{};
      for (final start in graph.keys) {
        if (colored.containsKey(start)) continue;

        // Track this component's cells.
        final component = <_CellPos>[];
        final queue = <_CellPos>[start];
        colored[start] = 0;
        component.add(start);

        var hasClash = false;
        var clashColor = 0;

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          final nextColor = 1 - colored[current]!;

          for (final neighbour in graph[current] ?? <_CellPos>{}) {
            if (colored.containsKey(neighbour)) {
              // Rule 2: same color in same component → contradiction.
              if (colored[neighbour] == colored[current]) {
                hasClash = true;
                clashColor = colored[current]!;
              }
              continue;
            }
            colored[neighbour] = nextColor;
            component.add(neighbour);
            queue.add(neighbour);
          }
        }

        // Rule 2: Color clash — all cells of the bad color are false.
        if (hasClash) {
          final eliminations = <Elimination>[];
          final involved = <({int row, int col})>[];

          for (final p in component) {
            involved.add((row: p.row, col: p.col));
            if (colored[p] == clashColor) {
              eliminations.add(Elimination(p.row, p.col, v));
            }
          }

          if (eliminations.isNotEmpty) {
            return SolveStep(
              strategy: StrategyType.simpleColoring,
              eliminations: eliminations,
              involvedCells: involved,
              description:
                  'Simple Coloring (color clash): eliminate $v '
                  'from same-color cells',
            );
          }
        }

        // Rule 4: Any uncolored cell that sees cells of both colors
        // within THIS component can have v eliminated.
        final color0 =
            component.where((p) => colored[p] == 0).toList();
        final color1 =
            component.where((p) => colored[p] == 1).toList();

        if (color0.isEmpty || color1.isEmpty) continue;

        final eliminations = <Elimination>[];
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            final cell = board.getCell(r, c);
            if (cell.isFilled || !cell.candidates.contains(v)) continue;
            final pos = _CellPos(r, c);
            if (colored.containsKey(pos)) continue;

            final seesC0 = color0.any((p) => isPeer(r, c, p.row, p.col));
            final seesC1 = color1.any((p) => isPeer(r, c, p.row, p.col));

            if (seesC0 && seesC1) {
              eliminations.add(Elimination(r, c, v));
            }
          }
        }

        if (eliminations.isNotEmpty) {
          final involved =
              component.map((p) => (row: p.row, col: p.col)).toList();
          return SolveStep(
            strategy: StrategyType.simpleColoring,
            eliminations: eliminations,
            involvedCells: involved,
            description:
                'Simple Coloring (sees both colors): eliminate $v',
          );
        }
      }
    }
    return null;
  }

  void _addConjugatePair(
      List<Cell> house, int v, Map<_CellPos, Set<_CellPos>> graph) {
    final cells =
        house.where((c) => c.isEmpty && c.candidates.contains(v)).toList();
    if (cells.length != 2) return;

    final a = _CellPos(cells[0].row, cells[0].col);
    final b = _CellPos(cells[1].row, cells[1].col);
    (graph[a] ??= {}).add(b);
    (graph[b] ??= {}).add(a);
  }

}

class _CellPos {
  final int row;
  final int col;

  const _CellPos(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is _CellPos && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}
