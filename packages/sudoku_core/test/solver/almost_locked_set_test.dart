import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final strategy = AlmostLockedSet();

  group('Almost Locked Set (ALS-XZ)', () {
    test('finds ALS-XZ elimination', () {
      final board = Board.empty();

      // ALS A: 1 cell with 2 candidates = ALS of size 1 (N=1, N+1=2 candidates).
      // ALS B: 1 cell with 2 candidates.
      // They must not overlap, share restricted common X, and common Z.

      // ALS A at (0,0): {1,2} — in row 0.
      board.getCell(0, 0).setCandidates({1, 2});

      // ALS B at (0,8): {1,3} — in row 0.
      board.getCell(0, 8).setCandidates({1, 3});

      // Common candidates: {1}. Need at least 2 common candidates for X and Z.
      // Let me use bigger ALS.

      // ALS A: cells (0,0) and (0,1) with candidates {1,2,3} — 2 cells, 3 candidates.
      board.getCell(0, 0).setCandidates({1, 2});
      board.getCell(0, 1).setCandidates({2, 3});

      // ALS B: cell (2,0) with candidates {1,3} — 1 cell, 2 candidates.
      // In same column as (0,0).
      board.getCell(2, 0).setCandidates({1, 3});

      // A candidates: {1,2,3}, B candidates: {1,3}. Common: {1,3}.
      // X (restricted common): say X=1.
      //   A cells with 1: (0,0). B cells with 1: (2,0).
      //   (0,0) and (2,0) are peers (same col) → restricted. ✓
      // Z=3: A cells with 3: (0,1). B cells with 3: (2,0).
      //   Eliminate 3 from cells seeing all Z-cells in both A and B.
      //   A Z-cell: (0,1). B Z-cell: (2,0).
      //   Need a cell with candidate 3 that sees both (0,1) and (2,0).

      // (2,1) sees (0,1) via col 1 and (2,0) via row 2. Also in same box 0.
      board.getCell(2, 1).setCandidates({3, 7});

      // Both ALS found in row 0 / col 0 houses.
      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.almostLockedSet);
      expect(step.eliminations, isNotEmpty);

      final hasElim = step.eliminations
          .any((e) => e.row == 2 && e.col == 1 && e.value == 3);
      expect(hasElim, isTrue);
    });

    test('returns null when no ALS pattern exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates({1, 2, 3, 4, 5});

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
