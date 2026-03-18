import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_difficulty_summary_card.dart';
import 'stats_hints_card.dart';
import 'stats_leaderboard_card.dart';
import 'stats_overview_card.dart';
import 'stats_streaks_card.dart';
import 'stats_times_card.dart';

/// Composites stats cards into a scrollable body for a single tab.
class StatsTabBody extends StatelessWidget {
  final StatsStore store;
  final Difficulty? difficulty; // null = "All" tab

  const StatsTabBody({
    super.key,
    required this.store,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final games = difficulty != null
        ? store.gamesForDifficulty(difficulty!)
        : store.games;

    if (games.isEmpty) {
      return _emptyState(context);
    }

    final slice = StatsSlice(games);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatsOverviewCard(slice: slice),
        const SizedBox(height: 12),
        StatsStreaksCard(slice: slice),
        const SizedBox(height: 12),
        StatsTimesCard(slice: slice),
        const SizedBox(height: 12),
        if (difficulty == null) ...[
          StatsDifficultySummaryCard(store: store),
          const SizedBox(height: 12),
        ],
        if (difficulty != null) ...[
          StatsLeaderboardCard(store: store, difficulty: difficulty!),
          const SizedBox(height: 12),
        ],
        StatsHintsCard(slice: slice),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = difficulty?.label ?? 'any';
    return Center(
      child: Text(
        'No $label games yet.',
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
