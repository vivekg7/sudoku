import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'package:cli/src/game.dart';
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
    ..addFlag('stats', negatable: false, help: 'Show accumulated stats');

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
    print('Sudoku CLI — play sudoku in the terminal.\n');
    print('Usage: sudoku [options]\n');
    print(parser.usage);
    exit(0);
  }

  final saveFile = args.option('save-file')!;

  if (args.flag('stats')) {
    _showStats(saveFile);
    exit(0);
  }

  Puzzle puzzle;

  if (args.option('load') != null) {
    puzzle = _loadGame(args.option('load')!);
  } else if (args.option('import') != null) {
    puzzle = _importPuzzle(args.option('import')!);
  } else {
    final difficultyName = args.option('difficulty')!;
    final difficulty = Difficulty.values.byName(difficultyName);
    puzzle = _generatePuzzle(difficulty);
  }

  final useClassic = args.flag('classic') || !stdout.hasTerminal;

  if (useClassic) {
    // Classic line-based mode
    final game = Game(puzzle);
    game.run();

    if (!puzzle.isSolved) {
      stdout.write('Save game? (y/n): ');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer == 'y') {
        _saveGame(puzzle, saveFile);
        print('Game saved to $saveFile.');
      }
    }

    final stats = game.toGameStats();
    _recordStats(stats, saveFile);
  } else {
    // TUI mode
    final game = TuiGame(puzzle);
    await game.run();

    // After TUI exits, terminal is restored — use line-based I/O for save prompt
    if (!puzzle.isSolved) {
      stdout.write('Save game? (y/n): ');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer == 'y') {
        _saveGame(puzzle, saveFile);
        print('Game saved to $saveFile.');
      }
    }

    final stats = game.toGameStats();
    _recordStats(stats, saveFile);
  }
}

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

  // Reconstruct solution board.
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

void _saveGame(Puzzle puzzle, String path) {
  final entry = PuzzleEntry(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    puzzle: puzzle,
  );
  final json = const JsonEncoder.withIndent('  ').convert(entry.toJson());
  File(path).writeAsStringSync(json);
}

Puzzle _loadGame(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    print('Error: save file not found: $path');
    exit(1);
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final entry = PuzzleEntry.fromJson(json);
  print('Loaded saved game (${entry.puzzle.difficulty.label}).');
  return entry.puzzle;
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

String _formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
