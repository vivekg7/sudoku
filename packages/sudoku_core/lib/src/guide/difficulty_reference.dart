import '../models/difficulty.dart';
import '../solver/strategy_type.dart';

/// Reference info for one difficulty level.
class DifficultyInfo {
  final Difficulty difficulty;
  final String description;
  final List<StrategyType> strategies;

  const DifficultyInfo({
    required this.difficulty,
    required this.description,
    required this.strategies,
  });
}

/// All difficulty levels with their descriptions and required strategies.
const List<DifficultyInfo> difficultyReference = [
  DifficultyInfo(
    difficulty: Difficulty.beginner,
    description:
        'Solvable by scanning rows, columns, and boxes for where a digit '
        'fits or which digit a cell must contain. No advanced techniques '
        'needed — just careful observation.',
    strategies: [
      StrategyType.hiddenSingle,
      StrategyType.nakedSingle,
    ],
  ),
  DifficultyInfo(
    difficulty: Difficulty.easy,
    description:
        'Introduces intersection tricks and pair logic. You start '
        'noticing how candidates in one box constrain another, and '
        'how two cells sharing the same two candidates lock each '
        'other out.',
    strategies: [
      StrategyType.pointingPair,
      StrategyType.pointingTriple,
      StrategyType.boxLineReduction,
      StrategyType.nakedPair,
      StrategyType.hiddenPair,
    ],
  ),
  DifficultyInfo(
    difficulty: Difficulty.medium,
    description:
        'Larger subsets and fish patterns. You need to track three or '
        'four candidates at once and spot digit alignments across '
        'multiple rows or columns.',
    strategies: [
      StrategyType.nakedTriple,
      StrategyType.hiddenTriple,
      StrategyType.nakedQuad,
      StrategyType.hiddenQuad,
      StrategyType.xWing,
      StrategyType.swordfish,
    ],
  ),
  DifficultyInfo(
    difficulty: Difficulty.hard,
    description:
        'Wings and unique rectangles. These patterns are harder to '
        'spot because they involve cells that aren\'t in the same '
        'row, column, or box — you have to see diagonal and '
        'cross-box relationships.',
    strategies: [
      StrategyType.jellyfish,
      StrategyType.xyWing,
      StrategyType.xyzWing,
      StrategyType.uniqueRectangleType1,
      StrategyType.uniqueRectangleType2,
      StrategyType.uniqueRectangleType3,
      StrategyType.uniqueRectangleType4,
    ],
  ),
  DifficultyInfo(
    difficulty: Difficulty.expert,
    description:
        'Coloring and chains. You follow a trail of linked candidates '
        'across the grid, alternating between "if this is true, then '
        'that is false" until you reach a conclusion.',
    strategies: [
      StrategyType.simpleColoring,
      StrategyType.xChain,
      StrategyType.xyChain,
      StrategyType.alternatingInferenceChain,
    ],
  ),
  DifficultyInfo(
    difficulty: Difficulty.master,
    description:
        'The hardest logical techniques. Forcing chains test both '
        'possibilities for a candidate and see what they have in '
        'common. Almost Locked Sets and Sue de Coq use groups of '
        'cells with tightly constrained candidates to force '
        'eliminations elsewhere.',
    strategies: [
      StrategyType.forcingChain,
      StrategyType.almostLockedSet,
      StrategyType.sueDeCoq,
    ],
  ),
];
