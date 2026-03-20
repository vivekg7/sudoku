import '../solver/strategy_type.dart';
import 'guides/aic.dart';
import 'guides/almost_locked_set.dart';
import 'guides/box_line_reduction.dart';
import 'guides/fish.dart';
import 'guides/forcing_chain.dart';
import 'guides/hidden_single.dart';
import 'guides/hidden_subsets.dart';
import 'guides/naked_single.dart';
import 'guides/naked_subsets.dart';
import 'guides/pointing.dart';
import 'guides/simple_coloring.dart';
import 'guides/sue_de_coq.dart';
import 'guides/unique_rectangle.dart';
import 'guides/x_chain.dart';
import 'guides/xy_chain.dart';
import 'guides/xy_wing.dart';
import 'guides/xyz_wing.dart';
import 'strategy_guide.dart';

/// Registry of all strategy guides, keyed by strategy type.
final Map<StrategyType, StrategyGuide> strategyGuides = {
  for (final guide in _allGuides) guide.strategy: guide,
};

/// All strategy guides ordered by difficulty then strategy.
final List<StrategyGuide> allStrategyGuides = List.unmodifiable(_allGuides);

final List<StrategyGuide> _allGuides = [
  hiddenSingleGuide,
  nakedSingleGuide,
  pointingPairGuide,
  pointingTripleGuide,
  boxLineReductionGuide,
  nakedPairGuide,
  hiddenPairGuide,
  nakedTripleGuide,
  hiddenTripleGuide,
  nakedQuadGuide,
  hiddenQuadGuide,
  xWingGuide,
  swordfishGuide,
  jellyfishGuide,
  xyWingGuide,
  xyzWingGuide,
  uniqueRectangleType1Guide,
  uniqueRectangleType2Guide,
  uniqueRectangleType3Guide,
  uniqueRectangleType4Guide,
  simpleColoringGuide,
  xChainGuide,
  xyChainGuide,
  aicGuide,
  forcingChainGuide,
  almostLockedSetGuide,
  sueDeCoqGuide,
];
