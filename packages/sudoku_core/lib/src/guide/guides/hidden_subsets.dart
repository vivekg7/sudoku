import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Hidden Pair
// ---------------------------------------------------------------------------
//
// In row 3, candidates 2 and 6 appear only in cells (3,0) and (3,4).
// Those cells also have other candidates (3 and 5 respectively), but
// since 2 and 6 can only go in those two cells, the extras are eliminated.
//
// Row 3: _, 7, _, 4, _, 9, 8, 1, _
// Empty: (3,0), (3,2), (3,4), (3,8) - missing digits: 2, 3, 5, 6
// Candidates:
//   (3,0): {2, 3, 6}  - has 2 and 6
//   (3,2): {3, 5}     - no 2, no 6
//   (3,4): {2, 5, 6}  - has 2 and 6
//   (3,8): {3, 5}     - no 2, no 6
// Hidden pair {2, 6} in (3,0) and (3,4).

final hiddenPairGuide = StrategyGuide(
  strategy: StrategyType.hiddenPair,
  difficulty: Difficulty.easy,
  intro: 'Two candidates that appear in exactly the same two cells within '
      'a house - all other candidates can be removed from those cells.',
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
    3 * 9 + 0: {2, 3, 6},       // has 2 and 6 <- hidden pair
    3 * 9 + 2: {3, 5},          // no 2, no 6
    3 * 9 + 4: {2, 5, 6},       // has 2 and 6 <- hidden pair
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
      caption: 'Where can 6 go? The same two cells - and nowhere else. '
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
// Hidden Triple
// ---------------------------------------------------------------------------
//
// In row 5, candidates 1, 4, and 9 appear only in cells (5,0), (5,3),
// and (5,7). Those cells also have other candidates, but since 1, 4, 9
// can only go in those three cells, the extras are eliminated.
//
// Row 5: _, _, 3, _, 8, _, 7, _, 5
// Empty: (5,0), (5,1), (5,3), (5,5), (5,7) - missing: 1, 2, 4, 6, 9
// Candidates:
//   (5,0): {1, 2, 4}  - has 1, 4
//   (5,1): {2, 6}     - no 1, 4, or 9
//   (5,3): {1, 2, 9}  - has 1, 9
//   (5,5): {2, 6}     - no 1, 4, or 9
//   (5,7): {4, 6, 9}  - has 4, 9
// 1, 4, 9 only appear in (5,0), (5,3), (5,7) -> Hidden Triple.

final hiddenTripleGuide = StrategyGuide(
  strategy: StrategyType.hiddenTriple,
  difficulty: Difficulty.medium,
  intro: 'Three candidates that appear in exactly the same three cells - '
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
    5 * 9 + 0: {1, 2, 4},       // has 1, 4 <- hidden triple
    5 * 9 + 1: {2, 6},          // no 1, 4, or 9
    5 * 9 + 3: {1, 2, 9},       // has 1, 9 <- hidden triple
    5 * 9 + 5: {2, 6},          // no 1, 4, or 9
    5 * 9 + 7: {4, 6, 9},       // has 4, 9 <- hidden triple
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
      caption: 'Where can 9 go? Only two cells - '
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
// Hidden Quad
// ---------------------------------------------------------------------------
//
// In row 2, candidates 1, 3, 7, 8 appear only in cells (2,0), (2,2),
// (2,4), (2,7). Those cells have other candidates too, which get removed.
//
// Row 2: _, _, _, 6, _, _, 9, _, 5
// Empty: (2,0), (2,1), (2,2), (2,4), (2,5), (2,7) - missing: 1,2,3,4,7,8
// Candidates:
//   (2,0): {1, 2, 3}     - has 1, 3 (quad)
//   (2,1): {2, 4}         - no quad digits
//   (2,2): {3, 4, 7, 8}  - has 3, 7, 8 (quad)
//   (2,4): {1, 4, 8}     - has 1, 8 (quad)
//   (2,5): {2, 4}         - no quad digits
//   (2,7): {4, 7, 8}     - has 7, 8 (quad)
// Digits 1, 3, 7, 8 only appear in the 4 quad cells.

final hiddenQuadGuide = StrategyGuide(
  strategy: StrategyType.hiddenQuad,
  difficulty: Difficulty.medium,
  intro: 'Four candidates that appear in exactly four cells - all other '
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
    2 * 9 + 0: {1, 2, 3},       // has 1, 3 <- hidden quad
    2 * 9 + 1: {2, 4},          // no quad digits
    2 * 9 + 2: {3, 4, 7, 8},    // has 3, 7, 8 <- hidden quad
    2 * 9 + 4: {1, 4, 8},       // has 1, 8 <- hidden quad
    2 * 9 + 5: {2, 4},          // no quad digits
    2 * 9 + 7: {4, 7, 8},       // has 7, 8 <- hidden quad
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
      caption: 'Four digits, four cells - a Hidden Quad. '
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
