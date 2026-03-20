import '../solver/solve_step.dart';
import '../solver/strategy_type.dart';
import '../models/difficulty.dart';

/// Complete analysis of a solved puzzle.
class PuzzleAnalysis {
  /// Ordered list of all logical steps taken to solve the puzzle.
  final List<SolveStep> steps;

  /// How many times each strategy was used, ordered by first appearance.
  final List<StrategyCount> strategyCounts;

  /// The most advanced strategy used (defines the puzzle's difficulty).
  final StrategyType hardestStrategy;

  /// Difficulty classification.
  final Difficulty difficulty;

  /// Breakdown of how the difficulty score was computed.
  final DifficultyScoreBreakdown scoreBreakdown;

  /// Solve order for each cell: 81 entries (row-major), 0 = given, 1..N = order.
  final List<int> solveOrder;

  /// Cells that required the most advanced techniques.
  final List<BottleneckCell> bottlenecks;

  const PuzzleAnalysis({
    required this.steps,
    required this.strategyCounts,
    required this.hardestStrategy,
    required this.difficulty,
    required this.scoreBreakdown,
    required this.solveOrder,
    required this.bottlenecks,
  });
}

/// A strategy and its usage count, preserving first-appearance order.
class StrategyCount {
  final StrategyType strategy;
  final int count;

  const StrategyCount(this.strategy, this.count);
}

/// Breakdown of difficulty score components.
class DifficultyScoreBreakdown {
  /// Raw weight of the hardest strategy used.
  final int hardestWeight;

  /// hardestWeight * 3.
  final int hardestContribution;

  /// Sum of weights for strategies with weight > 2.
  final int advancedTotal;

  /// advancedTotal ~/ 4.
  final int advancedContribution;

  /// Number of given (pre-filled) cells.
  final int givenCount;

  /// max(0, 36 - givenCount), clamped to 20.
  final int givenPenalty;

  /// Total number of solve steps.
  final int stepCount;

  /// max(0, stepCount - 30), clamped to 20.
  final int stepPenalty;

  /// Final computed score.
  final int totalScore;

  const DifficultyScoreBreakdown({
    required this.hardestWeight,
    required this.hardestContribution,
    required this.advancedTotal,
    required this.advancedContribution,
    required this.givenCount,
    required this.givenPenalty,
    required this.stepCount,
    required this.stepPenalty,
    required this.totalScore,
  });
}

/// A cell that required an advanced technique to solve.
class BottleneckCell {
  final int row;
  final int col;
  final int value;
  final StrategyType strategy;

  /// Index into the steps list (for scroll-to in UI).
  final int stepIndex;

  const BottleneckCell({
    required this.row,
    required this.col,
    required this.value,
    required this.strategy,
    required this.stepIndex,
  });
}

/// How a puzzle was completed.
enum CompletionType {
  /// Player solved it themselves.
  solved,

  /// Player triggered analysis (solution was revealed).
  analyzed,

  /// Player abandoned the puzzle.
  abandoned,
}
