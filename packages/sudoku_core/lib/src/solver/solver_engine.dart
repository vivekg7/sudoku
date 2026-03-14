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
/// path and classifies the puzzle's difficulty based on the hardest strategy
/// required.
class Solver {
  /// Strategies ordered from easiest to hardest.
  ///
  /// The solver always tries the easiest strategy first — this ensures the
  /// difficulty classification reflects the minimum required difficulty.
  static final List<({StrategyType type, Strategy strategy})> _strategies = [
    // Beginner
    (type: StrategyType.nakedSingle, strategy: NakedSingle()),
    (type: StrategyType.hiddenSingle, strategy: HiddenSingle()),
    // Easy
    (type: StrategyType.nakedPair, strategy: NakedSubset(2)),
    (type: StrategyType.hiddenPair, strategy: HiddenSubset(2)),
    (type: StrategyType.pointingPair, strategy: Pointing()),
    (type: StrategyType.boxLineReduction, strategy: BoxLineReduction()),
    // Medium
    (type: StrategyType.nakedTriple, strategy: NakedSubset(3)),
    (type: StrategyType.hiddenTriple, strategy: HiddenSubset(3)),
    (type: StrategyType.nakedQuad, strategy: NakedSubset(4)),
    (type: StrategyType.hiddenQuad, strategy: HiddenSubset(4)),
    (type: StrategyType.xWing, strategy: Fish(2)),
    (type: StrategyType.swordfish, strategy: Fish(3)),
    // Hard
    (type: StrategyType.jellyfish, strategy: Fish(4)),
    (type: StrategyType.xyWing, strategy: XYWing()),
    (type: StrategyType.xyzWing, strategy: XYZWing()),
    (type: StrategyType.uniqueRectangleType1, strategy: UniqueRectangle()),
    // Expert
    (type: StrategyType.simpleColouring, strategy: SimpleColouring()),
    (type: StrategyType.xChain, strategy: XChain()),
    (type: StrategyType.xyChain, strategy: XYChain()),
    (type: StrategyType.alternatingInferenceChain, strategy: AIC()),
    // Master
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

    computeCandidates(work);

    final steps = <SolveStep>[];
    var highestStrategyIndex = -1;

    while (!work.isSolved) {
      final step = _findNextStep(work);

      if (step != null) {
        final strategyIndex = StrategyType.values.indexOf(step.strategy);
        if (strategyIndex > highestStrategyIndex) {
          highestStrategyIndex = strategyIndex;
        }
        steps.add(step);
        _applyStep(work, step);
        continue;
      }

      // No logical strategy found — try backtracking as fallback.
      if (useBacktracking) {
        final btStep = _backtracking.apply(work);
        if (btStep != null) {
          highestStrategyIndex = StrategyType.backtracking.index;
          steps.add(btStep);
          _applyStep(work, btStep);
          continue;
        }
      }

      // Stuck — puzzle cannot be solved.
      break;
    }

    final difficulty = highestStrategyIndex < 0
        ? Difficulty.beginner
        : classifyDifficulty(StrategyType.values[highestStrategyIndex]);

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

  /// Maps a strategy type to a difficulty level.
  static Difficulty classifyDifficulty(StrategyType strategy) {
    return switch (strategy) {
      // Beginner: only naked and hidden singles
      StrategyType.nakedSingle ||
      StrategyType.hiddenSingle =>
        Difficulty.beginner,

      // Easy: basic subset and intersection strategies
      StrategyType.nakedPair ||
      StrategyType.hiddenPair ||
      StrategyType.pointingPair ||
      StrategyType.pointingTriple ||
      StrategyType.boxLineReduction =>
        Difficulty.easy,

      // Medium: larger subsets and basic fish
      StrategyType.nakedTriple ||
      StrategyType.hiddenTriple ||
      StrategyType.nakedQuad ||
      StrategyType.hiddenQuad ||
      StrategyType.xWing ||
      StrategyType.swordfish =>
        Difficulty.medium,

      // Hard: advanced fish, wings, and unique rectangles
      StrategyType.jellyfish ||
      StrategyType.xyWing ||
      StrategyType.xyzWing ||
      StrategyType.uniqueRectangleType1 ||
      StrategyType.uniqueRectangleType2 ||
      StrategyType.uniqueRectangleType3 ||
      StrategyType.uniqueRectangleType4 =>
        Difficulty.hard,

      // Expert: colouring and chains
      StrategyType.simpleColouring ||
      StrategyType.xChain ||
      StrategyType.xyChain ||
      StrategyType.alternatingInferenceChain =>
        Difficulty.expert,

      // Master: forcing chains, ALS, Sue de Coq, backtracking
      StrategyType.forcingChain ||
      StrategyType.almostLockedSet ||
      StrategyType.sueDeCoq ||
      StrategyType.backtracking =>
        Difficulty.master,
    };
  }
}
