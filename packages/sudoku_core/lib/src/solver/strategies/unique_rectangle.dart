import '../../models/board.dart';
import '../../models/candidate_set.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Unique Rectangle: If a deadly pattern (two values in exactly four cells
/// forming a rectangle across two boxes) would create two solutions, we
/// can eliminate candidates to prevent it.
class UniqueRectangle extends Strategy {
  @override
  SolveStep? apply(Board board) {
    // Find all bi-value cells.
    final biCells = <Cell>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isEmpty && cell.candidates.length == 2) {
          biCells.add(cell);
        }
      }
    }

    // Try all pairs of bi-value cells with the same candidates in the same row.
    for (var i = 0; i < biCells.length; i++) {
      for (var j = i + 1; j < biCells.length; j++) {
        final a = biCells[i];
        final b = biCells[j];

        if (a.row != b.row) continue;
        if (a.box == b.box) continue; // must span two boxes
        if (!_sameCandidates(a, b)) continue;

        final pair = a.candidates.toList()..sort();
        final x = pair[0];
        final y = pair[1];

        // Look for the other two corners in a different row.
        for (var r2 = 0; r2 < 9; r2++) {
          if (r2 == a.row) continue;
          final c1 = board.getCell(r2, a.col);
          final c2 = board.getCell(r2, b.col);

          if (c1.isFilled || c2.isFilled) continue;
          if (!c1.candidates.contains(x) || !c1.candidates.contains(y)) {
            continue;
          }
          if (!c2.candidates.contains(x) || !c2.candidates.contains(y)) {
            continue;
          }

          // Must span exactly 2 boxes.
          final boxes = {a.box, b.box, c1.box, c2.box};
          if (boxes.length != 2) continue;

          // Now classify the UR type based on the floor/roof cells.
          // a, b are "floor" (bi-value). c1, c2 are "roof".
          final result = _classifyAndSolve(board, a, b, c1, c2, x, y);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  SolveStep? _classifyAndSolve(
    Board board,
    Cell floor1,
    Cell floor2,
    Cell roof1,
    Cell roof2,
    int x,
    int y,
  ) {
    final roofCells = [roof1, roof2];
    final allCells = [floor1, floor2, roof1, roof2];
    final involved =
        allCells.map((c) => (row: c.row, col: c.col)).toList();

    // Type 1: One roof cell is bi-value {x,y}, the other has extra candidates.
    // The bi-value roof would complete the deadly pattern, so the other roof
    // must not contain both x and y → eliminate x and y from the non-bi-value roof.
    for (var i = 0; i < 2; i++) {
      final biRoof = roofCells[i];
      final otherRoof = roofCells[1 - i];

      if (biRoof.candidates.length == 2 &&
          _sameCandidates(biRoof, floor1) &&
          otherRoof.candidates.length > 2) {
        final eliminations = <Elimination>[];
        if (otherRoof.candidates.contains(x)) {
          eliminations.add(Elimination(otherRoof.row, otherRoof.col, x));
        }
        if (otherRoof.candidates.contains(y)) {
          eliminations.add(Elimination(otherRoof.row, otherRoof.col, y));
        }
        if (eliminations.isNotEmpty) {
          return SolveStep(
            strategy: StrategyType.uniqueRectangleType1,
            eliminations: eliminations,
            involvedCells: involved,
            description:
                'UR Type 1: {$x,$y} at '
                '${_cellName(floor1)},${_cellName(floor2)},'
                '${_cellName(biRoof)} → eliminate from '
                '${_cellName(otherRoof)}',
          );
        }
      }
    }

    // Type 2: Both roof cells have the same extra candidate Z beyond {x,y}.
    // Z can be eliminated from cells that see both roof cells.
    if (roof1.candidates.length == 3 &&
        roof2.candidates.length == 3 &&
        _sameCandidates(roof1, roof2)) {
      final extras =
          roof1.candidates.where((v) => v != x && v != y).toList();
      if (extras.length == 1) {
        final z = extras.first;
        final r1Peers = board.peers(roof1.row, roof1.col).toSet();
        final r2Peers = board.peers(roof2.row, roof2.col).toSet();
        final commonPeers = r1Peers.intersection(r2Peers);

        final eliminations = <Elimination>[];
        for (final cell in commonPeers) {
          if (allCells.any((c) => c.row == cell.row && c.col == cell.col)) {
            continue;
          }
          if (cell.candidates.contains(z)) {
            eliminations.add(Elimination(cell.row, cell.col, z));
          }
        }

        if (eliminations.isNotEmpty) {
          return SolveStep(
            strategy: StrategyType.uniqueRectangleType2,
            eliminations: eliminations,
            involvedCells: involved,
            description:
                'UR Type 2: {$x,$y} rectangle, both roofs have $z '
                '→ eliminate $z from common peers',
          );
        }
      }
    }

    // Type 3: One or both roof cells have extra candidates. The extras in
    // the roof cells, combined, form a naked subset with other cells in
    // a shared house → eliminations from that house.
    // (Simplified: check if extras from both roofs form a pair with a
    // cell in a shared row/column/box.)
    final result = _type3(board, floor1, floor2, roof1, roof2, x, y, involved);
    if (result != null) return result;

    // Type 4: Lock one of {x,y} into the rectangle by showing it can only
    // appear in the roof cells within their shared row/column/box.
    // The other value is eliminated from both roof cells.
    for (final v in [x, y]) {
      final other = v == x ? y : x;

      // Check if v is locked to roof cells in their shared row.
      if (roof1.row == roof2.row) {
        final row = board.getRow(roof1.row);
        final vCells = row
            .where((c) =>
                c.candidates.contains(v) &&
                !(c.row == roof1.row && c.col == roof1.col) &&
                !(c.row == roof2.row && c.col == roof2.col))
            .toList();
        if (vCells.isEmpty) {
          // v is locked to roof cells in this row.
          final eliminations = <Elimination>[];
          if (roof1.candidates.contains(other)) {
            eliminations.add(Elimination(roof1.row, roof1.col, other));
          }
          if (roof2.candidates.contains(other)) {
            eliminations.add(Elimination(roof2.row, roof2.col, other));
          }
          if (eliminations.isNotEmpty) {
            return SolveStep(
              strategy: StrategyType.uniqueRectangleType4,
              eliminations: eliminations,
              involvedCells: involved,
              description:
                  'UR Type 4: $v locked in roof row → eliminate $other '
                  'from roof cells',
            );
          }
        }
      }

      // Check shared column.
      if (roof1.col == roof2.col) {
        final col = board.getColumn(roof1.col);
        final vCells = col
            .where((c) =>
                c.candidates.contains(v) &&
                !(c.row == roof1.row && c.col == roof1.col) &&
                !(c.row == roof2.row && c.col == roof2.col))
            .toList();
        if (vCells.isEmpty) {
          final eliminations = <Elimination>[];
          if (roof1.candidates.contains(other)) {
            eliminations.add(Elimination(roof1.row, roof1.col, other));
          }
          if (roof2.candidates.contains(other)) {
            eliminations.add(Elimination(roof2.row, roof2.col, other));
          }
          if (eliminations.isNotEmpty) {
            return SolveStep(
              strategy: StrategyType.uniqueRectangleType4,
              eliminations: eliminations,
              involvedCells: involved,
              description:
                  'UR Type 4: $v locked in roof column → eliminate $other '
                  'from roof cells',
            );
          }
        }
      }
    }

    return null;
  }

  SolveStep? _type3(
    Board board,
    Cell floor1,
    Cell floor2,
    Cell roof1,
    Cell roof2,
    int x,
    int y,
    List<({int row, int col})> involved,
  ) {
    // Collect extra candidates from both roof cells.
    final extras = CandidateSet();
    for (final v in roof1.candidates) {
      if (v != x && v != y) extras.add(v);
    }
    for (final v in roof2.candidates) {
      if (v != x && v != y) extras.add(v);
    }

    if (extras.isEmpty) return null;

    // If both roof cells are in the same row, check that row for a naked
    // subset with the extras.
    if (roof1.row == roof2.row) {
      final result = _type3InHouse(
        board.getRow(roof1.row),
        'row ${roof1.row + 1}',
        roof1,
        roof2,
        extras,
        x,
        y,
        involved,
      );
      if (result != null) return result;
    }

    // Both roofs always share a row (they're in the same row by construction
    // of the rectangle). But they might also share a box.
    if (roof1.box == roof2.box) {
      final result = _type3InHouse(
        board.getBox(roof1.box),
        'box ${roof1.box + 1}',
        roof1,
        roof2,
        extras,
        x,
        y,
        involved,
      );
      if (result != null) return result;
    }

    return null;
  }

  SolveStep? _type3InHouse(
    List<Cell> house,
    String houseName,
    Cell roof1,
    Cell roof2,
    CandidateSet extras,
    int x,
    int y,
    List<({int row, int col})> involved,
  ) {
    // Find cells in the house (not part of UR) whose candidates are a
    // subset of extras.
    final otherCells = house.where((c) {
      if (c.isFilled) return false;
      if (c.row == roof1.row && c.col == roof1.col) return false;
      if (c.row == roof2.row && c.col == roof2.col) return false;
      return c.candidates.isNotEmpty &&
          c.candidates.every((v) => extras.contains(v));
    }).toList();

    // Check if extras + any subset of otherCells forms a naked set of
    // size = extras.length. Simplest case: extras.length == 1 and one
    // other cell has exactly that candidate.
    // For now, handle the common case: extras form a pair with one cell.
    if (extras.length == 1) return null; // need at least a pair

    for (final cell in otherCells) {
      final combined = extras.union(cell.candidates);
      if (combined.length == extras.length && extras.length == 2) {
        // We have a naked pair between the UR extras and this cell.
        final eliminations = <Elimination>[];
        for (final hCell in house) {
          if (hCell.isFilled) continue;
          if (hCell.row == roof1.row && hCell.col == roof1.col) continue;
          if (hCell.row == roof2.row && hCell.col == roof2.col) continue;
          if (hCell.row == cell.row && hCell.col == cell.col) continue;
          for (final v in extras) {
            if (hCell.candidates.contains(v)) {
              eliminations.add(Elimination(hCell.row, hCell.col, v));
            }
          }
        }

        if (eliminations.isNotEmpty) {
          return SolveStep(
            strategy: StrategyType.uniqueRectangleType3,
            eliminations: eliminations,
            involvedCells: [
              ...involved,
              (row: cell.row, col: cell.col),
            ],
            description:
                'UR Type 3: extras {${extras.toList()..sort()}} form '
                'naked pair with ${_cellName(cell)} in $houseName',
          );
        }
      }
    }

    return null;
  }

  bool _sameCandidates(Cell a, Cell b) =>
      a.candidates.length == b.candidates.length &&
      a.candidates.containsAll(b.candidates);

  String _cellName(Cell c) => 'R${c.row + 1}C${c.col + 1}';
}
