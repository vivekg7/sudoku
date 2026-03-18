import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  GameStats makeGame({
    String id = 'g',
    Difficulty difficulty = Difficulty.beginner,
    int time = 100,
    bool completed = true,
    Map<HintLevel, int> hints = const {},
    String assistLevel = 'full',
  }) =>
      GameStats(
        id: id,
        difficulty: difficulty,
        solveTimeSeconds: time,
        completed: completed,
        hintsByLevel: hints,
        playedAt: DateTime(2026),
        assistLevel: assistLevel,
      );

  group('StatsSlice', () {
    test('empty slice returns defaults', () {
      const slice = StatsSlice([]);
      expect(slice.totalGames, 0);
      expect(slice.completedGames, 0);
      expect(slice.completionRate, 0.0);
      expect(slice.averageSolveTime, 0.0);
      expect(slice.bestSolveTime, isNull);
      expect(slice.currentStreak, 0);
      expect(slice.longestStreak, 0);
      expect(slice.noHintRate, 0.0);
    });

    test('computes aggregates identically to StatsStore', () {
      final games = [
        makeGame(id: '1', time: 200),
        makeGame(id: '2', time: 100),
        makeGame(id: '3', completed: false, time: 50),
      ];
      final slice = StatsSlice(games);

      expect(slice.totalGames, 3);
      expect(slice.completedGames, 2);
      expect(slice.averageSolveTime, 150.0);
      expect(slice.bestSolveTime, 100);
      expect(slice.completionRate, closeTo(2 / 3, 0.001));
    });

    test('streaks computed correctly', () {
      final games = [
        makeGame(id: '1'),
        makeGame(id: '2'),
        makeGame(id: '3'),
        makeGame(id: '4', completed: false),
        makeGame(id: '5'),
      ];
      final slice = StatsSlice(games);

      expect(slice.currentStreak, 1);
      expect(slice.longestStreak, 3);
    });

    test('hints aggregated', () {
      final games = [
        makeGame(id: '1', hints: {HintLevel.nudge: 3, HintLevel.strategy: 1}),
        makeGame(id: '2', hints: {HintLevel.nudge: 1, HintLevel.answer: 2}),
      ];
      final slice = StatsSlice(games);
      final byLevel = slice.totalHintsByLevel;

      expect(byLevel[HintLevel.nudge], 4);
      expect(byLevel[HintLevel.strategy], 1);
      expect(byLevel[HintLevel.answer], 2);
    });

    test('no hint rate', () {
      final games = [
        makeGame(id: '1'),
        makeGame(id: '2', hints: {HintLevel.nudge: 1}),
        makeGame(id: '3'),
      ];
      final slice = StatsSlice(games);
      expect(slice.noHintRate, closeTo(2 / 3, 0.001));
    });
  });

  group('StatsStore filter methods', () {
    late StatsStore store;

    setUp(() {
      store = StatsStore();
      store.record(makeGame(
        id: '1',
        difficulty: Difficulty.easy,
        time: 300,
        assistLevel: 'none',
      ));
      store.record(makeGame(
        id: '2',
        difficulty: Difficulty.easy,
        time: 200,
        assistLevel: 'full',
      ));
      store.record(makeGame(
        id: '3',
        difficulty: Difficulty.hard,
        time: 500,
        assistLevel: 'none',
      ));
      store.record(makeGame(
        id: '4',
        difficulty: Difficulty.easy,
        time: 100,
        assistLevel: 'basic',
      ));
      store.record(makeGame(
        id: '5',
        difficulty: Difficulty.hard,
        completed: false,
        time: 50,
      ));
    });

    test('gamesForDifficulty filters correctly', () {
      final easy = store.gamesForDifficulty(Difficulty.easy);
      expect(easy.length, 3);
      expect(easy.every((g) => g.difficulty == Difficulty.easy), true);

      final hard = store.gamesForDifficulty(Difficulty.hard);
      expect(hard.length, 2);
    });

    test('topScores returns fastest completed games', () {
      final top = store.topScores();
      expect(top.length, 4); // 4 completed games
      expect(top.first.solveTimeSeconds, 100);
      expect(top.last.solveTimeSeconds, 500);
    });

    test('topScores filters by difficulty', () {
      final top = store.topScores(difficulty: Difficulty.easy);
      expect(top.length, 3);
      expect(top.every((g) => g.difficulty == Difficulty.easy), true);
      expect(top.first.solveTimeSeconds, 100);
    });

    test('topScores filters by assist level', () {
      final top = store.topScores(assistLevel: 'none');
      expect(top.length, 2);
      expect(top.every((g) => g.assistLevel == 'none'), true);
    });

    test('topScores filters by both difficulty and assist level', () {
      final top = store.topScores(
        difficulty: Difficulty.easy,
        assistLevel: 'none',
      );
      expect(top.length, 1);
      expect(top.first.id, '1');
    });

    test('topScores respects limit', () {
      final top = store.topScores(limit: 2);
      expect(top.length, 2);
    });
  });
}
