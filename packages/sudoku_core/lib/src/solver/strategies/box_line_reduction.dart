import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Box/Line Reduction (Claiming): When a candidate in a row or column is
/// restricted to a single box, that candidate can be eliminated from the
/// rest of that box.
class BoxLineReduction extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Check rows.
    for (var row = 0; row < 9; row++) {
      final result = _findInLine(board, board.getRow(row), 'row ${row + 1}');
      if (result != null) return result;
    }
    // Check columns.
    for (var col = 0; col < 9; col++) {
      final result =
          _findInLine(board, board.getColumn(col), 'column ${col + 1}');
      if (result != null) return result;
    }
    return null;
  }

  SolveStep? _findInLine(Board board, List<Cell> line, String lineName) {
    for (var v = 1; v <= 9; v++) {
      if (line.any((c) => c.value == v)) continue;

      final cells = line.where((c) => c.candidates.contains(v)).toList();
      if (cells.length < 2 || cells.length > 3) continue;

      final boxes = cells.map((c) => c.box).toSet();
      if (boxes.length != 1) continue;

      final box = boxes.first;
      final eliminations = <Elimination>[];
      for (final cell in board.getBox(box)) {
        if (cells.any((c) => c.row == cell.row && c.col == cell.col)) continue;
        if (cell.candidates.contains(v)) {
          eliminations.add(Elimination(cell.row, cell.col, v));
        }
      }

      if (eliminations.isNotEmpty) {
        return SolveStep(
          strategy: StrategyType.boxLineReduction,
          eliminations: eliminations,
          involvedCells:
              cells.map((c) => (row: c.row, col: c.col)).toList(),
          description:
              'Box/Line Reduction: $v in $lineName is locked to '
              'box ${box + 1}',
        );
      }
    }
    return null;
  }
}
