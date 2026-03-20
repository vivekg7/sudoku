import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Box/Line Reduction
// ---------------------------------------------------------------------------
//
// Candidate 6 in row 6 appears only in cols 0 and 1 - both in box 6
// (rows 6-8, cols 0-2). So 6 can be eliminated from the rest of box 6.
//
// Why does 6 only appear in cols 0-1 of row 6? Fill the other cells
// in row 6 with non-6 digits so they're occupied. No 6 placed in any
// box that would make the elimination trivial.

final boxLineReductionGuide = StrategyGuide(
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
    6 * 9 + 0: {6, 7},          // has 6 <- box/line
    6 * 9 + 1: {6, 7},          // has 6 <- box/line
    // Rest of box 6 - cells with candidate 6 to be eliminated
    7 * 9 + 0: {1, 6, 8},       // will be eliminated
    7 * 9 + 1: {2, 4, 9},
    7 * 9 + 2: {4, 6, 8},       // will be eliminated
    8 * 9 + 0: {2, 3, 7},
    8 * 9 + 1: {3, 6, 9},       // will be eliminated
    8 * 9 + 2: {1, 7, 9},
  }),
  steps: [
    GuideStep(
      caption: 'Look at row 7. Most cells are filled - '
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
