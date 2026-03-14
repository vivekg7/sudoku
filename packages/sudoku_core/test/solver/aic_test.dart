import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  final strategy = AIC();

  group('Alternating Inference Chain', () {
    test('finds elimination via AIC', () {
      final board = Board.empty();

      // AIC chain:
      //   (6,0)[5] --strong(col 0, conjugate pair)--> (0,0)[5]
      //              ... but AIC impl starts from strong link nodes.
      //
      // Setup: col 0 has conjugate pair for 5: (0,0) and (6,0).
      // (6,0) is bi-value {5,2}: strong link within cell → (6,0)[5] ↔ (6,0)[2].
      // (6,4) is bi-value {2,5}: weak link for 2 in row 6 from (6,0)[2] → (6,4)[2].
      // Then (6,4) strong internal link → (6,4)[5].
      //
      // AIC endpoints: (6,0)[5] and (6,4)[5] — same candidate.
      // (6,8) has candidate 5, sees both via row 6 → eliminate 5.

      board.getCell(0, 0).setCandidates(CandidateSet.of([5, 1]));
      board.getCell(6, 0).setCandidates(CandidateSet.of([5, 2])); // bi-value
      board.getCell(6, 4).setCandidates(CandidateSet.of([2, 5])); // bi-value
      board.getCell(6, 8).setCandidates(CandidateSet.of([5, 9])); // target

      // Extra cells with 5 in row 6 to prevent conjugate pair for 5 in row 6.
      // Actually (6,0), (6,4), (6,8) already have 5 → 3 cells → no conjugate pair. ✓

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.alternatingInferenceChain);
      expect(step.eliminations, isNotEmpty);

      final hasElim = step.eliminations
          .any((e) => e.row == 6 && e.col == 8 && e.value == 5);
      expect(hasElim, isTrue);
    });

    test('returns null on empty board', () {
      final board = Board.empty();
      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
