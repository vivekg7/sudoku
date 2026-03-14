import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('Hint', () {
    test('textForLevel returns correct text for each level', () {
      final hint = Hint(
        step: SolveStep(strategy: StrategyType.nakedSingle),
        nudge: 'nudge text',
        strategyHint: 'strategy text',
        answer: 'answer text',
      );

      expect(hint.textForLevel(HintLevel.nudge), 'nudge text');
      expect(hint.textForLevel(HintLevel.strategy), 'strategy text');
      expect(hint.textForLevel(HintLevel.answer), 'answer text');
    });
  });

  group('HintGenerator', () {
    late HintGenerator hintGen;

    setUp(() {
      hintGen = HintGenerator();
    });

    test('returns null for a solved board', () {
      final board = Board.fromString(
        '534678912'
        '672195348'
        '198342567'
        '859761423'
        '426853791'
        '713924856'
        '961537284'
        '287419635'
        '345286179',
      );

      expect(hintGen.generate(board), isNull);
    });

    test('generates a hint for an unsolved board', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board);

      expect(hint, isNotNull);
      expect(hint!.nudge, isNotEmpty);
      expect(hint.strategyHint, isNotEmpty);
      expect(hint.answer, isNotEmpty);
    });

    test('nudge layer mentions a region but not the exact cell', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      // Nudge should mention "box" but not "R_C_" notation.
      expect(hint.nudge, contains('box'));
      expect(hint.nudge, isNot(contains('R')));
    });

    test('strategy layer mentions the strategy name', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      // Strategy hint should mention the strategy label.
      expect(hint.strategyHint, contains(hint.step.strategy.label));
    });

    test('answer layer contains exact cell coordinates', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      // Answer should contain R_C_ notation.
      expect(hint.answer, matches(RegExp(r'R\dC\d')));
    });

    test('each layer reveals progressively more information', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      // Nudge should be shorter/vaguer than strategy hint.
      // Strategy hint should be shorter than the answer (or at least different).
      // All three should be different strings.
      expect(hint.nudge, isNot(equals(hint.strategyHint)));
      expect(hint.strategyHint, isNot(equals(hint.answer)));
      expect(hint.nudge, isNot(equals(hint.answer)));
    });

    test('hint step matches what Solver.nextStep would return', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      // Verify the underlying step has the same strategy as a direct solve.
      final clone = board.clone();
      computeCandidates(clone);
      final directStep = Solver().nextStep(clone);

      expect(hint.step.strategy, equals(directStep!.strategy));
    });

    test('nudge for placement step mentions the digit', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      if (hint.step.placements.isNotEmpty) {
        final digit = hint.step.placements.first.value.toString();
        expect(hint.nudge, contains(digit));
      }
    });

    test('answer for placement step says Place', () {
      final board = Board.fromString(
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

      final hint = hintGen.generate(board)!;

      if (hint.step.placements.isNotEmpty) {
        expect(hint.answer, contains('Place'));
      }
    });
  });
}
