import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Almost Locked Set (ALS-XZ)
// ---------------------------------------------------------------------------
//
// ALS A: cells (0,0) and (0,1) with candidates {2,5,8} and {5,7,8}
//   -> 2 cells, 4 candidates (2,5,7,8) = N+2... that's too many.
//   -> Need N cells with N+1 candidates.
//   -> 2 cells with 3 candidates total: e.g., {2,5} and {5,8} -> union {2,5,8}, 3 candidates, 2 cells
//
// ALS A: (1,0)={2,5}, (1,1)={5,8} in row 1 -- 2 cells, 3 candidates {2,5,8}
// ALS B: (6,0)={2,4}, (6,1)={4,8} in row 6 -- 2 cells, 3 candidates {2,4,8}
//
// Restricted common X=2: appears in (1,0) of A and (6,0) of B.
// Both in col 0 -- they see each other. X is restricted.
// Common candidate Z=8: appears in (1,1) of A and (6,1) of B.
//
// Eliminate Z=8 from cells seeing all Z-holders: cells seeing both
// (1,1) and (6,1). They share col 1.
// Target: (3,1) has 8, sees both via col 1.

final almostLockedSetGuide = StrategyGuide(
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
