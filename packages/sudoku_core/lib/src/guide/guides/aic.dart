import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Alternating Inference Chain (AIC)
// ---------------------------------------------------------------------------
//
// An AIC alternates strong and weak links between (cell, candidate) nodes.
// Strong link: if one is false, the other must be true.
// Weak link: if one is true, the other must be false.
//
// Chain for candidate 5:
//   (1,3)=5 --strong[col 3]-- (7,3)=5
//   (7,3)=5 --weak[row 7]--   (7,6)=5
//   (7,6)=5 --strong[box 8]-- (8,8)=5
//
// Endpoints: (1,3) and (8,8). Both reached via strong links.
// One of them must be 5. Target (1,8) sees both -> eliminate 5.
// Extra 5s in row 1, row 7, and col 8 prevent simpler chains.

final aicGuide = StrategyGuide(
  strategy: StrategyType.alternatingInferenceChain,
  difficulty: Difficulty.expert,
  intro: 'A chain of alternating strong and weak links — when both '
      'endpoints point to the same candidate, eliminate it from '
      'cells seeing both ends.',
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
    // Chain nodes for candidate 5:
    1 * 9 + 3: {2, 5, 8},       // endpoint A (strong link via col 3)
    7 * 9 + 3: {1, 5, 7},       // link
    7 * 9 + 6: {3, 5, 9},       // link (weak from row 7)
    8 * 9 + 8: {4, 5, 6},       // endpoint B (strong link via box 8)
    // Extra 5s to prevent simpler conjugate pairs
    7 * 9 + 1: {5, 6, 8},       // 5 in row 7 -> not conjugate pair
    1 * 9 + 6: {1, 4, 5},       // 5 in row 1 -> not conjugate pair
    4 * 9 + 8: {2, 5, 7},       // 5 in col 8 -> not conjugate pair
    // Target: sees (1,3) via row 1 and (8,8) via col 8
    1 * 9 + 8: {5, 6, 9},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'AIC uses alternating strong and weak links. '
          'A strong link means: if one is false, the other must be true. '
          'Start with candidate 5 in column 4.',
      highlightCells: {(1, 3), (7, 3)},
      highlightCandidates: {(1, 3, 5), (7, 3, 5)},
    ),
    GuideStep(
      caption: 'These two cells are the only places for 5 in column 4 — '
          'a strong link. One of them must be 5.',
      highlightCells: {(1, 3), (7, 3)},
      highlightCandidates: {(1, 3, 5), (7, 3, 5)},
    ),
    GuideStep(
      caption: 'From the second cell, a weak link across row 8. '
          'Multiple cells have 5 in this row, so it\'s not a '
          'strong link — just peers with the same candidate.',
      highlightCells: {(1, 3), (7, 3), (7, 6)},
      highlightCandidates: {(1, 3, 5), (7, 3, 5), (7, 6, 5)},
    ),
    GuideStep(
      caption: 'Then a strong link within box 9 — only two cells '
          'have 5 there. The chain: strong \u2192 weak \u2192 strong.',
      highlightCells: {(1, 3), (7, 3), (7, 6), (8, 8)},
      highlightCandidates: {(1, 3, 5), (7, 3, 5), (7, 6, 5), (8, 8, 5)},
    ),
    GuideStep(
      caption: 'Both endpoints are reached via strong links — '
          'one of them must be 5. Any cell seeing both '
          'endpoints can\'t have 5.',
      highlightCells: {(1, 3), (8, 8), (1, 8)},
      highlightCandidates: {(1, 3, 5), (8, 8, 5), (1, 8, 5)},
    ),
    GuideStep(
      caption: 'This cell shares a row with one endpoint '
          'and a column with the other. Eliminate 5.',
      highlightCells: {(1, 3), (8, 8)},
      highlightCandidates: {(1, 3, 5), (8, 8, 5)},
      eliminateCandidates: {(1, 8, 5)},
    ),
    GuideStep(
      caption: 'AIC: the most general chain technique. Alternate '
          'strong and weak links — when both ends agree on a '
          'candidate, eliminate it from their common peers.',
    ),
  ],
);
