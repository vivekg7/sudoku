import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('XY-Wing', () {
    final strategy = XYWing();

    test('finds XY-Wing and eliminates Z from common peers', () {
      final board = Board.empty();

      // Pivot at R1C1 (0,0) with {3, 5}.
      // Pincer 1 at R1C5 (0,4) with {3, 7} — shares row with pivot.
      // Pincer 2 at R4C1 (3,0) with {5, 7} — shares column with pivot.
      // Z = 7.
      // Common peer of both pincers: R4C5 (3,4) — shares row with pincer2
      // and column with pincer1.
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 5]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(3, 0).setCandidates(CandidateSet.of([5, 7]));
      board.getCell(3, 4).setCandidates(CandidateSet.of([7, 8, 9])); // should eliminate 7

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.xyWing);
      expect(step.eliminations, isNotEmpty);

      final elim = step.eliminations.where(
        (e) => e.row == 3 && e.col == 4 && e.value == 7,
      );
      expect(elim, isNotEmpty);
    });

    test('returns null when no XY-Wing exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 5]));
      board.getCell(0, 4).setCandidates(CandidateSet.of([3, 7]));
      // No matching second pincer.

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
