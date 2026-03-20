import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// X-Wing
// ---------------------------------------------------------------------------
//
// Candidate 4 appears in exactly 2 columns (col 2 and col 7) in both
// row 1 and row 6. This forms a rectangle - 4 must go in two
// diagonally opposite corners. So 4 can be eliminated from cols 2
// and 7 in all other rows.
//
// No 4 is placed in cols 2 or 7, so the X-Wing is the only way
// to make these eliminations.

final xWingGuide = StrategyGuide(
  strategy: StrategyType.xWing,
  difficulty: Difficulty.medium,
  intro: 'A candidate appears in exactly two positions in two different '
      'rows (or columns), forming a rectangle - it can be eliminated '
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
          'in column 3 and column 8 - the same two columns.',
      highlightCells: {(1, 2), (1, 7), (6, 2), (6, 7)},
      highlightCandidates: {(1, 2, 4), (1, 7, 4), (6, 2, 4), (6, 7, 4)},
    ),
    GuideStep(
      caption: 'These four cells form a rectangle. '
          '4 must go in two of them - either the top-left and '
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

final swordfishGuide = StrategyGuide(
  strategy: StrategyType.swordfish,
  difficulty: Difficulty.medium,
  intro: 'Like an X-Wing but with three rows and three columns - '
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
          'three columns. Not every row needs all three columns - '
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

final jellyfishGuide = StrategyGuide(
  strategy: StrategyType.jellyfish,
  difficulty: Difficulty.hard,
  intro: 'Like Swordfish but with four rows and four columns - a candidate '
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
