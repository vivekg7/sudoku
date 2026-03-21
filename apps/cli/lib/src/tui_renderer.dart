import 'dart:io';

import 'package:sudoku_core/sudoku_core.dart';

import 'terminal.dart';

/// All state needed to render a single frame.
class RenderState {
  final Board board;
  final int cursorRow;
  final int cursorCol;
  final bool noteMode;
  final bool showCandidates;
  final String timerText;
  final Difficulty difficulty;
  final int emptyCells;
  final bool paused;
  final bool solved;
  final String? statusMessage;
  final String? confirmPrompt;
  final Set<(int, int)> conflictCells;
  final Set<(int, int)> hintCells;
  final int? quoteId;

  const RenderState({
    required this.board,
    required this.cursorRow,
    required this.cursorCol,
    required this.noteMode,
    required this.showCandidates,
    required this.timerText,
    required this.difficulty,
    required this.emptyCells,
    this.paused = false,
    this.solved = false,
    this.statusMessage,
    this.confirmPrompt,
    this.conflictCells = const {},
    this.hintCells = const {},
    this.quoteId,
  });
}

/// Renders the Sudoku board with ANSI colors and styling.
class TuiRenderer {
  /// Renders a complete frame to a string buffer, then writes it all at once.
  void renderFrame(RenderState state) {
    final buf = StringBuffer();
    buf.write('\x1B[2J\x1B[H'); // Clear screen, cursor home

    _renderHeader(buf, state);
    _renderQuote(buf, state);
    buf.writeln();

    if (state.showCandidates) {
      _renderBoardWithCandidates(buf, state);
    } else {
      _renderBoard(buf, state);
    }

    buf.writeln();
    _renderStatusBar(buf, state);
    buf.writeln();
    _renderHelpBar(buf, state);

    stdout.write(buf.toString());
  }

  void _renderHeader(StringBuffer buf, RenderState state) {
    buf.write('${Ansi.bold}${Ansi.fgWhite}');
    buf.write('  Sudoku');
    buf.write(Ansi.reset);

    buf.write('${Ansi.fgGray}  ${Ansi.reset}');
    buf.write('${Ansi.fgWhite}${state.difficulty.label}${Ansi.reset}');

    buf.write('${Ansi.fgGray}  │  ${Ansi.reset}');
    if (state.paused) {
      buf.write('${Ansi.fgYellow}${Ansi.bold}PAUSED${Ansi.reset}');
    } else {
      buf.write('${Ansi.fgWhite}${state.timerText}${Ansi.reset}');
    }

    buf.write('${Ansi.fgGray}  │  ${Ansi.reset}');
    buf.write('${Ansi.fgWhite}Empty: ${state.emptyCells}${Ansi.reset}');

    buf.write('${Ansi.fgGray}  │  ${Ansi.reset}');
    if (state.noteMode) {
      buf.write('${Ansi.fgYellow}${Ansi.bold}NOTE${Ansi.reset}');
    } else {
      buf.write('${Ansi.fgGray}NORMAL${Ansi.reset}');
    }

    buf.writeln();
  }

  void _renderQuote(StringBuffer buf, RenderState state) {
    if (state.quoteId == null) return;
    final quote = QuoteRepository.instance.getById(state.quoteId!);
    if (quote == null) return;
    buf.write('${Ansi.fgGray}${Ansi.dim}  "${quote.text}" - ${quote.author}${Ansi.reset}');
    buf.writeln();
  }

  void _renderBoard(StringBuffer buf, RenderState state) {
    final selectedValue = state.board.getCell(state.cursorRow, state.cursorCol).value;

    // Column headers - 4 chars prefix (3 label + 1 border), 3 chars per cell, 1 char per separator
    buf.write('${Ansi.fgGray}    ');
    for (var c = 0; c < 9; c++) {
      if (c > 0) buf.write(' ');
      buf.write(' ${c + 1} ');
    }
    buf.writeln(Ansi.reset);

    // Top border
    _renderThickHorizontalLine(buf, Ansi.boxThickTopLeft, Ansi.boxThickTeeDown, Ansi.boxThickTopRight);

    for (var r = 0; r < 9; r++) {
      if (r > 0 && r % 3 == 0) {
        _renderThickHorizontalLine(buf, Ansi.boxThickTeeRight, Ansi.boxThickCross, Ansi.boxThickTeeLeft);
      } else if (r > 0) {
        _renderThinHorizontalLine(buf);
      }

      // Row label
      buf.write('${Ansi.fgGray} ${r + 1} ${Ansi.reset}');
      buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');

      for (var c = 0; c < 9; c++) {
        if (c > 0 && c % 3 == 0) {
          buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
        } else if (c > 0) {
          buf.write('${Ansi.fgGray}${Ansi.boxVertical}${Ansi.reset}');
        }

        _renderCell(buf, state, r, c, selectedValue);
      }

      buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
      buf.writeln();
    }

    // Bottom border
    _renderThickHorizontalLine(buf, Ansi.boxThickBottomLeft, Ansi.boxThickTeeUp, Ansi.boxThickBottomRight);
  }

