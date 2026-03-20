import '../../models/board.dart';
import '../solve_step.dart';
import '../strategy.dart';
import '../strategy_type.dart';

/// A cell with only one candidate - that must be its value.
class NakedSingle extends Strategy {
  @override
  SolveStep? apply(Board board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (cell.isFilled || cell.candidates.length != 1) continue;

        final value = cell.candidates.first;
        return SolveStep(
          strategy: StrategyType.nakedSingle,
          placements: [Placement(r, c, value)],
          involvedCells: [(row: r, col: c)],
          description:
              'R${r + 1}C${c + 1} has only one candidate: $value',
        );
      }
    }
    return null;
  }
}
