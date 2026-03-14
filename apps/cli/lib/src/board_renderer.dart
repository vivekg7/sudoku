import 'package:sudoku_core/sudoku_core.dart';

/// Renders a Sudoku board as an ASCII grid for the terminal.
class BoardRenderer {
  /// Renders the board with row/column labels and box separators.
  ///
  /// If [selectedRow] and [selectedCol] are provided, marks that cell
  /// with brackets. If [showCandidates] is true, shows candidate lists
  /// for empty cells in a compact format.
  String render(
    Board board, {
    int? selectedRow,
    int? selectedCol,
    bool showCandidates = false,
    Set<({int row, int col})>? highlights,
  }) {
    if (showCandidates) {
      return _renderWithCandidates(board,
          selectedRow: selectedRow,
          selectedCol: selectedCol,
          highlights: highlights);
    }
    return _renderSimple(board,
        selectedRow: selectedRow,
        selectedCol: selectedCol,
        highlights: highlights);
  }

  String _renderSimple(
    Board board, {
    int? selectedRow,
    int? selectedCol,
    Set<({int row, int col})>? highlights,
  }) {
    final buf = StringBuffer();

    buf.writeln('    1 2 3   4 5 6   7 8 9');
    buf.writeln('  +-------+-------+-------+');

    for (var r = 0; r < 9; r++) {
      if (r > 0 && r % 3 == 0) {
        buf.writeln('  +-------+-------+-------+');
      }
      buf.write('${r + 1} |');

      for (var c = 0; c < 9; c++) {
        if (c > 0 && c % 3 == 0) buf.write('|');

        final cell = board.getCell(r, c);
        final isSelected = r == selectedRow && c == selectedCol;
        final isHighlighted =
            highlights != null && highlights.contains((row: r, col: c));

        String cellStr;
        if (cell.isEmpty) {
          cellStr = isSelected ? '[_]' : ' . ';
        } else {
          final v = '${cell.value}';
          if (isSelected) {
            cellStr = '[$v]';
          } else if (isHighlighted) {
            cellStr = '*$v*';
          } else if (cell.isGiven) {
            cellStr = ' $v ';
          } else {
            cellStr = ' $v ';
          }
        }

        // Trim to fit: each cell is exactly 2 chars + separator logic
        if (isSelected || isHighlighted) {
          buf.write(cellStr);
        } else {
          buf.write(' ${cell.isEmpty ? "." : cell.value} ');
        }
      }
      buf.writeln('|');
    }
    buf.writeln('  +-------+-------+-------+');

    return buf.toString();
  }

  String _renderWithCandidates(
    Board board, {
    int? selectedRow,
    int? selectedCol,
    Set<({int row, int col})>? highlights,
  }) {
    // Each cell takes 5 chars wide, 3 rows tall for candidates.
    final buf = StringBuffer();
    buf.writeln('     1     2     3       4     5     6       7     8     9');

    for (var r = 0; r < 9; r++) {
      if (r % 3 == 0) {
        buf.writeln(
            '  +${'-' * 17}+${'-' * 17}+${'-' * 17}+');
      }

      // Three sub-rows per cell row.
      for (var subRow = 0; subRow < 3; subRow++) {
        if (subRow == 1) {
          buf.write('${r + 1} |');
        } else {
          buf.write('  |');
        }

        for (var c = 0; c < 9; c++) {
          if (c > 0 && c % 3 == 0) buf.write('|');

          final cell = board.getCell(r, c);
          final isSelected = r == selectedRow && c == selectedCol;

          if (cell.isFilled) {
            if (subRow == 1) {
              if (isSelected) {
                buf.write(' [${cell.value}]  ');
              } else {
                buf.write('  ${cell.value}   ');
              }
            } else {
              buf.write('      ');
            }
          } else {
            // Show candidates for this sub-row.
            final start = subRow * 3 + 1;
            final candidateStr = StringBuffer();
            for (var v = start; v < start + 3; v++) {
              candidateStr
                  .write(cell.candidates.contains(v) ? '$v' : '.');
            }
            if (subRow == 1 && isSelected) {
              buf.write('[$candidateStr]  ');
            } else {
              buf.write(' $candidateStr   ');
            }
          }
        }
        buf.writeln('|');
      }
    }
    buf.writeln(
        '  +${'-' * 17}+${'-' * 17}+${'-' * 17}+');

    return buf.toString();
  }
}
