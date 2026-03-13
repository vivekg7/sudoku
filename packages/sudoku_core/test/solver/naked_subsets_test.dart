import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('NakedPair', () {
    final strategy = NakedSubset(2);

    test('finds naked pair and produces eliminations', () {
      // Construct a board where row 0 has a naked pair.
      // R1C1 and R1C2 both have candidates {3, 7}, and other cells in
      // row 0 also have 3 or 7 as candidates.
      final board = Board.empty();

      // Fill row 0 partially: place 1,2,4,5,6 leaving 3,7,8,9 open.
      board.getCell(0, 0).setValue(1);
      board.getCell(0, 3).setValue(2);
      board.getCell(0, 5).setValue(4);
      board.getCell(0, 6).setValue(5);
      board.getCell(0, 7).setValue(6);

      // Manually set candidates.
      board.getCell(0, 1).setCandidates({3, 7});
      board.getCell(0, 2).setCandidates({3, 7});
      board.getCell(0, 4).setCandidates({3, 7, 8});
      board.getCell(0, 8).setCandidates({3, 9});

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.nakedPair);
      expect(step.eliminations, isNotEmpty);

      // Eliminations should remove 3 or 7 from cells outside the pair.
      for (final e in step.eliminations) {
        expect(e.row, 0);
        expect([3, 7], contains(e.value));
        expect(e.col, isNot(1));
        expect(e.col, isNot(2));
      }
    });

    test('returns null when no naked pair exists', () {
      final board = Board.empty();
      // All empty cells with full candidates — no pair.
      for (var c = 0; c < 9; c++) {
        board.getCell(0, c).setCandidates({1, 2, 3, 4, 5, 6, 7, 8, 9});
      }

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });

  group('NakedTriple', () {
    final strategy = NakedSubset(3);

    test('finds naked triple', () {
      final board = Board.empty();

      // Place values to leave some cells open in row 0.
      board.getCell(0, 0).setValue(1);
      board.getCell(0, 1).setValue(2);
      board.getCell(0, 2).setValue(4);
      board.getCell(0, 3).setValue(5);
      board.getCell(0, 4).setValue(6);

      // Cells 5, 6, 7 form a naked triple {3, 7, 9}.
      board.getCell(0, 5).setCandidates({3, 7});
      board.getCell(0, 6).setCandidates({3, 9});
      board.getCell(0, 7).setCandidates({7, 9});
      // Cell 8 has overlap — should get eliminations.
      board.getCell(0, 8).setCandidates({3, 7, 8});

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.nakedTriple);
      expect(step.eliminations, isNotEmpty);
      // Should eliminate 3 and/or 7 from R1C9.
      expect(step.eliminations.every((e) => e.row == 0 && e.col == 8), true);
    });
  });

  group('NakedQuad', () {
    final strategy = NakedSubset(4);

    test('finds naked quad', () {
      final board = Board.empty();

      board.getCell(0, 0).setValue(5);

      // Cells 1–4 form a naked quad {1, 2, 3, 4}.
      board.getCell(0, 1).setCandidates({1, 2});
      board.getCell(0, 2).setCandidates({2, 3});
      board.getCell(0, 3).setCandidates({3, 4});
      board.getCell(0, 4).setCandidates({1, 4});
      // Cells 5–8 have overlap.
      board.getCell(0, 5).setCandidates({1, 6, 7});
      board.getCell(0, 6).setCandidates({2, 8});
      board.getCell(0, 7).setCandidates({3, 9});
      board.getCell(0, 8).setCandidates({4, 6});

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.nakedQuad);
      expect(step.eliminations, isNotEmpty);
    });
  });
}
