import '../../models/board.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Pointing Pairs/Triples: When a candidate in a box is restricted to a
/// single row or column, that candidate can be eliminated from the rest
/// of that row or column outside the box.
class Pointing extends Strategy {
  @override
  SolveStep? apply(Board board) {
    for (var box = 0; box < 9; box++) {
      final boxCells = board.getBox(box);

      for (var v = 1; v <= 9; v++) {
        // Skip if value is already placed in this box.
        if (boxCells.any((c) => c.value == v)) continue;

        final cells =
            boxCells.where((c) => c.candidates.contains(v)).toList();
        if (cells.length < 2 || cells.length > 3) continue;

        // Check if all cells are in the same row.
        final rows = cells.map((c) => c.row).toSet();
        if (rows.length == 1) {
          final row = rows.first;
          final eliminations = <Elimination>[];
          for (final cell in board.getRow(row)) {
            if (cell.box == box) continue; // skip cells in this box
            if (cell.candidates.contains(v)) {
              eliminations.add(Elimination(cell.row, cell.col, v));
            }
          }
          if (eliminations.isNotEmpty) {
            final type = cells.length == 2
                ? StrategyType.pointingPair
                : StrategyType.pointingTriple;
            return SolveStep(
              strategy: type,
              eliminations: eliminations,
              involvedCells:
                  cells.map((c) => (row: c.row, col: c.col)).toList(),
              description:
                  '${type.label}: $v in box ${box + 1} is locked to '
                  'row ${row + 1}',
            );
          }
        }

        // Check if all cells are in the same column.
        final cols = cells.map((c) => c.col).toSet();
        if (cols.length == 1) {
          final col = cols.first;
          final eliminations = <Elimination>[];
          for (final cell in board.getColumn(col)) {
            if (cell.box == box) continue;
            if (cell.candidates.contains(v)) {
              eliminations.add(Elimination(cell.row, cell.col, v));
            }
          }
          if (eliminations.isNotEmpty) {
            final type = cells.length == 2
                ? StrategyType.pointingPair
                : StrategyType.pointingTriple;
            return SolveStep(
              strategy: type,
              eliminations: eliminations,
              involvedCells:
                  cells.map((c) => (row: c.row, col: c.col)).toList(),
              description:
                  '${type.label}: $v in box ${box + 1} is locked to '
                  'column ${col + 1}',
            );
          }
        }
      }
    }
    return null;
  }
}
