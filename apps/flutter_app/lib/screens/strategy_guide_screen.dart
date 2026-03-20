import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'difficulty_reference_screen.dart';
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

    // +1 for the difficulty reference link at the top
    final listItemCount = 1 + _itemCount(grouped);

    return Scaffold(
      appBar: AppBar(title: const Text('Strategy Guide')),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: listItemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _difficultyReferenceLink(context, colorScheme);
          }
          final item = _getItem(grouped, index - 1);
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

  Widget _difficultyReferenceLink(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DifficultyReferenceScreen(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.signal_cellular_alt,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Which strategies does each difficulty level require?',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
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
