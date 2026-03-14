import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../state/game_state.dart';

class HintPanel extends StatelessWidget {
  final GameState gameState;

  const HintPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final text = gameState.hintText;
    if (text == null) return const SizedBox.shrink();

    final level = gameState.currentHintLevel!;
    final layer = gameState.hintLayer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor(level),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(level), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(_icon(level), size: 18, color: _iconColor(level)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _label(level),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _iconColor(level),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
          if (layer < 3)
            TextButton(
              onPressed: gameState.requestHint,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('More', style: TextStyle(fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: gameState.dismissHint,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            color: const Color(0xFF757575),
          ),
        ],
      ),
    );
  }

  String _label(HintLevel level) => switch (level) {
        HintLevel.nudge => 'NUDGE',
        HintLevel.strategy => 'STRATEGY',
        HintLevel.answer => 'ANSWER',
      };

  IconData _icon(HintLevel level) => switch (level) {
        HintLevel.nudge => Icons.lightbulb_outline,
        HintLevel.strategy => Icons.psychology_outlined,
        HintLevel.answer => Icons.check_circle_outline,
      };

  Color _bgColor(HintLevel level) => switch (level) {
        HintLevel.nudge => const Color(0xFFFFF8E1),
        HintLevel.strategy => const Color(0xFFE3F2FD),
        HintLevel.answer => const Color(0xFFE8F5E9),
      };

  Color _borderColor(HintLevel level) => switch (level) {
        HintLevel.nudge => const Color(0xFFFFE082),
        HintLevel.strategy => const Color(0xFF90CAF9),
        HintLevel.answer => const Color(0xFFA5D6A7),
      };

  Color _iconColor(HintLevel level) => switch (level) {
        HintLevel.nudge => const Color(0xFFF9A825),
        HintLevel.strategy => const Color(0xFF1565C0),
        HintLevel.answer => const Color(0xFF2E7D32),
      };
}
