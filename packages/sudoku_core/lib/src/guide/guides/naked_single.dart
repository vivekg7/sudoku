import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Naked Single
// ---------------------------------------------------------------------------
//
// A cell where all candidates except one have been eliminated by its
// row, column, and box. The remaining candidate must be the answer.
//
// Target cell: (4, 4) -- centre of the grid.
// We need 8 different digits visible in its row, column, and box,
// leaving only one candidate.
//
// Row 4: 5 . . | . ? . | . . 3   -> has 5, 3
// Col 4: 2 at (0,4), 8 at (8,4)  -> has 2, 8
// Box 4: 1 at (3,3), 9 at (3,5), 4 at (5,3), 6 at (5,5)  -> has 1, 9, 4, 6
//
// Eliminated: 1, 2, 3, 4, 5, 6, 8, 9 -> only 7 remains.

final nakedSingleGuide = StrategyGuide(
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
  candidates: _candidates({}), // No candidates needed -- elimination by scanning
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
