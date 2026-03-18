import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'stats_card.dart';

class StatsHintsCard extends StatelessWidget {
  final StatsSlice slice;

  const StatsHintsCard({super.key, required this.slice});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final byLevel = slice.totalHintsByLevel;
    final byStrategy = slice.totalHintsByStrategy;
    final totalHints =
        byLevel.values.fold<int>(0, (sum, count) => sum + count);

    if (totalHints == 0) {
      return const StatsCard(
        title: 'Hints',
        children: [StatRow('Total hints used', '0')],
      );
    }

    final sortedStrategies = byStrategy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topStrategies = sortedStrategies.take(5);

    return StatsCard(
      title: 'Hints',
      children: [
        StatRow('Total hints', '$totalHints'),
        for (final level in HintLevel.values)
          if (byLevel.containsKey(level))
            StatRow(
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
            StatRow('  ${e.key.label}', '${e.value}'),
        ],
      ],
    );
  }
}
