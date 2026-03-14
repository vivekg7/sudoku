import 'dart:io';

/// Manages raw terminal mode, ANSI escape codes, and cleanup.
class Terminal {
  bool _rawMode = false;

  /// Enters raw mode: disables echo and line buffering, hides cursor.
  void init() {
    if (_rawMode) return;
    stdin.echoMode = false;
    stdin.lineMode = false;
    _rawMode = true;
    stdout.write('\x1B[?25l'); // Hide cursor
    stdout.write('\x1B[2J\x1B[H'); // Clear screen
  }

  /// Restores terminal to normal state.
  void dispose() {
    if (!_rawMode) return;
    stdout.write('\x1B[0m'); // Reset all attributes
    stdout.write('\x1B[?25h'); // Show cursor
    stdout.write('\x1B[2J\x1B[H'); // Clear screen
    stdin.echoMode = true;
    stdin.lineMode = true;
    _rawMode = false;
  }

  /// Moves cursor to [row], [col] (1-based).
  void moveTo(int row, int col) {
    stdout.write('\x1B[$row;${col}H');
  }

  /// Clears the screen and moves cursor to top-left.
  void clear() {
    stdout.write('\x1B[2J\x1B[H');
  }

  /// Terminal width in columns.
  int get width => stdout.terminalColumns;

  /// Terminal height in rows.
  int get height => stdout.terminalLines;

  /// Whether we're currently in raw mode.
  bool get isRawMode => _rawMode;
}

/// ANSI escape code constants.
class Ansi {
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const dim = '\x1B[2m';

  // Foreground colors
  static const fgWhite = '\x1B[37m';
  static const fgCyan = '\x1B[36m';
  static const fgRed = '\x1B[31m';
  static const fgGreen = '\x1B[32m';
  static const fgYellow = '\x1B[33m';
  static const fgGray = '\x1B[90m';

  // 256-color backgrounds
  static const bgDefault = '\x1B[48;5;234m'; // Very dark gray
  static const bgGiven = '\x1B[48;5;236m'; // Slightly lighter
  static const bgSelected = '\x1B[48;5;25m'; // Blue
  static const bgRelated = '\x1B[48;5;235m'; // Subtle highlight
  static const bgSameDigit = '\x1B[48;5;237m'; // Subtle emphasis
  static const bgError = '\x1B[48;5;52m'; // Dark red
  static const bgHint = '\x1B[48;5;22m'; // Dark green
  static const bgPaused = '\x1B[48;5;238m'; // Paused overlay

  // Box drawing
  static const boxHorizontal = '─';
  static const boxVertical = '│';
  static const boxTopLeft = '┌';
  static const boxTopRight = '┐';
  static const boxBottomLeft = '└';
  static const boxBottomRight = '┘';
  static const boxTeeDown = '┬';
  static const boxTeeUp = '┴';
  static const boxTeeRight = '├';
  static const boxTeeLeft = '┤';
  static const boxCross = '┼';
  static const boxThickHorizontal = '━';
  static const boxThickVertical = '┃';
  static const boxThickTopLeft = '┏';
  static const boxThickTopRight = '┓';
  static const boxThickBottomLeft = '┗';
  static const boxThickBottomRight = '┛';
  static const boxThickTeeDown = '┳';
  static const boxThickTeeUp = '┻';
  static const boxThickTeeRight = '┣';
  static const boxThickTeeLeft = '┫';
  static const boxThickCross = '╋';
}
