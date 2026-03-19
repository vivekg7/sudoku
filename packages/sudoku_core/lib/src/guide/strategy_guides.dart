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
  candidates: _candidates({
    // Row 3 empty cells — only showing candidates for 7 (simplified)
    // (3,0): col 0 has 7 → no 7 here
    3 * 9 + 0: {1, 4, 5, 8},
    // (3,4): this is where 7 must go
    3 * 9 + 4: {1, 4, 7, 8},
    // (3,5): col 5 has 7 → no 7 here
    3 * 9 + 5: {1, 4, 8},
    // (3,7): col 7 has 7 → no 7 here
    3 * 9 + 7: {1, 4, 5, 8},
  }),
  steps: [
    // Step 1: Focus on the row
    GuideStep(
      caption: "Let's find where 7 goes in row 4. "
          "Some cells are already filled — focus on the empty ones.",
      highlightCells: {(3, 0), (3, 4), (3, 5), (3, 7)},
    ),

    // Step 2: Check which empty cells can hold 7
    GuideStep(
      caption: 'Look at column 1 — there\'s already a 7 at the top. '
          'So this cell can\'t be 7.',
      highlightCells: {(0, 0), (3, 0)},
      highlightCandidates: {(3, 0, 1), (3, 0, 4), (3, 0, 5), (3, 0, 8)},
    ),

    // Step 3: Col 5 has 7
    GuideStep(
      caption: 'Column 6 has a 7 further down. '
          'So this cell can\'t be 7 either.',
      highlightCells: {(7, 5), (3, 5)},
      highlightCandidates: {(3, 5, 1), (3, 5, 4), (3, 5, 8)},
    ),

    // Step 4: Col 7 has 7
    GuideStep(
      caption: 'Column 8 also has a 7. '
          'Another cell ruled out.',
      highlightCells: {(1, 7), (3, 7)},
      highlightCandidates: {(3, 7, 1), (3, 7, 4), (3, 7, 5), (3, 7, 8)},
    ),

    // Step 5: Only one cell left
    GuideStep(
      caption: 'Only one empty cell in this row can still hold 7. '
          "Even though it has other candidates too, it's the only "
          'spot for 7 — that makes it a Hidden Single.',
      highlightCells: {(3, 4)},
      highlightCandidates: {(3, 4, 7)},
    ),

    // Step 6: Place it
    GuideStep(
      caption: 'Place 7 here. The digit was "hidden" among other '
          "candidates, but it had nowhere else to go in this row.",
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
  candidates: _candidates({
    // Only the target cell matters for this demo
    4 * 9 + 4: {7},
    // Some surrounding empty cells with multiple candidates for context
    4 * 9 + 1: {2, 6, 7, 8},
    4 * 9 + 2: {2, 6, 7, 8},
    4 * 9 + 3: {2, 7, 8},
    4 * 9 + 5: {2, 7, 8},
    4 * 9 + 6: {1, 4, 6, 7},
    4 * 9 + 7: {1, 4, 6, 7},
  }),
  steps: [
    // Step 1: Focus on the cell
    GuideStep(
      caption: "Look at the centre cell. Let's figure out what can go here "
          'by checking its row, column, and box.',
      highlightCells: {(4, 4)},
    ),

    // Step 2: Check the row
    GuideStep(
      caption: 'Its row already has 5 and 3. '
          'So this cell can\'t be 5 or 3.',
      highlightCells: {(4, 0), (4, 8), (4, 4)},
    ),

    // Step 3: Check the column
    GuideStep(
      caption: 'Its column has 2 at the top and 8 at the bottom. '
          'Cross off 2 and 8 as well.',
      highlightCells: {(0, 4), (8, 4), (4, 4)},
    ),

    // Step 4: Check the box
    GuideStep(
      caption: 'Its box (the centre box) has 1, 9, 4, and 6. '
          'That rules out four more numbers.',
      highlightCells: {(3, 3), (3, 5), (5, 3), (5, 5), (4, 4)},
    ),

    // Step 5: Count what's left
    GuideStep(
      caption: "Let's count: 1, 2, 3, 4, 5, 6, 8, and 9 are all taken. "
          'Only one number is left: 7.',
      highlightCells: {(4, 4)},
      highlightCandidates: {(4, 4, 7)},
    ),

    // Step 6: Place it
    GuideStep(
      caption: 'Place 7. When a cell has only one candidate left, '
          "it's called a Naked Single — the answer is right there "
          'in plain sight.',
      placeCells: {(4, 4, 7)},
    ),
  ],
);
