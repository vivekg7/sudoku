import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Preset accent colors for the app theme.
enum AppColor {
  blue(Color(0xFF1565C0), 'Blue'),
  indigo(Color(0xFF3949AB), 'Indigo'),
  teal(Color(0xFF00695C), 'Teal'),
  green(Color(0xFF2E7D32), 'Green'),
  purple(Color(0xFF6A1B9A), 'Purple'),
  rose(Color(0xFFC2185B), 'Rose'),
  orange(Color(0xFFE65100), 'Orange'),
  red(Color(0xFFC62828), 'Red'),
  slate(Color(0xFF546E7A), 'Slate');

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

/// Individual visual-aid toggles - replaces the old tiered AssistLevel.
class AssistToggles {
  final bool highlightRelated;
  final bool highlightSameDigit;
  final bool showConflicts;
  final bool showRemainingCount;
  final bool autoRemoveCandidates;
  final bool autoFillNotes;

  const AssistToggles({
    this.highlightRelated = true,
    this.highlightSameDigit = true,
    this.showConflicts = true,
    this.showRemainingCount = true,
    this.autoRemoveCandidates = false,
    this.autoFillNotes = true,
  });

  static const allOn = AssistToggles();
  static const allOff = AssistToggles(
    highlightRelated: false,
    highlightSameDigit: false,
    showConflicts: false,
    showRemainingCount: false,
    autoRemoveCandidates: false,
    autoFillNotes: false,
  );

  /// Derived label for stats: none, full, or custom.
  String get statsLabel {
    final core = [highlightRelated, highlightSameDigit, showConflicts, showRemainingCount];
    if (core.every((t) => !t) && !autoRemoveCandidates) return 'none';
    if (core.every((t) => t) && !autoRemoveCandidates) return 'full';
    return 'custom';
  }

  AssistToggles copyWith({
    bool? highlightRelated,
    bool? highlightSameDigit,
    bool? showConflicts,
    bool? showRemainingCount,
    bool? autoRemoveCandidates,
    bool? autoFillNotes,
  }) =>
      AssistToggles(
        highlightRelated: highlightRelated ?? this.highlightRelated,
        highlightSameDigit: highlightSameDigit ?? this.highlightSameDigit,
        showConflicts: showConflicts ?? this.showConflicts,
        showRemainingCount: showRemainingCount ?? this.showRemainingCount,
        autoRemoveCandidates: autoRemoveCandidates ?? this.autoRemoveCandidates,
        autoFillNotes: autoFillNotes ?? this.autoFillNotes,
      );

  Map<String, dynamic> toJson() => {
        'highlightRelated': highlightRelated,
        'highlightSameDigit': highlightSameDigit,
        'showConflicts': showConflicts,
        'showRemainingCount': showRemainingCount,
        'autoRemoveCandidates': autoRemoveCandidates,
        'autoFillNotes': autoFillNotes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistToggles &&
          highlightRelated == other.highlightRelated &&
          highlightSameDigit == other.highlightSameDigit &&
          showConflicts == other.showConflicts &&
          showRemainingCount == other.showRemainingCount &&
          autoRemoveCandidates == other.autoRemoveCandidates &&
          autoFillNotes == other.autoFillNotes;

  @override
  int get hashCode => Object.hash(
        highlightRelated,
        highlightSameDigit,
        showConflicts,
        showRemainingCount,
        autoRemoveCandidates,
        autoFillNotes,
      );

  factory AssistToggles.fromJson(Map<String, dynamic> json) => AssistToggles(
        highlightRelated: json['highlightRelated'] as bool? ?? true,
        highlightSameDigit: json['highlightSameDigit'] as bool? ?? true,
        showConflicts: json['showConflicts'] as bool? ?? true,
        showRemainingCount: json['showRemainingCount'] as bool? ?? true,
        autoRemoveCandidates: json['autoRemoveCandidates'] as bool? ?? false,
        autoFillNotes: json['autoFillNotes'] as bool? ?? true,
      );
}

/// Board layout style.
enum BoardLayout {
  circular('Circular', 'Circular cells with tick-mark grid lines'),
  classic('Classic', 'Traditional rectangular grid with borders');

