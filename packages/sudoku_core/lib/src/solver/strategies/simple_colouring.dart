import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// Simple Colouring (Singles Chains): For a candidate that appears in
/// exactly two cells in some houses, build a chain of alternating
/// colours. Contradictions or eliminations arise from colour clashes.
class SimpleColouring extends Strategy {
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

      // BFS to colour each connected component independently.
      final coloured = <_CellPos, int>{};
      for (final start in graph.keys) {
        if (coloured.containsKey(start)) continue;

        // Track this component's cells.
        final component = <_CellPos>[];
        final queue = <_CellPos>[start];
        coloured[start] = 0;
        component.add(start);

        var hasClash = false;
        var clashColour = 0;

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          final nextColour = 1 - coloured[current]!;

          for (final neighbour in graph[current] ?? <_CellPos>{}) {
            if (coloured.containsKey(neighbour)) {
              // Rule 2: same colour in same component → contradiction.
              if (coloured[neighbour] == coloured[current]) {
                hasClash = true;
                clashColour = coloured[current]!;
              }
              continue;
            }
            coloured[neighbour] = nextColour;
            component.add(neighbour);
            queue.add(neighbour);
          }
        }

        // Rule 2: Colour clash — all cells of the bad colour are false.
        if (hasClash) {
          final eliminations = <Elimination>[];
          final involved = <({int row, int col})>[];

          for (final p in component) {
            involved.add((row: p.row, col: p.col));
            if (coloured[p] == clashColour) {
              eliminations.add(Elimination(p.row, p.col, v));
            }
          }

          if (eliminations.isNotEmpty) {
            return SolveStep(
              strategy: StrategyType.simpleColouring,
              eliminations: eliminations,
              involvedCells: involved,
              description:
                  'Simple Colouring (colour clash): eliminate $v '
                  'from same-colour cells',
            );
          }
        }

        // Rule 4: Any uncoloured cell that sees cells of both colours
        // within THIS component can have v eliminated.
        final colour0 =
            component.where((p) => coloured[p] == 0).toList();
        final colour1 =
            component.where((p) => coloured[p] == 1).toList();

        if (colour0.isEmpty || colour1.isEmpty) continue;

        final eliminations = <Elimination>[];
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            final cell = board.getCell(r, c);
            if (cell.isFilled || !cell.candidates.contains(v)) continue;
            final pos = _CellPos(r, c);
            if (coloured.containsKey(pos)) continue;

            final seesC0 = colour0.any((p) => isPeer(r, c, p.row, p.col));
            final seesC1 = colour1.any((p) => isPeer(r, c, p.row, p.col));

            if (seesC0 && seesC1) {
              eliminations.add(Elimination(r, c, v));
            }
          }
        }

        if (eliminations.isNotEmpty) {
          final involved =
              component.map((p) => (row: p.row, col: p.col)).toList();
          return SolveStep(
            strategy: StrategyType.simpleColouring,
            eliminations: eliminations,
            involvedCells: involved,
            description:
                'Simple Colouring (sees both colours): eliminate $v',
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
