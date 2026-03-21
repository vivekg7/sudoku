import 'dart:async';
import 'dart:io';

import 'package:sudoku_core/sudoku_core.dart';

import 'input_handler.dart';
import 'terminal.dart';

/// Actions the user can take from the homepage.
sealed class HomeAction {}

class NewGameAction extends HomeAction {
  final Difficulty difficulty;
  NewGameAction(this.difficulty);
}

class LoadGameAction extends HomeAction {}

class ExportPdfAction extends HomeAction {
  final Difficulty difficulty;
  final int count;
  final bool includeHints;
  final bool includeRoughGrid;
  final bool includeQuotes;
  final String outputPath;

  ExportPdfAction({
    required this.difficulty,
    required this.count,
    required this.includeHints,
    required this.includeRoughGrid,
    required this.includeQuotes,
    required this.outputPath,
  });
}

class ViewStatsAction extends HomeAction {}

class QuitAction extends HomeAction {}

/// Interactive TUI homepage menu.
class TuiHomepage {
  final Terminal _terminal;
  final InputHandler _input;
  final bool _ownsTerminal;
  final Completer<HomeAction> _actionComplete = Completer<HomeAction>();

  int _selectedIndex = 0;
  _Screen _screen = _Screen.main;

  // Difficulty selection state.
  int _difficultyIndex = 0;

  // PDF options state.
  int _pdfDifficultyIndex = 2; // medium
  int _pdfCount = 6;
  bool _pdfHints = true;
  bool _pdfRoughGrid = false;
  bool _pdfQuotes = true;
  int _pdfOptionIndex = 0;

  static const _mainItems = ['New Game', 'Load Game', 'Export PDF', 'View Stats', 'Quit'];
  static const _difficulties = Difficulty.values;
  static const _pdfOptionLabels = [
    'Difficulty',
    'Count',
    'Solve-order hints',
    'Rough work grid',
    'Include quotes',
    'Generate',
  ];

  /// Creates a TUI homepage. If [terminal] and [input] are provided, they are
  /// borrowed (not disposed on exit). Otherwise new ones are created and owned.
  TuiHomepage({Terminal? terminal, InputHandler? input})
      : _terminal = terminal ?? Terminal(),
        _input = input ?? InputHandler(),
        _ownsTerminal = terminal == null;

  /// Show the homepage and return the user's chosen action.
  Future<HomeAction> show() async {
    if (_ownsTerminal) _terminal.init();
    _terminal.clear();
    try {
      if (_ownsTerminal) _input.start();
      _redraw();

      final subscription = _input.keys.listen(_onKey);
      final action = await _actionComplete.future;

      await subscription.cancel();
      return action;
    } finally {
      if (_ownsTerminal) {
        await _input.stop();
        _terminal.dispose();
      }
    }
  }

  void _onKey(KeyEvent event) {
    switch (_screen) {
      case _Screen.main:
        _handleMainKey(event);
      case _Screen.difficulty:
        _handleDifficultyKey(event);
      case _Screen.pdfOptions:
        _handlePdfKey(event);
    }
  }

  void _handleMainKey(KeyEvent event) {
    switch (event) {
      case ArrowKey(direction: Direction.up):
        _selectedIndex = (_selectedIndex - 1 + _mainItems.length) % _mainItems.length;
        _redraw();
      case ArrowKey(direction: Direction.down):
        _selectedIndex = (_selectedIndex + 1) % _mainItems.length;
        _redraw();
      case EnterKey():
        _selectMainItem();
      case CharKey(char: final c):
        switch (c.toLowerCase()) {
          case ' ':
            _selectMainItem();
          case 'n':
            _selectedIndex = 0;
            _selectMainItem();
          case 'l':
            _selectedIndex = 1;
            _selectMainItem();
          case 'e':
            _selectedIndex = 2;
            _selectMainItem();
          case 's':
            _selectedIndex = 3;
            _selectMainItem();
          case 'q':
            _actionComplete.complete(QuitAction());
        }
      case EscapeKey():
        _actionComplete.complete(QuitAction());
      default:
        break;
    }
  }

  void _selectMainItem() {
    switch (_selectedIndex) {
      case 0:
        _screen = _Screen.difficulty;
        _difficultyIndex = 0;
        _redraw();
      case 1:
        _actionComplete.complete(LoadGameAction());
      case 2:
        _screen = _Screen.pdfOptions;
        _pdfOptionIndex = 0;
        _redraw();
      case 3:
        _actionComplete.complete(ViewStatsAction());
      case 4:
        _actionComplete.complete(QuitAction());
    }
  }

  void _handleDifficultyKey(KeyEvent event) {
    switch (event) {
      case ArrowKey(direction: Direction.up):
        _difficultyIndex = (_difficultyIndex - 1 + _difficulties.length) % _difficulties.length;
        _redraw();
      case ArrowKey(direction: Direction.down):
        _difficultyIndex = (_difficultyIndex + 1) % _difficulties.length;
        _redraw();
      case EnterKey():
        _actionComplete.complete(NewGameAction(_difficulties[_difficultyIndex]));
      case CharKey(char: final c):
        if (c == ' ') {
          _actionComplete.complete(NewGameAction(_difficulties[_difficultyIndex]));
        } else {
          final idx = _difficultyShortcut(c);
          if (idx != null) {
            _actionComplete.complete(NewGameAction(_difficulties[idx]));
          }
        }
      case EscapeKey():
        _screen = _Screen.main;
        _redraw();
      default:
        break;
    }
  }

