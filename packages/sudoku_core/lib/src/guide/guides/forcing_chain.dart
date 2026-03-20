import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ===========================================================================
// MASTER
// ===========================================================================

// ---------------------------------------------------------------------------
// Forcing Chain
// ---------------------------------------------------------------------------
//
// Cell (4,4) has candidates {3, 7}.
// If (4,4)=3 -> propagation forces (4,8)=9 (via naked singles in row 4)
// If (4,4)=7 -> propagation forces (4,8)=9 (via different path)
// Both branches agree: (4,8) must be 9.
//
// Row 4: _, 2, 6, 1, _, 8, 5, 4, _
// Empty: (4,0), (4,4), (4,8) - missing: 3, 7, 9
// (4,0) has {3, 9}, (4,4) has {3, 7}, (4,8) has {7, 9}
// If (4,4)=3 -> (4,0) loses 3 -> (4,0)=9 -> (4,8) loses 9... wait.
// Let me reconsider.
//
// Actually simpler: (4,4) has {3,7}. (4,0) has {7,9}. (4,8) has {3,9}.
// If (4,4)=3 -> 3 gone from row -> (4,8) loses 3 -> (4,8)=9
// If (4,4)=7 -> 7 gone from row -> (4,0) loses 7 -> (4,0)=9 -> (4,8) loses 9 -> (4,8)=9... wait, (4,8) still has {3,9}.
// Hmm, need the chain to propagate to the same conclusion.
//
// If (4,4)=7 -> (4,0) loses 7 -> (4,0)=9 -> (4,8) loses 9 -> (4,8)=3
// That's NOT the same. Let me redesign.
//
// Better: use a cell outside the row.
// (4,4) has {3,7}. Pivot cell.
// Branch 3: (4,4)=3 -> some chain -> forces (0,4)=6
// Branch 7: (4,4)=7 -> some chain -> forces (0,4)=6
// Both agree on (0,4)=6.
//
// Keep it simple - the walkthrough doesn't need full propagation,
// just the concept. Show a bi-value cell, two branches, same result.

// Pivot (4,4): {2, 8}
//
// Path A (2+ steps): (4,4)=2
//   -> (4,7)={2,5} loses 2 (row 4) -> (4,7)=5
//   -> (7,7)={3,5} loses 5 (col 7) -> (7,7)=3
//   -> (7,1)={3,6} loses 3 (row 7) -> (7,1)=6 -> eliminates 6 from (1,1)
//
// Path B (2+ steps): (4,4)=8
//   -> (1,4)={4,8} loses 8 (col 4) -> (1,4)=4
//   -> (1,7)={4,6} loses 4 (row 1) -> (1,7)=6 -> eliminates 6 from (1,1)
//
// Both branches eliminate 6 from (1,1) via multi-step propagation.
// NOT an XY-Wing: the pincers don't share a common digit (5 vs 4).

final forcingChainGuide = StrategyGuide(
  strategy: StrategyType.forcingChain,
  difficulty: Difficulty.master,
  intro: 'Assume each candidate in a cell - if all assumptions lead to '
      'the same conclusion elsewhere, that conclusion must be true.',
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
    4 * 9 + 4: {2, 8},          // pivot cell
    // Path A chain: row 4 -> col 7 -> row 7
    4 * 9 + 7: {2, 5},          // loses 2 -> becomes 5
    7 * 9 + 7: {3, 5},          // loses 5 -> becomes 3
    7 * 9 + 1: {3, 6},          // loses 3 -> becomes 6 -> col 1
    // Path B chain: col 4 -> row 1
    1 * 9 + 4: {4, 8},          // loses 8 -> becomes 4
    1 * 9 + 7: {4, 6},          // loses 4 -> becomes 6 -> row 1
    // Target: both paths place 6 where it eliminates from (1,1)
    1 * 9 + 1: {4, 6, 9},       // 6 eliminated
  }),
  steps: [
    GuideStep(
      caption: 'This cell has two candidates: {2, 8}. '
          "Let's try each one and follow the chain of consequences.",
      highlightCells: {(4, 4)},
      highlightCandidates: {(4, 4, 2), (4, 4, 8)},
    ),
    GuideStep(
      caption: 'Branch 1: Assume it\'s 2. In the same row, this cell '
          'loses 2 and becomes 5.',
      highlightCells: {(4, 4), (4, 7)},
      highlightCandidates: {(4, 4, 2), (4, 7, 5)},
    ),
    GuideStep(
      caption: '5 propagates down the column: this cell loses 5 '
          'and becomes 3. Then 3 propagates along the row: '
          'this cell loses 3 and becomes 6.',
      highlightCells: {(4, 4), (4, 7), (7, 7), (7, 1)},
      highlightCandidates: {(4, 4, 2), (4, 7, 5), (7, 7, 3), (7, 1, 6)},
    ),
    GuideStep(
      caption: 'With 6 placed in column 2, this target cell '
          'loses 6. That\'s the end of branch 1.',
      highlightCells: {(4, 4), (7, 1), (1, 1)},
      highlightCandidates: {(4, 4, 2), (7, 1, 6), (1, 1, 4), (1, 1, 9)},
    ),
    GuideStep(
      caption: 'Branch 2: Assume it\'s 8 instead. In the same column, '
          'this cell loses 8 and becomes 4.',
      highlightCells: {(4, 4), (1, 4)},
      highlightCandidates: {(4, 4, 8), (1, 4, 4)},
    ),
    GuideStep(
      caption: '4 propagates along the row: this cell loses 4 '
          'and becomes 6.',
      highlightCells: {(4, 4), (1, 4), (1, 7)},
      highlightCandidates: {(4, 4, 8), (1, 4, 4), (1, 7, 6)},
    ),
    GuideStep(
      caption: 'With 6 in row 2, the same target cell loses 6 again - '
          'through a completely different path.',
      highlightCells: {(4, 4), (1, 7), (1, 1)},
      highlightCandidates: {(4, 4, 8), (1, 7, 6), (1, 1, 4), (1, 1, 9)},
    ),
    GuideStep(
      caption: 'Both branches eliminate 6 from the same cell. Eliminate 6.',
      highlightCells: {(4, 4)},
      eliminateCandidates: {(1, 1, 6)},
    ),
    GuideStep(
      caption: 'Forcing Chain: try each candidate, propagate using '
          'naked singles, and compare. If every branch agrees on '
          'the same result - it must be true. This goes beyond '
          'simpler chain techniques because each branch involves '
          'multiple steps of propagation.',
    ),
  ],
);
