import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ===========================================================================
// EASY
// ===========================================================================

// ---------------------------------------------------------------------------
// Pointing Pair
// ---------------------------------------------------------------------------
//
// Candidate 3 appears in box 1 (top-left) only in (0,1) and (0,2) -- both
// in row 0. So 3 can be eliminated from the rest of row 0 outside box 1.
//
// Why only those two cells in box 1?
//   (7,0)=3 -> eliminates col 0 (so (0,0), (1,0), (2,0) can't have 3)
//   (1,1)=8, (1,2)=4, (2,1)=2, (2,2)=1 -> filled, can't be 3
// No 3 is placed in boxes 2 or 3, so the pointing pair is the only
// way to eliminate 3 from row 0 outside box 1.

final pointingPairGuide = StrategyGuide(
  strategy: StrategyType.pointingPair,
  difficulty: Difficulty.easy,
  intro: 'When a candidate in a box is confined to a single row or column, '
      'it can be eliminated from that row or column outside the box.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 0: target row
    [0, 8, 4, 0, 0, 0, 0, 0, 0], // row 1: filled cells in box 1
    [0, 2, 1, 0, 0, 0, 0, 0, 0], // row 2: filled cells in box 1
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [3, 0, 0, 0, 0, 0, 0, 0, 0], // row 7: 3 in col 0
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    // Box 1: only (0,1) and (0,2) have candidate 3
    0 * 9 + 0: {1, 5, 7},       // no 3 -- col 0 has 3
    0 * 9 + 1: {1, 3, 5},       // has 3 <- pointing pair
    0 * 9 + 2: {3, 5, 9},       // has 3 <- pointing pair
    1 * 9 + 0: {5, 6, 9},       // no 3 -- col 0 has 3
    2 * 9 + 0: {5, 6, 7},       // no 3 -- col 0 has 3
    // Row 0 outside box 1 -- some cells have 3 (to be eliminated)
    0 * 9 + 3: {2, 6, 8},
    0 * 9 + 4: {1, 4, 6},
    0 * 9 + 5: {2, 3, 6},       // has 3 -- will be eliminated
    0 * 9 + 6: {4, 8, 9},
    0 * 9 + 7: {1, 3, 8},       // has 3 -- will be eliminated
    0 * 9 + 8: {4, 5, 9},
  }),
  steps: [
    GuideStep(
      caption: 'Look at the top-left box. '
          'Where can 3 go in this box?',
      highlightCells: {(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)},
    ),
    GuideStep(
      caption: 'Four cells are filled, and column 1 has a 3 '
          'further down — ruling out the rest. '
          'Only two cells can hold 3.',
      highlightCells: {(0, 1), (0, 2), (7, 0)},
      highlightCandidates: {(0, 1, 3), (0, 2, 3)},
    ),
    GuideStep(
      caption: 'Both cells are in the same row — row 1. '
          'Wherever 3 goes in this box, it will be in row 1.',
      highlightCells: {(0, 1), (0, 2)},
      highlightCandidates: {(0, 1, 3), (0, 2, 3)},
    ),
    GuideStep(
      caption: 'That means no other cell in row 1 can have 3. '
          "It's already claimed by this box.",
      highlightCells: {(0, 1), (0, 2), (0, 5), (0, 7)},
      highlightCandidates: {(0, 1, 3), (0, 2, 3), (0, 5, 3), (0, 7, 3)},
    ),
    GuideStep(
      caption: 'Eliminate 3 from the other cells in row 1 '
          'that are outside this box.',
      highlightCells: {(0, 1), (0, 2)},
      highlightCandidates: {(0, 1, 3), (0, 2, 3)},
      eliminateCandidates: {(0, 5, 3), (0, 7, 3)},
    ),
    GuideStep(
      caption: 'That\'s a Pointing Pair: two cells in a box share a '
          'candidate on the same row, eliminating it from the rest of that row.',
      highlightCells: {(0, 1), (0, 2)},
      highlightCandidates: {(0, 1, 3), (0, 2, 3)},
      eliminateCandidates: {(0, 5, 3), (0, 7, 3)},
    ),
  ],
);

