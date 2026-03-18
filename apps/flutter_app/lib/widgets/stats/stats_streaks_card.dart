import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_card.dart';

class StatsStreaksCard extends StatelessWidget {
  final StatsSlice slice;

  const StatsStreaksCard({super.key, required this.slice});

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      title: 'Streaks',
      children: [
        StatRow('Current streak', '${slice.currentStreak}'),
        StatRow('Longest streak', '${slice.longestStreak}'),
      ],
    );
  }
}
