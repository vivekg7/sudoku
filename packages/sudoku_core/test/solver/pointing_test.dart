import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('Pointing', () {
    final strategy = Pointing();

    test('finds pointing pair in a row', () {
      // In box 0, candidate 5 only appears in row 0 (R1C1, R1C2).
      // Other cells in row 0 outside box 0 also have 5 → eliminate.
      final board = Board.empty();

      // Box 0: only R1C0 and R1C1 have candidate 5.
      board.getCell(0, 0).setCandidates({5, 6});
      board.getCell(0, 1).setCandidates({5, 7});
      board.getCell(0, 2).setCandidates({6, 7}); // no 5
      board.getCell(1, 0).setCandidates({6, 8}); // no 5
      board.getCell(1, 1).setCandidates({7, 8}); // no 5
      board.getCell(1, 2).setCandidates({6, 9}); // no 5
      board.getCell(2, 0).setCandidates({8, 9}); // no 5
      board.getCell(2, 1).setCandidates({6, 9}); // no 5
      board.getCell(2, 2).setCandidates({7, 9}); // no 5

      // Rest of row 0 outside box 0 — some have 5.
      board.getCell(0, 3).setCandidates({5, 8});
      board.getCell(0, 4).setCandidates({3, 9});
      board.getCell(0, 5).setCandidates({5, 9});
      board.getCell(0, 6).setCandidates({2, 3});
      board.getCell(0, 7).setCandidates({2, 8});
      board.getCell(0, 8).setCandidates({3, 8});

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(
        step!.strategy,
        anyOf(StrategyType.pointingPair, StrategyType.pointingTriple),
      );
      expect(step.eliminations, isNotEmpty);

      // All eliminations should be for value 5, in row 0, outside box 0.
      for (final e in step.eliminations) {
        expect(e.value, 5);
        expect(e.row, 0);
        expect(e.col, greaterThanOrEqualTo(3));
      }
    });

    test('finds pointing pair in a column', () {
      final board = Board.empty();

      // Box 0: candidate 3 only in column 0 (R1C0, R2C0).
      board.getCell(0, 0).setCandidates({3, 4});
      board.getCell(1, 0).setCandidates({3, 7});
      board.getCell(2, 0).setCandidates({4, 7}); // no 3
      board.getCell(0, 1).setCandidates({4, 8}); // no 3
      board.getCell(0, 2).setCandidates({7, 8}); // no 3
      board.getCell(1, 1).setCandidates({4, 9}); // no 3
      board.getCell(1, 2).setCandidates({7, 9}); // no 3
      board.getCell(2, 1).setCandidates({8, 9}); // no 3
      board.getCell(2, 2).setCandidates({4, 9}); // no 3

      // Rest of column 0 outside box 0.
      board.getCell(3, 0).setCandidates({3, 5});
      board.getCell(4, 0).setCandidates({5, 6});
      board.getCell(5, 0).setCandidates({3, 6});
      board.getCell(6, 0).setCandidates({5, 8});
      board.getCell(7, 0).setCandidates({6, 8});
      board.getCell(8, 0).setCandidates({5, 9});

      final step = strategy.apply(board);
      expect(step, isNotNull);

      for (final e in step!.eliminations) {
        expect(e.value, 3);
        expect(e.col, 0);
        expect(e.row, greaterThanOrEqualTo(3));
      }
    });

    test('returns null when no pointing pattern exists', () {
      final board = Board.empty();
      // Candidate 5 spread across multiple rows in box 0 — no pointing.
      board.getCell(0, 0).setCandidates({5, 6});
      board.getCell(1, 1).setCandidates({5, 7});
      board.getCell(2, 2).setCandidates({5, 8});

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
