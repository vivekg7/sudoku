import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';

class CellWidget extends StatelessWidget {
  final int row;
  final int col;
  final GameState gameState;
  final BoardLayout boardLayout;
  final bool animationsEnabled;

  const CellWidget({
    super.key,
    required this.row,
    required this.col,
    required this.gameState,
    required this.boardLayout,
    this.animationsEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cell = gameState.puzzle!.board.getCell(row, col);
    final isSelected = gameState.isSelected(row, col);
    final isRelated = gameState.isRelatedToSelected(row, col);
    final sameValue = gameState.hasSameValueAsSelected(row, col);
    final isConflict = gameState.assistToggles.showConflicts &&
        gameState.conflicts.contains((row, col));
    final isHintPlacement = gameState.hintPlacementCells.contains((row, col));
    final isHintInvolved = gameState.hintInvolvedCells.contains((row, col));

    final colorScheme = Theme.of(context).colorScheme;
    final sudokuColors = Theme.of(context).extension<SudokuColors>()!;

    final bgColor = _backgroundColor(
      colorScheme: colorScheme,
      sudokuColors: sudokuColors,
      isSelected: isSelected,
      isRelated: isRelated,
      sameValue: sameValue,
      isConflict: isConflict,
      isHintPlacement: isHintPlacement,
      isHintInvolved: isHintInvolved,
    );

    final content = cell.isFilled
        ? _buildValue(cell, isConflict, colorScheme)
        : _buildCandidates(cell.candidates, colorScheme);

    final bgDuration = animationsEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;

    Widget cellWidget = boardLayout == BoardLayout.circular
        ? Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: bgDuration,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: content,
            ),
          )
        : AnimatedContainer(
            duration: bgDuration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: bgColor,
              border: _cellBorder(
                colorScheme,
                colorScheme.brightness == Brightness.dark,
              ),
            ),
            child: content,
          );

    // Conflict flash: brief scale pulse when cell enters conflict.
    if (animationsEnabled && isConflict && !cell.isGiven) {
      cellWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.08, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, s, child) =>
            Transform.scale(scale: s, child: child),
        child: cellWidget,
      );
    }

    return GestureDetector(
      onTap: () => gameState.selectCell(row, col),
      onLongPress: () => _eraseCell(),
      child: cellWidget,
    );
  }

  void _eraseCell() {
    gameState.clearCellAt(row, col);
  }

  Color _backgroundColor({
    required ColorScheme colorScheme,
    required SudokuColors sudokuColors,
    required bool isSelected,
    required bool isRelated,
    required bool sameValue,
    required bool isConflict,
    required bool isHintPlacement,
    required bool isHintInvolved,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;

    if (isHintPlacement) return sudokuColors.hintPlacement;
    if (isHintInvolved) return sudokuColors.hintInvolved;
    if (isConflict && isSelected) return sudokuColors.conflictSelected;
    if (isSelected) return colorScheme.primaryContainer;
    if (isConflict) return sudokuColors.conflict;
    final isAmoled = isDark && colorScheme.surface == const Color(0xFF000000);
    final highlightAlpha = isAmoled ? 0.5 : isDark ? 0.3 : 0.4;

    if (sameValue) {
      return colorScheme.primaryContainer.withValues(alpha: highlightAlpha);
    }
    if (isRelated) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: highlightAlpha);
    }
    return colorScheme.surface;
  }

  Border _cellBorder(ColorScheme colorScheme, bool isDark) {
    final thinColor = isDark ? colorScheme.outlineVariant : const Color(0xFFBDBDBD);
    final thickColor = isDark ? colorScheme.outline : const Color(0xFF424242);
    final thin = BorderSide(color: thinColor, width: 0.5);
    final thick = BorderSide(color: thickColor, width: 1.5);

    return Border(
      top: row % 3 == 0 ? thick : thin,
      left: col % 3 == 0 ? thick : thin,
      bottom: row == 8 ? thick : BorderSide.none,
      right: col == 8 ? thick : BorderSide.none,
    );
  }

  Widget _buildValue(Cell cell, bool isConflict, ColorScheme colorScheme) {
    final color = isConflict
        ? colorScheme.error
        : cell.isGiven
            ? colorScheme.onSurface
            : colorScheme.primary;

    final textWidget = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${cell.value}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: cell.isGiven ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );

    if (!animationsEnabled || cell.isGiven) return textWidget;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${row}_${col}_${cell.value}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.scale(
        scale: 0.5 + 0.5 * t,
        child: Opacity(opacity: t, child: child),
      ),
      child: textWidget,
    );
  }

  Widget _buildCandidates(CandidateSet candidates, ColorScheme colorScheme) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(
                      child: Center(
                        child: _candidateDigit(r * 3 + c + 1, candidates, colorScheme),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _candidateDigit(int digit, CandidateSet candidates, ColorScheme colorScheme) {
    if (!candidates.contains(digit)) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$digit',
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
