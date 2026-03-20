import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  late Solver solver;

  setUp(() {
    solver = Solver();
  });

  group('Solver.solve', () {
    test('solves a singles-only puzzle', () {
      // A puzzle solvable with only naked and hidden singles.
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

      final result = solver.solve(board);

      expect(result.isSolved, isTrue);
      expect(result.steps, isNotEmpty);
      // Every step should be a naked or hidden single.
      for (final step in result.steps) {
        expect(
          step.strategy,
          isIn([StrategyType.nakedSingle, StrategyType.hiddenSingle]),
        );
      }
    });

    test('original board is not modified', () {
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
      final originalFlat = board.toFlatString();

      solver.solve(board);

      expect(board.toFlatString(), equals(originalFlat));
    });

    test('returns isSolved=false for an invalid/unsolvable puzzle', () {
      // Two 9s in the same row - unsolvable.
      final board = Board.fromString(
        '990000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000'
        '000000000',
      );

      final result = solver.solve(board);

      expect(result.isSolved, isFalse);
    });

    test('solves an already-solved board with zero steps', () {
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

      final result = solver.solve(board);

      expect(result.isSolved, isTrue);
      expect(result.steps, isEmpty);
      expect(result.difficulty, Difficulty.beginner);
    });

    test('solve path steps apply correctly to reach solved state', () {
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

      final result = solver.solve(board);

      // Verify by replaying steps on a fresh clone.
      final replay = board.clone();
      computeCandidates(replay);
      for (final step in result.steps) {
        for (final p in step.placements) {
          final cell = replay.getCell(p.row, p.col);
          cell.setValue(p.value);
          cell.setCandidates(CandidateSet.of([]));
          for (final peer in replay.peers(p.row, p.col)) {
            peer.removeCandidate(p.value);
          }
        }
        for (final e in step.eliminations) {
          replay.getCell(e.row, e.col).removeCandidate(e.value);
        }
      }
      expect(replay.isSolved, isTrue);
    });

    test('solves without backtracking when useBacktracking is false', () {
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

      final result = solver.solve(board, useBacktracking: false);

      expect(result.isSolved, isTrue);
      for (final step in result.steps) {
        expect(step.strategy, isNot(StrategyType.backtracking));
      }
    });
  });

  group('Solver.nextStep', () {
    test('returns the easiest applicable strategy', () {
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
      computeCandidates(board);

      final step = solver.nextStep(board);

      expect(step, isNotNull);
      // Should find a single (naked or hidden) first.
      expect(
        step!.strategy,
        isIn([StrategyType.nakedSingle, StrategyType.hiddenSingle]),
      );
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
      computeCandidates(board);

      expect(solver.nextStep(board), isNull);
    });
  });

  group('Solver.classifyPuzzle', () {
    test('hidden-singles-only with many givens is beginner', () {
      // Simulate: 10 hidden single steps, 40 givens.
      final steps = List.generate(
        10,
        (_) => SolveStep(strategy: StrategyType.hiddenSingle),
      );

      final difficulty = Solver.classifyPuzzle(
        steps: steps,
        givenCount: 40,
      );

      expect(difficulty, Difficulty.beginner);
    });

    test('naked singles with fewer givens can be easy', () {
      // Simulate: 40 naked single steps, 25 givens.
      // More steps + fewer givens pushes past beginner threshold.
      final steps = List.generate(
        40,
        (_) => SolveStep(strategy: StrategyType.nakedSingle),
      );

      final difficulty = Solver.classifyPuzzle(
        steps: steps,
        givenCount: 25,
      );

      expect(difficulty, Difficulty.easy);
    });

    test('empty steps is beginner', () {
      expect(
        Solver.classifyPuzzle(steps: [], givenCount: 81),
        Difficulty.beginner,
      );
    });

    test('advanced strategies push difficulty higher', () {
      final steps = [
        ...List.generate(
          20,
          (_) => SolveStep(strategy: StrategyType.hiddenSingle),
        ),
        SolveStep(strategy: StrategyType.xWing),
      ];

      final difficulty = Solver.classifyPuzzle(
        steps: steps,
        givenCount: 30,
      );

      // X-Wing (weight 16) should push this to at least medium.
      expect(difficulty.index, greaterThanOrEqualTo(Difficulty.medium.index));
    });

    test('many uses of hard strategy increases difficulty', () {
      final fewUses = [
        ...List.generate(
          30,
          (_) => SolveStep(strategy: StrategyType.hiddenSingle),
        ),
        SolveStep(strategy: StrategyType.nakedPair),
      ];

      final manyUses = [
        ...List.generate(
          20,
          (_) => SolveStep(strategy: StrategyType.hiddenSingle),
        ),
        ...List.generate(
          5,
          (_) => SolveStep(strategy: StrategyType.nakedPair),
        ),
      ];

      final fewDiff = Solver.classifyPuzzle(
        steps: fewUses,
        givenCount: 32,
      );
      final manyDiff = Solver.classifyPuzzle(
        steps: manyUses,
        givenCount: 32,
      );

      expect(manyDiff.index, greaterThanOrEqualTo(fewDiff.index));
    });

    test('fewer givens increases difficulty', () {
      final steps = List.generate(
        30,
        (_) => SolveStep(strategy: StrategyType.nakedSingle),
      );

      final manyGivens = Solver.classifyPuzzle(
        steps: steps,
        givenCount: 38,
      );
      final fewGivens = Solver.classifyPuzzle(
        steps: steps,
        givenCount: 22,
      );

      expect(fewGivens.index, greaterThanOrEqualTo(manyGivens.index));
    });

    test('forcing chain / ALS reaches master', () {
      final steps = [
        ...List.generate(
          30,
          (_) => SolveStep(strategy: StrategyType.hiddenSingle),
        ),
        ...List.generate(
          3,
          (_) => SolveStep(strategy: StrategyType.forcingChain),
        ),
      ];

      final difficulty = Solver.classifyPuzzle(
        steps: steps,
        givenCount: 22,
      );

      expect(difficulty, Difficulty.master);
    });
  });

  group('Solver.classifyDifficulty (per-strategy)', () {
    test('hidden/naked singles are beginner', () {
      expect(
        Solver.classifyDifficulty(StrategyType.hiddenSingle),
        Difficulty.beginner,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.nakedSingle),
        Difficulty.beginner,
      );
    });

    test('pairs and intersections are easy', () {
      expect(
        Solver.classifyDifficulty(StrategyType.nakedPair),
        Difficulty.easy,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.pointingPair),
        Difficulty.easy,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.boxLineReduction),
        Difficulty.easy,
      );
    });

    test('triples/quads and fish are medium', () {
      expect(
        Solver.classifyDifficulty(StrategyType.nakedTriple),
        Difficulty.medium,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.xWing),
        Difficulty.medium,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.swordfish),
        Difficulty.medium,
      );
    });

    test('wings and unique rectangles are hard', () {
      expect(
        Solver.classifyDifficulty(StrategyType.xyWing),
        Difficulty.hard,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.uniqueRectangleType1),
        Difficulty.hard,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.jellyfish),
        Difficulty.hard,
      );
    });

    test('coloring and chains are expert', () {
      expect(
        Solver.classifyDifficulty(StrategyType.simpleColoring),
        Difficulty.expert,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.xyChain),
        Difficulty.expert,
      );
    });

    test('forcing chain / ALS / backtracking are master', () {
      expect(
        Solver.classifyDifficulty(StrategyType.forcingChain),
        Difficulty.master,
      );
      expect(
        Solver.classifyDifficulty(StrategyType.backtracking),
        Difficulty.master,
      );
    });

    test('covers all strategy types', () {
      for (final type in StrategyType.values) {
        expect(
          () => Solver.classifyDifficulty(type),
          returnsNormally,
        );
      }
    });
  });

  group('SolveResult', () {
    test('hardestStrategy returns the most advanced strategy used', () {
      final result = SolveResult(
        steps: [
          SolveStep(strategy: StrategyType.nakedSingle),
          SolveStep(strategy: StrategyType.xWing),
          SolveStep(strategy: StrategyType.hiddenSingle),
        ],
        difficulty: Difficulty.medium,
        isSolved: true,
      );

      expect(result.hardestStrategy, StrategyType.xWing);
    });

    test('hardestStrategy returns null for empty steps', () {
      final result = SolveResult(
        steps: [],
        difficulty: Difficulty.beginner,
        isSolved: true,
      );

      expect(result.hardestStrategy, isNull);
    });
  });
}
