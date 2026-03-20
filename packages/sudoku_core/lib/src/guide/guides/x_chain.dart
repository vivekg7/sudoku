import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// X-Chain
// ---------------------------------------------------------------------------
//
// A chain of conjugate pairs for candidate 2, even length (4 nodes):
//   Row 0: (0,1) <-> (0,7)
//   Col 7: (0,7) <-> (5,7)
//   Row 5: (5,7) <-> (5,2)
//
// Chain: (0,1) -- (0,7) -- (5,7) -- (5,2)
// Both endpoints (0,1) and (5,2) have the same parity.
// Target (3,1) sees (0,1) via col 1 and (5,2) via box 3.
// Target is NOT in any chain house (row 0, col 7, row 5).

final xChainGuide = StrategyGuide(
  strategy: StrategyType.xChain,
  difficulty: Difficulty.expert,
  intro: 'A chain of conjugate pairs for one candidate - cells seeing '
      'both endpoints of an even-length chain can\'t have that candidate.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    // Chain nodes for candidate 2:
    0 * 9 + 1: {2, 5, 8},       // endpoint A
    0 * 9 + 7: {2, 4, 9},       // link
    5 * 9 + 7: {2, 3, 6},       // link
    5 * 9 + 2: {1, 2, 7},       // endpoint B
    // Extra 2s to prevent col 1 and box 3 from being conjugate pairs
    6 * 9 + 1: {2, 3, 8},       // 2 in col 1
    4 * 9 + 0: {2, 6, 9},       // 2 in box 3
    // Target: sees (0,1) via col 1 and (5,2) via box 3
    3 * 9 + 1: {2, 6, 9},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Focus on candidate 2. In row 1, it appears in '
          'only two cells - a conjugate pair. '
          'If one has 2, the other doesn\'t.',
      highlightCells: {(0, 1), (0, 7)},
      highlightCandidates: {(0, 1, 2), (0, 7, 2)},
    ),
    GuideStep(
      caption: 'From the second cell, follow another conjugate pair '
          'down column 8.',
      highlightCells: {(0, 1), (0, 7), (5, 7)},
      highlightCandidates: {(0, 1, 2), (0, 7, 2), (5, 7, 2)},
    ),
    GuideStep(
      caption: 'Then another pair along row 6. '
          'The chain has 4 nodes and 3 links - even length.',
      highlightCells: {(0, 1), (0, 7), (5, 7), (5, 2)},
      highlightCandidates: {(0, 1, 2), (0, 7, 2), (5, 7, 2), (5, 2, 2)},
    ),
    GuideStep(
      caption: 'The two endpoints have the same parity - one of them '
          'must be 2. Any cell seeing both endpoints can\'t have 2.',
      highlightCells: {(0, 1), (5, 2), (3, 1)},
      highlightCandidates: {(0, 1, 2), (5, 2, 2), (3, 1, 2)},
    ),
    GuideStep(
      caption: 'This cell shares a column with one endpoint '
          'and a box with the other. Eliminate 2.',
      highlightCells: {(0, 1), (5, 2)},
      highlightCandidates: {(0, 1, 2), (5, 2, 2)},
      eliminateCandidates: {(3, 1, 2)},
    ),
    GuideStep(
      caption: 'X-Chain: follow conjugate pairs for one digit, '
          'building a chain. If the chain has even length, '
          'eliminate the digit from cells seeing both ends.',
    ),
  ],
);
