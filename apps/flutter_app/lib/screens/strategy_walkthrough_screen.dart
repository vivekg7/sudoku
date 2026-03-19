import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../widgets/guide/walkthrough_board_widget.dart';

/// Step-through walkthrough for a single solving strategy.
class StrategyWalkthroughScreen extends StatefulWidget {
  final StrategyType strategy;

  const StrategyWalkthroughScreen({
    super.key,
    required this.strategy,
  });

  @override
  State<StrategyWalkthroughScreen> createState() =>
      _StrategyWalkthroughScreenState();
}

class _StrategyWalkthroughScreenState
    extends State<StrategyWalkthroughScreen> {
  late final StrategyGuide _guide;

  /// Current step index. 0 = intro (no highlights).
  int _step = 0;

  /// Total steps including the intro step.
  int get _totalSteps => _guide.steps.length + 1;

  @override
  void initState() {
    super.initState();
    _guide = strategyGuides[widget.strategy]!;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Permanent state (accumulates across all steps up to current)
    final placeCells = <(int, int, int)>{};
    final blockedCells = <(int, int)>{};
    final removedCandidates = <(int, int, int)>{};

    for (var i = 0; i < _step; i++) {
      final step = _guide.steps[i];
      placeCells.addAll(step.placeCells);
      blockedCells.addAll(step.blockedCells);
      // Candidates eliminated in previous steps are removed from the board
      if (i < _step - 1) {
        removedCandidates.addAll(step.eliminateCandidates);
      }
    }

    // Visual annotations (current step only)
    final currentStep = _step > 0 ? _guide.steps[_step - 1] : null;
    final highlightCells = currentStep?.highlightCells ?? const {};
    final highlightCandidates = currentStep?.highlightCandidates ?? const {};
    final eliminateCandidates = currentStep?.eliminateCandidates ?? const {};

    // Current caption
    final caption = _step == 0
        ? _guide.intro
        : _guide.steps[_step - 1].caption;

    return Scaffold(
      appBar: AppBar(title: Text(_guide.strategy.label)),
      body: SafeArea(
        child: Column(
          children: [
            // Board
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: WalkthroughBoardWidget(
                      board: _guide.board,
                      candidates: _guide.candidates,
                      highlightCells: highlightCells,
                      highlightCandidates: highlightCandidates,
                      eliminateCandidates: eliminateCandidates,
                      placeCells: placeCells,
                      blockedCells: blockedCells,
                      removedCandidates: removedCandidates,
                    ),
                  ),
                ),
              ),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    caption,
                    key: ValueKey(_step),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Step controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.outlined(
                    onPressed: _step > 0 ? _previousStep : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_step + 1} of $_totalSteps',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed:
                        _step < _totalSteps - 1 ? _nextStep : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousStep() => setState(() => _step--);
  void _nextStep() => setState(() => _step++);
}
