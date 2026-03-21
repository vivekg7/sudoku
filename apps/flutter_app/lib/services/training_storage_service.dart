import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A single leaderboard entry for a training game run.
class TrainingScore {
  final int streak;
  final int totalTimeMs;
  final DateTime playedAt;

  const TrainingScore({
    required this.streak,
    required this.totalTimeMs,
    required this.playedAt,
  });

  double get avgTimePerAnswer =>
      streak > 0 ? totalTimeMs / (streak * 1000) : 0;

  Map<String, dynamic> toJson() => {
        'streak': streak,
        'totalTimeMs': totalTimeMs,
        'playedAt': playedAt.toIso8601String(),
      };

  factory TrainingScore.fromJson(Map<String, dynamic> json) => TrainingScore(
        streak: json['streak'] as int,
        totalTimeMs: json['totalTimeMs'] as int,
        playedAt: DateTime.parse(json['playedAt'] as String),
      );

  /// Compare for ranking: higher streak wins, then shorter time.
  static int compare(TrainingScore a, TrainingScore b) {
    final streakCmp = b.streak.compareTo(a.streak);
    if (streakCmp != 0) return streakCmp;
    return a.totalTimeMs.compareTo(b.totalTimeMs);
  }
}

/// Difficulty modes for Number Rush.
enum NumberRushMode {
  chill('Chill', 10000, 7000, 200, [HouseType.box]),
  quick('Quick', 8000, 5000, 200, [HouseType.box]),
  sprint('Sprint', 5000, 2000, 100, HouseType.values);

  final String label;
  final int startingTimeMs;
  final int minTimeMs;
  final int decayPerRoundMs;
  final List<HouseType> houseTypes;

  const NumberRushMode(this.label, this.startingTimeMs, this.minTimeMs,
      this.decayPerRoundMs, this.houseTypes);

  /// Time allowed for a given round (in ms).
  int timeForRound(int round) {
    final decayed = startingTimeMs - (round * decayPerRoundMs);
    return decayed < minTimeMs ? minTimeMs : decayed;
  }
}

/// Type of house shown in Number Rush.
enum HouseType { box, row, column }

/// Persists training game leaderboards to a local JSON file.
class TrainingStorageService extends ChangeNotifier {
  late final String _filePath;
  final Map<String, List<TrainingScore>> _leaderboards = {};

  static const _maxEntries = 10;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/sudoku_training.json';
    await _load();
  }

  /// Get leaderboard for a game+mode key. Returns unmodifiable list.
  List<TrainingScore> getLeaderboard(String key) =>
      List.unmodifiable(_leaderboards[key] ?? []);

  /// Get best score (top of leaderboard) or null.
  TrainingScore? getBest(String key) {
    final board = _leaderboards[key];
    return (board != null && board.isNotEmpty) ? board.first : null;
  }

  /// Add a score. Returns the 1-based rank if it made the board, or null.
  Future<int?> addScore(String key, TrainingScore score) async {
    final board = _leaderboards.putIfAbsent(key, () => []);
    board.add(score);
    board.sort(TrainingScore.compare);
    if (board.length > _maxEntries) {
      board.removeRange(_maxEntries, board.length);
    }
    final rank = board.indexOf(score);
    if (rank == -1) return null; // Didn't make the board.
    await _save();
    notifyListeners();
    return rank + 1;
  }

  /// Storage key for Number Rush leaderboard.
  static String numberRushKey(NumberRushMode mode) =>
      'numberRush_${mode.name}';

  Future<void> _load() async {
    final file = File(_filePath);
    if (!file.existsSync()) return;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      for (final entry in json.entries) {
        final list = (entry.value as List)
            .map((e) => TrainingScore.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort(TrainingScore.compare);
        _leaderboards[entry.key] = list;
      }
    } catch (_) {
      // Ignore corrupt data.
    }
  }

  Future<void> _save() async {
    final json = <String, dynamic>{};
    for (final entry in _leaderboards.entries) {
      json[entry.key] = entry.value.map((s) => s.toJson()).toList();
    }
    await File(_filePath).writeAsString(jsonEncode(json));
  }
}
