import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Almost Locked Set (ALS-XZ): Two ALS groups where:
/// - ALS A has N cells with N+1 candidates.
/// - ALS B has M cells with M+1 candidates.
/// - They share a restricted common candidate X (X only appears in
///   cells of A and B that see each other).
/// - They share another common candidate Z.
/// - Z can be eliminated from any cell that sees all Z-cells in both A and B.
class AlmostLockedSet extends Strategy {
  @override
  SolveStep? apply(Board board) {
    final alsList = _findAllALS(board);
    if (alsList.length < 2) return null;

    for (var i = 0; i < alsList.length; i++) {
      for (var j = i + 1; j < alsList.length; j++) {
        final a = alsList[i];
        final b = alsList[j];

        // ALS must not overlap.
        if (a.cells.any((ac) =>
            b.cells.any((bc) => ac.row == bc.row && ac.col == bc.col))) {
          continue;
        }

        final commonCands = a.candidates.intersection(b.candidates);
        if (commonCands.length < 2) continue;

        // Find restricted common candidate X.
        for (final x in commonCands) {
          final aCellsWithX =
              a.cells.where((c) => c.candidates.contains(x)).toList();
          final bCellsWithX =
              b.cells.where((c) => c.candidates.contains(x)).toList();

          // X is restricted if every cell in A with X sees every cell in B with X.
          final isRestricted = aCellsWithX.every((ac) =>
              bCellsWithX.every((bc) =>
                  _isPeer(ac.row, ac.col, bc.row, bc.col)));

          if (!isRestricted) continue;

          // Find Z candidates (common candidates other than X).
          for (final z in commonCands) {
            if (z == x) continue;

            final aCellsWithZ =
                a.cells.where((c) => c.candidates.contains(z)).toList();
            final bCellsWithZ =
                b.cells.where((c) => c.candidates.contains(z)).toList();

            if (aCellsWithZ.isEmpty || bCellsWithZ.isEmpty) continue;

            // Eliminate Z from cells that see all Z-cells in both A and B.
            final eliminations = <Elimination>[];
            for (var r = 0; r < 9; r++) {
              for (var c = 0; c < 9; c++) {
                final cell = board.getCell(r, c);
                if (cell.isFilled || !cell.candidates.contains(z)) continue;
                if (a.cells.any((ac) => ac.row == r && ac.col == c)) continue;
                if (b.cells.any((bc) => bc.row == r && bc.col == c)) continue;

                final seesAllA = aCellsWithZ.every(
                    (ac) => _isPeer(r, c, ac.row, ac.col));
                final seesAllB = bCellsWithZ.every(
                    (bc) => _isPeer(r, c, bc.row, bc.col));

                if (seesAllA && seesAllB) {
                  eliminations.add(Elimination(r, c, z));
                }
              }
            }

            if (eliminations.isNotEmpty) {
              final involved = [
                ...a.cells.map((c) => (row: c.row, col: c.col)),
                ...b.cells.map((c) => (row: c.row, col: c.col)),
              ];
              return SolveStep(
                strategy: StrategyType.almostLockedSet,
                eliminations: eliminations,
                involvedCells: involved,
                description:
                    'ALS-XZ: X=$x, Z=$z → eliminate $z',
              );
            }
          }
        }
      }
    }
    return null;
  }

  List<_ALS> _findAllALS(Board board) {
    final result = <_ALS>[];

    // Find ALS in each house.
    for (var i = 0; i < 9; i++) {
      _findALSInHouse(board.getRow(i), result);
      _findALSInHouse(board.getColumn(i), result);
      _findALSInHouse(board.getBox(i), result);
    }

    return result;
  }

  void _findALSInHouse(List<Cell> house, List<_ALS> result) {
    final emptyCells =
        house.where((c) => c.isEmpty && c.candidates.isNotEmpty).toList();

    // An ALS is N cells with N+1 candidates. Try sizes 1..4.
    for (var size = 1; size <= 4 && size <= emptyCells.length; size++) {
      for (final combo in _combinations(emptyCells, size)) {
        final union = <int>{};
        for (final cell in combo) {
          union.addAll(cell.candidates);
        }
        if (union.length == size + 1) {
          result.add(_ALS(List.of(combo), union));
        }
      }
    }
  }

  bool _isPeer(int r1, int c1, int r2, int c2) {
    if (r1 == r2 && c1 == c2) return false;
    if (r1 == r2) return true;
    if (c1 == c2) return true;
    return (r1 ~/ 3 == r2 ~/ 3) && (c1 ~/ 3 == c2 ~/ 3);
  }
}

class _ALS {
  final List<Cell> cells;
  final Set<int> candidates;

  _ALS(this.cells, this.candidates);
}

List<List<T>> _combinations<T>(List<T> items, int k) {
  final results = <List<T>>[];
  void recurse(int start, List<T> current) {
    if (current.length == k) {
      results.add(List.of(current));
      return;
    }
    for (var i = start; i < items.length; i++) {
      current.add(items[i]);
      recurse(i + 1, current);
      current.removeLast();
    }
  }
  recurse(0, []);
  return results;
}
