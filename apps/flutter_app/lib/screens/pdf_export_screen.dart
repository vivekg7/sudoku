import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/pdf_service.dart';

class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  Difficulty _difficulty = Difficulty.medium;
  int _count = 6;
  Uint8List? _pdfBytes;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export PDF'),
        centerTitle: true,
      ),
      body: _pdfBytes != null ? _previewView() : _configView(),
    );
  }

  Widget _configView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Generate Puzzles',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 32),
            // Difficulty selector.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Difficulty: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                DropdownButton<Difficulty>(
                  value: _difficulty,
                  onChanged: (d) => setState(() => _difficulty = d!),
                  items: [
                    for (final d in Difficulty.values)
                      DropdownMenuItem(value: d, child: Text(d.label)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Count selector.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Puzzles: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _count > 1
                      ? () => setState(() => _count--)
                      : null,
                ),
                Text(
                  '$_count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _count < 20
                      ? () => setState(() => _count++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_generating)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Generating puzzles...',
                    style: TextStyle(color: Color(0xFF757575)),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate PDF'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _previewView() {
    return PdfPreview(
      build: (_) => _pdfBytes!,
      pdfFileName: 'sudoku_puzzles.pdf',
      allowPrinting: true,
      allowSharing: true,
      canChangePageFormat: false,
      canChangeOrientation: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _pdfBytes = null),
          tooltip: 'Back to settings',
        ),
      ],
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final bytes = await PdfService().generatePdf(_count, _difficulty);
      setState(() {
        _pdfBytes = bytes;
        _generating = false;
      });
    } catch (e) {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    }
  }
}
