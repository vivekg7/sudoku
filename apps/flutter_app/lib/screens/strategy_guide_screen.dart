import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'strategy_walkthrough_screen.dart';

/// Lists all strategies grouped by difficulty tier.
class StrategyGuideScreen extends StatelessWidget {
  const StrategyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final guides = allStrategyGuides;

    // Group by difficulty
    final grouped = <Difficulty, List<StrategyGuide>>{};
    for (final guide in guides) {
      grouped.putIfAbsent(guide.difficulty, () => []).add(guide);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Strategy Guide')),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _itemCount(grouped),
        itemBuilder: (context, index) {
          final item = _getItem(grouped, index);
          if (item is Difficulty) {
            return _DifficultyHeader(difficulty: item);
          }
          final guide = item as StrategyGuide;
          return ListTile(
            title: Text(guide.strategy.label),
            subtitle: Text(
              guide.intro,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _openWalkthrough(context, guide.strategy),
          );
        },
      ),
    );
  }

  int _itemCount(Map<Difficulty, List<StrategyGuide>> grouped) {
    var count = 0;
    for (final difficulty in Difficulty.values) {
      final guides = grouped[difficulty];
      if (guides == null || guides.isEmpty) continue;
      count += 1 + guides.length; // header + items
    }
    return count;
  }

  Object _getItem(Map<Difficulty, List<StrategyGuide>> grouped, int index) {
    var current = 0;
    for (final difficulty in Difficulty.values) {
      final guides = grouped[difficulty];
      if (guides == null || guides.isEmpty) continue;
      if (current == index) return difficulty;
      current++;
      for (final guide in guides) {
        if (current == index) return guide;
        current++;
      }
    }
    throw RangeError.index(index, grouped, 'index');
  }

  void _openWalkthrough(BuildContext context, StrategyType strategy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StrategyWalkthroughScreen(strategy: strategy),
      ),
    );
  }
}

class _DifficultyHeader extends StatelessWidget {
  final Difficulty difficulty;
  const _DifficultyHeader({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
