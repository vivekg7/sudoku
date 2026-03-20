import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('X-Wing', () {
    final strategy = Fish(2);

    test('finds row-based X-Wing', () {
      final board = Board.empty();

      // Value 5 appears in exactly columns 1 and 4 in rows 0 and 3.
      // This forms an X-Wing → eliminate 5 from cols 1 and 4 in other rows.

      // Row 0: 5 at cols 1 and 4 only.
      board.getCell(0, 1).setCandidates(CandidateSet.of([5, 6]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([5, 7]));
      // Row 3: 5 at cols 1 and 4 only.
      board.getCell(3, 1).setCandidates(CandidateSet.of([5, 8]));
      board.getCell(3, 4).setCandidates(CandidateSet.of([5, 9]));

      // Other rows with 5 in cols 1 or 4 → should be eliminated.
      board.getCell(1, 1).setCandidates(CandidateSet.of([5, 3]));
      board.getCell(6, 4).setCandidates(CandidateSet.of([5, 2]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.xWing);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect(e.value, 5);
        expect([1, 4], contains(e.col));
        expect(e.row, isNot(0));
        expect(e.row, isNot(3));
      }
    });

    test('finds column-based X-Wing', () {
      final board = Board.empty();

      // Value 3 in exactly rows 2 and 7 in columns 0 and 5.
      board.getCell(2, 0).setCandidates(CandidateSet.of([3, 4]));
      board.getCell(7, 0).setCandidates(CandidateSet.of([3, 6]));
      board.getCell(2, 5).setCandidates(CandidateSet.of([3, 8]));
      board.getCell(7, 5).setCandidates(CandidateSet.of([3, 9]));

      // Other columns with 3 in rows 2 or 7.
      board.getCell(2, 3).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(7, 8).setCandidates(CandidateSet.of([3, 1]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.xWing);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect(e.value, 3);
        expect([2, 7], contains(e.row));
        expect(e.col, isNot(0));
        expect(e.col, isNot(5));
      }
    });

    test('returns null when no X-Wing exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([5, 6]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([5, 7]));
      board.getCell(3, 1).setCandidates(CandidateSet.of([5, 8])); // different column pattern

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });

  group('Swordfish', () {
    final strategy = Fish(3);

    test('finds row-based Swordfish', () {
      final board = Board.empty();

      // Value 7 in rows 0, 3, 6 - each has 7 in at most 3 columns from {1, 4, 7}.
      board.getCell(0, 1).setCandidates(CandidateSet.of([7, 2]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([7, 3]));
      board.getCell(3, 4).setCandidates(CandidateSet.of([7, 5]));
      board.getCell(3, 7).setCandidates(CandidateSet.of([7, 6]));
      board.getCell(6, 1).setCandidates(CandidateSet.of([7, 8]));
      board.getCell(6, 7).setCandidates(CandidateSet.of([7, 9]));

      // Other rows with 7 in those columns.
      board.getCell(2, 1).setCandidates(CandidateSet.of([7, 4]));
      board.getCell(5, 4).setCandidates(CandidateSet.of([7, 8]));
      board.getCell(8, 7).setCandidates(CandidateSet.of([7, 1]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.swordfish);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect(e.value, 7);
        expect([1, 4, 7], contains(e.col));
        expect(e.row, isNot(0));
        expect(e.row, isNot(3));
        expect(e.row, isNot(6));
      }
    });
  });

  group('Jellyfish', () {
    final strategy = Fish(4);

    test('finds row-based Jellyfish', () {
      final board = Board.empty();

      // Value 2 in rows 0,2,5,8 confined to columns {0,3,5,7}.
      board.getCell(0, 0).setCandidates(CandidateSet.of([2, 4]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([2, 6]));
      board.getCell(2, 3).setCandidates(CandidateSet.of([2, 8]));
      board.getCell(2, 5).setCandidates(CandidateSet.of([2, 9]));
      board.getCell(5, 5).setCandidates(CandidateSet.of([2, 1]));
      board.getCell(5, 7).setCandidates(CandidateSet.of([2, 3]));
      board.getCell(8, 0).setCandidates(CandidateSet.of([2, 7]));
      board.getCell(8, 7).setCandidates(CandidateSet.of([2, 5]));

      // Elimination targets.
      board.getCell(1, 0).setCandidates(CandidateSet.of([2, 6]));
      board.getCell(4, 5).setCandidates(CandidateSet.of([2, 8]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.jellyfish);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect(e.value, 2);
        expect([0, 3, 5, 7], contains(e.col));
      }
    });
  });
}
