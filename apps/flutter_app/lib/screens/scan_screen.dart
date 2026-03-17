import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';

class ScanScreen extends StatefulWidget {
  final StorageService storage;
  final SettingsService settings;

  const ScanScreen({
    super.key,
    required this.storage,
    required this.settings,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _textController = TextEditingController();
  bool _showCamera = true;
  bool _processed = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Puzzle'),
        actions: [
          TextButton.icon(
            icon: Icon(_showCamera ? Icons.keyboard : Icons.camera_alt),
            label: Text(_showCamera ? 'Manual' : 'Camera'),
            onPressed: () => setState(() => _showCamera = !_showCamera),
          ),
        ],
      ),
      body: _showCamera ? _cameraView() : _manualView(),
    );
  }

  Widget _cameraView() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              formats: [BarcodeFormat.qrCode],
            ),
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt,
                        size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _showCamera = false),
                      child: const Text('Use manual entry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Point at a QR code on a printed puzzle',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _manualView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter puzzle code',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste the 83-character code from a printed puzzle.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'S2000050030...',
              labelText: 'Puzzle code',
            ),
            maxLines: 2,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _parsePuzzleCode(_textController.text.trim()),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _processed = true;
    _parsePuzzleCode(barcode!.rawValue!);
  }

  void _parsePuzzleCode(String code) {
    if (code.isEmpty) return;

    // Expected format: S<difficulty_index><81-char-flat-string>
    if (!code.startsWith('S') || code.length != 83) {
      _showError('Invalid puzzle code. Expected 83 characters starting with S.');
      _processed = false;
      return;
    }

    final diffIndex = int.tryParse(code[1]);
    if (diffIndex == null || diffIndex < 0 || diffIndex >= Difficulty.values.length) {
      _showError('Invalid difficulty in puzzle code.');
      _processed = false;
      return;
    }

    final boardStr = code.substring(2);
    if (boardStr.length != 81 || !RegExp(r'^[0-9.]+$').hasMatch(boardStr)) {
      _showError('Invalid board data in puzzle code.');
      _processed = false;
      return;
    }

    final difficulty = Difficulty.values[diffIndex];

    Board initialBoard;
    try {
      initialBoard = Board.fromString(boardStr);
    } catch (e) {
      _showError('Invalid board data in puzzle code.');
      _processed = false;
      return;
    }

    // Solve to get the solution.
    final solvedBoard = initialBoard.clone();
    if (!_backtrack(solvedBoard)) {
      _showError('Could not solve this puzzle. The code may be invalid.');
      _processed = false;
      return;
    }

    final puzzle = Puzzle(
      initialBoard: initialBoard,
      solution: solvedBoard,
      board: initialBoard.clone(),
      difficulty: difficulty,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: difficulty,
          storage: widget.storage,
          settings: widget.settings,
          resumeEntry: PuzzleEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            puzzle: puzzle,
          ),
        ),
      ),
    );
  }

  bool _backtrack(Board board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.getCell(r, c).isEmpty) {
          for (var v = 1; v <= 9; v++) {
            board.getCell(r, c).setValue(v);
            if (_isValidPlacement(board, r, c) && _backtrack(board)) {
              return true;
            }
            board.getCell(r, c).clearValue();
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidPlacement(Board board, int row, int col) {
    final value = board.getCell(row, col).value;
    for (final peer in board.peers(row, col)) {
      if (peer.value == value) return false;
    }
    return true;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
