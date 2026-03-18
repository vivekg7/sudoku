import '../hint/hint.dart';
import '../models/difficulty.dart';
import '../solver/strategy_type.dart';
import 'game_stats.dart';

/// Pure aggregate computation over any subset of [GameStats].
///
/// This allows computing identical metrics for a filtered list
/// (e.g. a single difficulty) without duplicating logic.
class StatsSlice {
  final List<GameStats> games;

  const StatsSlice(this.games);

  int get totalGames => games.length;

  int get completedGames => games.where((g) => g.completed).length;

  double get completionRate =>
      games.isEmpty ? 0.0 : completedGames / totalGames;

  double get averageSolveTime {
    final completed = games.where((g) => g.completed).toList();
    if (completed.isEmpty) return 0.0;
    final total =
        completed.fold<int>(0, (sum, g) => sum + g.solveTimeSeconds);
    return total / completed.length;
  }

  int? get bestSolveTime {
    final completed = games.where((g) => g.completed).toList();
    if (completed.isEmpty) return null;
    return completed
        .map((g) => g.solveTimeSeconds)
        .reduce((a, b) => a < b ? a : b);
  }

  int get currentStreak {
    var streak = 0;
    for (var i = games.length - 1; i >= 0; i--) {
      if (games[i].completed) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    var longest = 0;
    var current = 0;
    for (final game in games) {
      if (game.completed) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  Map<Difficulty, int> get gamesByDifficulty {
    final counts = <Difficulty, int>{};
    for (final game in games.where((g) => g.completed)) {
      counts[game.difficulty] = (counts[game.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  Map<Difficulty, double> get averageTimeByDifficulty {
    final times = <Difficulty, List<int>>{};
    for (final game in games.where((g) => g.completed)) {
      times.putIfAbsent(game.difficulty, () => []).add(game.solveTimeSeconds);
    }
    return {
      for (final e in times.entries)
        e.key: e.value.fold<int>(0, (s, t) => s + t) / e.value.length,
    };
  }

  Map<HintLevel, int> get totalHintsByLevel {
    final counts = <HintLevel, int>{};
    for (final game in games) {
      for (final e in game.hintsByLevel.entries) {
        counts[e.key] = (counts[e.key] ?? 0) + e.value;
      }
    }
    return counts;
  }

  Map<StrategyType, int> get totalHintsByStrategy {
    final counts = <StrategyType, int>{};
    for (final game in games) {
      for (final e in game.hintsByStrategy.entries) {
        counts[e.key] = (counts[e.key] ?? 0) + e.value;
      }
    }
    return counts;
  }

  /// Total mistakes across all games.
  int get totalMistakes =>
      games.fold<int>(0, (sum, g) => sum + g.mistakeCount);

  /// Average mistakes per completed game.
  double get averageMistakes {
    final completed = games.where((g) => g.completed).toList();
    if (completed.isEmpty) return 0.0;
    final total = completed.fold<int>(0, (sum, g) => sum + g.mistakeCount);
    return total / completed.length;
  }

  double get noHintRate {
    final completed = games.where((g) => g.completed).toList();
    if (completed.isEmpty) return 0.0;
    final noHint = completed.where((g) => !g.usedHints).length;
    return noHint / completed.length;
  }
}
