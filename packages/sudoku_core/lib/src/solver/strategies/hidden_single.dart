import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// A value that can only go in one cell within a row, column, or box.
class HiddenSingle extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Check each house type: rows, columns, boxes.
    for (var i = 0; i < 9; i++) {
      final result = _findInHouse(board.getRow(i), 'row ${i + 1}') ??
          _findInHouse(board.getColumn(i), 'column ${i + 1}') ??
          _findInHouse(board.getBox(i), 'box ${i + 1}');
      if (result != null) return result;
    }
    return null;
  }

  SolveStep? _findInHouse(List<Cell> house, String houseName) {
    for (var v = 1; v <= 9; v++) {
      // Skip if already placed in this house.
      if (house.any((c) => c.value == v)) continue;

      final cells = house.where((c) => c.candidates.contains(v)).toList();
      if (cells.length == 1) {
        final cell = cells.first;
        return SolveStep(
          strategy: StrategyType.hiddenSingle,
          placements: [Placement(cell.row, cell.col, v)],
          involvedCells: [(row: cell.row, col: cell.col)],
          description:
              '$v can only go in R${cell.row + 1}C${cell.col + 1} in $houseName',
        );
      }
    }
    return null;
  }
}
