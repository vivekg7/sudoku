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

/// Persists user preferences to a local JSON file.
class SettingsService extends ChangeNotifier {
  late final String _filePath;

  ThemeMode _themeMode = ThemeMode.system;
  AppColor _appColor = AppColor.blue;
  bool _quotesEnabled = true;

  ThemeMode get themeMode => _themeMode;
  AppColor get appColor => _appColor;
  bool get quotesEnabled => _quotesEnabled;

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
    } catch (_) {
      // Ignore corrupt settings — defaults are fine.
    }
  }

  Future<void> _save() async {
    final json = {
      'themeMode': _themeMode.name,
      'appColor': _appColor.name,
      'quotesEnabled': _quotesEnabled,
    };
    await File(_filePath).writeAsString(jsonEncode(json));
  }
}
