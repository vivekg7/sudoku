import 'package:flutter/material.dart';

/// The app logo: a rounded square with a 3x3 grid hash and "9" in the center.
/// Automatically adapts to the current theme's primary color.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: CustomPaint(
        painter: _LogoPainter(
          lineColor: colorScheme.onPrimary,
          textColor: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color lineColor;
  final Color textColor;

  _LogoPainter({required this.lineColor, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final inset = s * 0.215;
    final lineWidth = s * 0.022;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // Grid lines: divide the inner area into thirds.
    final innerSize = s - 2 * inset;
    final third = innerSize / 3;

    // Vertical lines
    final x1 = inset + third;
    final x2 = inset + third * 2;
    canvas.drawLine(Offset(x1, inset), Offset(x1, s - inset), paint);
    canvas.drawLine(Offset(x2, inset), Offset(x2, s - inset), paint);

    // Horizontal lines
    final y1 = inset + third;
    final y2 = inset + third * 2;
    canvas.drawLine(Offset(inset, y1), Offset(s - inset, y1), paint);
    canvas.drawLine(Offset(inset, y2), Offset(s - inset, y2), paint);

    // "9" in the center cell
    final centerX = (x1 + x2) / 2;
    final centerY = (y1 + y2) / 2;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '9',
        style: TextStyle(
          color: textColor,
          fontSize: s * 0.155,
          fontWeight: FontWeight.w600,
          fontFamily: 'Helvetica',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor || textColor != oldDelegate.textColor;
}
