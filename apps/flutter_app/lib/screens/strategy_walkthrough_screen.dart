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
  late final PageController _pageController;

  /// Current step index. 0 = intro (no highlights).
  int _step = 0;

  /// Total steps including the intro step.
  int get _totalSteps => _guide.steps.length + 1;

  @override
  void initState() {
    super.initState();
    _guide = strategyGuides[widget.strategy]!;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_guide.strategy.label)),
      body: SafeArea(
        child: Column(
          children: [
            // Board + caption in a swipeable PageView.
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalSteps,
                onPageChanged: (page) => setState(() => _step = page),
                itemBuilder: (context, index) => _buildPage(index, colorScheme),
              ),
            ),

            // Step controls (fixed at bottom).
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

  Widget _buildPage(int step, ColorScheme colorScheme) {
    // Permanent state (accumulates across all steps up to current).
    final placeCells = <(int, int, int)>{};
    final blockedCells = <(int, int)>{};
    final removedCandidates = <(int, int, int)>{};

    for (var i = 0; i < step; i++) {
      final s = _guide.steps[i];
      placeCells.addAll(s.placeCells);
      blockedCells.addAll(s.blockedCells);
      if (i < step - 1) {
        removedCandidates.addAll(s.eliminateCandidates);
      }
    }

    // Visual annotations (current step only).
    final currentStep = step > 0 ? _guide.steps[step - 1] : null;
    final highlightCells = currentStep?.highlightCells ?? const {};
    final highlightCandidates = currentStep?.highlightCandidates ?? const {};
    final eliminateCandidates = currentStep?.eliminateCandidates ?? const {};
    final colorACells = currentStep?.colorACells ?? const {};
    final colorBCells = currentStep?.colorBCells ?? const {};

    final caption = step == 0
        ? _guide.intro
        : _guide.steps[step - 1].caption;

    return Column(
      children: [
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
                  colorACells: colorACells,
                  colorBCells: colorBCells,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Center(
              child: Text(
                caption,
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
      ],
    );
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}
