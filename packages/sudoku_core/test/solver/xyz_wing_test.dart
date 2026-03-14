import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('XYZ-Wing', () {
    final strategy = XYZWing();

    test('finds XYZ-Wing and eliminates Z', () {
      final board = Board.empty();

      // Pivot at R1C1 (0,0) with {3, 5, 7}.
      // Pincer 1 at R1C2 (0,1) with {3, 7} — shares row and box with pivot.
      // Pincer 2 at R2C1 (1,0) with {5, 7} — shares column and box with pivot.
      // Z = 7 (common to pivot and both pincers).
      // A cell seeing all three: R2C2 (1,1) — same box.
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 5, 7]));
      board.getCell(0, 1).setCandidates(CandidateSet.of([3, 7]));
      board.getCell(1, 0).setCandidates(CandidateSet.of([5, 7]));
      board.getCell(1, 1).setCandidates(CandidateSet.of([7, 8, 9])); // should eliminate 7

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.xyzWing);
      expect(step.eliminations, isNotEmpty);

      final elim = step.eliminations.where(
        (e) => e.row == 1 && e.col == 1 && e.value == 7,
      );
      expect(elim, isNotEmpty);
    });

    test('returns null when no XYZ-Wing exists', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([3, 5, 7]));
      board.getCell(0, 1).setCandidates(CandidateSet.of([3, 8])); // not a valid pincer

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
