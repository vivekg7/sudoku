import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../screens/strategy_walkthrough_screen.dart';
import '../state/game_state.dart';
import '../theme/app_theme.dart';
import 'hold_button.dart';

class HintPanel extends StatelessWidget {
  final GameState gameState;
  final bool animationsEnabled;
  final VoidCallback? onRequestAnswer;

  const HintPanel({
    super.key,
    required this.gameState,
    this.animationsEnabled = false,
    this.onRequestAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (gameState.showCandidatePrompt) {
      return _buildCandidatePrompt(context);
    }

    final text = gameState.hintText;
    if (text == null) return const SizedBox.shrink();

    final level = gameState.currentHintLevel!;
    final layer = gameState.hintLayer;
    final sc = Theme.of(context).extension<SudokuColors>()!;

    final colorDuration = animationsEnabled
        ? const Duration(milliseconds: 250)
        : Duration.zero;

    return AnimatedContainer(
      duration: colorDuration,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor(level, sc),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(level, sc), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(_icon(level), size: 18, color: _accentColor(level, sc)),
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
                    color: _accentColor(level, sc),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                _buildHintText(context, text, level),
              ],
            ),
          ),
          if (layer < gameState.maxHintLayer) _moreButton(context),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: gameState.dismissHint,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Color _bgColor(HintLevel level, SudokuColors sc) => switch (level) {
        HintLevel.nudge => sc.nudgeBg,
        HintLevel.strategy => sc.strategyBg,
        HintLevel.answer => sc.answerBg,
      };

  Color _borderColor(HintLevel level, SudokuColors sc) => switch (level) {
        HintLevel.nudge => sc.nudgeBorder,
        HintLevel.strategy => sc.strategyBorder,
        HintLevel.answer => sc.answerBorder,
      };

  Color _accentColor(HintLevel level, SudokuColors sc) => switch (level) {
        HintLevel.nudge => sc.nudgeAccent,
        HintLevel.strategy => sc.strategyAccent,
        HintLevel.answer => sc.answerAccent,
      };

  Widget _buildHintText(BuildContext context, String text, HintLevel level) {
    // At strategy level, make the strategy name tappable if a guide exists.
    if (level == HintLevel.strategy) {
      final strategy = gameState.currentHint?.step.strategy;
      if (strategy != null && strategyGuides.containsKey(strategy)) {
        final name = strategy.label;
        final nameIndex = text.indexOf(name);
        if (nameIndex >= 0) {
          final before = text.substring(0, nameIndex);
          final after = text.substring(nameIndex + name.length);
          return Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13, height: 1.3),
              children: [
                if (before.isNotEmpty) TextSpan(text: before),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StrategyWalkthroughScreen(
                          strategy: strategy,
                        ),
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                if (after.isNotEmpty) TextSpan(text: after),
              ],
            ),
          );
        }
      }
    }

    return Text(text, style: const TextStyle(fontSize: 13, height: 1.3));
  }

  Widget _buildCandidatePrompt(BuildContext context) {
    final sc = Theme.of(context).extension<SudokuColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: sc.nudgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sc.nudgeBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 18, color: sc.nudgeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HINT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: sc.nudgeAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Fill in all pencil marks for better hints.',
                  style: TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: gameState.declineCandidatePrompt,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child:
                          const Text('Skip', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: gameState.acceptCandidatePrompt,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Auto-fill notes',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: gameState.dismissCandidatePrompt,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _moreButton(BuildContext context) {
    final cooldown = gameState.hintCooldownRemaining;
    final colorScheme = Theme.of(context).colorScheme;

    // Cooldown active: show countdown.
    if (cooldown > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '${cooldown}s',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    // Answer layer: regular tap triggers confirmation dialog.
    if (gameState.nextHintIsAnswer) {
      return TextButton(
        onPressed: onRequestAnswer,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('More', style: TextStyle(fontSize: 12)),
      );
    }

    // Strategy layer: hold to reveal.
    return HoldButton(
      holdDuration: const Duration(milliseconds: 1500),
      onActivated: gameState.requestHint,
      builder: (context, progress) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'More',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 1),
              SizedBox(
                width: 28,
                height: 1.5,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  color: colorScheme.primary,
                  minHeight: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
