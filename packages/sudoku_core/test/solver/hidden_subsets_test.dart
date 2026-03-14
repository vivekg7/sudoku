import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('HiddenPair', () {
    final strategy = HiddenSubset(2);

    test('finds hidden pair and eliminates extra candidates', () {
      final board = Board.empty();

      // In row 0: values 1 and 2 only appear in cells 3 and 4,
      // but those cells also have other candidates.
      board.getCell(0, 0).setValue(3);
      board.getCell(0, 1).setValue(4);
      board.getCell(0, 2).setValue(5);

      board.getCell(0, 3).setCandidates(CandidateSet.of([1, 2, 6]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([1, 2, 7]));
      board.getCell(0, 5).setCandidates(CandidateSet.of([6, 7, 8]));
      board.getCell(0, 6).setCandidates(CandidateSet.of([6, 8, 9]));
      board.getCell(0, 7).setCandidates(CandidateSet.of([7, 8, 9]));
      board.getCell(0, 8).setCandidates(CandidateSet.of([6, 9]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.hiddenPair);
      expect(step.eliminations, isNotEmpty);

      // Should eliminate 6 from R1C4 and 7 from R1C5.
      final elimValues = step.eliminations.map((e) => e.value).toSet();
      expect(elimValues, isNot(contains(1)));
      expect(elimValues, isNot(contains(2)));
    });

    test('returns null when no hidden pair exists', () {
      final board = Board.empty();
      for (var c = 0; c < 9; c++) {
        board.getCell(0, c).setCandidates(CandidateSet.of([1, 2, 3, 4, 5, 6, 7, 8, 9]));
      }

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });

  group('HiddenTriple', () {
    final strategy = HiddenSubset(3);

    test('finds hidden triple', () {
      final board = Board.empty();

      board.getCell(0, 0).setValue(9);

      // Values 1, 2, 3 only appear in cells 1, 2, 3.
      board.getCell(0, 1).setCandidates(CandidateSet.of([1, 2, 5, 6]));
      board.getCell(0, 2).setCandidates(CandidateSet.of([2, 3, 7]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([1, 3, 8]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([4, 5, 6]));
      board.getCell(0, 5).setCandidates(CandidateSet.of([5, 7, 8]));
      board.getCell(0, 6).setCandidates(CandidateSet.of([4, 6]));
      board.getCell(0, 7).setCandidates(CandidateSet.of([4, 7, 8]));
      board.getCell(0, 8).setCandidates(CandidateSet.of([5, 6, 8]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.hiddenTriple);
      expect(step.eliminations, isNotEmpty);

      // Should only eliminate non-{1,2,3} from cells 1,2,3.
      for (final e in step.eliminations) {
        expect([1, 2, 3], isNot(contains(e.value)));
      }
    });
  });

  group('HiddenQuad', () {
    final strategy = HiddenSubset(4);

    test('finds hidden quad', () {
      final board = Board.empty();

      // Values 1,2,3,4 only appear in cells 0,1,2,3 but those cells
      // also have other candidates.
      board.getCell(0, 0).setCandidates(CandidateSet.of([1, 2, 5]));
      board.getCell(0, 1).setCandidates(CandidateSet.of([2, 3, 6]));
      board.getCell(0, 2).setCandidates(CandidateSet.of([3, 4, 7]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([1, 4, 8]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([5, 6, 7]));
      board.getCell(0, 5).setCandidates(CandidateSet.of([6, 7, 8]));
      board.getCell(0, 6).setCandidates(CandidateSet.of([5, 8, 9]));
      board.getCell(0, 7).setCandidates(CandidateSet.of([7, 8, 9]));
      board.getCell(0, 8).setCandidates(CandidateSet.of([5, 6, 9]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.hiddenQuad);
      expect(step.eliminations, isNotEmpty);

      for (final e in step.eliminations) {
        expect([1, 2, 3, 4], isNot(contains(e.value)));
      }
    });
  });
}
