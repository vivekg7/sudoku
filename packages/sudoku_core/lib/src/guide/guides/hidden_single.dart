import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

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
// within box 5 (centre box, rows 3-5, cols 3-5).
//
// Row 3: . . . | 8 . 5 | . . .
// Row 4: . . . | . . . | . . .
// Row 5: . . . | . 5 . | . . .   <- 5 is already in col 4 and row 3
//
// Actually let's build a cleaner example where the hidden single is
// easy to follow.
//
// We want to show: digit 7 can only go in one cell in row 3.
// Row 3 already has most cells filled or their candidates exclude 7.
//
// Board (only relevant parts shown, rest is 0):
//   Row 0: 7 . . | . . . | . . .   <- 7 in col 0
//   Row 1: . . . | . . . | . 7 .   <- 7 in col 7
//   Row 2: . . . | . . . | . . .
//   Row 3: . 3 6 | 7 . . | 2 . 9   <- 7 placed in col 3; need to find 7 in this row
//   Row 4: . . . | . . . | . . .
//   Row 5: . . 7 | . . . | . . .   <- 7 in col 2
//   Row 6: . . . | . . . | . . .
//   Row 7: . . . | . . 7 | . . .   <- 7 in col 5
//   Row 8: . . . | . . . | . . .
//
// Row 3 needs 7. Cols already having 7: 0,2,3,5,7.
// Row 3 filled positions: col1=3, col2=6, col3=7, col6=2, col8=9
// Row 3 empty positions: col0, col4, col5, col7
// Col 0 has 7 (row 0) -> can't be 7
// Col 4 is free -> could be 7
// Col 5 has 7 (row 7) -> can't be 7
// Col 7 has 7 (row 1) -> can't be 7
// So 7 can only go in (3,4) -> Hidden Single!

final hiddenSingleGuide = StrategyGuide(
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
  candidates: _candidates({}), // No candidates needed - scanning strategy
  steps: [
    // Step 1: Focus on the row
    GuideStep(
      caption: "Let's find where 7 goes in row 4. "
          "Some cells are already filled - focus on the empty ones.",
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
          "That's a Hidden Single - 7 has nowhere else to go.",
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
