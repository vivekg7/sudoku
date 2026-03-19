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
