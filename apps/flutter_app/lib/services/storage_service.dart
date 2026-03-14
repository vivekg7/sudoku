import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sudoku_core/sudoku_core.dart';

/// Handles persistence of stats and saved puzzles to local JSON files.
class StorageService extends ChangeNotifier {
  late final String _dirPath;
  late StatsStore stats;
  late PuzzleStore puzzles;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _dirPath = dir.path;
    await _loadStats();
    await _loadPuzzles();
  }

  // -- Stats --

  Future<void> _loadStats() async {
    final file = File('$_dirPath/sudoku_stats.json');
    if (file.existsSync()) {
      try {
        final json = jsonDecode(await file.readAsString());
        stats = StatsStore.fromJson(json as Map<String, dynamic>);
      } catch (_) {
        stats = StatsStore();
      }
    } else {
      stats = StatsStore();
    }
  }

  Future<void> recordGame(GameStats gameStats) async {
    stats.record(gameStats);
    await _saveStats();
    notifyListeners();
  }

  Future<void> _saveStats() async {
    final file = File('$_dirPath/sudoku_stats.json');
    await file.writeAsString(jsonEncode(stats.toJson()));
  }

  // -- Puzzles --

  Future<void> _loadPuzzles() async {
    final file = File('$_dirPath/sudoku_puzzles.json');
    if (file.existsSync()) {
      try {
        final json = jsonDecode(await file.readAsString());
        puzzles = PuzzleStore.fromJson(json as Map<String, dynamic>);
      } catch (_) {
        puzzles = PuzzleStore();
      }
    } else {
      puzzles = PuzzleStore();
    }
  }

  Future<void> savePuzzle(PuzzleEntry entry) async {
    puzzles.save(entry);
    await _savePuzzles();
    notifyListeners();
  }

  Future<void> removePuzzle(String id) async {
    puzzles.remove(id);
    await _savePuzzles();
    notifyListeners();
  }

  Future<void> toggleBookmark(String id) async {
    puzzles.toggleBookmark(id);
    await _savePuzzles();
    notifyListeners();
  }

  Future<void> _savePuzzles() async {
    final file = File('$_dirPath/sudoku_puzzles.json');
    await file.writeAsString(jsonEncode(puzzles.toJson()));
  }

  // -- Export / Import --

  String exportData() {
    final export = DataExport(stats: stats, puzzles: puzzles);
    return export.toJsonString();
  }

  Future<void> importData(String jsonString) async {
    final export = DataExport.fromJsonString(jsonString);
    stats = export.stats;
    puzzles = export.puzzles;
    await _saveStats();
    await _savePuzzles();
    notifyListeners();
  }
}
