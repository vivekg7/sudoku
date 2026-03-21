import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'package:cli/src/game.dart';
import 'package:cli/src/homepage.dart';
import 'package:cli/src/input_handler.dart';
import 'package:cli/src/pdf_service.dart';
import 'package:cli/src/terminal.dart';
import 'package:cli/src/tui_game.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
    ..addFlag('classic',
        negatable: false, help: 'Use classic line-based input mode')
    ..addOption('difficulty',
        abbr: 'd',
        allowed: ['beginner', 'easy', 'medium', 'hard', 'expert', 'master'],
        defaultsTo: 'beginner',
        help: 'Puzzle difficulty')
    ..addOption('load',
        abbr: 'l', help: 'Load a saved game from a JSON file')
    ..addOption('save-file',
        abbr: 's',
        defaultsTo: 'sudoku_save.json',
        help: 'File path for saving games')
    ..addOption('import',
        help: 'Import a puzzle from an 81-character string')
    ..addFlag('stats', negatable: false, help: 'Show accumulated stats')
    ..addOption('pdf', help: 'Generate PDF puzzles to a file')
    ..addOption('count',
        defaultsTo: '6', help: 'Number of puzzles for PDF export')
    ..addFlag('hints',
        defaultsTo: true, help: 'Include solve-order hints in PDF')
    ..addFlag('rough-grid',
        negatable: false, help: 'Include rough work grid in PDF')
    ..addFlag('quotes', defaultsTo: true, help: 'Include quotes in PDF');

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print('Usage: sudoku [options]');
    print(parser.usage);
    exit(1);
  }

  if (args.flag('help')) {
    print('Sudoku CLI - play sudoku in the terminal.\n');
    print('Usage: sudoku [options]\n');
    print(parser.usage);
    exit(0);
  }

  final saveFile = args.option('save-file')!;
  final useClassic = args.flag('classic') || !stdout.hasTerminal;

  // --stats: show stats and exit.
  if (args.flag('stats')) {
    _showStats(saveFile);
    exit(0);
  }

  // --pdf: non-interactive PDF generation and exit.
  if (args.option('pdf') != null) {
    final outputPath = args.option('pdf')!;
    final difficultyName = args.option('difficulty')!;
    final difficulty = Difficulty.values.byName(difficultyName);
    final count = int.tryParse(args.option('count')!) ?? 6;

    await _runPdfExport(
      outputPath: outputPath,
      difficulty: difficulty,
      count: count.clamp(1, 20),
      includeHints: args.flag('hints'),
      includeRoughGrid: args.flag('rough-grid'),
      includeQuotes: args.flag('quotes'),
    );
    exit(0);
  }

  // Direct launch: --load, --import, or explicit --difficulty skip homepage.
  if (args.option('load') != null) {
    final entry = _loadGame(args.option('load')!);
    await _runGame(entry.puzzle, saveFile, useClassic, initialElapsedSeconds: entry.elapsedSeconds);
    exit(0);
  }
  if (args.option('import') != null) {
    final puzzle = _importPuzzle(args.option('import')!);
    await _runGame(puzzle, saveFile, useClassic);
    exit(0);
  }
  if (args.wasParsed('difficulty')) {
    final difficulty = Difficulty.values.byName(args.option('difficulty')!);
    final puzzle = _generatePuzzle(difficulty);
    await _runGame(puzzle, saveFile, useClassic);
    exit(0);
  }

  // No specific action: show interactive homepage.
  await _homepageLoop(saveFile, useClassic);
}

// -- Homepage loop --

