import '../models/difficulty.dart';
import '../solver/strategy_type.dart';
import 'strategy_guide.dart';

/// Registry of all strategy guides, keyed by strategy type.
final Map<StrategyType, StrategyGuide> strategyGuides = {
  for (final guide in _allGuides) guide.strategy: guide,
};

/// All strategy guides ordered by difficulty then strategy.
final List<StrategyGuide> allStrategyGuides = List.unmodifiable(_allGuides);

final List<StrategyGuide> _allGuides = [
  _hiddenSingleGuide,
  _nakedSingleGuide,
  _pointingPairGuide,
  _pointingTripleGuide,
  _boxLineReductionGuide,
  _nakedPairGuide,
  _hiddenPairGuide,
  _nakedTripleGuide,
  _hiddenTripleGuide,
  _nakedQuadGuide,
  _hiddenQuadGuide,
  _xWingGuide,
  _swordfishGuide,
  _jellyfishGuide,
  _xyWingGuide,
  _xyzWingGuide,
  _uniqueRectangleType1Guide,
  _uniqueRectangleType2Guide,
  _uniqueRectangleType3Guide,
  _uniqueRectangleType4Guide,
  _simpleColouringGuide,
  _xChainGuide,
  _xyChainGuide,
  _aicGuide,
  _forcingChainGuide,
  _almostLockedSetGuide,
  _sueDeCoqGuide,
];

// ---------------------------------------------------------------------------
// Helper to build a flat candidate list from a sparse map.
// Keys are cell indices (row * 9 + col), values are candidate sets.
// Cells not in the map get an empty set.
// ---------------------------------------------------------------------------
List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ===========================================================================
// BEGINNER
// ===========================================================================

// ---------------------------------------------------------------------------
// Hidden Single
// ---------------------------------------------------------------------------
//
// Board: A partially filled grid where digit 5 can only go in one cell
// within box 5 (centre box, rows 3–5, cols 3–5).
//
// Row 3: . . . | 8 . 5 | . . .
// Row 4: . . . | . . . | . . .
// Row 5: . . . | . 5 . | . . .   ← 5 is already in col 4 and row 3
//
// Actually let's build a cleaner example where the hidden single is
// easy to follow.
//
// We want to show: digit 7 can only go in one cell in row 3.
// Row 3 already has most cells filled or their candidates exclude 7.
//
// Board (only relevant parts shown, rest is 0):
//   Row 0: 7 . . | . . . | . . .   ← 7 in col 0
//   Row 1: . . . | . . . | . 7 .   ← 7 in col 7
//   Row 2: . . . | . . . | . . .
//   Row 3: . 3 6 | 7 . . | 2 . 9   ← 7 placed in col 3; need to find 7 in this row
//   Row 4: . . . | . . . | . . .
//   Row 5: . . 7 | . . . | . . .   ← 7 in col 2
//   Row 6: . . . | . . . | . . .
//   Row 7: . . . | . . 7 | . . .   ← 7 in col 5
//   Row 8: . . . | . . . | . . .
//
// Row 3 needs 7. Cols already having 7: 0,2,3,5,7.
// Row 3 filled positions: col1=3, col2=6, col3=7, col6=2, col8=9
// Row 3 empty positions: col0, col4, col5, col7
// Col 0 has 7 (row 0) → can't be 7
// Col 4 is free → could be 7
// Col 5 has 7 (row 7) → can't be 7
// Col 7 has 7 (row 1) → can't be 7
// So 7 can only go in (3,4) → Hidden Single!

final _hiddenSingleGuide = StrategyGuide(
  strategy: StrategyType.hiddenSingle,
  difficulty: Difficulty.beginner,
  intro: 'A digit that can only fit in one cell within a row, column, or box.',
  board: [
    [7, 0, 0, 0, 0, 0, 0, 0, 0], // row 0: 7 in col 0
    [0, 0, 0, 0, 0, 0, 0, 7, 0], // row 1: 7 in col 7
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 2
    [0, 3, 6, 7, 0, 0, 2, 0, 9], // row 3: target row
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 4
    [0, 0, 7, 0, 0, 0, 0, 0, 0], // row 5: 7 in col 2
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 6
    [0, 0, 0, 0, 0, 7, 0, 0, 0], // row 7: 7 in col 5
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 8
  ],
  candidates: _candidates({}), // No candidates needed — scanning strategy
  steps: [
    // Step 1: Focus on the row
    GuideStep(
      caption: "Let's find where 7 goes in row 4. "
          "Some cells are already filled — focus on the empty ones.",
      highlightCells: {(3, 0), (3, 4), (3, 5), (3, 7)},
    ),

    // Step 2: Col 0 has 7
    GuideStep(
      caption: 'Column 1 already has a 7 at the top. '
          "So 7 can't go here.",
      highlightCells: {(0, 0)},
      blockedCells: {(3, 0)},
    ),

    // Step 3: Col 5 has 7
    GuideStep(
      caption: 'Column 6 has a 7 further down. '
          'Ruled out too.',
      highlightCells: {(7, 5)},
      blockedCells: {(3, 5)},
    ),

    // Step 4: Col 7 has 7
    GuideStep(
      caption: 'Column 8 also has a 7. '
          'Another cell ruled out.',
      highlightCells: {(1, 7)},
      blockedCells: {(3, 7)},
    ),

    // Step 5: Only one cell left
    GuideStep(
      caption: 'Only one empty cell in this row can still hold 7. '
          "That's a Hidden Single — 7 has nowhere else to go.",
      highlightCells: {(3, 4)},
    ),

    // Step 6: Place it
    GuideStep(
      caption: 'Place 7 here. You found it by scanning the row '
          'and ruling out every other spot.',
      placeCells: {(3, 4, 7)},
    ),
  ],
);

// ---------------------------------------------------------------------------
// Naked Single
// ---------------------------------------------------------------------------
//
// A cell where all candidates except one have been eliminated by its
// row, column, and box. The remaining candidate must be the answer.
//
// Target cell: (4, 4) — centre of the grid.
// We need 8 different digits visible in its row, column, and box,
// leaving only one candidate.
//
// Row 4: 5 . . | . ? . | . . 3   → has 5, 3
// Col 4: 2 at (0,4), 8 at (8,4)  → has 2, 8
// Box 4: 1 at (3,3), 9 at (3,5), 4 at (5,3), 6 at (5,5)  → has 1, 9, 4, 6
//
// Eliminated: 1, 2, 3, 4, 5, 6, 8, 9 → only 7 remains.

final _nakedSingleGuide = StrategyGuide(
  strategy: StrategyType.nakedSingle,
  difficulty: Difficulty.beginner,
  intro: 'A cell with only one possible candidate left — all others are '
      'eliminated by its row, column, and box.',
  board: [
    [0, 0, 0, 0, 2, 0, 0, 0, 0], // row 0: 2 in col 4
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 1
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 2
    [0, 0, 0, 1, 0, 9, 0, 0, 0], // row 3: box 4 has 1, 9
    [5, 0, 0, 0, 0, 0, 0, 0, 3], // row 4: target row, has 5 and 3
    [0, 0, 0, 4, 0, 6, 0, 0, 0], // row 5: box 4 has 4, 6
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 6
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // row 7
    [0, 0, 0, 0, 8, 0, 0, 0, 0], // row 8: 8 in col 4
  ],
  candidates: _candidates({}), // No candidates needed — elimination by scanning
  steps: [
    // Step 1: Focus on the cell
    GuideStep(
      caption: "Look at the centre cell. Let's figure out what can go here "
          'by checking its row, column, and box.',
      highlightCells: {(4, 4)},
    ),

    // Step 2: Check the row
    GuideStep(
      caption: 'Its row has 5 and 3. '
          'That rules out two numbers.',
      highlightCells: {(4, 0), (4, 8)},
    ),

    // Step 3: Check the column
    GuideStep(
      caption: 'Its column has 2 and 8. '
          'Two more ruled out.',
      highlightCells: {(0, 4), (8, 4)},
    ),

    // Step 4: Check the box
    GuideStep(
      caption: 'Its box has 1, 9, 4, and 6. '
          'Four more gone.',
      highlightCells: {(3, 3), (3, 5), (5, 3), (5, 5)},
    ),

    // Step 5: Count what's left
    GuideStep(
      caption: '1, 2, 3, 4, 5, 6, 8, 9 are all taken. '
          'Only one number is left: 7.',
      highlightCells: {(4, 4)},
    ),

    // Step 6: Place it
    GuideStep(
      caption: 'Place 7. When every digit but one is ruled out, '
          "that's a Naked Single — the answer is right there "
          'in plain sight.',
      placeCells: {(4, 4, 7)},
    ),
  ],
);

// ===========================================================================
// EASY
// ===========================================================================

// ---------------------------------------------------------------------------
// Pointing Pair
// ---------------------------------------------------------------------------
//
// Candidate 3 appears in box 1 (top-left) only in (0,1) and (0,2) — both
// in row 0. So 3 can be eliminated from the rest of row 0 outside box 1.
//
// Why only those two cells in box 1?
//   (7,0)=3 → eliminates col 0 (so (0,0), (1,0), (2,0) can't have 3)
//   (1,1)=8, (1,2)=4, (2,1)=2, (2,2)=1 → filled, can't be 3
// No 3 is placed in boxes 2 or 3, so the pointing pair is the only
// way to eliminate 3 from row 0 outside box 1.

