import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Sue de Coq: An intersection of a box and a line contains N cells
/// with N+2 candidates. The extra candidates can be split into two
/// groups: one locked to the rest of the line, one locked to the rest
/// of the box. This allows eliminations in both.
class SueDeCoq extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Check each box-line intersection.
    for (var box = 0; box < 9; box++) {
      final boxCells = board.getBox(box);
      final boxStartRow = (box ~/ 3) * 3;
      final boxStartCol = (box % 3) * 3;

      // Check intersections with rows.
      for (var r = boxStartRow; r < boxStartRow + 3; r++) {
        final result = _check(board, boxCells, board.getRow(r), box, r, true);
        if (result != null) return result;
      }

      // Check intersections with columns.
      for (var c = boxStartCol; c < boxStartCol + 3; c++) {
        final result =
            _check(board, boxCells, board.getColumn(c), box, c, false);
        if (result != null) return result;
      }
    }
    return null;
  }

  SolveStep? _check(
    Board board,
    List<Cell> boxCells,
    List<Cell> line,
    int box,
    int lineIdx,
    bool isRow,
  ) {
    // Intersection cells: cells in both the box and the line.
    final intersection = line
        .where((c) => c.box == box && c.isEmpty && c.candidates.isNotEmpty)
        .toList();

    if (intersection.length < 2 || intersection.length > 3) return null;

    final interCands = <int>{};
    for (final c in intersection) {
      interCands.addAll(c.candidates);
    }

    // Need N+2 candidates for N cells.
    if (interCands.length != intersection.length + 2) return null;

    // Rest of line (outside box).
    final restLine = line
        .where((c) => c.box != box && c.isEmpty && c.candidates.isNotEmpty)
        .toList();
    // Rest of box (outside line).
    final restBox = boxCells
        .where((c) {
          if (isRow) return c.row != lineIdx;
          return c.col != lineIdx;
        })
        .where((c) => c.isEmpty && c.candidates.isNotEmpty)
        .toList();

    final restLineCands = <int>{};
    for (final c in restLine) {
      restLineCands.addAll(c.candidates);
    }
    final restBoxCands = <int>{};
    for (final c in restBox) {
      restBoxCands.addAll(c.candidates);
    }

    // Try to partition interCands into lineOnly + boxOnly + shared.
    // lineOnly: candidates that appear in restLine but not restBox.
    // boxOnly: candidates that appear in restBox but not restLine.
    final lineOnly = interCands.intersection(restLineCands).difference(restBoxCands);
    final boxOnly = interCands.intersection(restBoxCands).difference(restLineCands);

    if (lineOnly.isEmpty && boxOnly.isEmpty) return null;

    // Validate: lineOnly + boxOnly must cover the "extra" 2 candidates.
    // The remaining candidates (shared) form the core.
    final accounted = lineOnly.union(boxOnly);
    if (accounted.length < 2) return null;

    final eliminations = <Elimination>[];

    // Eliminate lineOnly candidates from rest of line.
    for (final c in restLine) {
      for (final v in lineOnly) {
        if (c.candidates.contains(v)) {
          eliminations.add(Elimination(c.row, c.col, v));
        }
      }
    }

    // Eliminate boxOnly candidates from rest of box.
    for (final c in restBox) {
      for (final v in boxOnly) {
        if (c.candidates.contains(v)) {
          eliminations.add(Elimination(c.row, c.col, v));
        }
      }
    }

    if (eliminations.isEmpty) return null;

    final involved =
        intersection.map((c) => (row: c.row, col: c.col)).toList();
    final lineName = isRow ? 'row ${lineIdx + 1}' : 'column ${lineIdx + 1}';

    return SolveStep(
      strategy: StrategyType.sueDeCoq,
      eliminations: eliminations,
      involvedCells: involved,
      description:
          'Sue de Coq: box ${box + 1} ∩ $lineName, '
          'line-locked={${lineOnly.toList()..sort()}}, '
          'box-locked={${boxOnly.toList()..sort()}}',
    );
  }
}
