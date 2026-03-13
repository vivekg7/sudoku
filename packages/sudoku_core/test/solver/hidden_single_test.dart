import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

import 'strategy_test_helper.dart';

void main() {
  group('HiddenSingle', () {
    final strategy = HiddenSingle();

    test('finds value that can only go in one cell in a row', () {
      // Standard puzzle where hidden singles exist.
      final board = boardWithCandidates(
        '530070000'
        '600195000'
        '098000060'
        '800060003'
        '400803001'
        '700020006'
        '060000280'
        '000419005'
        '000080079',
      );

      final step = strategy.apply(board);
      expect(step, isNotNull);
      expect(step!.strategy, StrategyType.hiddenSingle);
      expect(step.placements.length, 1);
      // Verify the placement is valid.
      final p = step.placements.first;
      expect(p.value, greaterThanOrEqualTo(1));
      expect(p.value, lessThanOrEqualTo(9));
    });

    test('returns null on empty board', () {
      final board = boardWithCandidates(
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000',
      );

      final step = strategy.apply(board);
      expect(step, isNull);
    });
  });
}
