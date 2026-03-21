import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../state/game_state.dart';
import 'hold_button.dart';

class NumberPad extends StatelessWidget {
  final GameState gameState;
  final BoardLayout boardLayout;
  final AssistToggles assistToggles;
  final bool animationsEnabled;

  const NumberPad({
    super.key,
    required this.gameState,
    required this.boardLayout,
    required this.assistToggles,
    this.animationsEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Number buttons.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (var i = 1; i <= 9; i++)
                    Expanded(child: _numberButton(context, i)),
                ],
              ),
            ),
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
              if (gameState.notesEnabled) _pencilButton(context),
              if (gameState.maxHintLayer > 0) _hintButton(context),
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
    final isCircular = boardLayout == BoardLayout.circular;
    final showCount = assistToggles.showRemainingCount && !isCompleted;

    final duration = animationsEnabled
        ? const Duration(milliseconds: 150)
        : Duration.zero;

    final color = isCompleted
        ? colorScheme.surfaceContainerHighest
        : isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow;

    final textColor = isCompleted
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : isActive
            ? colorScheme.primary
            : colorScheme.onSurface;

    final label = Text.rich(
      TextSpan(
        text: '$value',
        children: [
          if (showCount)
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Transform.translate(
                offset: const Offset(1, -2),
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
    );

    Widget button = isCircular
        ? AspectRatio(
            aspectRatio: 1.0,
            child: Material(
              color: color,
              shape: const CircleBorder(),
              child: InkWell(
                canRequestFocus: false,
                customBorder: const CircleBorder(),
                onTap: isCompleted ? null : () => gameState.enterValue(value),
                child: Center(child: label),
              ),
            ),
          )
        : Material(
            color: color,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              canRequestFocus: false,
              borderRadius: BorderRadius.circular(8),
              onTap: isCompleted ? null : () => gameState.enterValue(value),
              child: SizedBox(
                height: 48,
                child: Center(child: label),
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AnimatedScale(
        scale: isActive ? 1.08 : 1.0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isCompleted ? 0.5 : 1.0,
          duration: duration,
          child: button,
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
        const SizedBox(height: 2),
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
    final duration = animationsEnabled
        ? const Duration(milliseconds: 150)
        : Duration.zero;

    return GestureDetector(
      onLongPress: assistToggles.autoFillNotes
          ? () => _showAutoFillDialog(context)
          : null,
      child: AnimatedScale(
        scale: isActive ? 1.08 : 1.0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              icon: Icon(
                Icons.edit_outlined,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              onPressed: gameState.togglePencilMode,
              focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
              style: isActive
                  ? IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer)
                  : null,
            ),
            const SizedBox(height: 2),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoFillDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 32,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Fill all candidate notes?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will compute and fill valid candidates for '
                'every empty cell.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        gameState.autoFillAllNotes();
                      },
                      child: const Text('Fill'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintBadge(BuildContext context) {
    final totalHints = gameState.totalHints;
    if (totalHints == 0) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        constraints: const BoxConstraints(minWidth: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$totalHints',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _hintActionWithBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: null,
              color: colorScheme.onSurfaceVariant,
              disabledColor:
                  colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              focusNode:
                  FocusNode(skipTraversal: true, canRequestFocus: false),
            ),
            _hintBadge(context),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Hint',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _hintButton(BuildContext context) {
    // Disable the hold button while a hint is showing at a non-max layer
    // (advancing is done through "More" in the hint panel).
    final canRequestNew = gameState.currentHint == null ||
        gameState.hintLayer >= gameState.maxHintLayer;

    if (!canRequestNew) {
      return _hintActionWithBadge(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HoldButton(
          holdDuration: const Duration(milliseconds: 1500),
          onActivated: gameState.requestHint,
          builder: (context, progress) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AbsorbPointer(
                  child: IconButton.outlined(
                    icon: const Icon(Icons.lightbulb_outline),
                    onPressed: () {},
                    color: color,
                    focusNode: FocusNode(
                        skipTraversal: true, canRequestFocus: false),
                  ),
                ),
                if (progress > 0)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                _hintBadge(context),
              ],
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          'Hint',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
