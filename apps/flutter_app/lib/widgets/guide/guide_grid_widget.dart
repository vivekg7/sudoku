import 'package:flutter/material.dart';

/// A cell in the guide illustration grid.
class GuideCell {
  final String? value;
  final Color? bgColor;
  final Color? textColor;
  final bool strikethrough;
  final bool bold;
  final double? fontSize;

  const GuideCell({
    this.value,
    this.bgColor,
    this.textColor,
    this.strikethrough = false,
    this.bold = false,
    this.fontSize,
  });

  const GuideCell.empty() : this();

  const GuideCell.given(String digit)
      : this(value: digit, bold: true);

  const GuideCell.eliminated(String digit)
      : this(
          value: digit,
          strikethrough: true,
          textColor: const Color(0xFF9E9E9E),
        );
}

/// A lightweight grid widget for illustrative Sudoku diagrams in the guide.
///
/// Not a reuse of BoardWidget — this is purpose-built for small, static
/// illustrations with highlighting, annotations, and crossed-out digits.
class GuideGridWidget extends StatelessWidget {
  /// 2D list of cells, rows × cols.
  final List<List<GuideCell>> cells;

  /// Optional label shown below the grid.
  final String? caption;

  /// Size of each cell in logical pixels.
  final double cellSize;

  /// Thickness of inner grid lines.
  final double gridLineWidth;

  /// Thickness of box boundary lines (every 3 cells).
  final bool showBoxBorders;

  const GuideGridWidget({
    super.key,
    required this.cells,
    this.caption,
    this.cellSize = 38,
    this.gridLineWidth = 0.5,
    this.showBoxBorders = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = cells.length;
    final cols = cells.isEmpty ? 0 : cells[0].length;
    final borderColor = colorScheme.outline;
    final thinBorder = BorderSide(
      color: borderColor.withValues(alpha: 0.3),
      width: gridLineWidth,
    );
    final thickBorder = BorderSide(color: borderColor, width: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int r = 0; r < rows; r++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int c = 0; c < cols; c++)
                        _buildCell(
                          context,
                          cells[r][c],
                          topBorder: r > 0 &&
                                  showBoxBorders &&
                                  r % 3 == 0
                              ? thickBorder
                              : r > 0
                                  ? thinBorder
                                  : BorderSide.none,
                          leftBorder: c > 0 &&
                                  showBoxBorders &&
                                  c % 3 == 0
                              ? thickBorder
                              : c > 0
                                  ? thinBorder
                                  : BorderSide.none,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    GuideCell cell, {
    required BorderSide topBorder,
    required BorderSide leftBorder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: cell.bgColor,
        border: Border(top: topBorder, left: leftBorder),
      ),
      alignment: Alignment.center,
      child: cell.value != null
          ? Text(
              cell.value!,
              style: TextStyle(
                fontSize: cell.fontSize ?? 18,
                fontWeight:
                    cell.bold ? FontWeight.w700 : FontWeight.w400,
                color: cell.textColor ?? colorScheme.onSurface,
                decoration: cell.strikethrough
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: cell.textColor ?? colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          : null,
    );
  }
}
