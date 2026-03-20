import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// XYZ-Wing
// ---------------------------------------------------------------------------
//
// Pivot cell (4,4) has candidates {2, 5, 8}.
// Pincer 1: (4,3) has {2, 5} -- same row and same box as pivot.
// Pincer 2: (3,4) has {5, 8} -- same column and same box as pivot.
// All three share candidate 5. Eliminate 5 from cells seeing all three.
// Since all three are in box 4, eliminate 5 from other cells in box 4
// that have candidate 5.

final xyzWingGuide = StrategyGuide(
  strategy: StrategyType.xyzWing,
  difficulty: Difficulty.hard,
  intro: 'Like XY-Wing, but the pivot has three candidates — the shared '
      'candidate is eliminated from cells that see all three cells.',
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
    // Pivot: (4,4) with {2, 5, 8}
    4 * 9 + 4: {2, 5, 8},
    // Pincer 1: (4,3) with {2, 5} -- same row + box as pivot
    4 * 9 + 3: {2, 5},
    // Pincer 2: (3,4) with {5, 8} -- same col + box as pivot
    3 * 9 + 4: {5, 8},
    // All three are in box 4 -> eliminate 5 from other box 4 cells
    3 * 9 + 3: {1, 5, 9},       // will be eliminated
    5 * 9 + 3: {4, 5, 7},       // will be eliminated
    3 * 9 + 5: {3, 5, 6},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'The centre cell has three candidates: {2, 5, 8}. '
          'This is the pivot.',
      highlightCells: {(4, 4)},
      highlightCandidates: {(4, 4, 2), (4, 4, 5), (4, 4, 8)},
    ),
    GuideStep(
      caption: 'Next to it, a cell with {2, 5} — shares 2 and 5 '
          'with the pivot. That\'s pincer 1.',
      highlightCells: {(4, 4), (4, 3)},
      highlightCandidates: {(4, 4, 2), (4, 4, 5), (4, 3, 2), (4, 3, 5)},
    ),
    GuideStep(
      caption: 'Above the pivot, a cell with {5, 8} — shares 5 and 8. '
          'That\'s pincer 2. All three cells share candidate 5.',
      highlightCells: {(4, 4), (4, 3), (3, 4)},
      highlightCandidates: {
        (4, 4, 2), (4, 4, 5), (4, 4, 8),
        (4, 3, 2), (4, 3, 5),
        (3, 4, 5), (3, 4, 8),
      },
    ),
    GuideStep(
      caption: 'No matter what value the pivot takes, 5 must end up '
          'in one of these three cells. Think through each case: '
          'if pivot is 2, pincer 1 is 5. If pivot is 8, pincer 2 is 5. '
          'If pivot is 5, it\'s already there.',
      highlightCells: {(4, 4), (4, 3), (3, 4)},
      highlightCandidates: {(4, 4, 5), (4, 3, 5), (3, 4, 5)},
    ),
    GuideStep(
      caption: 'All three cells are in the same box. '
          'Any other cell in this box that sees all three '
          'can\'t have 5.',
      highlightCells: {(4, 4), (4, 3), (3, 4), (3, 3), (5, 3), (3, 5)},
      highlightCandidates: {
        (4, 4, 5), (4, 3, 5), (3, 4, 5),
        (3, 3, 5), (5, 3, 5), (3, 5, 5),
      },
    ),
    GuideStep(
      caption: 'Eliminate 5 from those cells.',
      highlightCells: {(4, 4), (4, 3), (3, 4)},
      highlightCandidates: {(4, 4, 5), (4, 3, 5), (3, 4, 5)},
      eliminateCandidates: {(3, 3, 5), (5, 3, 5), (3, 5, 5)},
    ),
    GuideStep(
      caption: 'XYZ-Wing: like XY-Wing but the pivot has three '
          'candidates. The shared digit must be in one of the three '
          'cells — eliminating it from their common peers. '
          'The three cells don\'t have to be in the same box — '
          'this example just happens to work that way.',
    ),
  ],
);
