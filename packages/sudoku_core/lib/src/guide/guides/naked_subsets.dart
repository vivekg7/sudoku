import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Naked Pair
// ---------------------------------------------------------------------------
//
// In row 2, cells (2,3) and (2,6) both have exactly candidates {4, 8}.
// Since 4 and 8 must go in these two cells, eliminate 4 and 8 from
// all other cells in row 2.

final nakedPairGuide = StrategyGuide(
  strategy: StrategyType.nakedPair,
  difficulty: Difficulty.easy,
  intro: 'Two cells in the same row, column, or box that share exactly the '
      'same two candidates - those digits can be removed from other cells '
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
    2 * 9 + 7: {3, 4, 6, 8},    // has 4 and 8 - will be eliminated
    2 * 9 + 8: {3, 6, 8},       // has 8 - will be eliminated
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
// Empty: (4,0), (4,1), (4,3), (4,5), (4,7) - missing: 2, 4, 5, 6, 8
// Candidates:
//   (4,0): {2, 5}        - triple cell
//   (4,1): {5, 8}        - triple cell
//   (4,3): {2, 4, 5, 6}  - has 2, 5 to eliminate
//   (4,5): {4, 6, 8}     - has 8 to eliminate
//   (4,7): {2, 8}        - triple cell

final nakedTripleGuide = StrategyGuide(
  strategy: StrategyType.nakedTriple,
  difficulty: Difficulty.medium,
  intro: 'Three cells in a house whose combined candidates contain exactly '
      'three digits - those digits can be removed from other cells.',
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
    4 * 9 + 3: {2, 4, 5, 6},    // has 2, 5 - will be eliminated
    4 * 9 + 5: {4, 6, 8},       // has 8 - will be eliminated
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
      caption: 'Three cells, three digits - a Naked Triple. '
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
          "Each cell doesn't need all three digits - "
          'the combined set just has to be exactly three.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Naked Quad
// ---------------------------------------------------------------------------
//
// In row 7, 4 cells together contain only candidates {2, 4, 6, 9}.
// Row 7: _, _, 7, _, _, 8, _, _, 1
// Empty: (7,0), (7,1), (7,3), (7,4), (7,6), (7,7) - missing: 2,3,4,5,6,9
// Candidates:
//   (7,0): {2, 4}       - quad cell
//   (7,1): {4, 6, 9}    - quad cell
//   (7,3): {3, 4, 5, 6} - has 4, 6 to eliminate
//   (7,4): {3, 5, 9}    - has 9 to eliminate
//   (7,6): {2, 9}       - quad cell
//   (7,7): {2, 6}       - quad cell

final nakedQuadGuide = StrategyGuide(
  strategy: StrategyType.nakedQuad,
  difficulty: Difficulty.medium,
  intro: 'Four cells in a house whose combined candidates contain exactly '
      'four digits - those digits can be removed from other cells.',
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
    7 * 9 + 3: {3, 4, 5, 6},    // has 4, 6 - will be eliminated
    7 * 9 + 4: {3, 5, 9},       // has 9 - will be eliminated
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
      caption: 'Four cells, four digits - a Naked Quad. '
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
