import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Unique Rectangle Type 1
// ---------------------------------------------------------------------------
//
// Four cells forming a rectangle spanning 2 boxes:
//   Floor: (0,1)={4,9}, (0,4)={4,9} -- both bi-value
//   Roof:  (2,1)={4,9}, (2,4)={4,7,9} -- one bi-value, one with extras
// If (2,4) were also {4,9}, the puzzle would have two solutions
// (swap 4 and 9). To avoid the deadly pattern, (2,4) must NOT be
// just {4,9} -- so 4 and 9 can be eliminated from it.

final uniqueRectangleType1Guide = StrategyGuide(
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
// Roof:  (5,2)={3,5,6}, (5,7)={3,5,6} -- both have same extra: 5
// To break the deadly pattern, 5 must go in one of the roof cells.
// Eliminate 5 from any cell that sees both roof cells.

final uniqueRectangleType2Guide = StrategyGuide(
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
    // Roof cells: both {3, 5, 6} -- same extra candidate 5
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
// has {4,6}, they form a naked pair on {4,6} -- eliminating 4 and 6
// from other cells in row 3.

final uniqueRectangleType3Guide = StrategyGuide(
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
    // Another cell in row 3 with {4, 6} -- forms naked pair with extras
    3 * 9 + 1: {4, 6},
    // Cells in row 3 with 4 or 6 to eliminate
    3 * 9 + 5: {1, 4, 7},       // has 4 -- will be eliminated
    3 * 9 + 8: {3, 6, 9},       // has 6 -- will be eliminated
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
// pattern, the roof can't both be {5,9} -- so 9 must be eliminated
// from both roof cells.

final uniqueRectangleType4Guide = StrategyGuide(
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
    // Other cells in row 4 -- none have candidate 5
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
