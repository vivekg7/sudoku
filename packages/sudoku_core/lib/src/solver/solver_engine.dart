import '../models/board.dart';
import '../models/difficulty.dart';
import 'candidate_helper.dart';
import 'solve_result.dart';
import 'solve_step.dart';
import 'strategy.dart';
import 'strategy_type.dart';
import 'strategies/strategies.dart';

/// Step-by-step Sudoku solver that applies strategies in order of difficulty.
///
/// The solver iterates through strategies from easiest to hardest, applying
/// the simplest applicable strategy at each step. It returns the full solve
/// path and classifies the puzzle's difficulty from a human perspective.
class Solver {
  /// Strategies ordered from easiest to hardest.
  ///
  /// Hidden singles come before naked singles because humans find them
  /// easier — you scan a house for where a digit can go rather than
  /// eliminating all but one candidate from a cell.
  static final List<({StrategyType type, Strategy strategy})> _strategies = [
    // Beginner: hidden singles are easiest for humans
    (type: StrategyType.hiddenSingle, strategy: HiddenSingle()),
    (type: StrategyType.nakedSingle, strategy: NakedSingle()),
    // Easy: intersections and pairs
    (type: StrategyType.pointingPair, strategy: Pointing()),
    (type: StrategyType.boxLineReduction, strategy: BoxLineReduction()),
    (type: StrategyType.nakedPair, strategy: NakedSubset(2)),
    (type: StrategyType.hiddenPair, strategy: HiddenSubset(2)),
    // Medium: larger subsets and basic fish
    (type: StrategyType.nakedTriple, strategy: NakedSubset(3)),
    (type: StrategyType.hiddenTriple, strategy: HiddenSubset(3)),
    (type: StrategyType.nakedQuad, strategy: NakedSubset(4)),
    (type: StrategyType.hiddenQuad, strategy: HiddenSubset(4)),
    (type: StrategyType.xWing, strategy: Fish(2)),
    (type: StrategyType.swordfish, strategy: Fish(3)),
    // Hard: larger fish, wings, unique rectangles
    (type: StrategyType.jellyfish, strategy: Fish(4)),
    (type: StrategyType.xyWing, strategy: XYWing()),
    (type: StrategyType.xyzWing, strategy: XYZWing()),
    (type: StrategyType.uniqueRectangleType1, strategy: UniqueRectangle()),
    // Expert: colouring and chains
    (type: StrategyType.simpleColouring, strategy: SimpleColouring()),
    (type: StrategyType.xChain, strategy: XChain()),
    (type: StrategyType.xyChain, strategy: XYChain()),
    (type: StrategyType.alternatingInferenceChain, strategy: AIC()),
    // Master: forcing chains, ALS, Sue de Coq
    (type: StrategyType.forcingChain, strategy: ForcingChain()),
    (type: StrategyType.almostLockedSet, strategy: AlmostLockedSet()),
    (type: StrategyType.sueDeCoq, strategy: SueDeCoq()),
  ];

  static final Backtracking _backtracking = Backtracking();

