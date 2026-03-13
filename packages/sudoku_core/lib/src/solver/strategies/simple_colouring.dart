import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

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

      // BFS to colour the graph.
      final colour = <_CellPos, int>{};
      for (final start in graph.keys) {
        if (colour.containsKey(start)) continue;

        final queue = <_CellPos>[start];
        colour[start] = 0;

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          final nextColour = 1 - colour[current]!;

          for (final neighbour in graph[current] ?? <_CellPos>{}) {
            if (colour.containsKey(neighbour)) {
              // If same colour → contradiction (Rule 2).
              if (colour[neighbour] == colour[current]) {
                // All cells of this colour can have v eliminated.
                final badColour = colour[current]!;
                final eliminations = <Elimination>[];
                final involved = <({int row, int col})>[];

                for (final entry in colour.entries) {
                  involved.add((row: entry.key.row, col: entry.key.col));
                  if (entry.value == badColour) {
                    eliminations.add(
                        Elimination(entry.key.row, entry.key.col, v));
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
              continue;
            }
            colour[neighbour] = nextColour;
            queue.add(neighbour);
          }
        }

        // Rule 4: Any uncoloured cell that sees cells of both colours
        // can have v eliminated.
        final colour0 = colour.entries
            .where((e) => e.value == 0)
            .map((e) => e.key)
            .toList();
        final colour1 = colour.entries
            .where((e) => e.value == 1)
            .map((e) => e.key)
            .toList();

        final eliminations = <Elimination>[];
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            final cell = board.getCell(r, c);
            if (cell.isFilled || !cell.candidates.contains(v)) continue;
            final pos = _CellPos(r, c);
            if (colour.containsKey(pos)) continue;

            final seesC0 = colour0.any((p) => _isPeer(r, c, p.row, p.col));
            final seesC1 = colour1.any((p) => _isPeer(r, c, p.row, p.col));

            if (seesC0 && seesC1) {
              eliminations.add(Elimination(r, c, v));
            }
          }
        }

        if (eliminations.isNotEmpty) {
          final involved = colour.keys
              .map((p) => (row: p.row, col: p.col))
              .toList();
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

  bool _isPeer(int r1, int c1, int r2, int c2) {
    if (r1 == r2 && c1 == c2) return false;
    if (r1 == r2) return true;
    if (c1 == c2) return true;
    return (r1 ~/ 3 == r2 ~/ 3) && (c1 ~/ 3 == c2 ~/ 3);
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
