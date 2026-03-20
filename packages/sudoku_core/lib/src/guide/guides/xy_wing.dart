import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// XY-Wing
// ---------------------------------------------------------------------------
//
// Pivot cell (4,4) has candidates {3, 7}.
// Pincer 1: (4,1) has {3, 5} -- shares row with pivot.
// Pincer 2: (1,4) has {7, 5} -- shares column with pivot.
// Both pincers have 5. Any cell seeing both pincers can't have 5.
// Elimination target: (1,1) sees both pincers (same row as pincer2,
// same col as pincer1... no wait, same BOX as pincer1 if in box 1).
//
// Let me redesign: pivot (4,4) {3,7}, pincer1 (4,0) {3,5} in row 4,
// pincer2 (7,4) {7,5} in col 4.
// Cell (7,0) sees pincer1 (col 0) and pincer2 (row 7) -- and has 5.

final xyWingGuide = StrategyGuide(
  strategy: StrategyType.xyWing,
  difficulty: Difficulty.hard,
  intro: 'A pivot cell with two candidates links to two pincer cells — '
      'their shared candidate can be eliminated from cells that see '
      'both pincers.',
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
    // Pivot: (4,4) with {3, 7}
    4 * 9 + 4: {3, 7},
    // Pincer 1: (4,0) with {3, 5} -- same row as pivot
    4 * 9 + 0: {3, 5},
    // Pincer 2: (7,4) with {7, 5} -- same col as pivot
    7 * 9 + 4: {5, 7},
    // Elimination target: (7,0) sees both pincers (col 0 + row 7)
    7 * 9 + 0: {1, 5, 8},       // has 5 -- will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at the centre cell — it has only two candidates: '
          '{3, 7}. This is the pivot.',
      highlightCells: {(4, 4)},
      highlightCandidates: {(4, 4, 3), (4, 4, 7)},
    ),
    GuideStep(
      caption: 'In the same row, this cell has {3, 5}. '
          'It shares candidate 3 with the pivot. '
          "That's pincer 1.",
      highlightCells: {(4, 4), (4, 0)},
      highlightCandidates: {(4, 4, 3), (4, 0, 3), (4, 0, 5)},
    ),
    GuideStep(
      caption: 'In the same column, this cell has {7, 5}. '
          'It shares candidate 7 with the pivot. '
          "That's pincer 2. Both pincers have 5.",
      highlightCells: {(4, 4), (4, 0), (7, 4)},
      highlightCandidates: {
        (4, 4, 3), (4, 4, 7),
        (4, 0, 3), (4, 0, 5),
        (7, 4, 7), (7, 4, 5),
      },
    ),
    GuideStep(
      caption: 'Think it through: if 3 goes in the pivot, then 5 '
          'must go in pincer 1. If 7 goes in the pivot, then 5 '
          'must go in pincer 2. Either way, 5 is in one of the pincers.',
      highlightCells: {(4, 4), (4, 0), (7, 4)},
      highlightCandidates: {(4, 0, 5), (7, 4, 5)},
    ),
    GuideStep(
      caption: 'Any cell that sees both pincers can\'t have 5. '
          'This cell is in the same column as pincer 1 '
          'and the same row as pincer 2.',
      highlightCells: {(4, 0), (7, 4), (7, 0)},
      highlightCandidates: {(4, 0, 5), (7, 4, 5), (7, 0, 5)},
    ),
    GuideStep(
      caption: 'Eliminate 5 from that cell.',
      highlightCells: {(4, 4), (4, 0), (7, 4)},
      highlightCandidates: {(4, 0, 5), (7, 4, 5)},
      eliminateCandidates: {(7, 0, 5)},
    ),
    GuideStep(
      caption: 'XY-Wing: a pivot with two candidates, two pincers '
          'that each share one candidate with the pivot — '
          'their common digit gets eliminated from shared peers.',
    ),
  ],
);
