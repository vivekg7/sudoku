import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../state/game_state.dart';
import '../widgets/board_widget.dart';
import '../widgets/hint_panel.dart';
import '../widgets/number_pad.dart';
import '../widgets/quote_banner.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final StorageService storage;
  final SettingsService settings;
  final PuzzleEntry? resumeEntry;

  const GameScreen({
    super.key,
    required this.difficulty,
    required this.storage,
    required this.settings,
    this.resumeEntry,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState _gameState;
  final FocusNode _focusNode = FocusNode();
  String? _puzzleEntryId;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.maxHintLayer = widget.settings.hintLimit.maxLayer;
    _gameState.notesEnabled = widget.settings.notesEnabled;
    _gameState.assistLevel = widget.settings.assistLevel;
    _gameState.addListener(_restoreKeyboardFocus);

    if (widget.resumeEntry != null) {
      _puzzleEntryId = widget.resumeEntry!.id;
      _gameState.resumePuzzle(widget.resumeEntry!.puzzle);
    } else {
      _gameState.newGame(widget.difficulty);
    }
  }

  @override
  void dispose() {
    _gameState.removeListener(_restoreKeyboardFocus);
    _gameState.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _restoreKeyboardFocus() {
    if (mounted && _gameState.isPlaying && !_gameState.isPaused) {
      _focusNode.requestFocus();
    }
  }

  /// Save the current puzzle for later resumption.
  Future<void> _saveCurrentPuzzle() async {
    final puzzle = _gameState.puzzle;
    if (puzzle == null || puzzle.isSolved) return;

    _puzzleEntryId ??=
        DateTime.now().millisecondsSinceEpoch.toString();
    await widget.storage.savePuzzle(PuzzleEntry(
      id: _puzzleEntryId!,
      puzzle: puzzle,
    ));
  }

  /// Record game stats on completion.
  Future<void> _recordStats() async {
    if (_gameState.puzzle == null) return;
    await widget.storage.recordGame(_gameState.toGameStats());
    // Remove from saved games if it was saved.
    if (_puzzleEntryId != null) {
      await widget.storage.removePuzzle(_puzzleEntryId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveCurrentPuzzle();
      },
      child: ListenableBuilder(
        listenable: _gameState,
        builder: (context, _) {
          _checkSolved();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                _gameState.puzzle != null
                    ? 'Sudoku — ${_gameState.puzzle!.difficulty.label}'
                    : 'Sudoku',
              ),
              actions: [
                if (_gameState.puzzle != null) ...[
                  if (widget.settings.showTimer) ...[
                    _timerDisplay(),
                    _pauseButton(),
                  ],
                  const SizedBox(width: 8),
                ],
              ],
            ),
            body: _gameState.error != null
                ? _errorView()
                : _gameState.puzzle == null
                    ? const Center(child: CircularProgressIndicator())
                    : _gameState.isPaused
                        ? _pausedView()
                        : _gameView(),
          );
        },
      ),
    );
  }

  Widget _timerDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: Text(
          _gameState.formattedTime,
          style: const TextStyle(
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _gameState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _gameState.newGame(widget.difficulty),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pauseButton() {
    return IconButton(
      icon: Icon(_gameState.isPaused ? Icons.play_arrow : Icons.pause),
      onPressed: _gameState.togglePause,
      tooltip: _gameState.isPaused ? 'Resume' : 'Pause',
    );
  }

  Widget _pausedView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_outline,
              size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Paused',
            style: TextStyle(fontSize: 24, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _gameState.togglePause,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Widget _gameView() {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _gameState.deselect,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: BoardWidget(
                        gameState: _gameState,
                        boardLayout: widget.settings.boardLayout,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.settings.quotesEnabled)
              QuoteBanner(quoteId: _gameState.puzzle?.quoteId),
            HintPanel(gameState: _gameState),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NumberPad(
                gameState: _gameState,
                boardLayout: widget.settings.boardLayout,
                assistLevel: widget.settings.assistLevel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      _gameState.moveSelection(-1, 0);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _gameState.moveSelection(1, 0);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _gameState.moveSelection(0, -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _gameState.moveSelection(0, 1);
    } else if (key.keyId >= LogicalKeyboardKey.digit1.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      _gameState.enterValue(key.keyId - LogicalKeyboardKey.digit0.keyId);
    } else if (key.keyId >= LogicalKeyboardKey.numpad1.keyId &&
        key.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      _gameState.enterValue(key.keyId - LogicalKeyboardKey.numpad0.keyId);
    } else if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _gameState.clearCell();
    } else if (key == LogicalKeyboardKey.keyP) {
      _gameState.togglePencilMode();
    } else if (key == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _gameState.redo();
        } else {
          _gameState.undo();
        }
      }
    } else if (key == LogicalKeyboardKey.keyY) {
      if (HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed) {
        _gameState.redo();
      }
    } else if (key == LogicalKeyboardKey.keyH) {
      _gameState.requestHint();
    } else if (key == LogicalKeyboardKey.space) {
      _gameState.togglePause();
    }
  }

  void _checkSolved() {
    if (_gameState.isSolved && !_gameState.isSolvedNotified) {
      _gameState.markSolvedNotified();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recordStats();
        _showSolvedDialog();
      });
    }
  }

  void _showSolvedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Puzzle Solved!'),
        content: Text(
          'Difficulty: ${_gameState.puzzle!.difficulty.label}\n'
          'Time: ${_gameState.formattedTime}\n'
          'Hints used: ${_gameState.totalHints}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _puzzleEntryId = null;
              _gameState.newGame(widget.difficulty);
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}
