import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_card.dart';

class StatsTimesCard extends StatelessWidget {
  final StatsSlice slice;

  const StatsTimesCard({super.key, required this.slice});

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      title: 'Solve Times',
      children: [
        StatRow('Best time', formatTime(slice.bestSolveTime)),
        StatRow('Average time', formatTime(slice.averageSolveTime.round())),
      ],
    );
  }
}
