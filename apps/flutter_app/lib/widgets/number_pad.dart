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
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberButton(BuildContext context, int value) {
    final remaining = gameState.remainingCount(value);
    final isCompleted = remaining == 0;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isCompleted
            ? const Color(0xFFE0E0E0)
            : const Color(0xFFF5F5F5),
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
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF212121),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: Icon(icon),
          onPressed: onPressed,
          color: const Color(0xFF424242),
          disabledColor: const Color(0xFFBDBDBD),
          focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
        ),
      ],
    );
  }

  Widget _pencilButton(BuildContext context) {
    final isActive = gameState.isPencilMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: Icon(Icons.edit, color: isActive ? Colors.blue : const Color(0xFF424242)),
          onPressed: gameState.togglePencilMode,
          focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
          style: isActive
              ? IconButton.styleFrom(backgroundColor: const Color(0xFFE3F2FD))
              : null,
        ),
        Text(
          'Notes',
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.blue : const Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}
