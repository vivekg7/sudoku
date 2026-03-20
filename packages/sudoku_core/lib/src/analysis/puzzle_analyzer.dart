import '../models/board.dart';
import '../models/puzzle.dart';
import '../solver/solve_step.dart';
import '../solver/solver_engine.dart';
import '../solver/strategy_type.dart';
import 'puzzle_analysis.dart';

/// Generates a [PuzzleAnalysis] from a puzzle's cached solve result.
///
/// This is a pure transformation - no new solving is performed.
class PuzzleAnalyzer {
  /// Human-perceived difficulty weight for each strategy.
  ///
  /// Mirrors [Solver._strategyWeight] - kept in sync manually since that
  /// map is private.
  static const Map<StrategyType, int> _strategyWeight = {
    StrategyType.hiddenSingle: 1,
    StrategyType.nakedSingle: 2,
    StrategyType.pointingPair: 4,
    StrategyType.pointingTriple: 4,
    StrategyType.boxLineReduction: 5,
    StrategyType.nakedPair: 6,
    StrategyType.hiddenPair: 6,
    StrategyType.nakedTriple: 10,
    StrategyType.hiddenTriple: 10,
    StrategyType.nakedQuad: 14,
    StrategyType.hiddenQuad: 14,
    StrategyType.xWing: 16,
    StrategyType.swordfish: 20,
    StrategyType.jellyfish: 25,
    StrategyType.xyWing: 28,
    StrategyType.xyzWing: 30,
    StrategyType.uniqueRectangleType1: 26,
    StrategyType.uniqueRectangleType2: 28,
    StrategyType.uniqueRectangleType3: 30,
    StrategyType.uniqueRectangleType4: 30,
    StrategyType.simpleColoring: 35,
    StrategyType.xChain: 40,
    StrategyType.xyChain: 45,
    StrategyType.alternatingInferenceChain: 50,
    StrategyType.forcingChain: 60,
    StrategyType.almostLockedSet: 55,
    StrategyType.sueDeCoq: 55,
    StrategyType.backtracking: 70,
  };

  /// Generate a full analysis from a puzzle.
  ///
  /// The puzzle must have a non-null [Puzzle.solveResult].
  static PuzzleAnalysis analyze(Puzzle puzzle) {
    final solveResult = puzzle.solveResult;
    if (solveResult == null) {
      throw ArgumentError('Puzzle has no cached solveResult');
    }

    final steps = solveResult.steps;

    // Strategy counts ordered by first appearance.
    final strategyCounts = _buildStrategyCounts(steps);

    // Hardest strategy by weight.
    final hardestStrategy = _findHardestStrategy(steps);

    // Given count.
    final givenCount = _countGivens(puzzle.initialBoard);

    // Difficulty score breakdown.
    final scoreBreakdown = _buildScoreBreakdown(steps, givenCount);

    // Solve order: 81 entries, 0 = given, 1..N = order solved.
    final solveOrder = _buildSolveOrder(puzzle.initialBoard, steps);

    // Bottleneck cells: placements that required the hardest techniques.
    final bottlenecks = _findBottlenecks(steps, hardestStrategy);

    return PuzzleAnalysis(
      steps: steps,
      strategyCounts: strategyCounts,
      hardestStrategy: hardestStrategy,
      difficulty: solveResult.difficulty,
      scoreBreakdown: scoreBreakdown,
      solveOrder: solveOrder,
      bottlenecks: bottlenecks,
    );
  }

  static List<StrategyCount> _buildStrategyCounts(List<SolveStep> steps) {
    final order = <StrategyType>[];
    final counts = <StrategyType, int>{};
    for (final step in steps) {
      if (!counts.containsKey(step.strategy)) {
        order.add(step.strategy);
      }
      counts[step.strategy] = (counts[step.strategy] ?? 0) + 1;
    }
    return [
      for (final strategy in order)
        StrategyCount(strategy, counts[strategy]!),
    ];
  }

  static StrategyType _findHardestStrategy(List<SolveStep> steps) {
    var hardest = steps.first.strategy;
    var maxWeight = _strategyWeight[hardest] ?? 0;
    for (final step in steps) {
      final w = _strategyWeight[step.strategy] ?? 0;
      if (w > maxWeight) {
        maxWeight = w;
        hardest = step.strategy;
      }
    }
    return hardest;
  }

  static int _countGivens(Board board) {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getCell(r, c).isGiven) count++;
      }
    }
    return count;
  }

  static DifficultyScoreBreakdown _buildScoreBreakdown(
    List<SolveStep> steps,
    int givenCount,
  ) {
    var maxWeight = 0;
    var advancedTotal = 0;
    for (final step in steps) {
      final w = _strategyWeight[step.strategy] ?? 0;
      if (w > maxWeight) maxWeight = w;
      if (w > 2) advancedTotal += w;
    }

    final hardestContribution = maxWeight * 3;
    final advancedContribution = advancedTotal ~/ 4;
    final givenPenalty = (36 - givenCount).clamp(0, 20);
    final stepPenalty = (steps.length - 30).clamp(0, 20);
    final totalScore =
        hardestContribution + advancedContribution + givenPenalty + stepPenalty;

    return DifficultyScoreBreakdown(
      hardestWeight: maxWeight,
      hardestContribution: hardestContribution,
      advancedTotal: advancedTotal,
      advancedContribution: advancedContribution,
      givenCount: givenCount,
      givenPenalty: givenPenalty,
      stepCount: steps.length,
      stepPenalty: stepPenalty,
      totalScore: totalScore,
    );
  }

  static List<int> _buildSolveOrder(Board initialBoard, List<SolveStep> steps) {
    final order = List.filled(81, 0);

    // Mark givens as 0 (they're already 0, but be explicit).
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (initialBoard.getCell(r, c).isGiven) {
          order[r * 9 + c] = 0;
        }
      }
    }

    // Assign solve order based on placement sequence.
    var seq = 1;
    for (final step in steps) {
      for (final p in step.placements) {
        order[p.row * 9 + p.col] = seq++;
      }
    }

    return order;
  }

  static List<BottleneckCell> _findBottlenecks(
    List<SolveStep> steps,
    StrategyType hardestStrategy,
  ) {
    final hardestWeight = _strategyWeight[hardestStrategy] ?? 0;

    // Include cells requiring the hardest strategy or anything within
    // one tier of it (weight >= hardestWeight * 0.7).
    final threshold = (hardestWeight * 0.7).ceil();

    final bottlenecks = <BottleneckCell>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final w = _strategyWeight[step.strategy] ?? 0;
      if (w >= threshold && step.placements.isNotEmpty) {
        for (final p in step.placements) {
          bottlenecks.add(BottleneckCell(
            row: p.row,
            col: p.col,
            value: p.value,
            strategy: step.strategy,
            stepIndex: i,
          ));
        }
      }
    }
    return bottlenecks;
  }
}
