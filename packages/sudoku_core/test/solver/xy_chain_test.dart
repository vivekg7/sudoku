import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final strategy = XYChain();

  group('XY-Chain', () {
    test('finds elimination via 3-cell chain', () {
      final board = Board.empty();

      // Chain of bi-value cells: A{1,2} → B{2,3} → C{3,1}
      // A and C both have candidate 1 as "free" ends.
      // Cells seeing both A and C can eliminate 1.

      // A at (0,0): {1,2}
      board.getCell(0, 0).setCandidates(CandidateSet.of([1, 2]));
      // B at (0,3): {2,3} - peer of A (same row), shares candidate 2.
      board.getCell(0, 3).setCandidates(CandidateSet.of([2, 3]));
      // C at (3,3): {3,1} - peer of B (same col), shares candidate 3.
      board.getCell(3, 3).setCandidates(CandidateSet.of([1, 3]));

      // Target: (3,0) has candidate 1, sees A via col 0 and C via row 3.
      board.getCell(3, 0).setCandidates(CandidateSet.of([1, 5]));

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.xyChain);
      expect(step.eliminations, isNotEmpty);

      final hasElim = step.eliminations
          .any((e) => e.row == 3 && e.col == 0 && e.value == 1);
      expect(hasElim, isTrue);
    });

    test('returns null with fewer than 3 bi-value cells', () {
      final board = Board.empty();
      board.getCell(0, 0).setCandidates(CandidateSet.of([1, 2]));
      board.getCell(0, 3).setCandidates(CandidateSet.of([2, 3]));

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