  void _renderCell(StringBuffer buf, RenderState state, int r, int c, int selectedValue) {
    final cell = state.board.getCell(r, c);
    final isSelected = r == state.cursorRow && c == state.cursorCol;
    final isRelated = _isRelated(r, c, state.cursorRow, state.cursorCol);
    final isConflict = state.conflictCells.contains((r, c));
    final isHint = state.hintCells.contains((r, c));
    final isSameDigit = !cell.isEmpty && cell.value == selectedValue && selectedValue != 0 && !isSelected;

    // Determine background
    String bg;
    if (isSelected) {
      bg = Ansi.bgSelected;
    } else if (isConflict) {
      bg = Ansi.bgError;
    } else if (isHint) {
      bg = Ansi.bgHint;
    } else if (isSameDigit) {
      bg = Ansi.bgSameDigit;
    } else if (isRelated) {
      bg = Ansi.bgRelated;
    } else {
      bg = Ansi.bgDefault;
    }

    // Determine foreground and style
    String fg;
    String style;
    String content;

    if (cell.isEmpty) {
      fg = Ansi.fgGray;
      style = Ansi.dim;
      content = '·';
    } else if (cell.isGiven) {
      fg = Ansi.fgWhite;
      style = Ansi.bold;
      content = '${cell.value}';
    } else {
      // User-filled
      fg = Ansi.fgCyan;
      style = isSameDigit ? Ansi.bold : '';
      content = '${cell.value}';
    }

    if (isConflict) {
      fg = Ansi.fgRed;
      style = Ansi.bold;
    } else if (isHint) {
      fg = Ansi.fgGreen;
      style = Ansi.bold;
    }

    buf.write('$bg$style$fg $content ${Ansi.reset}');
  }

  void _renderBoardWithCandidates(StringBuffer buf, RenderState state) {
    final selectedValue = state.board.getCell(state.cursorRow, state.cursorCol).value;

    // Column headers - 6 chars prefix (5 label + 1 border), 5 chars per cell, 1 char per separator
    buf.write('${Ansi.fgGray}      ');
    for (var c = 0; c < 9; c++) {
      if (c > 0) buf.write(' ');
      buf.write('  ${c + 1}  ');
    }
    buf.writeln(Ansi.reset);

    // Top border
    _renderThickHorizontalLineCandidates(buf, Ansi.boxThickTopLeft, Ansi.boxThickTeeDown, Ansi.boxThickTopRight);

    for (var r = 0; r < 9; r++) {
      if (r > 0 && r % 3 == 0) {
        _renderThickHorizontalLineCandidates(buf, Ansi.boxThickTeeRight, Ansi.boxThickCross, Ansi.boxThickTeeLeft);
      } else if (r > 0) {
        _renderThinHorizontalLineCandidates(buf);
      }

      // Three sub-rows per cell
      for (var subRow = 0; subRow < 3; subRow++) {
        if (subRow == 1) {
          buf.write('${Ansi.fgGray}  ${r + 1}  ${Ansi.reset}');
        } else {
          buf.write('     ');
        }
        buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');

        for (var c = 0; c < 9; c++) {
          if (c > 0 && c % 3 == 0) {
            buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
          } else if (c > 0) {
            buf.write('${Ansi.fgGray}${Ansi.boxVertical}${Ansi.reset}');
          }

          _renderCandidateCell(buf, state, r, c, subRow, selectedValue);
        }

        buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
        buf.writeln();
      }
    }

    _renderThickHorizontalLineCandidates(buf, Ansi.boxThickBottomLeft, Ansi.boxThickTeeUp, Ansi.boxThickBottomRight);
  }

