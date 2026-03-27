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

/// Difficulty modes for Where Does N Go.
enum WhereDoesNGoMode {
  chill('Chill', 15000, 10000, 300, true),
  quick('Quick', 12000, 7000, 200, false),
  sprint('Sprint', 10000, 5000, 200, false);

  final String label;
  final int startingTimeMs;
  final int minTimeMs;
  final int decayPerRoundMs;

  /// Whether to highlight the target house on the board.
  final bool highlightHouse;

  const WhereDoesNGoMode(this.label, this.startingTimeMs, this.minTimeMs,
      this.decayPerRoundMs, this.highlightHouse);

  /// Time allowed for a given round (in ms).
  int timeForRound(int round) {
    final decayed = startingTimeMs - (round * decayPerRoundMs);
    return decayed < minTimeMs ? minTimeMs : decayed;
  }
}

/// Difficulty modes for Candidate Fill.
enum CandidateFillMode {
  chill('Chill', 45000, 30000, 1000, [HouseType.box], 3, 4),
  quick('Quick', 35000, 20000, 800, HouseType.values, 4, 5),
  sprint('Sprint', 25000, 15000, 500, HouseType.values, 5, 6);

  final String label;
  final int startingTimeMs;
  final int minTimeMs;
  final int decayPerRoundMs;
  final List<HouseType> houseTypes;
  final int minEmptyCells;
  final int maxEmptyCells;

  const CandidateFillMode(this.label, this.startingTimeMs, this.minTimeMs,
      this.decayPerRoundMs, this.houseTypes, this.minEmptyCells, this.maxEmptyCells);

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
  String? _lastPlayedKey;

  /// The full game+mode key of the most recently played training game.
  String? get lastPlayedKey => _lastPlayedKey;

  /// The most recently played Number Rush mode, or `null` if none.
  NumberRushMode? get lastPlayedMode {
    final key = _lastPlayedKey;
    if (key == null || !key.startsWith('numberRush_')) return null;
    final modeName = key.substring('numberRush_'.length);
    return NumberRushMode.values
        .cast<NumberRushMode?>()
        .firstWhere((m) => m?.name == modeName, orElse: () => null);
  }

  /// The most recently played Where Does N Go mode, or `null` if none.
  WhereDoesNGoMode? get lastPlayedWhereDoesNGoMode {
    final key = _lastPlayedKey;
    if (key == null || !key.startsWith('whereDoesNGo_')) return null;
    final modeName = key.substring('whereDoesNGo_'.length);
    return WhereDoesNGoMode.values
        .cast<WhereDoesNGoMode?>()
        .firstWhere((m) => m?.name == modeName, orElse: () => null);
  }

  /// The most recently played Candidate Fill mode, or `null` if none.
  CandidateFillMode? get lastPlayedCandidateFillMode {
    final key = _lastPlayedKey;
    if (key == null || !key.startsWith('candidateFill_')) return null;
    final modeName = key.substring('candidateFill_'.length);
    return CandidateFillMode.values
        .cast<CandidateFillMode?>()
        .firstWhere((m) => m?.name == modeName, orElse: () => null);
  }

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

  /// Set the last played game+mode key (in memory only).
  /// Call [save] afterwards or rely on [addScore] to persist it.
  void setLastPlayedKey(String key) {
    _lastPlayedKey = key;
  }

  /// Convenience: set last played to a Number Rush mode.
  void setLastPlayedMode(NumberRushMode mode) {
    _lastPlayedKey = numberRushKey(mode);
  }

  /// Persist current state to disk and notify listeners.
  Future<void> save() async {
    await _save();
    notifyListeners();
  }

  /// Add a score. Returns the 1-based rank if it made the board, or null.
  /// Always persists (including any pending [setLastPlayedMode] change).
  Future<int?> addScore(String key, TrainingScore score) async {
    final board = _leaderboards.putIfAbsent(key, () => []);
    board.add(score);
    board.sort(TrainingScore.compare);
    if (board.length > _maxEntries) {
      board.removeRange(_maxEntries, board.length);
    }
    final rank = board.indexOf(score);
    await _save();
    notifyListeners();
    return rank == -1 ? null : rank + 1;
  }

  /// Storage key for Number Rush leaderboard.
  static String numberRushKey(NumberRushMode mode) =>
      'numberRush_${mode.name}';

  /// Storage key for Where Does N Go leaderboard.
  static String whereDoesNGoKey(WhereDoesNGoMode mode) =>
      'whereDoesNGo_${mode.name}';

  /// Storage key for Candidate Fill leaderboard.
  static String candidateFillKey(CandidateFillMode mode) =>
      'candidateFill_${mode.name}';

  Future<void> _load() async {
    final file = File(_filePath);
    if (!file.existsSync()) return;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      // Restore last played key.
      final lastKey = json['_lastPlayedKey'] as String?;
      if (lastKey != null) {
        _lastPlayedKey = lastKey;
      } else {
        // Migrate from old _lastPlayedMode format.
        final modeName = json['_lastPlayedMode'] as String?;
        if (modeName != null) {
          final mode = NumberRushMode.values
              .cast<NumberRushMode?>()
              .firstWhere((m) => m?.name == modeName, orElse: () => null);
          if (mode != null) _lastPlayedKey = numberRushKey(mode);
        }
      }
      for (final entry in json.entries) {
        if (entry.key.startsWith('_')) continue; // Skip metadata keys.
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
    if (_lastPlayedKey != null) {
      json['_lastPlayedKey'] = _lastPlayedKey;
    }
    for (final entry in _leaderboards.entries) {
      json[entry.key] = entry.value.map((s) => s.toJson()).toList();
    }
    await File(_filePath).writeAsString(jsonEncode(json));
  }
}
