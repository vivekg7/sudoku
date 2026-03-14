import '../models/difficulty.dart';
import 'solve_step.dart';
import 'strategy_type.dart';

/// The result of solving a puzzle step-by-step.
class SolveResult {
  /// Ordered list of logical steps taken to solve the puzzle.
  final List<SolveStep> steps;

  /// The difficulty classification based on the hardest strategy used.
  final Difficulty difficulty;

  /// Whether the solver reached a fully solved board.
  final bool isSolved;

  const SolveResult({
    required this.steps,
    required this.difficulty,
    required this.isSolved,
  });

  /// The hardest strategy used during the solve, or `null` if no steps.
  StrategyType? get hardestStrategy {
    if (steps.isEmpty) return null;
    return steps
        .map((s) => s.strategy)
        .reduce((a, b) => a.index > b.index ? a : b);
  }
}
