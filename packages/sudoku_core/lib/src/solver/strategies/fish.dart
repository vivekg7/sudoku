import '../../models/board.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// X-Wing, Swordfish, Jellyfish — generalized "fish" pattern.
///
/// For a candidate value, if N rows each contain that candidate in exactly
/// the same N columns (or vice versa), the candidate can be eliminated from
/// those columns in all other rows.
class Fish extends Strategy {
  final int size; // 2 = X-Wing, 3 = Swordfish, 4 = Jellyfish

  Fish(this.size) : assert(size >= 2 && size <= 4);

  StrategyType get _type {
    switch (size) {
      case 2:
        return StrategyType.xWing;
      case 3:
        return StrategyType.swordfish;
      default:
        return StrategyType.jellyfish;
    }
  }

  @override
  SolveStep? apply(Board board) {
    // Try rows as base, columns as cover.
    final result = _find(board, rowBased: true);
    if (result != null) return result;
    // Try columns as base, rows as cover.
    return _find(board, rowBased: false);
  }

  SolveStep? _find(Board board, {required bool rowBased}) {
    for (var v = 1; v <= 9; v++) {
      // Build a map: line index → set of positions in the cross direction
      // where candidate v appears.
      final linePositions = <int, Set<int>>{};

      for (var i = 0; i < 9; i++) {
        final line = rowBased ? board.getRow(i) : board.getColumn(i);
        final positions = <int>{};
        for (var j = 0; j < 9; j++) {
          final cell = line[j];
          if (cell.candidates.contains(v)) {
            positions.add(j);
          }
        }
        // Only consider lines with 2..size positions.
        if (positions.length >= 2 && positions.length <= size) {
          linePositions[i] = positions;
        }
      }

      if (linePositions.length < size) continue;

      // Try all combinations of `size` lines.
      final lineIndices = linePositions.keys.toList();
      for (final combo in combinations(lineIndices, size)) {
        final coverPositions = <int>{};
        for (final lineIdx in combo) {
          coverPositions.addAll(linePositions[lineIdx]!);
        }

        if (coverPositions.length != size) continue;

        // Found a fish! Eliminate v from cover lines outside the base lines.
        final baseSet = combo.toSet();
        final eliminations = <Elimination>[];
        final involvedCells = <({int row, int col})>[];

        for (final coverIdx in coverPositions) {
          final coverLine =
              rowBased ? board.getColumn(coverIdx) : board.getRow(coverIdx);
          for (var i = 0; i < 9; i++) {
            final cell = coverLine[i];
            final baseIdx = rowBased ? cell.row : cell.col;
            if (baseSet.contains(baseIdx)) {
              if (cell.candidates.contains(v)) {
                involvedCells.add((row: cell.row, col: cell.col));
              }
              continue;
            }
            if (cell.candidates.contains(v)) {
              eliminations.add(Elimination(cell.row, cell.col, v));
            }
          }
        }

        if (eliminations.isEmpty) continue;

        final baseName = rowBased ? 'rows' : 'columns';
        final coverName = rowBased ? 'columns' : 'rows';
        final baseList = combo.map((i) => i + 1).toList()..sort();
        final coverList = (coverPositions.toList()..sort())
            .map((i) => i + 1)
            .toList();

        return SolveStep(
          strategy: _type,
          eliminations: eliminations,
          involvedCells: involvedCells,
          description:
              '${_type.label}: $v in $baseName $baseList, '
              '$coverName $coverList',
        );
      }
    }
    return null;
  }
}
