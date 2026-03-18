import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_card.dart';

/// Grid showing games count + avg time per difficulty. All-tab only.
class StatsDifficultySummaryCard extends StatelessWidget {
  final StatsStore store;

  const StatsDifficultySummaryCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final byDifficulty = store.gamesByDifficulty;
    final avgByDifficulty = store.averageTimeByDifficulty;
    if (byDifficulty.isEmpty) return const SizedBox.shrink();

    return StatsCard(
      title: 'By Difficulty',
      children: [
        for (final d in Difficulty.values)
          if (byDifficulty.containsKey(d))
            StatRow(
              d.label,
              '${byDifficulty[d]} games, avg ${formatTime(avgByDifficulty[d]?.round())}',
            ),
      ],
    );
  }
}
