import '../../models/difficulty.dart';
import '../../solver/strategy_type.dart';
import '../strategy_guide.dart';

List<Set<int>> _candidates(Map<int, Set<int>> sparse) {
  return List.generate(81, (i) => sparse[i] ?? const {});
}

// ---------------------------------------------------------------------------
// Sue de Coq
// ---------------------------------------------------------------------------
//
// Box-line intersection: box 0, row 0.
// (0,2)=7 is filled, so intersection has 2 empty cells: (0,0) and (0,1).
// Together they have candidates {3, 5, 6, 8} - 2 cells, 4 candidates (N+2).
//
// Partition of the 2 "extra" candidates:
//   lineOnly = {5}: appears in rest of row 0 but NOT rest of box 0.
//   boxOnly = {8}: appears in rest of box 0 but NOT rest of row 0.
//   shared = {3, 6}: appear in BOTH rest of row and rest of box.
//
// Eliminate: 5 from rest of row 0. 8 from rest of box 0.
// After: (0,0) must be 5 (only cell with 5 in intersection),
//        (0,1) must be 8 (only cell with 8). No contradiction.

final sueDeCoqGuide = StrategyGuide(
  strategy: StrategyType.sueDeCoq,
  difficulty: Difficulty.master,
  intro: 'A box-line intersection with extra candidates that split - '
      'some locked to the row, others to the box.',
  board: [
    [0, 0, 7, 0, 0, 0, 0, 0, 0], // (0,2)=7 -> intersection is 2 cells
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
    // Intersection cells: box 0 ∩ row 0 (cols 0-1, since (0,2)=7)
    0 * 9 + 0: {3, 5, 6},       // intersection - has lineOnly 5
    0 * 9 + 1: {3, 6, 8},       // intersection - has boxOnly 8
    // Rest of row 0: has 5 (lineOnly), 3, 6 (shared), NOT 8
    0 * 9 + 4: {2, 3, 5},       // has 5 - will be eliminated
    0 * 9 + 6: {4, 5, 6},       // has 5 - will be eliminated
    // Rest of box 0: has 8 (boxOnly), 3, 6 (shared), NOT 5
    1 * 9 + 0: {3, 8, 9},       // has 8 - will be eliminated
    2 * 9 + 1: {6, 8},          // has 8 - will be eliminated
  }),
  steps: [
    GuideStep(
      caption: 'Look at where box 1 meets row 1 - two empty cells '
          'in the intersection. Together they have four candidates: '
          '{3, 5, 6, 8}. Two cells, four candidates - two more '
          'than the cells can hold.',
      highlightCells: {(0, 0), (0, 1)},
      highlightCandidates: {
        (0, 0, 3), (0, 0, 5), (0, 0, 6),
        (0, 1, 3), (0, 1, 6), (0, 1, 8),
      },
    ),
    GuideStep(
      caption: 'Look at where each candidate appears outside the '
          'intersection. 5 appears in the rest of the row '
          'but NOT the rest of the box - it\'s "line-only."',
      highlightCells: {(0, 0), (0, 1), (0, 4), (0, 6)},
      highlightCandidates: {
        (0, 0, 5), (0, 4, 5), (0, 6, 5),
      },
    ),
    GuideStep(
      caption: '8 appears in the rest of the box but NOT the rest '
          'of the row - it\'s "box-only."',
      highlightCells: {(0, 0), (0, 1), (1, 0), (2, 1)},
      highlightCandidates: {
        (0, 1, 8), (1, 0, 8), (2, 1, 8),
      },
    ),
    GuideStep(
      caption: '3 and 6 appear in both - they\'re shared and can go '
          'anywhere. But the extras (5 and 8) split cleanly: '
          '5 belongs to the row, 8 belongs to the box. '
          "That's a Sue de Coq.",
      highlightCells: {(0, 0), (0, 1)},
      highlightCandidates: {
        (0, 0, 3), (0, 0, 5), (0, 0, 6),
        (0, 1, 3), (0, 1, 6), (0, 1, 8),
      },
    ),
    GuideStep(
      caption: 'Since the intersection must supply 5 to the row '
          '(no other source), eliminate 5 from the rest of the row.',
      highlightCells: {(0, 0), (0, 1)},
      eliminateCandidates: {(0, 4, 5), (0, 6, 5)},
    ),
    GuideStep(
      caption: 'And since it must supply 8 to the box, '
          'eliminate 8 from the rest of the box.',
      highlightCells: {(0, 0), (0, 1)},
      eliminateCandidates: {(1, 0, 8), (2, 1, 8)},
    ),
    GuideStep(
      caption: 'Sue de Coq: a box-line intersection with extra '
          'candidates that split - one locked to the row, '
          'one to the box. One of the rarest strategies.',
    ),
  ],
);
