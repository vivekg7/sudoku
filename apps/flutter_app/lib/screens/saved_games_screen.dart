import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/storage_service.dart';
import 'game_screen.dart';

class SavedGamesScreen extends StatelessWidget {
  final StorageService storage;

  const SavedGamesScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final inProgress = storage.puzzles.inProgress;
        final bookmarked = storage.puzzles.bookmarked;
        final isEmpty = inProgress.isEmpty && bookmarked.isEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Saved Games'), centerTitle: true),
          body: isEmpty
              ? const Center(
                  child: Text(
                    'No saved games yet.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (inProgress.isNotEmpty) ...[
                      _sectionHeader('In Progress'),
                      for (final entry in inProgress)
                        _puzzleTile(context, entry),
                      const SizedBox(height: 16),
                    ],
                    if (bookmarked.isNotEmpty) ...[
                      _sectionHeader('Bookmarked'),
                      for (final entry in bookmarked)
                        _puzzleTile(context, entry),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF757575),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          puzzle.difficulty.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$filled / $total cells filled  \u2022  ${_formatDate(entry.savedAt)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        leading: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: const Color(0xFFE0E0E0),
            color: const Color(0xFF1565C0),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                entry.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: entry.bookmarked
                    ? const Color(0xFFF9A825)
                    : const Color(0xFF757575),
              ),
              onPressed: () => storage.toggleBookmark(entry.id),
              tooltip: entry.bookmarked ? 'Remove bookmark' : 'Bookmark',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF757575)),
              onPressed: () => _confirmDelete(context, entry),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _resumeGame(context, entry),
      ),
    );
  }

  void _resumeGame(BuildContext context, PuzzleEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: entry.puzzle.difficulty,
          storage: storage,
          resumeEntry: entry,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PuzzleEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved game?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              storage.removePuzzle(entry.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
