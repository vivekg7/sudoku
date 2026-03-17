import 'dart:math';

import 'package:flutter/material.dart';

const _solvedWords = [
  'Excellent!',
  'Outstanding!',
  'Brilliant!',
  'Well Done!',
  'Superb!',
  'Fantastic!',
  'Impressive!',
  'Magnificent!',
  'Splendid!',
  'Wonderful!',
  'Stellar!',
  'Flawless!',
  'Nailed It!',
  'Masterful!',
  'Top Notch!',
];

/// Shows the solved celebration dialog with a random praise word,
/// trophy icon, and optional confetti animation.
void showSolvedDialog({
  required BuildContext context,
  required String difficulty,
  required String time,
  required int hints,
  required bool animationsEnabled,
  required VoidCallback onHome,
  required VoidCallback onNewGame,
}) {
  final praise = _solvedWords[Random().nextInt(_solvedWords.length)];
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SolvedDialog(
      praise: praise,
      difficulty: difficulty,
      time: time,
      hints: hints,
      animationsEnabled: animationsEnabled,
      onHome: onHome,
      onNewGame: onNewGame,
    ),
  );
}

class _SolvedDialog extends StatefulWidget {
  final String praise;
  final String difficulty;
  final String time;
  final int hints;
  final bool animationsEnabled;
  final VoidCallback onHome;
  final VoidCallback onNewGame;

  const _SolvedDialog({
    required this.praise,
    required this.difficulty,
    required this.time,
    required this.hints,
    required this.animationsEnabled,
    required this.onHome,
    required this.onNewGame,
  });

  @override
  State<_SolvedDialog> createState() => _SolvedDialogState();
}

class _SolvedDialogState extends State<_SolvedDialog>
    with SingleTickerProviderStateMixin {
  AnimationController? _confettiController;
  List<_ConfettiPiece>? _particles;

  @override
  void initState() {
    super.initState();
    if (widget.animationsEnabled) {
      final rng = Random();
      _particles = List.generate(30, (_) => _ConfettiPiece.random(rng));
      _confettiController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3000),
      )..forward();
    }
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confettiColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];

    return Dialog(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Confetti layer.
          if (_confettiController != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController!,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles!,
                    progress: _confettiController!.value,
                    colors: confettiColors,
                  ),
                ),
              ),
            ),

          // Content layer.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.praise,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Difficulty: ${widget.difficulty}\n'
                  'Time: ${widget.time}\n'
                  'Hints used: ${widget.hints}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onHome();
                      },
                      child: const Text('Home'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onNewGame();
                      },
                      child: const Text('New Game'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti particles for the solved celebration.
// ---------------------------------------------------------------------------

class _ConfettiPiece {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final int colorIndex;
  final double rotation;
  final double rotationSpeed;
  final int shape; // 0 = rect, 1 = circle
  final double wobblePhase;
  final double wobbleAmp;

  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.colorIndex,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
    required this.wobblePhase,
    required this.wobbleAmp,
  });

  factory _ConfettiPiece.random(Random rng) {
    return _ConfettiPiece(
      x: rng.nextDouble(),
      startY: -0.3 + rng.nextDouble() * 0.5,
      speed: 0.6 + rng.nextDouble() * 0.8,
      size: 3.0 + rng.nextDouble() * 4.0,
      colorIndex: rng.nextInt(5),
      rotation: rng.nextDouble() * pi * 2,
      rotationSpeed: (rng.nextDouble() - 0.5) * 4,
      shape: rng.nextInt(2),
      wobblePhase: rng.nextDouble() * pi * 2,
      wobbleAmp: 0.02 + rng.nextDouble() * 0.03,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> particles;
  final double progress;
  final List<Color> colors;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.startY + progress * 1.5 * p.speed) * size.height;
      if (y < -p.size || y > size.height + p.size) continue;

      final x =
          (p.x + sin(progress * pi * 3 + p.wobblePhase) * p.wobbleAmp) *
              size.width;
      final rotation = p.rotation + progress * p.rotationSpeed * pi * 2;

      // Fade out in the last 30% of the animation.
      final opacity = progress < 0.7 ? 0.7 : (1.0 - progress) / 0.3 * 0.7;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = colors[p.colorIndex].withValues(alpha: opacity);

      if (p.shape == 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
