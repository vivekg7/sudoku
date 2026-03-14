import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../state/game_state.dart';
import '../widgets/board_widget.dart';
import '../widgets/number_pad.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState _gameState;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.addListener(_restoreKeyboardFocus);
    _gameState.newGame(widget.difficulty);
  }

  @override
  void dispose() {
    _gameState.removeListener(_restoreKeyboardFocus);
    _gameState.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// After any game state change (cell tap, number press, etc.), restore
  /// focus to the keyboard listener so arrow keys and shortcuts keep working.
  void _restoreKeyboardFocus() {
    if (mounted && _gameState.isPlaying && !_gameState.isPaused) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
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
            centerTitle: true,
            actions: [
              if (_gameState.puzzle != null) ...[
                _timerDisplay(),
                _pauseButton(),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: _gameState.puzzle == null
              ? const Center(child: CircularProgressIndicator())
              : _gameState.isPaused
                  ? _pausedView()
                  : _gameView(),
        );
      },
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

  Widget _pauseButton() {
    return IconButton(
      icon: Icon(_gameState.isPaused ? Icons.play_arrow : Icons.pause),
      onPressed: _gameState.togglePause,
      tooltip: _gameState.isPaused ? 'Resume' : 'Pause',
    );
  }

  Widget _pausedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pause_circle_outline, size: 64, color: Color(0xFF757575)),
          const SizedBox(height: 16),
          const Text(
            'Paused',
            style: TextStyle(fontSize: 24, color: Color(0xFF424242)),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: BoardWidget(gameState: _gameState),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NumberPad(gameState: _gameState),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

    // Arrow keys for navigation.
    if (key == LogicalKeyboardKey.arrowUp) {
      _gameState.moveSelection(-1, 0);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _gameState.moveSelection(1, 0);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _gameState.moveSelection(0, -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _gameState.moveSelection(0, 1);
    }
    // Number keys.
    else if (key.keyId >= LogicalKeyboardKey.digit1.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      _gameState.enterValue(key.keyId - LogicalKeyboardKey.digit0.keyId);
    } else if (key.keyId >= LogicalKeyboardKey.numpad1.keyId &&
        key.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      _gameState.enterValue(key.keyId - LogicalKeyboardKey.numpad0.keyId);
    }
    // Delete / Backspace to clear.
    else if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _gameState.clearCell();
    }
    // P for pencil mode.
    else if (key == LogicalKeyboardKey.keyP) {
      _gameState.togglePencilMode();
    }
    // Z for undo, Y for redo.
    else if (key == LogicalKeyboardKey.keyZ) {
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
    }
    // Space to pause/resume.
    else if (key == LogicalKeyboardKey.space) {
      _gameState.togglePause();
    }
  }

  void _checkSolved() {
    if (_gameState.isSolved && !_gameState.isSolvedNotified) {
      _gameState.markSolvedNotified();
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
          'Time: ${_gameState.formattedTime}',
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
              _gameState.newGame(widget.difficulty);
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}
