import 'package:sudoku_core/sudoku_core.dart';
import 'package:test/test.dart';

void main() {
  group('StatsStore', () {
    late StatsStore store;

    GameStats _game({
      String id = 'g',
      Difficulty difficulty = Difficulty.beginner,
      int time = 100,
      bool completed = true,
      Map<HintLevel, int> hints = const {},
    }) =>
        GameStats(
          id: id,
          difficulty: difficulty,
          solveTimeSeconds: time,
          completed: completed,
          hintsByLevel: hints,
          playedAt: DateTime(2026),
        );

    setUp(() {
      store = StatsStore();
    });

    test('starts empty', () {
      expect(store.totalGames, 0);
      expect(store.completedGames, 0);
      expect(store.averageSolveTime, 0.0);
      expect(store.bestSolveTime, isNull);
    });

    test('records games and counts', () {
      store.record(_game(id: '1'));
      store.record(_game(id: '2', completed: false));

      expect(store.totalGames, 2);
      expect(store.completedGames, 1);
    });

    test('completion rate', () {
      store.record(_game(id: '1'));
      store.record(_game(id: '2', completed: false));
      store.record(_game(id: '3'));

      expect(store.completionRate, closeTo(2 / 3, 0.001));
    });

    test('average and best solve time', () {
      store.record(_game(id: '1', time: 200));
      store.record(_game(id: '2', time: 100));
      store.record(_game(id: '3', completed: false, time: 50));

      expect(store.averageSolveTime, 150.0);
      expect(store.bestSolveTime, 100);
    });

    test('current streak', () {
      store.record(_game(id: '1'));
      store.record(_game(id: '2', completed: false));
      store.record(_game(id: '3'));
      store.record(_game(id: '4'));

      expect(store.currentStreak, 2);
    });

    test('longest streak', () {
      store.record(_game(id: '1'));
      store.record(_game(id: '2'));
      store.record(_game(id: '3'));
      store.record(_game(id: '4', completed: false));
      store.record(_game(id: '5'));

      expect(store.longestStreak, 3);
    });

    test('games by difficulty', () {
      store.record(_game(id: '1', difficulty: Difficulty.easy));
      store.record(_game(id: '2', difficulty: Difficulty.easy));
      store.record(_game(id: '3', difficulty: Difficulty.hard));

      final byDiff = store.gamesByDifficulty;
      expect(byDiff[Difficulty.easy], 2);
      expect(byDiff[Difficulty.hard], 1);
    });

    test('average time by difficulty', () {
      store.record(
          _game(id: '1', difficulty: Difficulty.easy, time: 100));
      store.record(
          _game(id: '2', difficulty: Difficulty.easy, time: 200));

      expect(store.averageTimeByDifficulty[Difficulty.easy], 150.0);
    });

    test('total hints by level', () {
      store.record(_game(
        id: '1',
        hints: {HintLevel.nudge: 3, HintLevel.strategy: 1},
      ));
      store.record(_game(
        id: '2',
        hints: {HintLevel.nudge: 1, HintLevel.answer: 2},
      ));

      final byLevel = store.totalHintsByLevel;
      expect(byLevel[HintLevel.nudge], 4);
      expect(byLevel[HintLevel.strategy], 1);
      expect(byLevel[HintLevel.answer], 2);
    });

    test('no hint rate', () {
      store.record(_game(id: '1'));
      store.record(_game(
        id: '2',
        hints: {HintLevel.nudge: 1},
      ));
      store.record(_game(id: '3'));

      expect(store.noHintRate, closeTo(2 / 3, 0.001));
    });

    test('JSON round-trip preserves all games', () {
      store.record(_game(id: '1', time: 100));
      store.record(_game(id: '2', time: 200, completed: false));

      final json = store.toJson();
      final restored = StatsStore.fromJson(json);

      expect(restored.totalGames, 2);
      expect(restored.completedGames, 1);
      expect(restored.averageSolveTime, 100.0);
    });
  });
}