  int? _difficultyShortcut(String c) {
    return switch (c.toLowerCase()) {
      'b' => 0, // beginner
      'e' => 1, // easy
      'm' => 2, // medium
      'h' => 3, // hard
      'x' => 4, // expert
      'r' => 5, // master
      _ => null,
    };
  }

  void _handlePdfKey(KeyEvent event) {
    switch (event) {
      case ArrowKey(direction: Direction.up):
        _pdfOptionIndex = (_pdfOptionIndex - 1 + _pdfOptionLabels.length) % _pdfOptionLabels.length;
        _redraw();
      case ArrowKey(direction: Direction.down):
        _pdfOptionIndex = (_pdfOptionIndex + 1) % _pdfOptionLabels.length;
        _redraw();
      case ArrowKey(direction: Direction.left):
        _adjustPdfOption(-1);
        _redraw();
      case ArrowKey(direction: Direction.right):
        _adjustPdfOption(1);
        _redraw();
      case EnterKey():
        if (_pdfOptionIndex == _pdfOptionLabels.length - 1) {
          _completePdf();
        } else {
          _adjustPdfOption(1);
          _redraw();
        }
      case CharKey(char: ' '):
        if (_pdfOptionIndex == _pdfOptionLabels.length - 1) {
          _completePdf();
        } else {
          _adjustPdfOption(1);
          _redraw();
        }
      case EscapeKey():
        _screen = _Screen.main;
        _redraw();
      default:
        break;
    }
  }

  void _adjustPdfOption(int delta) {
    switch (_pdfOptionIndex) {
      case 0: // difficulty
        _pdfDifficultyIndex = (_pdfDifficultyIndex + delta + _difficulties.length) % _difficulties.length;
      case 1: // count
        _pdfCount = (_pdfCount + delta).clamp(1, 20);
      case 2: // hints
        _pdfHints = !_pdfHints;
      case 3: // rough grid
        _pdfRoughGrid = !_pdfRoughGrid;
      case 4: // quotes
        _pdfQuotes = !_pdfQuotes;
    }
  }

  void _completePdf() {
    final diff = _difficulties[_pdfDifficultyIndex];
    final hintsTag = _pdfHints ? '_hints' : '';
    final gridTag = _pdfRoughGrid ? '_grid' : '';
    final filename = 'sudoku_${diff.name}_${_pdfCount}x$hintsTag$gridTag.pdf';

    _actionComplete.complete(ExportPdfAction(
      difficulty: diff,
      count: _pdfCount,
      includeHints: _pdfHints,
      includeRoughGrid: _pdfRoughGrid,
      includeQuotes: _pdfQuotes,
      outputPath: filename,
    ));
  }

  void _redraw() {
    final buf = StringBuffer();
    buf.write('\x1B[2J\x1B[H'); // clear screen

    buf.writeln();
    buf.writeln('${Ansi.bold}${Ansi.fgCyan}  ┏━━━━━━━━━━━━━━━━━━━━━┓${Ansi.reset}');
    buf.writeln('${Ansi.bold}${Ansi.fgCyan}  ┃      S U D O K U      ┃${Ansi.reset}');
    buf.writeln('${Ansi.bold}${Ansi.fgCyan}  ┗━━━━━━━━━━━━━━━━━━━━━┛${Ansi.reset}');
    buf.writeln();

    switch (_screen) {
      case _Screen.main:
        _drawMainMenu(buf);
      case _Screen.difficulty:
        _drawDifficultyMenu(buf);
      case _Screen.pdfOptions:
        _drawPdfOptions(buf);
    }

    stdout.write(buf);
  }

  void _drawMainMenu(StringBuffer buf) {
    for (var i = 0; i < _mainItems.length; i++) {
      final selected = i == _selectedIndex;
      final prefix = selected ? '${Ansi.fgCyan}${Ansi.bold}  > ' : '    ';
      buf.writeln('$prefix${_mainItems[i]}${Ansi.reset}');
    }
    buf.writeln();
    buf.writeln('${Ansi.dim}  Arrow keys to navigate, Enter to select${Ansi.reset}');
  }

  void _drawDifficultyMenu(StringBuffer buf) {
    buf.writeln('${Ansi.bold}  Select Difficulty${Ansi.reset}');
    buf.writeln();

    for (var i = 0; i < _difficulties.length; i++) {
      final selected = i == _difficultyIndex;
      final prefix = selected ? '${Ansi.fgCyan}${Ansi.bold}  > ' : '    ';
      buf.writeln('$prefix${_difficulties[i].label}${Ansi.reset}');
    }
    buf.writeln();
    buf.writeln('${Ansi.dim}  Arrow keys to navigate, Enter to select, Esc to go back${Ansi.reset}');
  }