  void _renderCandidateCell(StringBuffer buf, RenderState state, int r, int c, int subRow, int selectedValue) {
    final cell = state.board.getCell(r, c);
    final isSelected = r == state.cursorRow && c == state.cursorCol;
    final isRelated = _isRelated(r, c, state.cursorRow, state.cursorCol);
    final isConflict = state.conflictCells.contains((r, c));
    final isHint = state.hintCells.contains((r, c));
    final isSameDigit = !cell.isEmpty && cell.value == selectedValue && selectedValue != 0 && !isSelected;

    String bg;
    if (isSelected) {
      bg = Ansi.bgSelected;
    } else if (isConflict) {
      bg = Ansi.bgError;
    } else if (isHint) {
      bg = Ansi.bgHint;
    } else if (isSameDigit) {
      bg = Ansi.bgSameDigit;
    } else if (isRelated) {
      bg = Ansi.bgRelated;
    } else {
      bg = Ansi.bgDefault;
    }

    if (cell.isFilled) {
      if (subRow == 1) {
        String fg;
        String style;
        if (isConflict) {
          fg = Ansi.fgRed;
          style = Ansi.bold;
        } else if (isHint) {
          fg = Ansi.fgGreen;
          style = Ansi.bold;
        } else if (cell.isGiven) {
          fg = Ansi.fgWhite;
          style = Ansi.bold;
        } else {
          fg = Ansi.fgCyan;
          style = isSameDigit ? Ansi.bold : '';
        }
        buf.write('$bg$style$fg  ${cell.value}  ${Ansi.reset}');
      } else {
        buf.write('$bg     ${Ansi.reset}');
      }
    } else {
      // Show candidates
      final start = subRow * 3 + 1;
      final candidateStr = StringBuffer();
      for (var v = start; v < start + 3; v++) {
        if (cell.candidates.contains(v)) {
          candidateStr.write('$v');
        } else {
          candidateStr.write('${Ansi.fgGray}·${Ansi.reset}$bg${Ansi.dim}');
        }
      }
      buf.write('$bg${Ansi.dim}${Ansi.fgGray} $candidateStr ${Ansi.reset}');
    }
  }

  void _renderThickHorizontalLine(StringBuffer buf, String left, String mid, String right) {
    // 3 spaces prefix (matching row label width), 11 chars per box group (3+1+3+1+3)
    buf.write('${Ansi.bold}${Ansi.fgWhite}   $left');
    for (var i = 0; i < 3; i++) {
      if (i > 0) buf.write(mid);
      buf.write(Ansi.boxThickHorizontal * 11);
    }
    buf.writeln('$right${Ansi.reset}');
  }

  void _renderThinHorizontalLine(StringBuffer buf) {
    // 3 spaces prefix, then ┃ + (───┼───┼───) per box group + ┃
    buf.write('${Ansi.fgGray}   ${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
    for (var i = 0; i < 3; i++) {
      if (i > 0) buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
      buf.write('${Ansi.fgGray}${Ansi.boxHorizontal * 3}${Ansi.boxCross}${Ansi.boxHorizontal * 3}${Ansi.boxCross}${Ansi.boxHorizontal * 3}${Ansi.reset}');
    }
    buf.writeln('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
  }

  void _renderThickHorizontalLineCandidates(StringBuffer buf, String left, String mid, String right) {
    buf.write('${Ansi.bold}${Ansi.fgWhite}     $left');
    for (var i = 0; i < 3; i++) {
      if (i > 0) buf.write(mid);
      buf.write(Ansi.boxThickHorizontal * 17);
    }
    buf.writeln('$right${Ansi.reset}');
  }

  void _renderThinHorizontalLineCandidates(StringBuffer buf) {
    buf.write('     ${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
    for (var i = 0; i < 3; i++) {
      if (i > 0) buf.write('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
      buf.write('${Ansi.fgGray}${Ansi.boxHorizontal * 5}${Ansi.boxCross}${Ansi.boxHorizontal * 5}${Ansi.boxCross}${Ansi.boxHorizontal * 5}${Ansi.reset}');
    }
    buf.writeln('${Ansi.bold}${Ansi.fgWhite}${Ansi.boxThickVertical}${Ansi.reset}');
  }

  void _renderStatusBar(StringBuffer buf, RenderState state) {
    if (state.solved) {
      buf.write('${Ansi.bold}${Ansi.fgGreen}  ');
      buf.write('Congratulations! Puzzle solved in ${state.timerText}');
      buf.write(Ansi.reset);
      buf.writeln();
      return;
    }

    if (state.confirmPrompt != null) {
      buf.write('${Ansi.bold}${Ansi.fgYellow}  ${state.confirmPrompt}${Ansi.reset}');
      buf.writeln();
      return;
    }

    if (state.statusMessage != null) {
      buf.write('${Ansi.fgWhite}  ${state.statusMessage}${Ansi.reset}');
      buf.writeln();
    }
  }

  void _renderHelpBar(StringBuffer buf, RenderState state) {
    buf.write('${Ansi.fgGray}  ');
    buf.write('Arrows/WASD:move  1-9:place  n:notes  h:hint  ');
    buf.write('u:undo  r:redo  c:candidates  p:pause  q:quit');
    buf.write(Ansi.reset);
    buf.writeln();
  }

  bool _isRelated(int r, int c, int cursorRow, int cursorCol) {
    if (r == cursorRow && c == cursorCol) return false;
    if (r == cursorRow || c == cursorCol) return true;
    // Same box
    return (r ~/ 3 == cursorRow ~/ 3) && (c ~/ 3 == cursorCol ~/ 3);
  }
}