final _pointingPairGuide = StrategyGuide(
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
    0 * 9 + 0: {1, 5, 7},       // no 3 — col 0 has 3
    0 * 9 + 1: {1, 3, 5},       // has 3 ← pointing pair
    0 * 9 + 2: {3, 5, 9},       // has 3 ← pointing pair
    1 * 9 + 0: {5, 6, 9},       // no 3 — col 0 has 3
    2 * 9 + 0: {5, 6, 7},       // no 3 — col 0 has 3
    // Row 0 outside box 1 — some cells have 3 (to be eliminated)
    0 * 9 + 3: {2, 6, 8},
    0 * 9 + 4: {1, 4, 6},
    0 * 9 + 5: {2, 3, 6},       // has 3 — will be eliminated
    0 * 9 + 6: {4, 8, 9},
    0 * 9 + 7: {1, 3, 8},       // has 3 — will be eliminated
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
// Candidate 5 appears in box 4 (centre) only in (3,3), (4,3), (5,3) —
// all in column 3. So 5 can be eliminated from col 3 outside box 4.
//
// Box 4 has 6 cells filled: (3,4)=8, (3,5)=2, (4,4)=1, (4,5)=9,
// (5,4)=6, (5,5)=4. The only 3 empty cells are in col 3.
// No 5 is placed in boxes 1, 2, 3, 7, 8, or 9 — so the pointing
// triple is the only way to eliminate 5 from col 3 outside box 4.

final _pointingTripleGuide = StrategyGuide(
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
    3 * 9 + 3: {1, 5, 7},       // has 5 ← pointing triple
    4 * 9 + 3: {3, 5, 7},       // has 5 ← pointing triple
    5 * 9 + 3: {3, 5, 7},       // has 5 ← pointing triple
    // Col 3 outside box 4 — cells with candidate 5
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

// ---------------------------------------------------------------------------
// Box/Line Reduction
// ---------------------------------------------------------------------------
//
// Candidate 6 in row 6 appears only in cols 0 and 1 — both in box 6
// (rows 6-8, cols 0-2). So 6 can be eliminated from the rest of box 6.
//
// Why does 6 only appear in cols 0-1 of row 6? Fill the other cells
// in row 6 with non-6 digits so they're occupied. No 6 placed in any
// box that would make the elimination trivial.

final _boxLineReductionGuide = StrategyGuide(
  strategy: StrategyType.boxLineReduction,
  difficulty: Difficulty.easy,
  intro: 'When a candidate in a row or column is confined to one box, '
      'it can be eliminated from the rest of that box.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 3, 8, 5, 1, 9, 4, 2], // row 6: filled except cols 0-1
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    // Row 6: only cols 0 and 1 are empty, both have candidate 6
    6 * 9 + 0: {6, 7},          // has 6 ← box/line
    6 * 9 + 1: {6, 7},          // has 6 ← box/line
    // Rest of box 6 — cells with candidate 6 to be eliminated
    7 * 9 + 0: {1, 6, 8},       // will be eliminated
    7 * 9 + 1: {2, 4, 9},
    7 * 9 + 2: {4, 6, 8},       // will be eliminated
    8 * 9 + 0: {2, 3, 7},
    8 * 9 + 1: {3, 6, 9},       // will be eliminated
    8 * 9 + 2: {1, 7, 9},
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 7. Most cells are filled — '
          'only two are empty, both in the bottom-left box.',
      highlightCells: {(6, 0), (6, 1)},
    ),
    GuideStep(
      caption: 'Both empty cells have 6 as a candidate. '
          'Since these are the only spots for 6 in this row, '
          '6 must end up in this box.',
      highlightCells: {(6, 0), (6, 1)},
      highlightCandidates: {(6, 0, 6), (6, 1, 6)},
    ),
    GuideStep(
      caption: 'The row has "claimed" 6 for this box. '
          'So no other cell in the box can have 6.',
      highlightCells: {(6, 0), (6, 1), (7, 0), (7, 2), (8, 1)},
      highlightCandidates: {(6, 0, 6), (6, 1, 6), (7, 0, 6), (7, 2, 6), (8, 1, 6)},
    ),
    GuideStep(
      caption: 'Eliminate 6 from the rest of the bottom-left box.',
      highlightCells: {(6, 0), (6, 1)},
      highlightCandidates: {(6, 0, 6), (6, 1, 6)},
      eliminateCandidates: {(7, 0, 6), (7, 2, 6), (8, 1, 6)},
    ),
    GuideStep(
      caption: "That's Box/Line Reduction: a row confines a candidate to "
          'one box, so it can be eliminated from the rest of that box. '
          "It's the reverse of Pointing Pairs.",
    ),
  ],
);

// ---------------------------------------------------------------------------
// Naked Pair
// ---------------------------------------------------------------------------
//
// In row 2, cells (2,3) and (2,6) both have exactly candidates {4, 8}.
// Since 4 and 8 must go in these two cells, eliminate 4 and 8 from
// all other cells in row 2.

final _nakedPairGuide = StrategyGuide(
  strategy: StrategyType.nakedPair,
  difficulty: Difficulty.easy,
  intro: 'Two cells in the same row, column, or box that share exactly the '
      'same two candidates — those digits can be removed from other cells '
      'in that house.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 9, 5, 0, 2, 7, 0, 0, 0], // row 2: partly filled
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    2 * 9 + 3: {4, 8},          // naked pair cell
    2 * 9 + 6: {4, 8},          // naked pair cell
    2 * 9 + 7: {3, 4, 6, 8},    // has 4 and 8 — will be eliminated
    2 * 9 + 8: {3, 6, 8},       // has 8 — will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 3. Some cells are filled, '
          'and four are empty with candidates.',
      highlightCells: {(2, 3), (2, 6), (2, 7), (2, 8)},
    ),
    GuideStep(
      caption: 'Two of these cells have exactly the same candidates: '
          '{4, 8}. No other possibilities.',
      highlightCells: {(2, 3), (2, 6)},
      highlightCandidates: {(2, 3, 4), (2, 3, 8), (2, 6, 4), (2, 6, 8)},
    ),
    GuideStep(
      caption: 'Since both cells can only be 4 or 8, '
          'one will be 4 and the other will be 8. '
          'We don\'t know which is which yet, but we know '
          'they claim both digits.',
      highlightCells: {(2, 3), (2, 6)},
      highlightCandidates: {(2, 3, 4), (2, 3, 8), (2, 6, 4), (2, 6, 8)},
    ),
    GuideStep(
      caption: 'That means no other cell in this row can be 4 or 8.',
      highlightCells: {(2, 3), (2, 6), (2, 7), (2, 8)},
      highlightCandidates: {
        (2, 3, 4), (2, 3, 8), (2, 6, 4), (2, 6, 8),
        (2, 7, 4), (2, 7, 8), (2, 8, 8),
      },
    ),
    GuideStep(
      caption: 'Eliminate 4 and 8 from the other cells in this row.',
      highlightCells: {(2, 3), (2, 6)},
      highlightCandidates: {(2, 3, 4), (2, 3, 8), (2, 6, 4), (2, 6, 8)},
      eliminateCandidates: {(2, 7, 4), (2, 7, 8), (2, 8, 8)},
    ),
    GuideStep(
      caption: "That's a Naked Pair: two cells, two candidates, "
          'locked together. The digits are "naked" because '
          'they\'re the only candidates in those cells.',
      highlightCells: {(2, 3), (2, 6)},
      highlightCandidates: {(2, 3, 4), (2, 3, 8), (2, 6, 4), (2, 6, 8)},
      eliminateCandidates: {(2, 7, 4), (2, 7, 8), (2, 8, 8)},
    ),
  ],
);

// ---------------------------------------------------------------------------
// Hidden Pair
// ---------------------------------------------------------------------------
//
// In row 3, candidates 2 and 6 appear only in cells (3,0) and (3,4).
// Those cells also have other candidates (3 and 5 respectively), but
// since 2 and 6 can only go in those two cells, the extras are eliminated.
//
// Row 3: _, 7, _, 4, _, 9, 8, 1, _
// Empty: (3,0), (3,2), (3,4), (3,8) — missing digits: 2, 3, 5, 6
// Candidates:
//   (3,0): {2, 3, 6}  — has 2 and 6
//   (3,2): {3, 5}     — no 2, no 6
//   (3,4): {2, 5, 6}  — has 2 and 6
//   (3,8): {3, 5}     — no 2, no 6
// Hidden pair {2, 6} in (3,0) and (3,4).

final _hiddenPairGuide = StrategyGuide(
  strategy: StrategyType.hiddenPair,
  difficulty: Difficulty.easy,
  intro: 'Two candidates that appear in exactly the same two cells within '
      'a house — all other candidates can be removed from those cells.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 7, 0, 4, 0, 9, 8, 1, 0], // row 3: 4 empty cells
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    3 * 9 + 0: {2, 3, 6},       // has 2 and 6 ← hidden pair
    3 * 9 + 2: {3, 5},          // no 2, no 6
    3 * 9 + 4: {2, 5, 6},       // has 2 and 6 ← hidden pair
    3 * 9 + 8: {3, 5},          // no 2, no 6
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 4. Four cells are empty '
          'with various candidates.',
      highlightCells: {(3, 0), (3, 2), (3, 4), (3, 8)},
    ),
    GuideStep(
      caption: 'Where can 2 go in this row? '
          'Only in these two cells.',
      highlightCells: {(3, 0), (3, 4)},
      highlightCandidates: {(3, 0, 2), (3, 4, 2)},
    ),
    GuideStep(
      caption: 'Where can 6 go? The same two cells — and nowhere else. '
          'Two digits, two cells. That\'s a Hidden Pair.',
      highlightCells: {(3, 0), (3, 4)},
      highlightCandidates: {(3, 0, 2), (3, 0, 6), (3, 4, 2), (3, 4, 6)},
    ),
    GuideStep(
      caption: 'Since 2 and 6 must go in these two cells, '
          'one gets 2 and the other gets 6. '
          'No room for anything else.',
      highlightCells: {(3, 0), (3, 4)},
      highlightCandidates: {(3, 0, 2), (3, 0, 6), (3, 4, 2), (3, 4, 6)},
    ),
    GuideStep(
      caption: 'Eliminate the extra candidates: '
          '3 from the first cell, 5 from the second.',
      highlightCells: {(3, 0), (3, 4)},
      highlightCandidates: {(3, 0, 2), (3, 0, 6), (3, 4, 2), (3, 4, 6)},
      eliminateCandidates: {(3, 0, 3), (3, 4, 5)},
    ),
    GuideStep(
      caption: 'That\'s a Hidden Pair: two digits "hidden" among other '
          'candidates, but they only appear in these two cells. '
          'The pair locks in and everything else gets removed.',
    ),
  ],
);

