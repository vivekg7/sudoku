import '../../models/board.dart';
import '../../models/cell.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// Naked Pair/Triple/Quad: N cells in a house that together contain exactly
/// N candidates → those candidates can be eliminated from other cells in
/// the house.
class NakedSubset extends Strategy {
  final int size; // 2, 3, or 4

  NakedSubset(this.size) : assert(size >= 2 && size <= 4);

  StrategyType get _type {
    switch (size) {
      case 2:
        return StrategyType.nakedPair;
      case 3:
        return StrategyType.nakedTriple;
      default:
        return StrategyType.nakedQuad;
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
    final emptyCells =
        house.where((c) => c.isEmpty && c.candidates.isNotEmpty).toList();

    // Find all combinations of `size` cells from emptyCells.
    final combos = _combinations(emptyCells, size);

    for (final combo in combos) {
      final union = <int>{};
      for (final cell in combo) {
        union.addAll(cell.candidates);
      }

      if (union.length != size) continue;

      // Found a naked subset — check if there are eliminations.
      final eliminations = <Elimination>[];
      for (final cell in emptyCells) {
        if (combo.contains(cell)) continue;
        for (final v in union) {
          if (cell.candidates.contains(v)) {
            eliminations.add(Elimination(cell.row, cell.col, v));
          }
        }
      }

      if (eliminations.isEmpty) continue;

      return SolveStep(
        strategy: _type,
        eliminations: eliminations,
        involvedCells: combo.map((c) => (row: c.row, col: c.col)).toList(),
        description:
            'Naked $_label {${union.toList()..sort()}} '
            'in $houseName at ${combo.map((c) => 'R${c.row + 1}C${c.col + 1}').join(', ')}',
      );
    }
    return null;
  }
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
