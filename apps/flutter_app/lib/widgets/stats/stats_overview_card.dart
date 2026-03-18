import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_card.dart';

class StatsOverviewCard extends StatelessWidget {
  final StatsSlice slice;

  const StatsOverviewCard({super.key, required this.slice});

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      title: 'Overview',
      children: [
        StatRow('Games played', '${slice.totalGames}'),
        StatRow('Completed', '${slice.completedGames}'),
        StatRow(
          'Completion rate',
          '${(slice.completionRate * 100).toStringAsFixed(0)}%',
        ),
        StatRow(
          'No-hint rate',
          '${(slice.noHintRate * 100).toStringAsFixed(0)}%',
        ),
      ],
    );
  }
}