// ---------------------------------------------------------------------------
// Pointing Triple
// ---------------------------------------------------------------------------
//
// Same concept as Pointing Pair but with 3 cells.
// Candidate 5 appears in box 4 (centre) only in (3,3), (4,3), (5,3) --
// all in column 3. So 5 can be eliminated from col 3 outside box 4.
//
// Box 4 has 6 cells filled: (3,4)=8, (3,5)=2, (4,4)=1, (4,5)=9,
// (5,4)=6, (5,5)=4. The only 3 empty cells are in col 3.
// No 5 is placed in boxes 1, 2, 3, 7, 8, or 9 -- so the pointing
// triple is the only way to eliminate 5 from col 3 outside box 4.

final pointingTripleGuide = StrategyGuide(
  strategy: StrategyType.pointingTriple,
  difficulty: Difficulty.easy,
  intro: 'Like a Pointing Pair, but with three cells — a candidate confined '
      'to one row or column within a box eliminates it from outside.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 8, 2, 0, 0, 0], // box 4: col 4-5 filled
    [0, 0, 0, 0, 1, 9, 0, 0, 0],
    [0, 0, 0, 0, 6, 4, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    // Box 4: only the 3 empty cells in col 3 have candidate 5
    3 * 9 + 3: {1, 5, 7},       // has 5 <- pointing triple
    4 * 9 + 3: {3, 5, 7},       // has 5 <- pointing triple
    5 * 9 + 3: {3, 5, 7},       // has 5 <- pointing triple
    // Col 3 outside box 4 -- cells with candidate 5
    0 * 9 + 3: {2, 5, 6},       // will be eliminated
    1 * 9 + 3: {4, 5, 8},       // will be eliminated
    2 * 9 + 3: {1, 4, 7},
    6 * 9 + 3: {2, 5, 9},       // will be eliminated
    7 * 9 + 3: {1, 6, 8},
    8 * 9 + 3: {4, 7, 9},
  }),
  steps: [
    GuideStep(
      caption: 'Look at the centre box. '
          'Six cells are filled — only three are empty.',
      highlightCells: {(3, 3), (4, 3), (5, 3)},
    ),
    GuideStep(
      caption: 'All three empty cells have 5 as a candidate, '
          'and they\'re all in column 4.',
      highlightCells: {(3, 3), (4, 3), (5, 3)},
      highlightCandidates: {(3, 3, 5), (4, 3, 5), (5, 3, 5)},
    ),
    GuideStep(
      caption: 'Wherever 5 ends up in this box, '
          'it must be in column 4. Three cells, one column — '
          'a Pointing Triple.',
      highlightCells: {(3, 3), (4, 3), (5, 3)},
      highlightCandidates: {(3, 3, 5), (4, 3, 5), (5, 3, 5)},
    ),
    GuideStep(
      caption: 'That means no other cell in column 4 can have 5.',
      highlightCells: {(3, 3), (4, 3), (5, 3), (0, 3), (1, 3), (6, 3)},
      highlightCandidates: {(3, 3, 5), (4, 3, 5), (5, 3, 5), (0, 3, 5), (1, 3, 5), (6, 3, 5)},
    ),
    GuideStep(
      caption: 'Eliminate 5 from column 4 outside the centre box.',
      highlightCells: {(3, 3), (4, 3), (5, 3)},
      highlightCandidates: {(3, 3, 5), (4, 3, 5), (5, 3, 5)},
      eliminateCandidates: {(0, 3, 5), (1, 3, 5), (6, 3, 5)},
    ),
    GuideStep(
      caption: 'A Pointing Triple works exactly like a Pointing Pair — '
          'three cells instead of two, same logic.',
    ),
  ],
);