Future<void> _homepageLoop(String saveFile, bool useClassic) async {
  if (useClassic) {
    await _classicHomepageLoop(saveFile);
    return;
  }

  // TUI mode: share a single Terminal + InputHandler across the session.
  final terminal = Terminal();
  final input = InputHandler();
  terminal.init();
  input.start();

  try {
    while (true) {
      final action = await TuiHomepage(terminal: terminal, input: input).show();

      switch (action) {
        case NewGameAction(:final difficulty):
          // Temporarily exit raw mode for puzzle generation output.
          terminal.dispose();
          final puzzle = _generatePuzzle(difficulty);
          terminal.init();
          input.start();
          final game = TuiGame(puzzle, terminal: terminal, input: input);
          await game.run();
          terminal.dispose();
          if (game.analysis != null) _printAnalysis(game.analysis!);
          if (!puzzle.isSolved) {
            stdout.write('Save game? (y/n): ');
            final answer = stdin.readLineSync()?.trim().toLowerCase();
            if (answer == 'y') {
              _saveGame(puzzle, saveFile, elapsedSeconds: game.elapsedSeconds);
              print('Game saved to $saveFile.');
            }
          }
          _recordStats(game.toGameStats(), saveFile);
          terminal.init();
          input.start();

        case LoadGameAction():
          terminal.dispose();
          final file = File(saveFile);
          if (!file.existsSync()) {
            print('No saved game found at $saveFile.');
            stdout.write('Press Enter to continue...');
            stdin.readLineSync();
            terminal.init();
            input.start();
            continue;
          }
          final entry = _loadGame(saveFile);
          terminal.init();
          input.start();
          final game = TuiGame(entry.puzzle, terminal: terminal, input: input, initialElapsedSeconds: entry.elapsedSeconds);
          await game.run();
          terminal.dispose();
          if (game.analysis != null) _printAnalysis(game.analysis!);
          if (!entry.puzzle.isSolved) {
            stdout.write('Save game? (y/n): ');
            final answer = stdin.readLineSync()?.trim().toLowerCase();
            if (answer == 'y') {
              _saveGame(entry.puzzle, saveFile, elapsedSeconds: game.elapsedSeconds);
              print('Game saved to $saveFile.');
            }
          }
          _recordStats(game.toGameStats(), saveFile);
          terminal.init();
          input.start();

        case ExportPdfAction(
            :final difficulty,
            :final count,
            :final includeHints,
            :final includeRoughGrid,
            :final includeQuotes,
            :final outputPath,
          ):
          terminal.dispose();
          await _runPdfExport(
            outputPath: outputPath,
            difficulty: difficulty,
            count: count,
            includeHints: includeHints,
            includeRoughGrid: includeRoughGrid,
            includeQuotes: includeQuotes,
          );
          stdout.write('Press Enter to continue...');
          stdin.readLineSync();
          terminal.init();
          input.start();

        case ViewStatsAction():
          terminal.dispose();
          _showStats(saveFile);
          stdout.write('\nPress Enter to continue...');
          stdin.readLineSync();
          terminal.init();
          input.start();

        case QuitAction():
          return;
      }
    }
  } finally {
    terminal.dispose();
    await input.stop();
  }
}

Future<void> _classicHomepageLoop(String saveFile) async {
  while (true) {
    final action = ClassicHomepage().show();

    switch (action) {
      case NewGameAction(:final difficulty):
        final puzzle = _generatePuzzle(difficulty);
        await _runGame(puzzle, saveFile, true);

      case LoadGameAction():
        final file = File(saveFile);
        if (!file.existsSync()) {
          print('No saved game found at $saveFile.');
          continue;
        }
        final entry = _loadGame(saveFile);
        await _runGame(entry.puzzle, saveFile, true, initialElapsedSeconds: entry.elapsedSeconds);

      case ExportPdfAction(
          :final difficulty,
          :final count,
          :final includeHints,
          :final includeRoughGrid,
          :final includeQuotes,
          :final outputPath,
        ):
        await _runPdfExport(
          outputPath: outputPath,
          difficulty: difficulty,
          count: count,
          includeHints: includeHints,
          includeRoughGrid: includeRoughGrid,
          includeQuotes: includeQuotes,
        );

      case ViewStatsAction():
        _showStats(saveFile);

      case QuitAction():
        return;
    }
  }
}

// -- Game runner --

Future<void> _runGame(Puzzle puzzle, String saveFile, bool useClassic, {int initialElapsedSeconds = 0}) async {
  if (useClassic) {
    final game = Game(puzzle, initialElapsedSeconds: initialElapsedSeconds);
    game.run();

    if (!puzzle.isSolved) {
      stdout.write('Save game? (y/n): ');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer == 'y') {
        _saveGame(puzzle, saveFile, elapsedSeconds: game.elapsedSeconds);
        print('Game saved to $saveFile.');
      }
    }

    final stats = game.toGameStats();
    _recordStats(stats, saveFile);
  } else {
    final game = TuiGame(puzzle, initialElapsedSeconds: initialElapsedSeconds);
    await game.run();

    if (game.analysis != null) {
      _printAnalysis(game.analysis!);
    }

    if (!puzzle.isSolved) {
      stdout.write('Save game? (y/n): ');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer == 'y') {
        _saveGame(puzzle, saveFile, elapsedSeconds: game.elapsedSeconds);
        print('Game saved to $saveFile.');
      }
    }

    final stats = game.toGameStats();
    _recordStats(stats, saveFile);
  }
}

// -- PDF export --

Future<void> _runPdfExport({
  required String outputPath,
  required Difficulty difficulty,
  required int count,
  required bool includeHints,
  required bool includeRoughGrid,
  required bool includeQuotes,
}) async {
  print('Generating $count ${difficulty.label} puzzles...');

  final service = CliPdfService();
  await service.generateAndSave(
    outputPath,
    count: count,
    difficulty: difficulty,
    includeRoughGrid: includeRoughGrid,
    includeHints: includeHints,
    includeQuotes: includeQuotes,
    onProgress: (completed) {
      stdout.write('\r  Puzzle $completed/$count');
    },
  );

  print('');
  final pages = count + (includeHints ? ((count + 3) ~/ 4) : 0);
  print('Wrote $outputPath ($count puzzles, $pages pages).');
}

// -- Helpers --

