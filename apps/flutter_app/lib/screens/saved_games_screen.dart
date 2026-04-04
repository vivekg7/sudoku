import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/share_puzzle_sheet.dart';
import 'game_screen.dart';

class SavedGamesScreen extends StatelessWidget {
  final StorageService storage;
  final SettingsService settings;

  const SavedGamesScreen({
    super.key,
    required this.storage,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final inProgress = storage.puzzles.inProgress;
        final bookmarked = storage.puzzles.bookmarked;
        final isEmpty = inProgress.isEmpty && bookmarked.isEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Saved Games')),
          body: isEmpty
              ? Center(
                  child: Text(
                    'No saved games yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (inProgress.isNotEmpty) ...[
                      _sectionHeader(context, 'In Progress'),
                      for (final entry in inProgress)
                        _puzzleTile(context, entry),
                      const SizedBox(height: 16),
                    ],
                    if (bookmarked.isNotEmpty) ...[
                      _sectionHeader(context, 'Bookmarked'),
                      for (final entry in bookmarked)
                        _puzzleTile(context, entry),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _puzzleTile(BuildContext context, PuzzleEntry entry) {
    final puzzle = entry.puzzle;
    final filled = puzzle.totalToFill - puzzle.emptyCellCount;
    final total = puzzle.totalToFill;
    final progress = total > 0 ? filled / total : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final sudokuColors = Theme.of(context).extension<SudokuColors>()!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _resumeGame(context, entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: colorScheme.outlineVariant,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          puzzle.difficulty.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$filled / $total cells filled  \u2022  ${_formatDate(entry.savedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => showSharePuzzleSheet(
                      context: context,
                      puzzle: entry.puzzle,
                    ),
                    tooltip: 'Share',
                  ),
                  IconButton(
                    icon: Icon(
                      entry.bookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 20,
                      color: entry.bookmarked
                          ? sudokuColors.bookmark
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => storage.toggleBookmark(entry.id),
                    tooltip:
                        entry.bookmarked ? 'Remove bookmark' : 'Bookmark',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _confirmDelete(context, entry),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resumeGame(BuildContext context, PuzzleEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: entry.puzzle.difficulty,
          storage: storage,
          settings: settings,
          resumeEntry: entry,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PuzzleEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 32,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Delete saved game?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        storage.removePuzzle(entry.id);
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
