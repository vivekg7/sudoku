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
import '../widgets/solved_dialog.dart';

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
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.maxHintLayer = widget.settings.hintLimit.maxLayer;
    _gameState.notesEnabled = widget.settings.notesEnabled;
    _gameState.assistToggles = widget.settings.assistToggles;
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
    await widget.storage.recordGame(_gameState.toGameStats(
      showTimer: widget.settings.showTimer,
      boardLayout: widget.settings.boardLayout.name,
    ));
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
                    ? _gameState.puzzle!.difficulty.label
                    : '',
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
    final content = Column(
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
    );

    if (!widget.settings.animationsEnabled) return Center(child: content);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
        ),
        child: content,
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
                      child: _buildBoardArea(),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.settings.quotesEnabled)
              QuoteBanner(quoteId: _gameState.puzzle?.quoteId),
            AnimatedSize(
              duration: widget.settings.animationsEnabled
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: HintPanel(
                gameState: _gameState,
                animationsEnabled: widget.settings.animationsEnabled,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NumberPad(
                gameState: _gameState,
                boardLayout: widget.settings.boardLayout,
                assistToggles: widget.settings.assistToggles,
                animationsEnabled: widget.settings.animationsEnabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardArea() {
    final animate = widget.settings.animationsEnabled;

    Widget board = BoardWidget(
      gameState: _gameState,
      boardLayout: widget.settings.boardLayout,
      animationsEnabled: animate,
    );

    if (!animate) return board;

    // Board reveal: fade in when a new puzzle loads.
    board = TweenAnimationBuilder<double>(
      key: ValueKey(_gameState.puzzle!.initialBoard.toFlatString()),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: board,
    );

    // Celebration: scale pulse + accent overlay when solved.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _celebrating ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        if (t < 0.001) return child!;
        // Parabolic curve: peaks at t=0.5, zero at t=0 and t=1.
        final p = 4 * t * (1 - t);
        return Transform.scale(
          scale: 1.0 + 0.015 * p,
          child: Stack(
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12 * p),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: board,
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
        if (widget.settings.animationsEnabled) {
          setState(() => _celebrating = true);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) {
              setState(() => _celebrating = false);
              _showSolvedDialog();
            }
          });
        } else {
          _showSolvedDialog();
        }
      });
    }
  }

  void _showSolvedDialog() {
    showSolvedDialog(
      context: context,
      difficulty: _gameState.puzzle!.difficulty.label,
      time: _gameState.formattedTime,
      hints: _gameState.totalHints,
      animationsEnabled: widget.settings.animationsEnabled,
      onHome: () => Navigator.of(context).pop(),
      onNewGame: () {
        _puzzleEntryId = null;
        _gameState.newGame(widget.difficulty);
      },
    );
  }
}
