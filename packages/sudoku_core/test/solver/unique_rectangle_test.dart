import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('UniqueRectangle', () {
    final strategy = UniqueRectangle();

    // Valid UR needs exactly 2 boxes. Use rows 0,1 (same box band) with
    // cols 0,3: (0,0) box 0, (0,3) box 1, (1,0) box 0, (1,3) box 1.

    test('Type 1: eliminates UR candidates from non-bi-value roof', () {
      final board = Board.empty();

      // Floor: R1C1 {3,7}, R1C4 {3,7} — row 0, boxes 0 and 1.
      // Roof: R2C1 {3,7} (bi-value), R2C4 {3,7,9} (has extra).
      // Type 1: eliminate 3 and 7 from R2C4.
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(1, 0).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(1, 3).setCandidates(CandidateSet.of([3, 7, 9]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.uniqueRectangleType1);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect(e.row, 1);
        expect(e.col, 3);
        expect([3, 7], contains(e.value));
      }
    });

    test('Type 2: eliminates extra candidate from common peers', () {
      final board = Board.empty();

      // Floor: R1C1 {3,7}, R1C4 {3,7}.
      // Roof: R2C1 {3,7,5}, R2C4 {3,7,5} — both have extra candidate 5.
      // Eliminate 5 from cells seeing both roof cells.
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(1, 0).setCandidates(CandidateSet.of([3, 7, 5]));
      board.getCell(1, 3).setCandidates(CandidateSet.of([3, 7, 5]));

      // Cells in row 1 that see both roof cells and have candidate 5.
      board.getCell(1, 1).setCandidates(CandidateSet.of([5, 8]));
      board.getCell(1, 5).setCandidates(CandidateSet.of([5, 9]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.uniqueRectangleType2);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect(e.value, 5);
      }
    });

    test('Type 4: locked candidate eliminates other UR value from roof', () {
      final board = Board.empty();

      // Floor: R1C1 {3,7}, R1C4 {3,7}.
      // Roof: R2C1 {3,7,5}, R2C4 {3,7,8}.
      // If 3 only appears in the roof cells within row 1,
      // then 3 is locked and 7 can be eliminated from both roofs.
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(1, 0).setCandidates(CandidateSet.of([3, 7, 5]));
      board.getCell(1, 3).setCandidates(CandidateSet.of([3, 7, 8]));

      // No other cell in row 1 has candidate 3.
      // Avoid extras {5,8} forming a naked pair with any cell (prevents Type 3).
      board.getCell(1, 1).setCandidates(CandidateSet.of([4, 6]));
      board.getCell(1, 2).setCandidates(CandidateSet.of([6, 9]));
      board.getCell(1, 4).setCandidates(CandidateSet.of([4, 9]));
      board.getCell(1, 5).setCandidates(CandidateSet.of([2, 9]));
      board.getCell(1, 6).setCandidates(CandidateSet.of([2, 6]));
      board.getCell(1, 7).setCandidates(CandidateSet.of([4, 9]));
      board.getCell(1, 8).setCandidates(CandidateSet.of([2, 6]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.uniqueRectangleType4);
      expect(step.eliminations, isNotEmpty);

      // Should eliminate 7 from both roof cells.
      for (final e in step.eliminations) {
        expect(e.value, 7);
        expect(e.row, 1);
        expect([0, 3], contains(e.col));
      }
    });

    test('returns null when no UR pattern exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([3, 8])); // different candidates

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
