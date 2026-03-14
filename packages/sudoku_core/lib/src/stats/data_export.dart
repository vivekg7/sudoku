import 'dart:convert';

import 'puzzle_store.dart';
import 'stats_store.dart';

/// Combines all user data into a single exportable/importable format.
class DataExport {
  final StatsStore stats;
  final PuzzleStore puzzles;

  const DataExport({required this.stats, required this.puzzles});

  /// Serialises all data to a JSON string.
  String toJsonString() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'stats': stats.toJson(),
      'puzzles': puzzles.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Deserialises all data from a JSON string.
  factory DataExport.fromJsonString(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return DataExport(
      stats: StatsStore.fromJson(data['stats'] as Map<String, dynamic>),
      puzzles: PuzzleStore.fromJson(data['puzzles'] as Map<String, dynamic>),
    );
  }
}
