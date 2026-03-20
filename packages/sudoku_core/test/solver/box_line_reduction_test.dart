import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('BoxLineReduction', () {
    final strategy = BoxLineReduction();

    test('finds box/line reduction from a row', () {
      // In row 0, candidate 5 only appears in box 0 (cols 0-2).
      // Other cells in box 0 (rows 1,2) also have 5 → eliminate from them.
      final board = Board.empty();

      // Row 0: candidate 5 only in cols 0,1 (both in box 0).
      board.getCell(0, 0).setCandidates(CandidateSet.of([5, 6]));
      board.getCell(0, 1).setCandidates(CandidateSet.of([5, 7]));
      board.getCell(0, 2).setCandidates(CandidateSet.of([6, 7])); // no 5
      board.getCell(0, 3).setCandidates(CandidateSet.of([2, 3]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([3, 8]));
      board.getCell(0, 5).setCandidates(CandidateSet.of([2, 8]));
      board.getCell(0, 6).setCandidates(CandidateSet.of([2, 9]));
      board.getCell(0, 7).setCandidates(CandidateSet.of([3, 9]));
      board.getCell(0, 8).setCandidates(CandidateSet.of([8, 9]));

      // Other cells in box 0 have candidate 5 → should be eliminated.
      board.getCell(1, 0).setCandidates(CandidateSet.of([5, 8]));
      board.getCell(1, 1).setCandidates(CandidateSet.of([4, 8]));
      board.getCell(1, 2).setCandidates(CandidateSet.of([4, 9]));
      board.getCell(2, 0).setCandidates(CandidateSet.of([5, 9]));
      board.getCell(2, 1).setCandidates(CandidateSet.of([4, 6]));
      board.getCell(2, 2).setCandidates(CandidateSet.of([6, 9]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.boxLineReduction);
      expect(step.eliminations, isNotEmpty);

      // Eliminations should remove 5 from box 0 cells not in row 0.
      for (final e in step.eliminations) {
        expect(e.value, 5);
        expect(e.row, greaterThan(0));
        expect(e.col, lessThan(3));
      }
    });

    test('finds box/line reduction from a column', () {
      // Use a real puzzle position where a column-based box/line reduction
      // is the first pattern found. We fill ALL cells in box 0 rows with
      // candidates to prevent spurious row-based matches.
      //
      // Column 0: value 3 only in box 0 (rows 0,1).
      // Every row that passes through box 0 has value 3 spread across
      // multiple boxes, so no row-based match can fire for value 3.
      final board = Board.empty();

      // Column 0 candidates.
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 6]));
      board.getCell(1, 0).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(2, 0).setCandidates(CandidateSet.of([6, 7])); // no 3
      board.getCell(3, 0).setCandidates(CandidateSet.of([4, 5]));
      board.getCell(4, 0).setCandidates(CandidateSet.of([5, 8]));
      board.getCell(5, 0).setCandidates(CandidateSet.of([4, 8]));
      board.getCell(6, 0).setCandidates(CandidateSet.of([5, 9]));
      board.getCell(7, 0).setCandidates(CandidateSet.of([8, 9]));
      board.getCell(8, 0).setCandidates(CandidateSet.of([4, 9]));

      // Fill ALL empty cells in rows 0,1,2 with candidates.
      // Spread every value across multiple boxes in each row to prevent
      // any row-based box/line reduction.
      // Row 0: 3 in cols 0 (box 0) and 4 (box 1) - not confined to one box.
      board.getCell(0, 1).setCandidates(CandidateSet.of([4, 5]));
      board.getCell(0, 2).setCandidates(CandidateSet.of([4, 5]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([6, 9]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([3, 6])); // 3 in box 1 - breaks row confinement
      board.getCell(0, 5).setCandidates(CandidateSet.of([5, 9]));
      board.getCell(0, 6).setCandidates(CandidateSet.of([4, 9]));
      board.getCell(0, 7).setCandidates(CandidateSet.of([5, 6]));
      board.getCell(0, 8).setCandidates(CandidateSet.of([4, 9]));
      // Row 1: 3 in cols 0 (box 0) and 5 (box 1).
      board.getCell(1, 1).setCandidates(CandidateSet.of([3, 8])); // 3 here → will be eliminated
      board.getCell(1, 2).setCandidates(CandidateSet.of([4, 8]));
      board.getCell(1, 3).setCandidates(CandidateSet.of([5, 9]));
      board.getCell(1, 4).setCandidates(CandidateSet.of([6, 9]));
      board.getCell(1, 5).setCandidates(CandidateSet.of([3, 5])); // 3 in box 1 - breaks row confinement
      board.getCell(1, 6).setCandidates(CandidateSet.of([4, 6]));
      board.getCell(1, 7).setCandidates(CandidateSet.of([5, 8]));
      board.getCell(1, 8).setCandidates(CandidateSet.of([6, 9]));
      // Row 2: no 3 anywhere in col 0, so it's fine.
      board.getCell(2, 1).setCandidates(CandidateSet.of([3, 5])); // 3 here → will be eliminated
      board.getCell(2, 2).setCandidates(CandidateSet.of([4, 8]));
      board.getCell(2, 3).setCandidates(CandidateSet.of([3, 9])); // 3 in box 1 - breaks row confinement
      board.getCell(2, 4).setCandidates(CandidateSet.of([5, 6]));
      board.getCell(2, 5).setCandidates(CandidateSet.of([4, 9]));
      board.getCell(2, 6).setCandidates(CandidateSet.of([5, 8]));
      board.getCell(2, 7).setCandidates(CandidateSet.of([6, 9]));
      board.getCell(2, 8).setCandidates(CandidateSet.of([4, 7]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.boxLineReduction);
      expect(step.description, contains('column'));

      // Eliminations: value 3 from box 0 cells outside col 0.
      expect(step.eliminations, isNotEmpty);
      for (final e in step.eliminations) {
        expect(e.value, 3);
        expect(e.row, lessThan(3)); // in box 0
        expect(e.col, isNot(0));    // not in col 0
        expect(e.col, lessThan(3)); // but still in box 0
      }
    });

    test('returns null when no box/line reduction exists', () {
      final board = Board.empty();
      // Candidate spread across multiple boxes in row - no reduction.
      board.getCell(0, 0).setCandidates(CandidateSet.of([5, 6]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([5, 7]));
      board.getCell(0, 8).setCandidates(CandidateSet.of([5, 8]));

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