  void _drawPdfOptions(StringBuffer buf) {
    buf.writeln('${Ansi.bold}  Export PDF${Ansi.reset}');
    buf.writeln();

    final values = [
      _difficulties[_pdfDifficultyIndex].label,
      '$_pdfCount',
      _pdfHints ? 'Yes' : 'No',
      _pdfRoughGrid ? 'Yes' : 'No',
      _pdfQuotes ? 'Yes' : 'No',
      '',
    ];

    for (var i = 0; i < _pdfOptionLabels.length; i++) {
      final selected = i == _pdfOptionIndex;
      final prefix = selected ? '${Ansi.fgCyan}${Ansi.bold}  > ' : '    ';

      if (i == _pdfOptionLabels.length - 1) {
        // Generate button
        buf.writeln('$prefix[${_pdfOptionLabels[i]}]${Ansi.reset}');
      } else {
        final arrows = selected ? ' < ${values[i]} >' : '   ${values[i]}';
        buf.writeln('$prefix${_pdfOptionLabels[i]}:$arrows${Ansi.reset}');
      }
    }
    buf.writeln();
    buf.writeln('${Ansi.dim}  Arrow keys to navigate/adjust, Enter to confirm, Esc to go back${Ansi.reset}');
  }
}

/// Classic line-based homepage for non-TTY terminals.
class ClassicHomepage {
  HomeAction show() {
    while (true) {
      print('');
      print('=== SUDOKU ===');
      print('');
      print('  1. New Game');
      print('  2. Load Game');
      print('  3. Export PDF');
      print('  4. View Stats');
      print('  5. Quit');
      print('');
      stdout.write('Choose (1-5): ');
      final choice = stdin.readLineSync()?.trim();

      switch (choice) {
        case '1' || 'n':
          final diff = _chooseDifficulty();
          if (diff != null) return NewGameAction(diff);
        case '2' || 'l':
          return LoadGameAction();
        case '3' || 'e':
          final action = _choosePdfOptions();
          if (action != null) return action;
        case '4' || 's':
          return ViewStatsAction();
        case '5' || 'q':
          return QuitAction();
        default:
          print('Invalid choice.');
      }
    }
  }

  Difficulty? _chooseDifficulty() {
    print('');
    print('Select difficulty:');
    for (var i = 0; i < Difficulty.values.length; i++) {
      print('  ${i + 1}. ${Difficulty.values[i].label}');
    }
    stdout.write('Choose (1-${Difficulty.values.length}): ');
    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) return null;
    final idx = int.tryParse(input);
    if (idx == null || idx < 1 || idx > Difficulty.values.length) {
      print('Invalid choice.');
      return null;
    }
    return Difficulty.values[idx - 1];
  }

  ExportPdfAction? _choosePdfOptions() {
    print('');
    print('--- Export PDF ---');

    // Difficulty
    print('Difficulty:');
    for (var i = 0; i < Difficulty.values.length; i++) {
      print('  ${i + 1}. ${Difficulty.values[i].label}');
    }
    stdout.write('Choose (1-${Difficulty.values.length}) [3]: ');
    var input = stdin.readLineSync()?.trim();
    final diffIdx = (input != null && input.isNotEmpty ? int.tryParse(input) : 3) ?? 3;
    if (diffIdx < 1 || diffIdx > Difficulty.values.length) {
      print('Invalid choice.');
      return null;
    }
    final difficulty = Difficulty.values[diffIdx - 1];

    // Count
    stdout.write('Number of puzzles (1-20) [6]: ');
    input = stdin.readLineSync()?.trim();
    final count = (input != null && input.isNotEmpty ? int.tryParse(input) : 6) ?? 6;
    if (count < 1 || count > 20) {
      print('Invalid count.');
      return null;
    }

    // Hints
    stdout.write('Include solve-order hints? (y/n) [y]: ');
    input = stdin.readLineSync()?.trim().toLowerCase();
    final hints = input != 'n';

    // Rough grid
    stdout.write('Include rough work grid? (y/n) [n]: ');
    input = stdin.readLineSync()?.trim().toLowerCase();
    final roughGrid = input == 'y';

    // Quotes
    stdout.write('Include quotes? (y/n) [y]: ');
    input = stdin.readLineSync()?.trim().toLowerCase();
    final quotes = input != 'n';

    final hintsTag = hints ? '_hints' : '';
    final gridTag = roughGrid ? '_grid' : '';
    final defaultName = 'sudoku_${difficulty.name}_${count}x$hintsTag$gridTag.pdf';

    stdout.write('Output file [$defaultName]: ');
    input = stdin.readLineSync()?.trim();
    final outputPath = (input != null && input.isNotEmpty) ? input : defaultName;

    return ExportPdfAction(
      difficulty: difficulty,
      count: count,
      includeHints: hints,
      includeRoughGrid: roughGrid,
      includeQuotes: quotes,
      outputPath: outputPath,
    );
  }
}

enum _Screen { main, difficulty, pdfOptions }