  /// Solves the puzzle step-by-step, returning the full solve path.
  ///
  /// The board is cloned internally — the original is not modified.
  /// If [useBacktracking] is true (default), backtracking is used as a
  /// last resort when no logical strategy applies.
  SolveResult solve(Board board, {bool useBacktracking = true}) {
    final work = board.clone();

    // An invalid starting board can never be solved.
    if (!work.isValid) {
      return const SolveResult(
        steps: [],
        difficulty: Difficulty.beginner,
        isSolved: false,
      );
    }

    // Count givens before solving.
    var givenCount = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (work.getCell(r, c).isFilled) givenCount++;
      }
    }

    computeCandidates(work);

    final steps = <SolveStep>[];

    while (!work.isSolved) {
      final step = _findNextStep(work);

      if (step != null) {
        steps.add(step);
        _applyStep(work, step);
        continue;
      }

      // No logical strategy found — try backtracking as fallback.
      if (useBacktracking) {
        final btStep = _backtracking.apply(work);
        if (btStep != null) {
          steps.add(btStep);
          _applyStep(work, btStep);
          continue;
        }
      }

      // Stuck — puzzle cannot be solved.
      break;
    }

    final difficulty = classifyPuzzle(
      steps: steps,
      givenCount: givenCount,
    );

    return SolveResult(
      steps: steps,
      difficulty: difficulty,
      isSolved: work.isSolved,
    );
  }

  /// Returns the next logical step for the current board state, or `null`
  /// if no strategy applies.
  ///
  /// This is the entry point for the hint system — it finds what the player
  /// should do next without solving the entire puzzle.
  ///
  /// Candidates must already be computed on [board].
  SolveStep? nextStep(Board board) => _findNextStep(board);

  /// Tries each strategy in order and returns the first applicable step.
  SolveStep? _findNextStep(Board board) {
    for (final entry in _strategies) {
      final step = entry.strategy.apply(board);
      if (step != null) return step;
    }
    return null;
  }

  /// Applies a solve step to the board: places values and eliminates candidates.
  void _applyStep(Board board, SolveStep step) {
    for (final placement in step.placements) {
      final cell = board.getCell(placement.row, placement.col);
      cell.setValue(placement.value);
      cell.setCandidates({});
      // Remove this value from all peers' candidates.
      for (final peer in board.peers(placement.row, placement.col)) {
        peer.removeCandidate(placement.value);
      }
    }

    for (final elimination in step.eliminations) {
      final cell = board.getCell(elimination.row, elimination.col);
      cell.removeCandidate(elimination.value);
    }
  }

  // ---------------------------------------------------------------------------
  // Human-calibrated difficulty classification
  // ---------------------------------------------------------------------------

  /// Human-perceived difficulty weight for each strategy.
  ///
  /// Higher weight = harder for a human. These weights are calibrated
  /// to reflect human experience, not computational complexity.
  /// Hidden singles are the easiest for humans (scan a house), while
  /// naked singles require full candidate elimination — harder to spot.
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
    StrategyType.simpleColouring: 35,
    StrategyType.xChain: 40,
    StrategyType.xyChain: 45,
    StrategyType.alternatingInferenceChain: 50,
    StrategyType.forcingChain: 60,
    StrategyType.almostLockedSet: 55,
    StrategyType.sueDeCoq: 55,
    StrategyType.backtracking: 70,
  };

  /// Classifies a puzzle's difficulty from a human perspective.
  ///
  /// Takes into account:
  /// - **Hardest strategy required** (primary factor)
  /// - **Number of givens** (fewer = harder to scan)
  /// - **Total solve steps** (more steps = more mental work)
  /// - **Frequency of advanced strategies** (using X-Wing once vs five times)
  static Difficulty classifyPuzzle({
    required List<SolveStep> steps,
    required int givenCount,
  }) {
    if (steps.isEmpty) return Difficulty.beginner;

    // 1. Find the hardest strategy weight.
    var maxWeight = 0;
    for (final step in steps) {
      final w = _strategyWeight[step.strategy] ?? 0;
      if (w > maxWeight) maxWeight = w;
    }

    // 2. Compute a weighted score from all steps.
    //    Sum of weights for non-single strategies (they add cognitive load).
    var advancedScore = 0;
    for (final step in steps) {
      final w = _strategyWeight[step.strategy] ?? 0;
      if (w > 2) advancedScore += w;
    }

    // 3. Adjust for given count — fewer givens means harder scanning.
    //    Baseline: 36 givens is "neutral". Each given below adds difficulty.
    final givenPenalty = (36 - givenCount).clamp(0, 20);

    // 4. Step count penalty — more steps = more work.
    final stepPenalty = (steps.length - 30).clamp(0, 20);

    // 5. Combine into a final score.
    //    maxWeight is the dominant factor; others are modifiers.
    final score = maxWeight * 3 + advancedScore ~/ 4 + givenPenalty + stepPenalty;

    // 6. Map score to difficulty.
    if (score <= 12) return Difficulty.beginner;
    if (score <= 30) return Difficulty.easy;
    if (score <= 55) return Difficulty.medium;
    if (score <= 85) return Difficulty.hard;
    if (score <= 130) return Difficulty.expert;
    return Difficulty.master;
  }

  /// Maps a single strategy type to a difficulty level.
  ///
  /// This is a simplified classification — [classifyPuzzle] gives a more
  /// accurate human-calibrated result by considering the full solve context.
  static Difficulty classifyDifficulty(StrategyType strategy) {
    final weight = _strategyWeight[strategy] ?? 0;
    // Use thresholds that align with the weight ranges.
    if (weight <= 2) return Difficulty.beginner;
    if (weight <= 6) return Difficulty.easy;
    if (weight <= 20) return Difficulty.medium;
    if (weight <= 30) return Difficulty.hard;
    if (weight <= 50) return Difficulty.expert;
    return Difficulty.master;
  }
}
