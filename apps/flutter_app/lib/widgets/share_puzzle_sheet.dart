import 'dart:io';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sudoku_core/sudoku_core.dart';

/// Shows a bottom sheet with a QR code for sharing a puzzle.
void showSharePuzzleSheet({
  required BuildContext context,
  required Puzzle puzzle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _SharePuzzleSheet(puzzle: puzzle),
  );
}

class _SharePuzzleSheet extends StatefulWidget {
  final Puzzle puzzle;

  const _SharePuzzleSheet({required this.puzzle});

  @override
  State<_SharePuzzleSheet> createState() => _SharePuzzleSheetState();
}

class _SharePuzzleSheetState extends State<_SharePuzzleSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _sharing = false;

  String get _puzzleCode =>
      'S${widget.puzzle.difficulty.index}'
      '${widget.puzzle.initialBoard.toFlatString()}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.share_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Share Puzzle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.puzzle.difficulty.label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _QrCodePainter(data: _puzzleCode),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _shareImage,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.share, size: 18),
                    label: const Text('Share Image'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _puzzleCode));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puzzle code copied')),
      );
    }
  }

  Future<void> _shareImage() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/sudoku_puzzle.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Can you solve this ${widget.puzzle.difficulty.label} '
              'Sudoku puzzle?',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _QrCodePainter extends CustomPainter {
  final String data;

  _QrCodePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final bc = Barcode.qrCode();
    final elements = bc.make(data, width: size.width, height: size.height);

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final element in elements) {
      if (element is BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrCodePainter oldDelegate) => oldDelegate.data != data;
}