// ===========================================================================
// MEDIUM
// ===========================================================================

// ---------------------------------------------------------------------------
// Naked Triple
// ---------------------------------------------------------------------------
//
// In row 4, cells (4,0), (4,1), and (4,7) together contain only
// candidates {2, 5, 8}. These 3 digits are locked into those 3 cells,
// so eliminate 2, 5, 8 from the other empty cells in row 4.
//
// Row 4: _, _, 7, _, 3, _, 9, _, 1
// Empty: (4,0), (4,1), (4,3), (4,5), (4,7) — missing: 2, 4, 5, 6, 8
// Candidates:
//   (4,0): {2, 5}        — triple cell
//   (4,1): {5, 8}        — triple cell
//   (4,3): {2, 4, 5, 6}  — has 2, 5 to eliminate
//   (4,5): {4, 6, 8}     — has 8 to eliminate
//   (4,7): {2, 8}        — triple cell

final _nakedTripleGuide = StrategyGuide(
  strategy: StrategyType.nakedTriple,
  difficulty: Difficulty.medium,
  intro: 'Three cells in a house whose combined candidates contain exactly '
      'three digits — those digits can be removed from other cells.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 7, 0, 3, 0, 9, 0, 1], // row 4: 5 empty cells
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    // The triple: cells with subsets of {2, 5, 8}
    4 * 9 + 0: {2, 5},          // naked triple cell
    4 * 9 + 1: {5, 8},          // naked triple cell
    4 * 9 + 7: {2, 8},          // naked triple cell
    // Other empty cells in row 4 with overlapping candidates
    4 * 9 + 3: {2, 4, 5, 6},    // has 2, 5 — will be eliminated
    4 * 9 + 5: {4, 6, 8},       // has 8 — will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 5. Five cells are empty.',
      highlightCells: {(4, 0), (4, 1), (4, 3), (4, 5), (4, 7)},
    ),
    GuideStep(
      caption: 'Three of them have very few candidates: '
          '{2, 5}, {5, 8}, and {2, 8}. '
          'All drawn from the same three digits: 2, 5, and 8.',
      highlightCells: {(4, 0), (4, 1), (4, 7)},
      highlightCandidates: {
        (4, 0, 2), (4, 0, 5),
        (4, 1, 5), (4, 1, 8),
        (4, 7, 2), (4, 7, 8),
      },
    ),
    GuideStep(
      caption: 'Three cells, three digits — a Naked Triple. '
          '2, 5, and 8 must go in these cells, one per cell.',
      highlightCells: {(4, 0), (4, 1), (4, 7)},
      highlightCandidates: {
        (4, 0, 2), (4, 0, 5),
        (4, 1, 5), (4, 1, 8),
        (4, 7, 2), (4, 7, 8),
      },
    ),
    GuideStep(
      caption: 'The other empty cells in this row also have some of '
          'these digits as candidates. Since the triple has '
          'claimed 2, 5, 8, they need to go.',
      highlightCells: {(4, 0), (4, 1), (4, 7), (4, 3), (4, 5)},
      highlightCandidates: {
        (4, 0, 2), (4, 0, 5),
        (4, 1, 5), (4, 1, 8),
        (4, 7, 2), (4, 7, 8),
        (4, 3, 2), (4, 3, 5),
        (4, 5, 8),
      },
    ),
    GuideStep(
      caption: 'Eliminate 2, 5, and 8 from the other cells in this row.',
      highlightCells: {(4, 0), (4, 1), (4, 7)},
      highlightCandidates: {
        (4, 0, 2), (4, 0, 5),
        (4, 1, 5), (4, 1, 8),
        (4, 7, 2), (4, 7, 8),
      },
      eliminateCandidates: {(4, 3, 2), (4, 3, 5), (4, 5, 8)},
    ),
    GuideStep(
      caption: 'Naked Triple: same idea as Naked Pair, one size up. '
          "Each cell doesn't need all three digits — "
          'the combined set just has to be exactly three.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Hidden Triple
// ---------------------------------------------------------------------------
//
// In row 5, candidates 1, 4, and 9 appear only in cells (5,0), (5,3),
// and (5,7). Those cells also have other candidates, but since 1, 4, 9
// can only go in those three cells, the extras are eliminated.
//
// Row 5: _, _, 3, _, 8, _, 7, _, 5
// Empty: (5,0), (5,1), (5,3), (5,5), (5,7) — missing: 1, 2, 4, 6, 9
// Candidates:
//   (5,0): {1, 2, 4}  — has 1, 4
//   (5,1): {2, 6}     — no 1, 4, or 9
//   (5,3): {1, 2, 9}  — has 1, 9
//   (5,5): {2, 6}     — no 1, 4, or 9
//   (5,7): {4, 6, 9}  — has 4, 9
// 1, 4, 9 only appear in (5,0), (5,3), (5,7) → Hidden Triple.

final _hiddenTripleGuide = StrategyGuide(
  strategy: StrategyType.hiddenTriple,
  difficulty: Difficulty.medium,
  intro: 'Three candidates that appear in exactly the same three cells — '
      'all other candidates can be removed from those cells.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 3, 0, 8, 0, 7, 0, 5], // row 5: 5 empty cells
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    5 * 9 + 0: {1, 2, 4},       // has 1, 4 ← hidden triple
    5 * 9 + 1: {2, 6},          // no 1, 4, or 9
    5 * 9 + 3: {1, 2, 9},       // has 1, 9 ← hidden triple
    5 * 9 + 5: {2, 6},          // no 1, 4, or 9
    5 * 9 + 7: {4, 6, 9},       // has 4, 9 ← hidden triple
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 6. Five cells are empty '
          'with various candidates.',
      highlightCells: {(5, 0), (5, 1), (5, 3), (5, 5), (5, 7)},
    ),
    GuideStep(
      caption: 'Where can 1 go in this row? '
          'Only two of the five cells.',
      highlightCells: {(5, 0), (5, 3)},
      highlightCandidates: {(5, 0, 1), (5, 3, 1)},
    ),
    GuideStep(
      caption: 'Where can 9 go? Only two cells — '
          'and one of them overlaps with 1.',
      highlightCells: {(5, 3), (5, 7)},
      highlightCandidates: {(5, 3, 9), (5, 7, 9)},
    ),
    GuideStep(
      caption: 'Where can 4 go? Again only two cells. '
          'Together, 1, 4, and 9 only appear in these three cells. '
          "That's a Hidden Triple.",
      highlightCells: {(5, 0), (5, 3), (5, 7)},
      highlightCandidates: {
        (5, 0, 1), (5, 0, 4),
        (5, 3, 1), (5, 3, 9),
        (5, 7, 4), (5, 7, 9),
      },
    ),
    GuideStep(
      caption: 'Since 1, 4, 9 must go in these three cells, '
          'eliminate every other candidate from them.',
      highlightCells: {(5, 0), (5, 3), (5, 7)},
      highlightCandidates: {
        (5, 0, 1), (5, 0, 4),
        (5, 3, 1), (5, 3, 9),
        (5, 7, 4), (5, 7, 9),
      },
      eliminateCandidates: {(5, 0, 2), (5, 3, 2), (5, 7, 6)},
    ),
    GuideStep(
      caption: 'Hidden Triple: three digits hidden among other '
          'candidates, but confined to exactly three cells. '
          'Same idea as Hidden Pair, one size up.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Naked Quad
// ---------------------------------------------------------------------------
//
// In row 7, 4 cells together contain only candidates {2, 4, 6, 9}.
// Row 7: _, _, 7, _, _, 8, _, _, 1
// Empty: (7,0), (7,1), (7,3), (7,4), (7,6), (7,7) — missing: 2,3,4,5,6,9
// Candidates:
//   (7,0): {2, 4}       — quad cell
//   (7,1): {4, 6, 9}    — quad cell
//   (7,3): {3, 4, 5, 6} — has 4, 6 to eliminate
//   (7,4): {3, 5, 9}    — has 9 to eliminate
//   (7,6): {2, 9}       — quad cell
//   (7,7): {2, 6}       — quad cell

final _nakedQuadGuide = StrategyGuide(
  strategy: StrategyType.nakedQuad,
  difficulty: Difficulty.medium,
  intro: 'Four cells in a house whose combined candidates contain exactly '
      'four digits — those digits can be removed from other cells.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 7, 0, 0, 8, 0, 0, 1], // row 7: 6 empty cells
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    // The quad: cells with subsets of {2, 4, 6, 9}
    7 * 9 + 0: {2, 4},          // quad cell
    7 * 9 + 1: {4, 6, 9},       // quad cell
    7 * 9 + 6: {2, 9},          // quad cell
    7 * 9 + 7: {2, 6},          // quad cell
    // Other empty cells in row 7 with overlapping candidates
    7 * 9 + 3: {3, 4, 5, 6},    // has 4, 6 — will be eliminated
    7 * 9 + 4: {3, 5, 9},       // has 9 — will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 8. Six cells are empty.',
      highlightCells: {(7, 0), (7, 1), (7, 3), (7, 4), (7, 6), (7, 7)},
    ),
    GuideStep(
      caption: 'Four of them have candidates drawn only from '
          '{2, 4, 6, 9}: cells with {2, 4}, {4, 6, 9}, '
          '{2, 9}, and {2, 6}.',
      highlightCells: {(7, 0), (7, 1), (7, 6), (7, 7)},
      highlightCandidates: {
        (7, 0, 2), (7, 0, 4),
        (7, 1, 4), (7, 1, 6), (7, 1, 9),
        (7, 6, 2), (7, 6, 9),
        (7, 7, 2), (7, 7, 6),
      },
    ),
    GuideStep(
      caption: 'Four cells, four digits — a Naked Quad. '
          '2, 4, 6, 9 are locked into these four cells.',
      highlightCells: {(7, 0), (7, 1), (7, 6), (7, 7)},
      highlightCandidates: {
        (7, 0, 2), (7, 0, 4),
        (7, 1, 4), (7, 1, 6), (7, 1, 9),
        (7, 6, 2), (7, 6, 9),
        (7, 7, 2), (7, 7, 6),
      },
    ),
    GuideStep(
      caption: 'The other two empty cells also have some of '
          'these digits. Since the quad has claimed them, '
          'they need to go.',
      highlightCells: {(7, 0), (7, 1), (7, 6), (7, 7), (7, 3), (7, 4)},
      highlightCandidates: {
        (7, 0, 2), (7, 0, 4),
        (7, 1, 4), (7, 1, 6), (7, 1, 9),
        (7, 6, 2), (7, 6, 9),
        (7, 7, 2), (7, 7, 6),
        (7, 3, 4), (7, 3, 6),
        (7, 4, 9),
      },
    ),
    GuideStep(
      caption: 'Eliminate 4, 6, and 9 from the other cells in this row.',
      highlightCells: {(7, 0), (7, 1), (7, 6), (7, 7)},
      highlightCandidates: {
        (7, 0, 2), (7, 0, 4),
        (7, 1, 4), (7, 1, 6), (7, 1, 9),
        (7, 6, 2), (7, 6, 9),
        (7, 7, 2), (7, 7, 6),
      },
      eliminateCandidates: {(7, 3, 4), (7, 3, 6), (7, 4, 9)},
    ),
    GuideStep(
      caption: 'Naked Quad: same logic as Naked Pair and Triple, '
          'just bigger. Four cells claim four digits.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Hidden Quad
// ---------------------------------------------------------------------------
//
// In row 2, candidates 1, 3, 7, 8 appear only in cells (2,0), (2,2),
// (2,4), (2,7). Those cells have other candidates too, which get removed.
//
// Row 2: _, _, _, 6, _, _, 9, _, 5
// Empty: (2,0), (2,1), (2,2), (2,4), (2,5), (2,7) — missing: 1,2,3,4,7,8
// Candidates:
//   (2,0): {1, 2, 3}     — has 1, 3 (quad)
//   (2,1): {2, 4}         — no quad digits
//   (2,2): {3, 4, 7, 8}  — has 3, 7, 8 (quad)
//   (2,4): {1, 4, 8}     — has 1, 8 (quad)
//   (2,5): {2, 4}         — no quad digits
//   (2,7): {4, 7, 8}     — has 7, 8 (quad)
// Digits 1, 3, 7, 8 only appear in the 4 quad cells.

final _hiddenQuadGuide = StrategyGuide(
  strategy: StrategyType.hiddenQuad,
  difficulty: Difficulty.medium,
  intro: 'Four candidates that appear in exactly four cells — all other '
      'candidates can be removed from those cells.',
  board: [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 6, 0, 0, 9, 0, 5], // row 2: 6 empty cells
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
  ],
  candidates: _candidates({
    2 * 9 + 0: {1, 2, 3},       // has 1, 3 ← hidden quad
    2 * 9 + 1: {2, 4},          // no quad digits
    2 * 9 + 2: {3, 4, 7, 8},    // has 3, 7, 8 ← hidden quad
    2 * 9 + 4: {1, 4, 8},       // has 1, 8 ← hidden quad
    2 * 9 + 5: {2, 4},          // no quad digits
    2 * 9 + 7: {4, 7, 8},       // has 7, 8 ← hidden quad
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 3. Six cells are empty '
          'with various candidates.',
      highlightCells: {(2, 0), (2, 1), (2, 2), (2, 4), (2, 5), (2, 7)},
    ),
    GuideStep(
      caption: 'Where can 1 go? Only two cells. '
          'Where can 3 go? Also only two cells.',
      highlightCells: {(2, 0), (2, 2), (2, 4)},
      highlightCandidates: {(2, 0, 1), (2, 4, 1), (2, 0, 3), (2, 2, 3)},
    ),
    GuideStep(
      caption: 'Where can 7 go? Two cells. And 8? Three cells. '
          'Together, 1, 3, 7, 8 only appear in these four cells.',
      highlightCells: {(2, 0), (2, 2), (2, 4), (2, 7)},
      highlightCandidates: {
        (2, 0, 1), (2, 0, 3),
        (2, 2, 3), (2, 2, 7), (2, 2, 8),
        (2, 4, 1), (2, 4, 8),
        (2, 7, 7), (2, 7, 8),
      },
    ),
    GuideStep(
      caption: 'Four digits, four cells — a Hidden Quad. '
          'These digits are locked into these cells.',
      highlightCells: {(2, 0), (2, 2), (2, 4), (2, 7)},
      highlightCandidates: {
        (2, 0, 1), (2, 0, 3),
        (2, 2, 3), (2, 2, 7), (2, 2, 8),
        (2, 4, 1), (2, 4, 8),
        (2, 7, 7), (2, 7, 8),
      },
    ),
    GuideStep(
      caption: 'Eliminate every other candidate from those four cells.',
      highlightCells: {(2, 0), (2, 2), (2, 4), (2, 7)},
      highlightCandidates: {
        (2, 0, 1), (2, 0, 3),
        (2, 2, 3), (2, 2, 7), (2, 2, 8),
        (2, 4, 1), (2, 4, 8),
        (2, 7, 7), (2, 7, 8),
      },
      eliminateCandidates: {(2, 0, 2), (2, 2, 4), (2, 4, 4), (2, 7, 4)},
    ),
    GuideStep(
      caption: 'Hidden Quad: four digits confined to four cells, '
          'hidden among other candidates. '
          'Rare, but the same logic as Hidden Pair and Triple.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// X-Wing
// ---------------------------------------------------------------------------
//
// Candidate 4 appears in exactly 2 columns (col 2 and col 7) in both
// row 1 and row 6. This forms a rectangle — 4 must go in two
// diagonally opposite corners. So 4 can be eliminated from cols 2
// and 7 in all other rows.
//
// No 4 is placed in cols 2 or 7, so the X-Wing is the only way
// to make these eliminations.

final _xWingGuide = StrategyGuide(
  strategy: StrategyType.xWing,
  difficulty: Difficulty.medium,
  intro: 'A candidate appears in exactly two positions in two different '
      'rows (or columns), forming a rectangle — it can be eliminated '
      'from the rest of those columns (or rows).',
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
    // Row 1: candidate 4 only in cols 2 and 7
    1 * 9 + 2: {3, 4, 6},
    1 * 9 + 7: {4, 5, 9},
    // Row 6: candidate 4 only in cols 2 and 7
    6 * 9 + 2: {1, 4, 8},
    6 * 9 + 7: {2, 4, 7},
    // Other cells in cols 2 and 7 with candidate 4 (to be eliminated)
    0 * 9 + 2: {4, 5, 7},       // will be eliminated
    3 * 9 + 2: {2, 4, 9},       // will be eliminated
    4 * 9 + 7: {4, 6, 8},       // will be eliminated
    8 * 9 + 7: {1, 4, 3},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at candidate 4. In row 2, '
          'it can only go in two cells: column 3 and column 8.',
      highlightCells: {(1, 2), (1, 7)},
      highlightCandidates: {(1, 2, 4), (1, 7, 4)},
    ),
    GuideStep(
      caption: 'Now check row 7. Candidate 4 can also only go '
          'in column 3 and column 8 — the same two columns.',
      highlightCells: {(1, 2), (1, 7), (6, 2), (6, 7)},
      highlightCandidates: {(1, 2, 4), (1, 7, 4), (6, 2, 4), (6, 7, 4)},
    ),
    GuideStep(
      caption: 'These four cells form a rectangle. '
          '4 must go in two of them — either the top-left and '
          'bottom-right, or top-right and bottom-left.',
      highlightCells: {(1, 2), (1, 7), (6, 2), (6, 7)},
      highlightCandidates: {(1, 2, 4), (1, 7, 4), (6, 2, 4), (6, 7, 4)},
    ),
    GuideStep(
      caption: 'Either way, columns 3 and 8 each get exactly one 4 '
          'from these two rows. No other cell in those columns '
          'can have 4.',
      highlightCells: {
        (1, 2), (1, 7), (6, 2), (6, 7),
        (0, 2), (3, 2), (4, 7), (8, 7),
      },
      highlightCandidates: {
        (1, 2, 4), (1, 7, 4), (6, 2, 4), (6, 7, 4),
        (0, 2, 4), (3, 2, 4), (4, 7, 4), (8, 7, 4),
      },
    ),
    GuideStep(
      caption: 'Eliminate 4 from columns 3 and 8 outside the X-Wing.',
      highlightCells: {(1, 2), (1, 7), (6, 2), (6, 7)},
      highlightCandidates: {(1, 2, 4), (1, 7, 4), (6, 2, 4), (6, 7, 4)},
      eliminateCandidates: {(0, 2, 4), (3, 2, 4), (4, 7, 4), (8, 7, 4)},
    ),
    GuideStep(
      caption: "That's an X-Wing: two rows, two columns, one candidate, "
          'four cells forming a rectangle. '
          'Named after the shape the pattern makes.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Swordfish
// ---------------------------------------------------------------------------
//
// Candidate 6 appears in exactly cols {1, 4, 7} across rows 0, 3, and 8.
// Each row has 6 in 2-3 of those columns, and collectively they cover
// exactly 3 columns. So 6 can be eliminated from cols 1, 4, 7 in all
// other rows.

final _swordfishGuide = StrategyGuide(
  strategy: StrategyType.swordfish,
  difficulty: Difficulty.medium,
  intro: 'Like an X-Wing but with three rows and three columns — '
      'a candidate confined to the same three columns across three rows '
      'can be eliminated from those columns in other rows.',
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
    // Row 0: candidate 6 in cols 1 and 4
    0 * 9 + 1: {2, 6, 8},
    0 * 9 + 4: {3, 6, 7},
    // Row 3: candidate 6 in cols 4 and 7
    3 * 9 + 4: {1, 6, 5},
    3 * 9 + 7: {6, 8, 9},
    // Row 8: candidate 6 in cols 1 and 7
    8 * 9 + 1: {1, 6, 3},
    8 * 9 + 7: {5, 6, 7},
    // Other cells in cols 1, 4, 7 with candidate 6 (to be eliminated)
    2 * 9 + 1: {4, 6, 9},       // will be eliminated
    5 * 9 + 4: {2, 6, 8},       // will be eliminated
    6 * 9 + 7: {3, 6, 5},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at candidate 6. In row 1, '
          'it can only go in columns 2 and 5.',
      highlightCells: {(0, 1), (0, 4)},
      highlightCandidates: {(0, 1, 6), (0, 4, 6)},
    ),
    GuideStep(
      caption: 'In row 4, candidate 6 can only go in columns 5 and 8.',
      highlightCells: {(0, 1), (0, 4), (3, 4), (3, 7)},
      highlightCandidates: {(0, 1, 6), (0, 4, 6), (3, 4, 6), (3, 7, 6)},
    ),
    GuideStep(
      caption: 'In row 9, candidate 6 can only go in columns 2 and 8. '
          'Three rows, and they collectively use just three columns: '
          '2, 5, and 8.',
      highlightCells: {(0, 1), (0, 4), (3, 4), (3, 7), (8, 1), (8, 7)},
      highlightCandidates: {
        (0, 1, 6), (0, 4, 6),
        (3, 4, 6), (3, 7, 6),
        (8, 1, 6), (8, 7, 6),
      },
    ),
    GuideStep(
      caption: 'This is a Swordfish. Each of the three columns must '
          'get exactly one 6 from these three rows. '
          'So no other row can have 6 in those columns.',
      highlightCells: {(0, 1), (0, 4), (3, 4), (3, 7), (8, 1), (8, 7)},
      highlightCandidates: {
        (0, 1, 6), (0, 4, 6),
        (3, 4, 6), (3, 7, 6),
        (8, 1, 6), (8, 7, 6),
      },
    ),
    GuideStep(
      caption: 'Eliminate 6 from columns 2, 5, and 8 outside '
          'the Swordfish rows.',
      highlightCells: {(0, 1), (0, 4), (3, 4), (3, 7), (8, 1), (8, 7)},
      highlightCandidates: {
        (0, 1, 6), (0, 4, 6),
        (3, 4, 6), (3, 7, 6),
        (8, 1, 6), (8, 7, 6),
      },
      eliminateCandidates: {(2, 1, 6), (5, 4, 6), (6, 7, 6)},
    ),
    GuideStep(
      caption: 'Swordfish: an X-Wing scaled up to three rows and '
          'three columns. Not every row needs all three columns — '
          'just that the set of columns used is exactly three.',
    ),
  ],
);

// ===========================================================================
// HARD
// ===========================================================================

// ---------------------------------------------------------------------------
// Jellyfish
// ---------------------------------------------------------------------------
//
// Like Swordfish but with 4 rows and 4 columns.
// Candidate 3 across rows 0, 2, 5, 7 uses only cols {0, 3, 5, 8}.
// Each row has 3 in 2-3 of those columns. Eliminate 3 from those
// cols in other rows.

final _jellyfishGuide = StrategyGuide(
  strategy: StrategyType.jellyfish,
  difficulty: Difficulty.hard,
  intro: 'Like Swordfish but with four rows and four columns — a candidate '
      'confined to four columns across four rows can be eliminated '
      'from those columns in other rows.',
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
    // Row 0: 3 in cols 0 and 3
    0 * 9 + 0: {1, 3, 7},
    0 * 9 + 3: {3, 6, 9},
    // Row 2: 3 in cols 3 and 5
    2 * 9 + 3: {2, 3, 4},
    2 * 9 + 5: {3, 7, 8},
    // Row 5: 3 in cols 5 and 8
    5 * 9 + 5: {1, 3, 6},
    5 * 9 + 8: {3, 4, 9},
    // Row 7: 3 in cols 0 and 8
    7 * 9 + 0: {3, 5, 8},
    7 * 9 + 8: {2, 3, 7},
    // Elimination targets: cols 0, 3, 5, 8 in other rows
    4 * 9 + 0: {3, 6, 9},       // will be eliminated
    1 * 9 + 3: {1, 3, 5},       // will be eliminated
    6 * 9 + 5: {3, 4, 8},       // will be eliminated
    3 * 9 + 8: {2, 3, 6},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at candidate 3 across the grid. In row 1, '
          'it can only go in columns 1 and 4.',
      highlightCells: {(0, 0), (0, 3)},
      highlightCandidates: {(0, 0, 3), (0, 3, 3)},
    ),
    GuideStep(
      caption: 'Row 3: columns 4 and 6. Row 6: columns 6 and 9. '
          'Row 8: columns 1 and 9.',
      highlightCells: {
        (0, 0), (0, 3), (2, 3), (2, 5),
        (5, 5), (5, 8), (7, 0), (7, 8),
      },
      highlightCandidates: {
        (0, 0, 3), (0, 3, 3), (2, 3, 3), (2, 5, 3),
        (5, 5, 3), (5, 8, 3), (7, 0, 3), (7, 8, 3),
      },
    ),
    GuideStep(
      caption: 'Four rows, and they collectively use just four columns: '
          '1, 4, 6, and 9. That\'s a Jellyfish.',
      highlightCells: {
        (0, 0), (0, 3), (2, 3), (2, 5),
        (5, 5), (5, 8), (7, 0), (7, 8),
      },
      highlightCandidates: {
        (0, 0, 3), (0, 3, 3), (2, 3, 3), (2, 5, 3),
        (5, 5, 3), (5, 8, 3), (7, 0, 3), (7, 8, 3),
      },
    ),
    GuideStep(
      caption: 'Each of the four columns gets exactly one 3 from '
          'these four rows. Eliminate 3 from those columns '
          'in all other rows.',
      highlightCells: {
        (0, 0), (0, 3), (2, 3), (2, 5),
        (5, 5), (5, 8), (7, 0), (7, 8),
        (4, 0), (1, 3), (6, 5), (3, 8),
      },
      highlightCandidates: {
        (0, 0, 3), (0, 3, 3), (2, 3, 3), (2, 5, 3),
        (5, 5, 3), (5, 8, 3), (7, 0, 3), (7, 8, 3),
        (4, 0, 3), (1, 3, 3), (6, 5, 3), (3, 8, 3),
      },
    ),
    GuideStep(
      caption: 'Eliminate 3 from the four columns outside the Jellyfish.',
      highlightCells: {
        (0, 0), (0, 3), (2, 3), (2, 5),
        (5, 5), (5, 8), (7, 0), (7, 8),
      },
      highlightCandidates: {
        (0, 0, 3), (0, 3, 3), (2, 3, 3), (2, 5, 3),
        (5, 5, 3), (5, 8, 3), (7, 0, 3), (7, 8, 3),
      },
      eliminateCandidates: {(4, 0, 3), (1, 3, 3), (6, 5, 3), (3, 8, 3)},
    ),
    GuideStep(
      caption: 'Jellyfish: the Fish pattern scaled to size 4. '
          'Rare in practice, but the same logic as X-Wing and Swordfish.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// XY-Wing
// ---------------------------------------------------------------------------
//
// Pivot cell (4,4) has candidates {3, 7}.
// Pincer 1: (4,1) has {3, 5} — shares row with pivot.
// Pincer 2: (1,4) has {7, 5} — shares column with pivot.
// Both pincers have 5. Any cell seeing both pincers can't have 5.
// Elimination target: (1,1) sees both pincers (same row as pincer2,
// same col as pincer1... no wait, same BOX as pincer1 if in box 1).
//
// Let me redesign: pivot (4,4) {3,7}, pincer1 (4,0) {3,5} in row 4,
// pincer2 (7,4) {7,5} in col 4.
// Cell (7,0) sees pincer1 (col 0) and pincer2 (row 7) — and has 5.

final _xyWingGuide = StrategyGuide(
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
    // Pincer 1: (4,0) with {3, 5} — same row as pivot
    4 * 9 + 0: {3, 5},
    // Pincer 2: (7,4) with {7, 5} — same col as pivot
    7 * 9 + 4: {5, 7},
    // Elimination target: (7,0) sees both pincers (col 0 + row 7)
    7 * 9 + 0: {1, 5, 8},       // has 5 — will be eliminated
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

// ---------------------------------------------------------------------------
// XYZ-Wing
// ---------------------------------------------------------------------------
//
// Pivot cell (4,4) has candidates {2, 5, 8}.
// Pincer 1: (4,3) has {2, 5} — same row and same box as pivot.
// Pincer 2: (3,4) has {5, 8} — same column and same box as pivot.
// All three share candidate 5. Eliminate 5 from cells seeing all three.
// Since all three are in box 4, eliminate 5 from other cells in box 4
// that have candidate 5.

final _xyzWingGuide = StrategyGuide(
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
    // Pincer 1: (4,3) with {2, 5} — same row + box as pivot
    4 * 9 + 3: {2, 5},
    // Pincer 2: (3,4) with {5, 8} — same col + box as pivot
    3 * 9 + 4: {5, 8},
    // All three are in box 4 → eliminate 5 from other box 4 cells
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

// ---------------------------------------------------------------------------
// Unique Rectangle Type 1
// ---------------------------------------------------------------------------
//
// Four cells forming a rectangle spanning 2 boxes:
//   Floor: (0,1)={4,9}, (0,4)={4,9} — both bi-value
//   Roof:  (2,1)={4,9}, (2,4)={4,7,9} — one bi-value, one with extras
// If (2,4) were also {4,9}, the puzzle would have two solutions
// (swap 4 and 9). To avoid the deadly pattern, (2,4) must NOT be
// just {4,9} — so 4 and 9 can be eliminated from it.

final _uniqueRectangleType1Guide = StrategyGuide(
  strategy: StrategyType.uniqueRectangleType1,
  difficulty: Difficulty.hard,
  intro: 'Four cells form a rectangle with the same two candidates — '
      'one cell must break the pattern to keep the puzzle unique.',
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
    // Floor cells (row 0): both {4, 9}
    0 * 9 + 1: {4, 9},
    0 * 9 + 4: {4, 9},
    // Roof cells (row 2): one {4,9}, one with extra
    2 * 9 + 1: {4, 9},
    2 * 9 + 4: {4, 7, 9},       // has extra 7
  }),
  steps: [
    GuideStep(
      caption: 'Four cells form a rectangle across two boxes. '
          'Three of them have exactly the same candidates: {4, 9}.',
      highlightCells: {(0, 1), (0, 4), (2, 1), (2, 4)},
      highlightCandidates: {
        (0, 1, 4), (0, 1, 9),
        (0, 4, 4), (0, 4, 9),
        (2, 1, 4), (2, 1, 9),
        (2, 4, 4), (2, 4, 7), (2, 4, 9),
      },
    ),
    GuideStep(
      caption: 'If the fourth cell were also just {4, 9}, you could '
          'swap 4 and 9 in all four corners and get a second valid '
          'solution. But every puzzle has exactly one solution.',
      highlightCells: {(0, 1), (0, 4), (2, 1), (2, 4)},
      highlightCandidates: {
        (0, 1, 4), (0, 1, 9),
        (0, 4, 4), (0, 4, 9),
        (2, 1, 4), (2, 1, 9),
      },
    ),
    GuideStep(
      caption: 'So this cell must NOT end up as just {4, 9}. '
          'It has an extra candidate — 7 — which must be its value. '
          'Eliminate 4 and 9 from it.',
      highlightCells: {(2, 4)},
      highlightCandidates: {(2, 4, 7)},
      eliminateCandidates: {(2, 4, 4), (2, 4, 9)},
    ),
    GuideStep(
      caption: 'Unique Rectangle Type 1: three bi-value cells form '
          'a deadly pattern — the fourth must break it by using '
          'its extra candidate.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Unique Rectangle Type 2
// ---------------------------------------------------------------------------
//
// Floor: (1,2)={3,6}, (1,7)={3,6}
// Roof:  (5,2)={3,5,6}, (5,7)={3,5,6} — both have same extra: 5
// To break the deadly pattern, 5 must go in one of the roof cells.
// Eliminate 5 from any cell that sees both roof cells.

final _uniqueRectangleType2Guide = StrategyGuide(
  strategy: StrategyType.uniqueRectangleType2,
  difficulty: Difficulty.hard,
  intro: 'Both roof cells have the same extra candidate — it must go in '
      'one of them, so eliminate it from their common peers.',
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
    // Floor cells: both {3, 6}
    1 * 9 + 2: {3, 6},
    1 * 9 + 7: {3, 6},
    // Roof cells: both {3, 5, 6} — same extra candidate 5
    5 * 9 + 2: {3, 5, 6},
    5 * 9 + 7: {3, 5, 6},
    // Cells seeing both roof cells (same row) with candidate 5
    5 * 9 + 0: {1, 5, 8},       // will be eliminated
    5 * 9 + 4: {2, 5, 9},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Four cells form a rectangle. The two floor cells '
          '(top) both have {3, 6}.',
      highlightCells: {(1, 2), (1, 7), (5, 2), (5, 7)},
      highlightCandidates: {
        (1, 2, 3), (1, 2, 6),
        (1, 7, 3), (1, 7, 6),
      },
    ),
    GuideStep(
      caption: 'The two roof cells (bottom) both have {3, 5, 6} — '
          'the same extra candidate: 5.',
      highlightCells: {(1, 2), (1, 7), (5, 2), (5, 7)},
      highlightCandidates: {
        (5, 2, 3), (5, 2, 5), (5, 2, 6),
        (5, 7, 3), (5, 7, 5), (5, 7, 6),
      },
    ),
    GuideStep(
      caption: 'To avoid a deadly pattern, 5 must go in one of the '
          'roof cells. So 5 can be eliminated from any cell '
          'that sees both roof cells.',
      highlightCells: {(5, 2), (5, 7), (5, 0), (5, 4)},
      highlightCandidates: {(5, 2, 5), (5, 7, 5), (5, 0, 5), (5, 4, 5)},
    ),
    GuideStep(
      caption: 'Eliminate 5 from the common peers of the roof cells.',
      highlightCells: {(5, 2), (5, 7)},
      highlightCandidates: {(5, 2, 5), (5, 7, 5)},
      eliminateCandidates: {(5, 0, 5), (5, 4, 5)},
    ),
    GuideStep(
      caption: 'Unique Rectangle Type 2: both roof cells share '
          'the same extra digit — it\'s "trapped" in the roof, '
          'eliminating it from their common peers.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Unique Rectangle Type 3
// ---------------------------------------------------------------------------
//
// Floor: (0,3)={2,8}, (0,6)={2,8}
// Roof:  (3,3)={2,6,8}, (3,6)={2,4,8}
// Extras in roof: 6 and 4. Together with another cell in row 3 that
// has {4,6}, they form a naked pair on {4,6} — eliminating 4 and 6
// from other cells in row 3.

final _uniqueRectangleType3Guide = StrategyGuide(
  strategy: StrategyType.uniqueRectangleType3,
  difficulty: Difficulty.hard,
  intro: 'The extra candidates in the roof cells form a naked subset '
      'with another cell, enabling further eliminations.',
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
    // Floor: both {2, 8}
    0 * 9 + 3: {2, 8},
    0 * 9 + 6: {2, 8},
    // Roof: extras are 6 and 4
    3 * 9 + 3: {2, 6, 8},
    3 * 9 + 6: {2, 4, 8},
    // Another cell in row 3 with {4, 6} — forms naked pair with extras
    3 * 9 + 1: {4, 6},
    // Cells in row 3 with 4 or 6 to eliminate
    3 * 9 + 5: {1, 4, 7},       // has 4 — will be eliminated
    3 * 9 + 8: {3, 6, 9},       // has 6 — will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Four cells form a rectangle. The floor cells '
          'both have {2, 8}.',
      highlightCells: {(0, 3), (0, 6), (3, 3), (3, 6)},
      highlightCandidates: {
        (0, 3, 2), (0, 3, 8), (0, 6, 2), (0, 6, 8),
      },
    ),
    GuideStep(
      caption: 'The roof cells have extras beyond {2, 8}: '
          'one has 6, the other has 4.',
      highlightCells: {(3, 3), (3, 6)},
      highlightCandidates: {
        (3, 3, 2), (3, 3, 6), (3, 3, 8),
        (3, 6, 2), (3, 6, 4), (3, 6, 8),
      },
    ),
    GuideStep(
      caption: 'To break the deadly pattern, at least one roof cell '
          'must use its extra (4 or 6). Together, the extras '
          'form the set {4, 6}.',
      highlightCells: {(3, 3), (3, 6)},
      highlightCandidates: {(3, 3, 6), (3, 6, 4)},
    ),
    GuideStep(
      caption: 'Another cell in row 4 has exactly {4, 6}. '
          'Combined with the roof extras, this forms a naked pair '
          'on {4, 6} in this row.',
      highlightCells: {(3, 3), (3, 6), (3, 1)},
      highlightCandidates: {(3, 3, 6), (3, 6, 4), (3, 1, 4), (3, 1, 6)},
    ),
    GuideStep(
      caption: 'Eliminate 4 and 6 from other cells in row 4.',
      highlightCells: {(3, 3), (3, 6), (3, 1)},
      highlightCandidates: {(3, 3, 6), (3, 6, 4), (3, 1, 4), (3, 1, 6)},
      eliminateCandidates: {(3, 5, 4), (3, 8, 6)},
    ),
    GuideStep(
      caption: 'Unique Rectangle Type 3: the roof extras form a '
          'naked subset with neighbouring cells, unlocking '
          'further eliminations in the house.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Unique Rectangle Type 4
// ---------------------------------------------------------------------------
//
// Floor: (1,0)={5,9}, (1,3)={5,9}
// Roof:  (4,0)={3,5,9}, (4,3)={5,7,9}
// In row 4, candidate 5 appears only in the two roof cells (among the
// cells of this row). So 5 is locked in the roof. To break the deadly
// pattern, the roof can't both be {5,9} — so 9 must be eliminated
// from both roof cells.

final _uniqueRectangleType4Guide = StrategyGuide(
  strategy: StrategyType.uniqueRectangleType4,
  difficulty: Difficulty.hard,
  intro: 'One of the rectangle\'s candidates is locked in the roof cells — '
      'the other candidate can be eliminated from both roof cells.',
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
    // Floor: both {5, 9}
    1 * 9 + 0: {5, 9},
    1 * 9 + 3: {5, 9},
    // Roof: both have 5 and 9 plus extras
    4 * 9 + 0: {3, 5, 9},
    4 * 9 + 3: {5, 7, 9},
    // Other cells in row 4 — none have candidate 5
    // (5 is locked in the roof cells for this row)
    4 * 9 + 1: {1, 3, 7},
    4 * 9 + 2: {1, 7, 8},
    4 * 9 + 4: {2, 3, 8},
    4 * 9 + 5: {1, 7, 8},
    4 * 9 + 6: {2, 3, 8},
    4 * 9 + 7: {1, 7, 8},
    4 * 9 + 8: {2, 3, 7},
  }),
  steps: [
    GuideStep(
      caption: 'Four cells form a rectangle. The floor cells '
          'both have {5, 9}.',
      highlightCells: {(1, 0), (1, 3), (4, 0), (4, 3)},
      highlightCandidates: {
        (1, 0, 5), (1, 0, 9), (1, 3, 5), (1, 3, 9),
      },
    ),
    GuideStep(
      caption: 'The roof cells also have 5 and 9, plus extras. '
          'Look at row 5: where can 5 go?',
      highlightCells: {(4, 0), (4, 3)},
      highlightCandidates: {
        (4, 0, 3), (4, 0, 5), (4, 0, 9),
        (4, 3, 5), (4, 3, 7), (4, 3, 9),
      },
    ),
    GuideStep(
      caption: 'In row 5, candidate 5 appears only in the two roof '
          'cells — nowhere else. So 5 is locked in the roof.',
      highlightCells: {(4, 0), (4, 3)},
      highlightCandidates: {(4, 0, 5), (4, 3, 5)},
    ),
    GuideStep(
      caption: 'Since 5 must go in one of the roof cells, they can\'t '
          'both end up as {5, 9} — that would create a deadly pattern. '
          'So 9 must be eliminated from both roof cells.',
      highlightCells: {(4, 0), (4, 3)},
      highlightCandidates: {(4, 0, 5), (4, 3, 5)},
      eliminateCandidates: {(4, 0, 9), (4, 3, 9)},
    ),
    GuideStep(
      caption: 'Unique Rectangle Type 4: one candidate is locked '
          'in the roof — the other gets eliminated to prevent '
          'the deadly pattern.',
    ),
  ],
);

// ===========================================================================
// EXPERT
// ===========================================================================

// ---------------------------------------------------------------------------
// Simple Coloring
// ---------------------------------------------------------------------------
//
// Candidate 7 forms conjugate pairs (exactly 2 cells per house):
//   Box 0: (0,2) ↔ (2,0) — conjugate pair
//   Col 0: (2,0) ↔ (6,0) — conjugate pair
//   Row 6: (6,0) ↔ (6,8) — conjugate pair
//
// Color A (blue): (0,2), (6,0)
// Color B (amber): (2,0), (6,8)
//
// Target (0,8): sees (0,2) [color A] via row 0 and (6,8) [color B]
// via col 8. It sees both colors → eliminate 7.
// Target is NOT in any conjugate pair house (box 0, col 0, row 6).

final _simpleColouringGuide = StrategyGuide(
  strategy: StrategyType.simpleColouring,
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
    0 * 9 + 5: {5, 7, 8},       // 7 in row 0 → not a conjugate pair
    3 * 9 + 8: {2, 7, 9},       // 7 in col 8 → not a conjugate pair
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

// ---------------------------------------------------------------------------
// X-Chain
// ---------------------------------------------------------------------------
//
// A chain of conjugate pairs for candidate 2, even length (4 nodes):
//   Row 0: (0,1) ↔ (0,7)
//   Col 7: (0,7) ↔ (5,7)
//   Row 5: (5,7) ↔ (5,2)
//
// Chain: (0,1) — (0,7) — (5,7) — (5,2)
// Both endpoints (0,1) and (5,2) have the same parity.
// Target (3,1) sees (0,1) via col 1 and (5,2) via box 3.
// Target is NOT in any chain house (row 0, col 7, row 5).

final _xChainGuide = StrategyGuide(
  strategy: StrategyType.xChain,
  difficulty: Difficulty.expert,
  intro: 'A chain of conjugate pairs for one candidate — cells seeing '
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
          'only two cells — a conjugate pair. '
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
          'The chain has 4 nodes and 3 links — even length.',
      highlightCells: {(0, 1), (0, 7), (5, 7), (5, 2)},
      highlightCandidates: {(0, 1, 2), (0, 7, 2), (5, 7, 2), (5, 2, 2)},
    ),
    GuideStep(
      caption: 'The two endpoints have the same parity — one of them '
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

// ---------------------------------------------------------------------------
// XY-Chain
// ---------------------------------------------------------------------------
//
// A chain of bi-value cells:
//   (0,0)={3,8} → (0,5)={8,5} → (4,5)={5,1} → (4,2)={1,3}
// Shared: consecutive cells share one candidate.
// Free value at start: 3. Free value at end: 3. They match!
// Eliminate 3 from cells seeing both endpoints.
// (4,0) sees (0,0) via col 0 and (4,2) via row 4.

final _xyChainGuide = StrategyGuide(
  strategy: StrategyType.xyChain,
  difficulty: Difficulty.expert,
  intro: 'A chain of bi-value cells where consecutive cells share one '
      'candidate — the unshared candidate at both ends can be eliminated '
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
      caption: 'A peer cell has {8, 5} — it shares 8 with the first. '
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

// ---------------------------------------------------------------------------
// Alternating Inference Chain (AIC)
// ---------------------------------------------------------------------------
//
// An AIC alternates strong and weak links between (cell, candidate) nodes.
// Strong link: if one is false, the other must be true.
// Weak link: if one is true, the other must be false.
//
// Chain for candidate 5:
//   (1,3)=5 —strong[col 3]— (7,3)=5
//   (7,3)=5 —weak[row 7]—   (7,6)=5
//   (7,6)=5 —strong[box 8]— (8,8)=5
//
// Endpoints: (1,3) and (8,8). Both reached via strong links.
// One of them must be 5. Target (1,8) sees both → eliminate 5.
// Extra 5s in row 1, row 7, and col 8 prevent simpler chains.

final _aicGuide = StrategyGuide(
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
    7 * 9 + 1: {5, 6, 8},       // 5 in row 7 → not conjugate pair
    1 * 9 + 6: {1, 4, 5},       // 5 in row 1 → not conjugate pair
    4 * 9 + 8: {2, 5, 7},       // 5 in col 8 → not conjugate pair
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
          'have 5 there. The chain: strong → weak → strong.',
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

// ===========================================================================
// MASTER
// ===========================================================================

// ---------------------------------------------------------------------------
// Forcing Chain
// ---------------------------------------------------------------------------
//
// Cell (4,4) has candidates {3, 7}.
// If (4,4)=3 → propagation forces (4,8)=9 (via naked singles in row 4)
// If (4,4)=7 → propagation forces (4,8)=9 (via different path)
// Both branches agree: (4,8) must be 9.
//
// Row 4: _, 2, 6, 1, _, 8, 5, 4, _
// Empty: (4,0), (4,4), (4,8) — missing: 3, 7, 9
// (4,0) has {3, 9}, (4,4) has {3, 7}, (4,8) has {7, 9}
// If (4,4)=3 → (4,0) loses 3 → (4,0)=9 → (4,8) loses 9... wait.
// Let me reconsider.
//
// Actually simpler: (4,4) has {3,7}. (4,0) has {7,9}. (4,8) has {3,9}.
// If (4,4)=3 → 3 gone from row → (4,8) loses 3 → (4,8)=9
// If (4,4)=7 → 7 gone from row → (4,0) loses 7 → (4,0)=9 → (4,8) loses 9 → (4,8)=9... wait, (4,8) still has {3,9}.
// Hmm, need the chain to propagate to the same conclusion.
//
// If (4,4)=7 → (4,0) loses 7 → (4,0)=9 → (4,8) loses 9 → (4,8)=3
// That's NOT the same. Let me redesign.
//
// Better: use a cell outside the row.
// (4,4) has {3,7}. Pivot cell.
// Branch 3: (4,4)=3 → some chain → forces (0,4)=6
// Branch 7: (4,4)=7 → some chain → forces (0,4)=6
// Both agree on (0,4)=6.
//
// Keep it simple — the walkthrough doesn't need full propagation,
// just the concept. Show a bi-value cell, two branches, same result.

// Pivot (4,4): {2, 8}
//
// Path A (2+ steps): (4,4)=2
//   → (4,7)={2,5} loses 2 (row 4) → (4,7)=5
//   → (7,7)={3,5} loses 5 (col 7) → (7,7)=3
//   → (7,1)={3,6} loses 3 (row 7) → (7,1)=6 → eliminates 6 from (1,1)
//
// Path B (2+ steps): (4,4)=8
//   → (1,4)={4,8} loses 8 (col 4) → (1,4)=4
//   → (1,7)={4,6} loses 4 (row 1) → (1,7)=6 → eliminates 6 from (1,1)
//
// Both branches eliminate 6 from (1,1) via multi-step propagation.
// NOT an XY-Wing: the pincers don't share a common digit (5 vs 4).

final _forcingChainGuide = StrategyGuide(
  strategy: StrategyType.forcingChain,
  difficulty: Difficulty.master,
  intro: 'Assume each candidate in a cell — if all assumptions lead to '
      'the same conclusion elsewhere, that conclusion must be true.',
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
    4 * 9 + 4: {2, 8},          // pivot cell
    // Path A chain: row 4 → col 7 → row 7
    4 * 9 + 7: {2, 5},          // loses 2 → becomes 5
    7 * 9 + 7: {3, 5},          // loses 5 → becomes 3
    7 * 9 + 1: {3, 6},          // loses 3 → becomes 6 → col 1
    // Path B chain: col 4 → row 1
    1 * 9 + 4: {4, 8},          // loses 8 → becomes 4
    1 * 9 + 7: {4, 6},          // loses 4 → becomes 6 → row 1
    // Target: both paths place 6 where it eliminates from (1,1)
    1 * 9 + 1: {4, 6, 9},       // 6 eliminated
  }),
  steps: [
    GuideStep(
      caption: 'This cell has two candidates: {2, 8}. '
          "Let's try each one and follow the chain of consequences.",
      highlightCells: {(4, 4)},
      highlightCandidates: {(4, 4, 2), (4, 4, 8)},
    ),
    GuideStep(
      caption: 'Branch 1: Assume it\'s 2. In the same row, this cell '
          'loses 2 and becomes 5.',
      highlightCells: {(4, 4), (4, 7)},
      highlightCandidates: {(4, 4, 2), (4, 7, 5)},
    ),
    GuideStep(
      caption: '5 propagates down the column: this cell loses 5 '
          'and becomes 3. Then 3 propagates along the row: '
          'this cell loses 3 and becomes 6.',
      highlightCells: {(4, 4), (4, 7), (7, 7), (7, 1)},
      highlightCandidates: {(4, 4, 2), (4, 7, 5), (7, 7, 3), (7, 1, 6)},
    ),
    GuideStep(
      caption: 'With 6 placed in column 2, this target cell '
          'loses 6. That\'s the end of branch 1.',
      highlightCells: {(4, 4), (7, 1), (1, 1)},
      highlightCandidates: {(4, 4, 2), (7, 1, 6), (1, 1, 4), (1, 1, 9)},
    ),
    GuideStep(
      caption: 'Branch 2: Assume it\'s 8 instead. In the same column, '
          'this cell loses 8 and becomes 4.',
      highlightCells: {(4, 4), (1, 4)},
      highlightCandidates: {(4, 4, 8), (1, 4, 4)},
    ),
    GuideStep(
      caption: '4 propagates along the row: this cell loses 4 '
          'and becomes 6.',
      highlightCells: {(4, 4), (1, 4), (1, 7)},
      highlightCandidates: {(4, 4, 8), (1, 4, 4), (1, 7, 6)},
    ),
    GuideStep(
      caption: 'With 6 in row 2, the same target cell loses 6 again — '
          'through a completely different path.',
      highlightCells: {(4, 4), (1, 7), (1, 1)},
      highlightCandidates: {(4, 4, 8), (1, 7, 6), (1, 1, 4), (1, 1, 9)},
    ),
    GuideStep(
      caption: 'Both branches eliminate 6 from the same cell. Eliminate 6.',
      highlightCells: {(4, 4)},
      eliminateCandidates: {(1, 1, 6)},
    ),
    GuideStep(
      caption: 'Forcing Chain: try each candidate, propagate using '
          'naked singles, and compare. If every branch agrees on '
          'the same result — it must be true. This goes beyond '
          'simpler chain techniques because each branch involves '
          'multiple steps of propagation.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Almost Locked Set (ALS-XZ)
// ---------------------------------------------------------------------------
//
// ALS A: cells (0,0) and (0,1) with candidates {2,5,8} and {5,7,8}
//   → 2 cells, 4 candidates (2,5,7,8) = N+2... that's too many.
//   → Need N cells with N+1 candidates.
//   → 2 cells with 3 candidates total: e.g., {2,5} and {5,8} → union {2,5,8}, 3 candidates, 2 cells ✓
//
// ALS A: (1,0)={2,5}, (1,1)={5,8} in row 1 — 2 cells, 3 candidates {2,5,8}
// ALS B: (6,0)={2,4}, (6,1)={4,8} in row 6 — 2 cells, 3 candidates {2,4,8}
//
// Restricted common X=2: appears in (1,0) of A and (6,0) of B.
// Both in col 0 — they see each other. X is restricted ✓.
// Common candidate Z=8: appears in (1,1) of A and (6,1) of B.
//
// Eliminate Z=8 from cells seeing all Z-holders: cells seeing both
// (1,1) and (6,1). They share col 1.
// Target: (3,1) has 8, sees both via col 1.

final _almostLockedSetGuide = StrategyGuide(
  strategy: StrategyType.almostLockedSet,
  difficulty: Difficulty.master,
  intro: 'Two groups of cells, each "almost locked" (N cells with N+1 '
      'candidates), sharing two common digits — one digit can be '
      'eliminated from cells seeing both groups.',
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
    // ALS A (row 1): 2 cells, 3 candidates {2, 5, 8}
    1 * 9 + 0: {2, 5},
    1 * 9 + 1: {5, 8},
    // ALS B (row 6): 2 cells, 3 candidates {2, 4, 8}
    6 * 9 + 0: {2, 4},
    6 * 9 + 1: {4, 8},
    // Target: sees Z=8 holders (1,1) and (6,1) via col 1
    3 * 9 + 1: {1, 8, 9},       // will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'An Almost Locked Set (ALS) is a group of N cells '
          'with N+1 candidates. Here are two such groups.',
      highlightCells: {(1, 0), (1, 1), (6, 0), (6, 1)},
    ),
    GuideStep(
      caption: 'ALS A: two cells in row 2 with candidates '
          '{2, 5} and {5, 8} — three candidates total in two cells. '
          'If you fixed any one candidate, the rest would be locked.',
      colorACells: {(1, 0), (1, 1)},
      highlightCandidates: {(1, 0, 2), (1, 0, 5), (1, 1, 5), (1, 1, 8)},
    ),
    GuideStep(
      caption: 'ALS B: two cells in row 7 with candidates '
          '{2, 4} and {4, 8} — three candidates in two cells.',
      colorACells: {(1, 0), (1, 1)},
      colorBCells: {(6, 0), (6, 1)},
      highlightCandidates: {(6, 0, 2), (6, 0, 4), (6, 1, 4), (6, 1, 8)},
    ),
    GuideStep(
      caption: 'The two groups share candidate 2 via column 1 — '
          'cells that can see each other. This is the '
          '"restricted common" (X). They also share candidate 8 '
          'via column 2 — this is Z.',
      colorACells: {(1, 0), (1, 1)},
      colorBCells: {(6, 0), (6, 1)},
      highlightCandidates: {
        (1, 0, 2), (6, 0, 2), (1, 1, 8), (6, 1, 8),
      },
    ),
    GuideStep(
      caption: 'Because X=2 is restricted (the groups see each other '
          'on 2), at most one group can contain 2. This forces '
          'Z=8 into one of the groups. So 8 must be in one '
          'of the Z-holders.',
      colorACells: {(1, 0), (1, 1)},
      colorBCells: {(6, 0), (6, 1)},
      highlightCandidates: {(1, 1, 8), (6, 1, 8)},
    ),
    GuideStep(
      caption: 'Any cell seeing all Z-holders can\'t have 8. '
          'This cell shares a column with both.',
      colorACells: {(1, 0), (1, 1)},
      colorBCells: {(6, 0), (6, 1)},
      highlightCells: {(3, 1)},
      highlightCandidates: {(1, 1, 8), (6, 1, 8), (3, 1, 8)},
    ),
    GuideStep(
      caption: 'Eliminate 8 from that cell.',
      colorACells: {(1, 0), (1, 1)},
      colorBCells: {(6, 0), (6, 1)},
      eliminateCandidates: {(3, 1, 8)},
    ),
    GuideStep(
      caption: 'ALS-XZ: two almost locked sets share a restricted '
          'common (X) and another common (Z). Z gets eliminated '
          'from cells seeing all Z-holders in both groups.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Sue de Coq
// ---------------------------------------------------------------------------
//
// Box-line intersection: box 0, row 0.
// (0,2)=7 is filled, so intersection has 2 empty cells: (0,0) and (0,1).
// Together they have candidates {3, 5, 6, 8} — 2 cells, 4 candidates (N+2).
//
// Partition of the 2 "extra" candidates:
//   lineOnly = {5}: appears in rest of row 0 but NOT rest of box 0.
//   boxOnly = {8}: appears in rest of box 0 but NOT rest of row 0.
//   shared = {3, 6}: appear in BOTH rest of row and rest of box.
//
// Eliminate: 5 from rest of row 0. 8 from rest of box 0.
// After: (0,0) must be 5 (only cell with 5 in intersection),
//        (0,1) must be 8 (only cell with 8). No contradiction.

final _sueDeCoqGuide = StrategyGuide(
  strategy: StrategyType.sueDeCoq,
  difficulty: Difficulty.master,
  intro: 'A box-line intersection with extra candidates that split — '
      'some locked to the row, others to the box.',
  board: [
    [0, 0, 7, 0, 0, 0, 0, 0, 0], // (0,2)=7 → intersection is 2 cells
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
    // Intersection cells: box 0 ∩ row 0 (cols 0-1, since (0,2)=7)
    0 * 9 + 0: {3, 5, 6},       // intersection — has lineOnly 5
    0 * 9 + 1: {3, 6, 8},       // intersection — has boxOnly 8
    // Rest of row 0: has 5 (lineOnly), 3, 6 (shared), NOT 8
    0 * 9 + 4: {2, 3, 5},       // has 5 — will be eliminated
    0 * 9 + 6: {4, 5, 6},       // has 5 — will be eliminated
    // Rest of box 0: has 8 (boxOnly), 3, 6 (shared), NOT 5
    1 * 9 + 0: {3, 8, 9},       // has 8 — will be eliminated
    2 * 9 + 1: {6, 8},          // has 8 — will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at where box 1 meets row 1 — two empty cells '
          'in the intersection. Together they have four candidates: '
          '{3, 5, 6, 8}. Two cells, four candidates — two more '
          'than the cells can hold.',
      highlightCells: {(0, 0), (0, 1)},
      highlightCandidates: {
        (0, 0, 3), (0, 0, 5), (0, 0, 6),
        (0, 1, 3), (0, 1, 6), (0, 1, 8),
      },
    ),
    GuideStep(
      caption: 'Look at where each candidate appears outside the '
          'intersection. 5 appears in the rest of the row '
          'but NOT the rest of the box — it\'s "line-only."',
      highlightCells: {(0, 0), (0, 1), (0, 4), (0, 6)},
      highlightCandidates: {
        (0, 0, 5), (0, 4, 5), (0, 6, 5),
      },
    ),
    GuideStep(
      caption: '8 appears in the rest of the box but NOT the rest '
          'of the row — it\'s "box-only."',
      highlightCells: {(0, 0), (0, 1), (1, 0), (2, 1)},
      highlightCandidates: {
        (0, 1, 8), (1, 0, 8), (2, 1, 8),
      },
    ),
    GuideStep(
      caption: '3 and 6 appear in both — they\'re shared and can go '
          'anywhere. But the extras (5 and 8) split cleanly: '
          '5 belongs to the row, 8 belongs to the box. '
          "That's a Sue de Coq.",
      highlightCells: {(0, 0), (0, 1)},
      highlightCandidates: {
        (0, 0, 3), (0, 0, 5), (0, 0, 6),
        (0, 1, 3), (0, 1, 6), (0, 1, 8),
      },
    ),
    GuideStep(
      caption: 'Since the intersection must supply 5 to the row '
          '(no other source), eliminate 5 from the rest of the row.',
      highlightCells: {(0, 0), (0, 1)},
      eliminateCandidates: {(0, 4, 5), (0, 6, 5)},
    ),
    GuideStep(
      caption: 'And since it must supply 8 to the box, '
          'eliminate 8 from the rest of the box.',
      highlightCells: {(0, 0), (0, 1)},
      eliminateCandidates: {(1, 0, 8), (2, 1, 8)},
    ),
    GuideStep(
      caption: 'Sue de Coq: a box-line intersection with extra '
          'candidates that split — one locked to the row, '
          'one to the box. One of the rarest strategies.',
    ),
  ],
);
