import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// XY-Chain
// ---------------------------------------------------------------------------
//
// A chain of bi-value cells:
//   (0,0)={3,8} -> (0,5)={8,5} -> (4,5)={5,1} -> (4,2)={1,3}
// Shared: consecutive cells share one candidate.
// Free value at start: 3. Free value at end: 3. They match!
// Eliminate 3 from cells seeing both endpoints.
// (4,0) sees (0,0) via col 0 and (4,2) via row 4.

final xyChainGuide = StrategyGuide(
  strategy: StrategyType.xyChain,
  difficulty: Difficulty.expert,
  intro: 'A chain of bi-value cells where consecutive cells share one '
      'candidate - the unshared candidate at both ends can be eliminated '
      'from cells seeing both endpoints.',
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
    // Chain of bi-value cells:
    0 * 9 + 0: {3, 8},          // endpoint A, free = 3
    0 * 9 + 5: {5, 8},          // shares 8 with prev
    4 * 9 + 5: {1, 5},          // shares 5 with prev
    4 * 9 + 2: {1, 3},          // shares 1 with prev, free = 3
    // Target: sees both endpoints
    4 * 9 + 0: {3, 6, 7},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Find a chain of bi-value cells (cells with exactly '
          'two candidates). Start here: {3, 8}.',
      highlightCells: {(0, 0)},
      highlightCandidates: {(0, 0, 3), (0, 0, 8)},
    ),
    GuideStep(
      caption: 'A peer cell has {8, 5} - it shares 8 with the first. '
          'Link them. The chain continues through shared candidates.',
      highlightCells: {(0, 0), (0, 5)},
      highlightCandidates: {(0, 0, 3), (0, 0, 8), (0, 5, 8), (0, 5, 5)},
    ),
    GuideStep(
      caption: 'Next: {5, 1} shares 5. Then: {1, 3} shares 1. '
          'Four cells form a chain.',
      highlightCells: {(0, 0), (0, 5), (4, 5), (4, 2)},
      highlightCandidates: {
        (0, 0, 3), (0, 0, 8),
        (0, 5, 8), (0, 5, 5),
        (4, 5, 5), (4, 5, 1),
        (4, 2, 1), (4, 2, 3),
      },
    ),
    GuideStep(
      caption: 'The "free" candidate (the one not shared with the next '
          'cell) is 3 at both ends. If the first cell is 3, great. '
          'If it\'s 8, the chain forces 3 to the last cell. '
          'Either way, 3 is at one end.',
      highlightCells: {(0, 0), (4, 2)},
      highlightCandidates: {(0, 0, 3), (4, 2, 3)},
    ),
    GuideStep(
      caption: 'Any cell seeing both endpoints can\'t have 3. '
          'This cell shares a column with the first and a row '
          'with the last.',
      highlightCells: {(0, 0), (4, 2), (4, 0)},
      highlightCandidates: {(0, 0, 3), (4, 2, 3), (4, 0, 3)},
    ),
    GuideStep(
      caption: 'Eliminate 3 from that cell.',
      highlightCells: {(0, 0), (4, 2)},
      highlightCandidates: {(0, 0, 3), (4, 2, 3)},
      eliminateCandidates: {(4, 0, 3)},
    ),
    GuideStep(
      caption: 'XY-Chain: a chain of bi-value cells linked by shared '
          'candidates. When the free value matches at both ends, '
          'eliminate it from cells seeing both endpoints.',
    ),
  ],
);
