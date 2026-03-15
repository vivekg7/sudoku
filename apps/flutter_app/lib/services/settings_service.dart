import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Preset accent colors for the app theme.
enum AppColor {
  blue(Color(0xFF1565C0), 'Blue'),
  teal(Color(0xFF00695C), 'Teal'),
  green(Color(0xFF2E7D32), 'Green'),
  purple(Color(0xFF6A1B9A), 'Purple'),
  orange(Color(0xFFE65100), 'Orange'),
  red(Color(0xFFC62828), 'Red');

  final Color seed;
  final String label;
  const AppColor(this.seed, this.label);
}

/// Maximum hint depth available to the player.
enum HintLimit {
  /// Hints are completely disabled.
  disabled(0, 'Disabled', 'No hints available'),

  /// Only nudge hints (e.g. "Look for 3 in box 4").
  nudgeOnly(1, 'Nudge only', 'Direction nudge'),

  /// Nudge + strategy hints (e.g. "Try X-Wing on rows 2 and 7").
  upToStrategy(2, 'Up to strategy', 'Nudge + strategy name'),

  /// All three layers: nudge, strategy, and exact answer.
  all(3, 'All hints', 'Nudge + strategy + answer');

  /// Maximum hint layer (1 = nudge, 2 = strategy, 3 = answer, 0 = none).
  final int maxLayer;
  final String label;
  final String description;
  const HintLimit(this.maxLayer, this.label, this.description);
}

/// Persists user preferences to a local JSON file.
class SettingsService extends ChangeNotifier {
  late final String _filePath;

  ThemeMode _themeMode = ThemeMode.system;
  AppColor _appColor = AppColor.blue;
  bool _quotesEnabled = true;
  HintLimit _hintLimit = HintLimit.all;
  bool _showTimer = true;
  bool _notesEnabled = true;

  ThemeMode get themeMode => _themeMode;
  AppColor get appColor => _appColor;
  bool get quotesEnabled => _quotesEnabled;
  HintLimit get hintLimit => _hintLimit;
  bool get showTimer => _showTimer;
  bool get notesEnabled => _notesEnabled;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/sudoku_settings.json';
    await _load();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _save();
  }

  void setAppColor(AppColor color) {
    if (_appColor == color) return;
    _appColor = color;
    notifyListeners();
    _save();
  }

  void setQuotesEnabled(bool enabled) {
    if (_quotesEnabled == enabled) return;
    _quotesEnabled = enabled;
    notifyListeners();
    _save();
  }

  void setHintLimit(HintLimit limit) {
    if (_hintLimit == limit) return;
    _hintLimit = limit;
    notifyListeners();
    _save();
  }

  void setNotesEnabled(bool enabled) {
    if (_notesEnabled == enabled) return;
    _notesEnabled = enabled;
    notifyListeners();
    _save();
  }

  void setShowTimer(bool show) {
    if (_showTimer == show) return;
    _showTimer = show;
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final file = File(_filePath);
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      );
      _appColor = AppColor.values.firstWhere(
        (c) => c.name == json['appColor'],
        orElse: () => AppColor.blue,
      );
      _quotesEnabled = json['quotesEnabled'] as bool? ?? true;
      _showTimer = json['showTimer'] as bool? ?? true;
      _notesEnabled = json['notesEnabled'] as bool? ?? true;
      _hintLimit = HintLimit.values.firstWhere(
        (h) => h.name == json['hintLimit'],
        orElse: () => HintLimit.all,
      );
    } catch (_) {
      // Ignore corrupt settings — defaults are fine.
    }
  }

  Future<void> _save() async {
    final json = {
      'themeMode': _themeMode.name,
      'appColor': _appColor.name,
      'quotesEnabled': _quotesEnabled,
      'showTimer': _showTimer,
      'notesEnabled': _notesEnabled,
      'hintLimit': _hintLimit.name,
    };
    await File(_filePath).writeAsString(jsonEncode(json));
  }
}
