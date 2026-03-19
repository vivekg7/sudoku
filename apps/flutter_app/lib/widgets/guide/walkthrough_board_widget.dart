import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A read-only 9×9 Sudoku board for strategy walkthroughs.
///
/// Uses the same layout as the game board (classic style) — GridView with
/// per-cell borders and FittedBox for scaling digits and candidates.
class WalkthroughBoardWidget extends StatelessWidget {
  /// 9×9 grid of placed digits (0 = empty).
  final List<List<int>> board;

  /// 81-entry flat list of candidate sets (row-major).
  final List<Set<int>> candidates;

  /// Cells to highlight with accent colour.
  final Set<(int, int)> highlightCells;

  /// Candidates to accent — (row, col, digit).
  final Set<(int, int, int)> highlightCandidates;

  /// Candidates being eliminated — (row, col, digit).
  final Set<(int, int, int)> eliminateCandidates;

  /// Digits being placed — (row, col, digit).
  final Set<(int, int, int)> placeCells;

  /// Cells marked as blocked (red/error background).
  final Set<(int, int)> blockedCells;

  /// Candidates removed in previous steps (hidden from rendering).
  final Set<(int, int, int)> removedCandidates;

  const WalkthroughBoardWidget({
    super.key,
    required this.board,
    required this.candidates,
    this.highlightCells = const {},
    this.highlightCandidates = const {},
    this.eliminateCandidates = const {},
    this.placeCells = const {},
    this.blockedCells = const {},
    this.removedCandidates = const {},
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    const labelSize = 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate grid size: square that fits in available space minus labels
        final maxGridW = constraints.maxWidth - labelSize;
        final maxGridH = constraints.maxHeight - labelSize;
        final gridSize = maxGridW < maxGridH ? maxGridW : maxGridH;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Column numbers
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: labelSize),
                SizedBox(
                  width: gridSize,
                  height: labelSize,
                  child: Row(
                    children: [
                      for (int c = 1; c <= 9; c++)
                        Expanded(
                          child: Center(
                            child: Text('$c', style: labelStyle),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Row numbers + grid
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: labelSize,
                  height: gridSize,
                  child: Column(
                    children: [
                      for (int r = 1; r <= 9; r++)
                        Expanded(
                          child: Center(
                            child: Text('$r', style: labelStyle),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: gridSize,
                  height: gridSize,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemCount: 81,
                    itemBuilder: (context, index) {
                      final row = index ~/ 9;
                      final col = index % 9;
                      return _buildCell(context, row, col);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final colorScheme = Theme.of(context).colorScheme;
    final sudokuColors = Theme.of(context).extension<SudokuColors>()!;
    final isDark = colorScheme.brightness == Brightness.dark;
    final value = board[row][col];
    final isPlaced = value != 0;
    final candidateSet = candidates[row * 9 + col];

    // Check if this cell has a placement from the current step
    final placement = placeCells
        .where((p) => p.$1 == row && p.$2 == col)
        .firstOrNull;
    final isStepPlacement = placement != null;

    // Background colour
    Color bgColor;
    if (isStepPlacement) {
      bgColor = sudokuColors.answerBg;
    } else if (blockedCells.contains((row, col))) {
      bgColor = sudokuColors.conflict;
    } else if (highlightCells.contains((row, col))) {
      bgColor = colorScheme.primaryContainer.withValues(alpha: 0.5);
    } else {
      bgColor = colorScheme.surface;
    }

    // Cell border — same style as classic game board
    final thinColor =
        isDark ? colorScheme.outlineVariant : const Color(0xFFBDBDBD);
    final thickColor =
        isDark ? colorScheme.outline : const Color(0xFF424242);
    final thin = BorderSide(color: thinColor, width: 0.5);
    final thick = BorderSide(color: thickColor, width: 1.5);

    final border = Border(
      top: row % 3 == 0 ? thick : thin,
      left: col % 3 == 0 ? thick : thin,
      bottom: row == 8 ? thick : BorderSide.none,
      right: col == 8 ? thick : BorderSide.none,
    );

    Widget content;
    if (isStepPlacement) {
      content = _buildDigit(placement.$3, sudokuColors.answerAccent);
    } else if (isPlaced) {
      content = _buildDigit(value, colorScheme.onSurface);
    } else {
      content = _buildCandidates(
        context,
        row,
        col,
        candidateSet,
      );
    }

    return Container(
      decoration: BoxDecoration(color: bgColor, border: border),
      child: content,
    );
  }

  Widget _buildDigit(int digit, Color color) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$digit',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCandidates(
    BuildContext context,
    int row,
    int col,
    Set<int> cellCandidates,
  ) {
    if (cellCandidates.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final sudokuColors = Theme.of(context).extension<SudokuColors>()!;

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
                        child: _candidateDigit(
                          r * 3 + c + 1,
                          cellCandidates,
                          row,
                          col,
                          colorScheme,
                          sudokuColors,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _candidateDigit(
    int digit,
    Set<int> cellCandidates,
    int row,
    int col,
    ColorScheme colorScheme,
    SudokuColors sudokuColors,
  ) {
    if (!cellCandidates.contains(digit)) return const SizedBox.shrink();
    if (removedCandidates.contains((row, col, digit))) {
      return const SizedBox.shrink();
    }

    final isEliminated = eliminateCandidates.contains((row, col, digit));
    final isHighlighted = highlightCandidates.contains((row, col, digit));

    Color textColor;
    TextDecoration? decoration;

    if (isEliminated) {
      textColor = colorScheme.error;
      decoration = TextDecoration.lineThrough;
    } else if (isHighlighted) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurfaceVariant;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$digit',
        style: TextStyle(
          fontSize: 10,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
          color: textColor,
          decoration: decoration,
          decorationColor: textColor,
        ),
      ),
    );
  }
}
