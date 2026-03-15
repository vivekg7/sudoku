import 'package:flutter/material.dart';

import '../state/game_state.dart';

class NumberPad extends StatelessWidget {
  final GameState gameState;

  const NumberPad({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Number buttons.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (var i = 1; i <= 9; i++)
                Expanded(child: _numberButton(context, i)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Action buttons.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                context,
                icon: Icons.undo,
                label: 'Undo',
                onPressed:
                    gameState.puzzle?.history.canUndo == true
                        ? gameState.undo
                        : null,
              ),
              _actionButton(
                context,
                icon: Icons.redo,
                label: 'Redo',
                onPressed:
                    gameState.puzzle?.history.canRedo == true
                        ? gameState.redo
                        : null,
              ),
              _actionButton(
                context,
                icon: Icons.backspace_outlined,
                label: 'Erase',
                onPressed: gameState.clearCell,
              ),
              _pencilButton(context),
              _actionButton(
                context,
                icon: Icons.lightbulb_outline,
                label: 'Hint',
                onPressed: gameState.maxHintLayer > 0
                    ? gameState.requestHint
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberButton(BuildContext context, int value) {
    final remaining = gameState.remainingCount(value);
    final isCompleted = remaining == 0;
    final isActive = gameState.activeNumber == value;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isCompleted
            ? colorScheme.surfaceContainerHighest
            : isActive
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(8),
          onTap: isCompleted ? null : () => gameState.enterValue(value),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: Icon(icon),
          onPressed: onPressed,
          color: colorScheme.onSurfaceVariant,
          disabledColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _pencilButton(BuildContext context) {
    final isActive = gameState.isPencilMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: Icon(
            Icons.edit,
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          onPressed: gameState.togglePencilMode,
          focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
          style: isActive
              ? IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer)
              : null,
        ),
        Text(
          'Notes',
          style: TextStyle(
            fontSize: 11,
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
