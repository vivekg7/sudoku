import '../models/board.dart';
import '../solver/candidate_helper.dart';
import '../solver/solve_step.dart';
import '../solver/solver_engine.dart';
import 'hint.dart';

/// Generates multi-layer hints for the current board state.
///
/// Uses the [Solver] to find the next logical step, then extracts
/// three progressively detailed hint layers from it.
class HintGenerator {
  final Solver _solver;

  HintGenerator({Solver? solver}) : _solver = solver ?? Solver();

  /// Generates a [Hint] for the current board state, or `null` if
  /// the board is already solved or no strategy applies.
  ///
  /// The board must have candidates computed. If [computeCandidatesFirst]
  /// is true (default), candidates are computed on a clone before solving.
  Hint? generate(Board board, {bool computeCandidatesFirst = true}) {
    final work = computeCandidatesFirst ? board.clone() : board;
    if (computeCandidatesFirst) computeCandidates(work);

    final step = _solver.nextStep(work);
    if (step == null) return null;

    return Hint(
      step: step,
      nudge: _buildNudge(step),
      strategyHint: _buildStrategyHint(step),
      answer: _buildAnswer(step),
    );
  }

  /// Layer 1: A vague directional nudge.
  ///
  /// Points the player to a region and digit without revealing the
  /// technique or exact cell. Picks the most specific single region
  /// (box > row > column) that contains the action.
  String _buildNudge(SolveStep step) {
    // Determine the target cell and value.
    if (step.placements.isNotEmpty) {
      final p = step.placements.first;
      final region = _mostSpecificRegion(p.row, p.col);
      return 'Look for ${p.value} in $region';
    }

    if (step.eliminations.isNotEmpty) {
      // For eliminations, nudge toward the area where the pattern is.
      final cell = step.involvedCells.isNotEmpty
          ? step.involvedCells.first
          : (row: step.eliminations.first.row, col: step.eliminations.first.col);
      final region = _mostSpecificRegion(cell.row, cell.col);
      return 'Take a closer look at $region';
    }

    return 'Look at the board carefully';
  }

  /// Layer 2: Strategy name and the region where it applies.
  String _buildStrategyHint(SolveStep step) {
    final strategyName = step.strategy.label;

    if (step.involvedCells.isEmpty) {
      return 'Try using $strategyName';
    }

    final regionDesc = _describeInvolvedRegion(step);
    return 'Try using $strategyName $regionDesc';
  }

  /// Layer 3: The exact action to take.
  String _buildAnswer(SolveStep step) {
    final parts = <String>[];

    for (final p in step.placements) {
      parts.add('Place ${p.value} at R${p.row + 1}C${p.col + 1}');
    }

    for (final e in step.eliminations) {
      parts.add('Eliminate ${e.value} from R${e.row + 1}C${e.col + 1}');
    }

    if (parts.isEmpty) return step.description;
    return parts.join('; ');
  }

  /// Returns the most specific single region name for a cell.
  /// Prefers box (smaller area = better nudge) over row/column.
  String _mostSpecificRegion(int row, int col) {
    final box = (row ~/ 3) * 3 + col ~/ 3;
    return 'box ${box + 1}';
  }

  /// Describes where the involved cells are located.
  String _describeInvolvedRegion(SolveStep step) {
    final cells = step.involvedCells;
    if (cells.isEmpty) return '';

    final rows = cells.map((c) => c.row).toSet();
    final cols = cells.map((c) => c.col).toSet();
    final boxes = cells.map((c) => (c.row ~/ 3) * 3 + c.col ~/ 3).toSet();

    // If all in one box, say that.
    if (boxes.length == 1) {
      return 'in box ${boxes.first + 1}';
    }

    // If spanning specific rows, mention those.
    if (rows.length <= 3 && rows.length < cols.length) {
      final rowLabels = (rows.toList()..sort()).map((r) => '${r + 1}');
      return 'on row${rows.length > 1 ? 's' : ''} ${rowLabels.join(' and ')}';
    }

    // If spanning specific columns, mention those.
    if (cols.length <= 3) {
      final colLabels = (cols.toList()..sort()).map((c) => '${c + 1}');
      return 'on column${cols.length > 1 ? 's' : ''} ${colLabels.join(' and ')}';
    }

    // Fallback: mention the boxes involved.
    final boxLabels = (boxes.toList()..sort()).map((b) => '${b + 1}');
    return 'in boxes ${boxLabels.join(' and ')}';
  }
}
