import '../hint/hint.dart';
import '../models/difficulty.dart';
import '../solver/strategy_type.dart';
import 'game_stats.dart';

/// Accumulates stats across games and computes aggregates.
class StatsStore {
  StatsStore();

  final List<GameStats> _games = [];

  /// All recorded game stats, newest first.
  List<GameStats> get games => List.unmodifiable(_games);

  /// Adds a completed game's stats.
  void record(GameStats stats) {
    _games.add(stats);
  }

  /// Total number of games played.
  int get totalGames => _games.length;

  /// Number of completed games.
  int get completedGames => _games.where((g) => g.completed).length;

  /// Completion rate as a fraction (0.0–1.0).
  double get completionRate =>
      _games.isEmpty ? 0.0 : completedGames / totalGames;

  /// Average solve time in seconds (completed games only).
  double get averageSolveTime {
    final completed = _games.where((g) => g.completed).toList();
    if (completed.isEmpty) return 0.0;
    final total =
        completed.fold<int>(0, (sum, g) => sum + g.solveTimeSeconds);
    return total / completed.length;
  }

  /// Best (shortest) solve time in seconds (completed games only).
  int? get bestSolveTime {
    final completed = _games.where((g) => g.completed).toList();
    if (completed.isEmpty) return null;
    return completed
        .map((g) => g.solveTimeSeconds)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Current streak of consecutive completed games (most recent first).
  int get currentStreak {
    var streak = 0;
    for (var i = _games.length - 1; i >= 0; i--) {
      if (_games[i].completed) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Longest streak of consecutive completed games ever.
  int get longestStreak {
    var longest = 0;
    var current = 0;
    for (final game in _games) {
      if (game.completed) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  /// Number of completed games per difficulty level.
  Map<Difficulty, int> get gamesByDifficulty {
    final counts = <Difficulty, int>{};
    for (final game in _games.where((g) => g.completed)) {
      counts[game.difficulty] = (counts[game.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  /// Average solve time per difficulty level (completed games only).
  Map<Difficulty, double> get averageTimeByDifficulty {
    final times = <Difficulty, List<int>>{};
    for (final game in _games.where((g) => g.completed)) {
      times.putIfAbsent(game.difficulty, () => []).add(game.solveTimeSeconds);
    }
    return {
      for (final e in times.entries)
        e.key: e.value.fold<int>(0, (s, t) => s + t) / e.value.length,
    };
  }

  /// Total hints taken across all games, broken down by level.
  Map<HintLevel, int> get totalHintsByLevel {
    final counts = <HintLevel, int>{};
    for (final game in _games) {
      for (final e in game.hintsByLevel.entries) {
        counts[e.key] = (counts[e.key] ?? 0) + e.value;
      }
    }
    return counts;
  }

  /// Total hints taken across all games, broken down by strategy.
  /// Shows which strategies the player needs help with most.
  Map<StrategyType, int> get totalHintsByStrategy {
    final counts = <StrategyType, int>{};
    for (final game in _games) {
      for (final e in game.hintsByStrategy.entries) {
        counts[e.key] = (counts[e.key] ?? 0) + e.value;
      }
    }
    return counts;
  }

  /// Percentage of games completed without any hints.
  double get noHintRate {
    final completed = _games.where((g) => g.completed).toList();
    if (completed.isEmpty) return 0.0;
    final noHint = completed.where((g) => !g.usedHints).length;
    return noHint / completed.length;
  }

  Map<String, dynamic> toJson() => {
        'games': _games.map((g) => g.toJson()).toList(),
      };

  factory StatsStore.fromJson(Map<String, dynamic> json) {
    final store = StatsStore();
    final games = json['games'] as List<dynamic>;
    for (final g in games) {
      store.record(GameStats.fromJson(g as Map<String, dynamic>));
    }
    return store;
  }
}
