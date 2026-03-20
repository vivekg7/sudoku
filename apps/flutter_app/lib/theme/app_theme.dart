import 'package:flutter/material.dart';

/// Semantic colors for Sudoku-specific UI elements.
///
/// Access via `Theme.of(context).extension<SudokuColors>()!`.
@immutable
class SudokuColors extends ThemeExtension<SudokuColors> {
  // Hint panel - nudge level
  final Color nudgeBg;
  final Color nudgeBorder;
  final Color nudgeAccent;

  // Hint panel - strategy level
  final Color strategyBg;
  final Color strategyBorder;
  final Color strategyAccent;

  // Hint panel - answer level
  final Color answerBg;
  final Color answerBorder;
  final Color answerAccent;

  // Cell highlights
  final Color hintPlacement;
  final Color hintInvolved;
  final Color conflictSelected;
  final Color conflict;

  // Misc
  final Color bookmark;

  const SudokuColors({
    required this.nudgeBg,
    required this.nudgeBorder,
    required this.nudgeAccent,
    required this.strategyBg,
    required this.strategyBorder,
    required this.strategyAccent,
    required this.answerBg,
    required this.answerBorder,
    required this.answerAccent,
    required this.hintPlacement,
    required this.hintInvolved,
    required this.conflictSelected,
    required this.conflict,
    required this.bookmark,
  });

  static const light = SudokuColors(
    // Nudge: warm amber
    nudgeBg: Color(0xFFFFF8E1),
    nudgeBorder: Color(0xFFFFE082),
    nudgeAccent: Color(0xFFF9A825),
    // Strategy: cool blue
    strategyBg: Color(0xFFE3F2FD),
    strategyBorder: Color(0xFF90CAF9),
    strategyAccent: Color(0xFF1565C0),
    // Answer: fresh green
    answerBg: Color(0xFFE8F5E9),
    answerBorder: Color(0xFFA5D6A7),
    answerAccent: Color(0xFF2E7D32),
    // Cell highlights
    hintPlacement: Color(0xFFC8E6C9),
    hintInvolved: Color(0xFFFFE0B2),
    conflictSelected: Color(0xFFFFCDD2),
    conflict: Color(0xFFFFEBEE),
    // Misc
    bookmark: Color(0xFFF9A825),
  );

  static const dark = SudokuColors(
    // Nudge: deep brown-amber
    nudgeBg: Color(0xFF3E2723),
    nudgeBorder: Color(0xFF8D6E63),
    nudgeAccent: Color(0xFFFFB74D),
    // Strategy: deep navy
    strategyBg: Color(0xFF162640),
    strategyBorder: Color(0xFF42A5F5),
    strategyAccent: Color(0xFF64B5F6),
    // Answer: deep forest
    answerBg: Color(0xFF15301A),
    answerBorder: Color(0xFF66BB6A),
    answerAccent: Color(0xFF81C784),
    // Cell highlights - opaque equivalents of previous alpha-blended colors
    hintPlacement: Color(0xFF1A3A1C),
    hintInvolved: Color(0xFF3D2200),
    conflictSelected: Color(0xFF4A1414),
    conflict: Color(0xFF2E1010),
    // Misc
    bookmark: Color(0xFFF9A825),
  );

  @override
  SudokuColors copyWith({
    Color? nudgeBg,
    Color? nudgeBorder,
    Color? nudgeAccent,
    Color? strategyBg,
    Color? strategyBorder,
    Color? strategyAccent,
    Color? answerBg,
    Color? answerBorder,
    Color? answerAccent,
    Color? hintPlacement,
    Color? hintInvolved,
    Color? conflictSelected,
    Color? conflict,
    Color? bookmark,
  }) {
    return SudokuColors(
      nudgeBg: nudgeBg ?? this.nudgeBg,
      nudgeBorder: nudgeBorder ?? this.nudgeBorder,
      nudgeAccent: nudgeAccent ?? this.nudgeAccent,
      strategyBg: strategyBg ?? this.strategyBg,
      strategyBorder: strategyBorder ?? this.strategyBorder,
      strategyAccent: strategyAccent ?? this.strategyAccent,
      answerBg: answerBg ?? this.answerBg,
      answerBorder: answerBorder ?? this.answerBorder,
      answerAccent: answerAccent ?? this.answerAccent,
      hintPlacement: hintPlacement ?? this.hintPlacement,
      hintInvolved: hintInvolved ?? this.hintInvolved,
      conflictSelected: conflictSelected ?? this.conflictSelected,
      conflict: conflict ?? this.conflict,
      bookmark: bookmark ?? this.bookmark,
    );
  }

  @override
  SudokuColors lerp(SudokuColors? other, double t) {
    if (other is! SudokuColors) return this;
    return SudokuColors(
      nudgeBg: Color.lerp(nudgeBg, other.nudgeBg, t)!,
      nudgeBorder: Color.lerp(nudgeBorder, other.nudgeBorder, t)!,
      nudgeAccent: Color.lerp(nudgeAccent, other.nudgeAccent, t)!,
      strategyBg: Color.lerp(strategyBg, other.strategyBg, t)!,
      strategyBorder: Color.lerp(strategyBorder, other.strategyBorder, t)!,
      strategyAccent: Color.lerp(strategyAccent, other.strategyAccent, t)!,
      answerBg: Color.lerp(answerBg, other.answerBg, t)!,
      answerBorder: Color.lerp(answerBorder, other.answerBorder, t)!,
      answerAccent: Color.lerp(answerAccent, other.answerAccent, t)!,
      hintPlacement: Color.lerp(hintPlacement, other.hintPlacement, t)!,
      hintInvolved: Color.lerp(hintInvolved, other.hintInvolved, t)!,
      conflictSelected: Color.lerp(conflictSelected, other.conflictSelected, t)!,
      conflict: Color.lerp(conflict, other.conflict, t)!,
      bookmark: Color.lerp(bookmark, other.bookmark, t)!,
    );
  }
}

/// Builds the app [ThemeData] for the given [seedColor] and [brightness].
///
/// Set [amoled] to true for a pure-black dark theme optimized for OLED screens.
ThemeData buildAppTheme(
  Color seedColor,
  Brightness brightness, {
  bool amoled = false,
}) {
  final isDark = brightness == Brightness.dark;
  var colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );

  if (amoled && isDark) {
    colorScheme = colorScheme.copyWith(
      surface: const Color(0xFF000000),
      surfaceDim: const Color(0xFF000000),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0C0C0C),
      surfaceContainer: const Color(0xFF141414),
      surfaceContainerHigh: const Color(0xFF1C1C1C),
      surfaceContainerHighest: const Color(0xFF252525),
    );
  }

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: amoled ? 0 : 0.5,
      backgroundColor: amoled ? const Color(0xFF000000) : null,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      indent: 16,
      endIndent: 16,
    ),
    extensions: [
      isDark ? SudokuColors.dark : SudokuColors.light,
    ],
  );
}
