import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import 'strategy_walkthrough_screen.dart';

/// Shows all difficulty levels with descriptions and their required strategies.
class DifficultyReferenceScreen extends StatelessWidget {
  const DifficultyReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Difficulty Levels')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: difficultyReference.length,
        itemBuilder: (context, index) {
          return _DifficultyCard(info: difficultyReference[index]);
        },
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final DifficultyInfo info;
  const _DifficultyCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty header
          Text(
            info.difficulty.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            info.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          // Strategy chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: info.strategies.map((strategy) {
              final hasGuide = strategyGuides.containsKey(strategy);
              return ActionChip(
                label: Text(
                  strategy.label,
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: hasGuide
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StrategyWalkthroughScreen(strategy: strategy),
                          ),
                        )
                    : null,
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
