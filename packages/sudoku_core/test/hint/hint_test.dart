import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

/// Helper: extracts a [Hint] from a [HintResult], or returns null.
Hint? _extractHint(HintResult result) => switch (result) {
      HintFound(:final hint) => hint,
      HintNeedsCandidates(:final placementHint) => placementHint,
      HintNotAvailable() => null,
    };

/// Creates a board with candidates already filled so the hint generator
/// goes through the candidate-aware path.
Board _boardWithCandidates(String flat) {
  final board = Board.fromString(flat);
  computeCandidates(board);
  return board;
}

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

    test('returns HintNotAvailable for a solved board', () {
      final board = _boardWithCandidates(
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

      final result = hintGen.generateHint(board);
      expect(result, isA<HintNotAvailable>());
    });

    test('returns HintNeedsCandidates for board without candidates', () {
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

      final result = hintGen.generateHint(board);
      expect(result, isA<HintNeedsCandidates>());

      final hint = (result as HintNeedsCandidates).placementHint;
      expect(hint, isNotNull);
      expect(hint!.nudge, isNotEmpty);
    });

    test('generates a hint for board with candidates', () {
      final board = _boardWithCandidates(
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

      final result = hintGen.generateHint(board);
      final hint = _extractHint(result);

      expect(hint, isNotNull);
      expect(hint!.nudge, isNotEmpty);
      expect(hint.strategyHint, isNotEmpty);
      expect(hint.answer, isNotEmpty);
    });

    test('nudge layer mentions a region but not the exact cell', () {
      final board = _boardWithCandidates(
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

      final hint = _extractHint(hintGen.generateHint(board))!;

      expect(hint.nudge, contains('box'));
      expect(hint.nudge, isNot(contains('R')));
    });

    test('strategy layer mentions the strategy name', () {
      final board = _boardWithCandidates(
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

      final hint = _extractHint(hintGen.generateHint(board))!;
      expect(hint.strategyHint, contains(hint.step.strategy.label));
    });

    test('answer layer contains exact cell coordinates', () {
      final board = _boardWithCandidates(
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

      final hint = _extractHint(hintGen.generateHint(board))!;
      expect(hint.answer, matches(RegExp(r'R\dC\d')));
    });

    test('each layer reveals progressively more information', () {
      final board = _boardWithCandidates(
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

      final hint = _extractHint(hintGen.generateHint(board))!;

      expect(hint.nudge, isNot(equals(hint.strategyHint)));
      expect(hint.strategyHint, isNot(equals(hint.answer)));
      expect(hint.nudge, isNot(equals(hint.answer)));
    });

    test('hint fast-forwards past already-applied eliminations', () {
      final board = _boardWithCandidates(
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

      // Get the first hint.
      final result1 = hintGen.generateHint(board);
      final hint1 = _extractHint(result1)!;

      // Apply its effects to the board.
      final solver = Solver();
      solver.applyStep(board, hint1.step);

      // Request a second hint — should be different.
      final result2 = hintGen.generateHint(board);
      final hint2 = _extractHint(result2)!;

      // At least one of strategy or description should differ.
      final sameStrategy = hint2.step.strategy == hint1.step.strategy;
      final sameDescription = hint2.step.description == hint1.step.description;
      expect(sameStrategy && sameDescription, isFalse);
    });

    test('nudge for placement step mentions the digit', () {
      final board = _boardWithCandidates(
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

      final hint = _extractHint(hintGen.generateHint(board))!;

      if (hint.step.placements.isNotEmpty) {
        final digit = hint.step.placements.first.value.toString();
        expect(hint.nudge, contains(digit));
      }
    });

    test('answer for placement step says Place', () {
      final board = _boardWithCandidates(
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

      final hint = _extractHint(hintGen.generateHint(board))!;

      if (hint.step.placements.isNotEmpty) {
        expect(hint.answer, contains('Place'));
      }
    });
  });
}
