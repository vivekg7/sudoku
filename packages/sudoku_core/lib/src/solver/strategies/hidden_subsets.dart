import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';
import '../strategy_utils.dart';

/// Hidden Pair/Triple/Quad: N candidates in a house that only appear in
/// exactly N cells → all other candidates can be eliminated from those cells.
class HiddenSubset extends Strategy {
  final int size; // 2, 3, or 4

  HiddenSubset(this.size) : assert(size >= 2 && size <= 4);

  StrategyType get _type {
    switch (size) {
      case 2:
        return StrategyType.hiddenPair;
      case 3:
        return StrategyType.hiddenTriple;
      default:
        return StrategyType.hiddenQuad;
    }
  }

  String get _label {
    switch (size) {
      case 2:
        return 'pair';
      case 3:
        return 'triple';
      default:
        return 'quad';
    }
  }

  @override
  SolveStep? apply(Board board) {
    for (var i = 0; i < 9; i++) {
      final result = _findInHouse(board.getRow(i), 'row ${i + 1}') ??
          _findInHouse(board.getColumn(i), 'column ${i + 1}') ??
          _findInHouse(board.getBox(i), 'box ${i + 1}');
      if (result != null) return result;
    }
    return null;
  }

  SolveStep? _findInHouse(List<Cell> house, String houseName) {
    // Build a map: candidate value → list of cells that contain it.
    final valueToCells = <int, List<Cell>>{};
    for (final cell in house) {
      if (cell.isFilled) continue;
      for (final v in cell.candidates) {
        (valueToCells[v] ??= []).add(cell);
      }
    }

    // Only consider values that appear in 2..size cells.
    final candidateValues = valueToCells.entries
        .where((e) => e.value.length >= 2 && e.value.length <= size)
        .map((e) => e.key)
        .toList();

    if (candidateValues.length < size) return null;

    // Try all combinations of `size` values.
    final combos = combinations(candidateValues, size);

    for (final valueCombo in combos) {
      // Union of cells that contain any of these values.
      final cells = <Cell>{};
      for (final v in valueCombo) {
        cells.addAll(valueToCells[v]!);
      }

      if (cells.length != size) continue;

      // Found a hidden subset - eliminate other candidates from these cells.
      final valueSet = valueCombo.toSet();
      final eliminations = <Elimination>[];
      for (final cell in cells) {
        for (final v in cell.candidates) {
          if (!valueSet.contains(v)) {
            eliminations.add(Elimination(cell.row, cell.col, v));
          }
        }
      }

      if (eliminations.isEmpty) continue;

      return SolveStep(
        strategy: _type,
        eliminations: eliminations,
        involvedCells: cells.map((c) => (row: c.row, col: c.col)).toList(),
        description:
            'Hidden $_label {${valueCombo.toList()..sort()}} '
            'in $houseName at ${cells.map((c) => 'R${c.row + 1}C${c.col + 1}').join(', ')}',
      );
    }
    return null;
  }
}
