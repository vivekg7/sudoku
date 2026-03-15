import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/storage_service.dart';

class StatsScreen extends StatelessWidget {
  final StorageService storage;

  const StatsScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final stats = storage.stats;
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
          body: stats.totalGames == 0
              ? Center(
                  child: Text(
                    'No games played yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _overviewCard(context, stats),
                    const SizedBox(height: 12),
                    _streaksCard(context, stats),
                    const SizedBox(height: 12),
                    _timesCard(context, stats),
                    const SizedBox(height: 12),
                    _difficultyCard(context, stats),
                    const SizedBox(height: 12),
                    _hintsCard(context, stats),
                  ],
                ),
        );
      },
    );
  }

  Widget _overviewCard(BuildContext context, StatsStore stats) {
    return _card(
      context,
      title: 'Overview',
      children: [
        _statRow('Games played', '${stats.totalGames}'),
        _statRow('Completed', '${stats.completedGames}'),
        _statRow(
          'Completion rate',
          '${(stats.completionRate * 100).toStringAsFixed(0)}%',
        ),
        _statRow(
          'No-hint rate',
          '${(stats.noHintRate * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  Widget _streaksCard(BuildContext context, StatsStore stats) {
    return _card(
      context,
      title: 'Streaks',
      children: [
        _statRow('Current streak', '${stats.currentStreak}'),
        _statRow('Longest streak', '${stats.longestStreak}'),
      ],
    );
  }

  Widget _timesCard(BuildContext context, StatsStore stats) {
    return _card(
      context,
      title: 'Solve Times',
      children: [
        _statRow('Best time', _formatTime(stats.bestSolveTime)),
        _statRow('Average time', _formatTime(stats.averageSolveTime.round())),
      ],
    );
  }

  Widget _difficultyCard(BuildContext context, StatsStore stats) {
    final byDifficulty = stats.gamesByDifficulty;
    final avgByDifficulty = stats.averageTimeByDifficulty;
    if (byDifficulty.isEmpty) return const SizedBox.shrink();

    return _card(
      context,
      title: 'By Difficulty',
      children: [
        for (final d in Difficulty.values)
          if (byDifficulty.containsKey(d))
            _statRow(
              d.label,
              '${byDifficulty[d]} games, avg ${_formatTime(avgByDifficulty[d]?.round())}',
            ),
      ],
    );
  }

  Widget _hintsCard(BuildContext context, StatsStore stats) {
    final colorScheme = Theme.of(context).colorScheme;
    final byLevel = stats.totalHintsByLevel;
    final byStrategy = stats.totalHintsByStrategy;
    final totalHints =
        byLevel.values.fold<int>(0, (sum, count) => sum + count);
    if (totalHints == 0) {
      return _card(
        context,
        title: 'Hints',
        children: [_statRow('Total hints used', '0')],
      );
    }

    // Sort strategies by count descending, show top 5.
    final sortedStrategies = byStrategy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topStrategies = sortedStrategies.take(5);

    return _card(
      context,
      title: 'Hints',
      children: [
        _statRow('Total hints', '$totalHints'),
        for (final level in HintLevel.values)
          if (byLevel.containsKey(level))
            _statRow(
              '  ${level.name[0].toUpperCase()}${level.name.substring(1)}',
              '${byLevel[level]}',
            ),
        if (topStrategies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Most-hinted strategies',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final e in topStrategies)
            _statRow('  ${e.key.label}', '${e.value}'),
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