Puzzle _generatePuzzle(Difficulty difficulty) {
  print('Generating ${difficulty.label} puzzle...');
  final generator = PuzzleGenerator(random: Random());
  final puzzle = generator.generate(difficulty);
  if (puzzle == null) {
    print('Failed to generate a puzzle at this difficulty. Try again.');
    exit(1);
  }
  return puzzle;
}

Puzzle _importPuzzle(String flat) {
  if (flat.length != 81) {
    print('Error: puzzle string must be exactly 81 characters.');
    exit(1);
  }
  final board = Board.fromString(flat);
  final solver = Solver();
  final result = solver.solve(board);
  if (!result.isSolved) {
    print('Error: this puzzle has no solution.');
    exit(1);
  }

  final solutionBoard = board.clone();
  computeCandidates(solutionBoard);
  for (final step in result.steps) {
    for (final p in step.placements) {
      solutionBoard.getCell(p.row, p.col).setValue(p.value);
    }
  }

  return Puzzle(
    initialBoard: board,
    solution: solutionBoard,
    board: board.clone(),
    difficulty: result.difficulty,
  );
}

void _saveGame(Puzzle puzzle, String path, {int elapsedSeconds = 0}) {
  final entry = PuzzleEntry(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    puzzle: puzzle,
    elapsedSeconds: elapsedSeconds,
  );
  final json = const JsonEncoder.withIndent('  ').convert(entry.toJson());
  File(path).writeAsStringSync(json);
}

PuzzleEntry _loadGame(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    print('Error: save file not found: $path');
    exit(1);
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final entry = PuzzleEntry.fromJson(json);
  print('Loaded saved game (${entry.puzzle.difficulty.label}, '
      '${_formatSeconds(entry.elapsedSeconds)} elapsed).');
  return entry;
}

void _showStats(String saveFile) {
  final statsFile = File('${saveFile}_stats.json');
  if (!statsFile.existsSync()) {
    print('No stats recorded yet.');
    return;
  }
  final json =
      jsonDecode(statsFile.readAsStringSync()) as Map<String, dynamic>;
  final store = StatsStore.fromJson(json);

  print('--- Accumulated Stats ---');
  print('Games played: ${store.totalGames}');
  print('Completed: ${store.completedGames}');
  print(
      'Completion rate: ${(store.completionRate * 100).toStringAsFixed(1)}%');
  if (store.completedGames > 0) {
    print(
        'Average solve time: ${_formatSeconds(store.averageSolveTime.round())}');
    print('Best solve time: ${_formatSeconds(store.bestSolveTime!)}');
  }
  print('Current streak: ${store.currentStreak}');
  print('Longest streak: ${store.longestStreak}');

  final byDiff = store.gamesByDifficulty;
  if (byDiff.isNotEmpty) {
    print('Games by difficulty:');
    for (final e in byDiff.entries) {
      print('  ${e.key.label}: ${e.value}');
    }
  }

  final hintsByLevel = store.totalHintsByLevel;
  if (hintsByLevel.isNotEmpty) {
    print('Total hints:');
    for (final e in hintsByLevel.entries) {
      print('  ${e.key.name}: ${e.value}');
    }
  }
}

void _recordStats(GameStats stats, String saveFile) {
  final statsFile = File('${saveFile}_stats.json');
  StatsStore store;

  if (statsFile.existsSync()) {
    final json =
        jsonDecode(statsFile.readAsStringSync()) as Map<String, dynamic>;
    store = StatsStore.fromJson(json);
  } else {
    store = StatsStore();
  }

  store.record(stats);
  statsFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(store.toJson()),
  );
}

void _printAnalysis(PuzzleAnalysis analysis) {
  print('\n--- Puzzle Analysis ---');
  print('Difficulty: ${analysis.difficulty.label} '
      '(score: ${analysis.scoreBreakdown.totalScore})');
  print('Hardest strategy: ${analysis.hardestStrategy.label}');
  print('Total steps: ${analysis.steps.length}');
  print('');

  print('Strategies used:');
  for (final sc in analysis.strategyCounts) {
    print('  ${sc.strategy.label}: ${sc.count}x');
  }

  if (analysis.bottlenecks.isNotEmpty) {
    print('');
    print('Bottleneck cells:');
    for (final b in analysis.bottlenecks) {
      print('  R${b.row + 1}C${b.col + 1} = ${b.value} '
          '(${b.strategy.label})');
    }
  }

  final sb = analysis.scoreBreakdown;
  print('');
  print('Score breakdown:');
  print('  Hardest strategy weight: ${sb.hardestWeight} x3 = ${sb.hardestContribution}');
  print('  Advanced techniques: ${sb.advancedTotal} /4 = ${sb.advancedContribution}');
  print('  Given penalty (${sb.givenCount} givens): ${sb.givenPenalty}');
  print('  Step penalty (${sb.stepCount} steps): ${sb.stepPenalty}');
  print('  Total: ${sb.totalScore}');
}

String _formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
