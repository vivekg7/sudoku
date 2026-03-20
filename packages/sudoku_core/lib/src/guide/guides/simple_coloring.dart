import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ===========================================================================
// EXPERT
// ===========================================================================

// ---------------------------------------------------------------------------
// Simple Coloring
// ---------------------------------------------------------------------------
//
// Candidate 7 forms conjugate pairs (exactly 2 cells per house):
//   Box 0: (0,2) <-> (2,0) -- conjugate pair
//   Col 0: (2,0) <-> (6,0) -- conjugate pair
//   Row 6: (6,0) <-> (6,8) -- conjugate pair
//
// Color A (blue): (0,2), (6,0)
// Color B (amber): (2,0), (6,8)
//
// Target (0,8): sees (0,2) [color A] via row 0 and (6,8) [color B]
// via col 8. It sees both colors -> eliminate 7.
// Target is NOT in any conjugate pair house (box 0, col 0, row 6).

final simpleColoringGuide = StrategyGuide(
  strategy: StrategyType.simpleColoring,
  difficulty: Difficulty.expert,
  intro: 'Color conjugate pairs of a candidate with two alternating '
      'colors — cells seeing both colors can\'t have that candidate.',
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
    // Chain nodes for candidate 7:
    0 * 9 + 2: {3, 7, 9},       // color A (blue)
    2 * 9 + 0: {2, 7, 8},       // color B (amber)
    6 * 9 + 0: {1, 5, 7},       // color A (blue)
    6 * 9 + 8: {4, 6, 7},       // color B (amber)
    // Extra 7s to prevent row 0 and col 8 from being conjugate pairs
    0 * 9 + 5: {5, 7, 8},       // 7 in row 0 -> not a conjugate pair
    3 * 9 + 8: {2, 7, 9},       // 7 in col 8 -> not a conjugate pair
    // Target: sees color A (0,2) via row 0, color B (6,8) via col 8
    0 * 9 + 8: {1, 4, 7},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Focus on candidate 7. In some houses, 7 can only go '
          'in exactly two cells — these are conjugate pairs. '
          'One must be true, the other false.',
      highlightCandidates: {(0, 2, 7), (2, 0, 7)},
    ),
    GuideStep(
      caption: 'Start coloring: in box 1, these two cells form a '
          'conjugate pair for 7. Give them alternating colors.',
      colorACells: {(0, 2)},
      colorBCells: {(2, 0)},
      highlightCandidates: {(0, 2, 7), (2, 0, 7)},
    ),
    GuideStep(
      caption: 'Extend the chain. The amber cell links to another '
          'conjugate pair in column 1 — alternating to blue.',
      colorACells: {(0, 2), (6, 0)},
      colorBCells: {(2, 0)},
      highlightCandidates: {(0, 2, 7), (2, 0, 7), (6, 0, 7)},
    ),
    GuideStep(
      caption: 'Continue along row 7 to another conjugate pair — '
          'alternating back to amber.',
      colorACells: {(0, 2), (6, 0)},
      colorBCells: {(2, 0), (6, 8)},
      highlightCandidates: {(0, 2, 7), (2, 0, 7), (6, 0, 7), (6, 8, 7)},
    ),
    GuideStep(
      caption: 'Now look at this cell. It sees a blue cell in its row '
          'and an amber cell in its column. One of those colors must '
          'be 7 — either way, this cell can\'t be 7.',
      colorACells: {(0, 2), (6, 0)},
      colorBCells: {(2, 0), (6, 8)},
      highlightCells: {(0, 8)},
      highlightCandidates: {(0, 8, 7), (0, 2, 7), (6, 8, 7)},
    ),
    GuideStep(
      caption: 'Eliminate 7 from this cell — it sees both colors.',
      colorACells: {(0, 2), (6, 0)},
      colorBCells: {(2, 0), (6, 8)},
      eliminateCandidates: {(0, 8, 7)},
    ),
    GuideStep(
      caption: 'Simple Coloring: build a chain of conjugate pairs, '
          'alternate two colors, and eliminate the candidate from '
          'any cell that can see both colors.',
    ),
  ],
);
