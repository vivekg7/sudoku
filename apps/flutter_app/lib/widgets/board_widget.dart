import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../state/game_state.dart';
import 'cell_widget.dart';

class BoardWidget extends StatelessWidget {
  final GameState gameState;
  final BoardLayout boardLayout;

  const BoardWidget({
    super.key,
    required this.gameState,
    required this.boardLayout,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: boardLayout == BoardLayout.circular
          ? _circularBoard(context)
          : _classicBoard(),
    );
  }

  Widget _classicBoard() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
      ),
      itemCount: 81,
      itemBuilder: (context, index) {
        final row = index ~/ 9;
        final col = index % 9;
        return CellWidget(
          row: row,
          col: col,
          gameState: gameState,
          boardLayout: boardLayout,
        );
      },
    );
  }

  Widget _circularBoard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thickColor = isDark ? colorScheme.outline : const Color(0xFF424242);
    final thinColor = isDark ? colorScheme.outlineVariant : const Color(0xFFBDBDBD);

    return Stack(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final row = index ~/ 9;
            final col = index % 9;
            return CellWidget(
              row: row,
              col: col,
              gameState: gameState,
              boardLayout: boardLayout,
            );
          },
        ),
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _GridLinesPainter(
              thickColor: thickColor,
              thinColor: thinColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  final Color thickColor;
  final Color thinColor;

  _GridLinesPainter({required this.thickColor, required this.thinColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;
    final tickLen = cellSize * 0.25;

    // --- Thin tick marks between adjacent cells (not at box boundaries) ---
    final thinPaint = Paint()
      ..color = thinColor
      ..strokeWidth = 0.5;

    // Horizontal marks between vertically adjacent cells (at row boundaries).
    // Skip box boundaries at rows 3 and 6.
    for (final r in [1, 2, 4, 5, 7, 8]) {
      final y = r * cellSize;
      // One mark centered between each pair of horizontally adjacent cells.
      for (var c = 0; c < 9; c++) {
        final midX = (c + 0.5) * cellSize;
        canvas.drawLine(
          Offset(midX - tickLen, y),
          Offset(midX + tickLen, y),
          thinPaint,
        );
      }
    }

    // Vertical marks between horizontally adjacent cells (at column boundaries).
    // Skip box boundaries at cols 3 and 6.
    for (final c in [1, 2, 4, 5, 7, 8]) {
      final x = c * cellSize;
      // One mark centered between each pair of vertically adjacent cells.
      for (var r = 0; r < 9; r++) {
        final midY = (r + 0.5) * cellSize;
        canvas.drawLine(
          Offset(x, midY - tickLen),
          Offset(x, midY + tickLen),
          thinPaint,
        );
      }
    }

    // --- Thick box divider lines (internal only, no outer border) ---
    final thickPaint = Paint()
      ..color = thickColor
      ..strokeWidth = 1.5;

    for (final col in [3, 6]) {
      final x = col * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thickPaint);
    }

    for (final row in [3, 6]) {
      final y = row * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thickPaint);
    }
  }

  @override
  bool shouldRepaint(_GridLinesPainter oldDelegate) =>
      thickColor != oldDelegate.thickColor || thinColor != oldDelegate.thinColor;
}