  final String label;
  final String description;
  const BoardLayout(this.label, this.description);
}

/// App theme mode - extends Flutter's ThemeMode with AMOLED support.
enum AppThemeMode {
  system,
  light,
  dark,
  amoled;

  /// Maps to Flutter's [ThemeMode] for [MaterialApp].
  ThemeMode get flutterThemeMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.amoled => ThemeMode.dark,
      };

  bool get isAmoled => this == AppThemeMode.amoled;
}

/// Persists user preferences to a local JSON file.
class SettingsService extends ChangeNotifier {
  late final String _filePath;

  AppThemeMode _appThemeMode = AppThemeMode.system;
  AppColor _appColor = AppColor.blue;
  bool _quotesEnabled = true;
  HintLimit _hintLimit = HintLimit.all;
  bool _showTimer = true;
  bool _notesEnabled = true;
  AssistToggles _assistToggles = AssistToggles.allOn;
  BoardLayout _boardLayout = BoardLayout.circular;
  bool _animationsEnabled = true;

  AppThemeMode get appThemeMode => _appThemeMode;
  AppColor get appColor => _appColor;
  bool get quotesEnabled => _quotesEnabled;
  HintLimit get hintLimit => _hintLimit;
  bool get showTimer => _showTimer;
  bool get notesEnabled => _notesEnabled;
  AssistToggles get assistToggles => _assistToggles;
  BoardLayout get boardLayout => _boardLayout;
  bool get animationsEnabled => _animationsEnabled;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/sudoku_settings.json';
    await _load();
  }

  void setThemeMode(AppThemeMode mode) {
    if (_appThemeMode == mode) return;
    _appThemeMode = mode;
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

  void setAssistToggles(AssistToggles toggles) {
    if (_assistToggles == toggles) return;
    _assistToggles = toggles;
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

  void setBoardLayout(BoardLayout layout) {
    if (_boardLayout == layout) return;
    _boardLayout = layout;
    notifyListeners();
    _save();
  }

  void setAnimationsEnabled(bool enabled) {
    if (_animationsEnabled == enabled) return;
    _animationsEnabled = enabled;
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final file = File(_filePath);
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _appThemeMode = AppThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      );
      _appColor = AppColor.values.firstWhere(
        (c) => c.name == json['appColor'],
        orElse: () => AppColor.blue,
      );
      _quotesEnabled = json['quotesEnabled'] as bool? ?? true;
      _showTimer = json['showTimer'] as bool? ?? true;
      _notesEnabled = json['notesEnabled'] as bool? ?? true;
      if (json['assistToggles'] is Map<String, dynamic>) {
        _assistToggles = AssistToggles.fromJson(
            json['assistToggles'] as Map<String, dynamic>);
      }
      _hintLimit = HintLimit.values.firstWhere(
        (h) => h.name == json['hintLimit'],
        orElse: () => HintLimit.all,
      );
      _boardLayout = BoardLayout.values.firstWhere(
        (l) => l.name == json['boardLayout'],
        orElse: () => BoardLayout.circular,
      );
      _animationsEnabled = json['animationsEnabled'] as bool? ?? true;
    } catch (_) {
      // Ignore corrupt settings - defaults are fine.
    }
  }

  Future<void> _save() async {
    final json = {
      'themeMode': _appThemeMode.name,
      'appColor': _appColor.name,
      'quotesEnabled': _quotesEnabled,
      'showTimer': _showTimer,
      'notesEnabled': _notesEnabled,
      'assistToggles': _assistToggles.toJson(),
      'hintLimit': _hintLimit.name,
      'boardLayout': _boardLayout.name,
      'animationsEnabled': _animationsEnabled,
    };
    await File(_filePath).writeAsString(jsonEncode(json));
  }
}
