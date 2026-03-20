import 'package:flutter/material.dart';
import 'package:sudoku_core/sudoku_core.dart';

import '../widgets/guide/walkthrough_board_widget.dart';
import 'strategy_walkthrough_screen.dart';

/// Full analysis of a puzzle: strategy breakdown, difficulty scoring,
/// step-by-step solution, solve-order heatmap, and bottleneck cells.
class AnalysisScreen extends StatefulWidget {
  final PuzzleAnalysis analysis;
  final Puzzle puzzle;

  /// Number of cells the player filled before analysis (0 if solved normally).
  final int playerFilledCount;

  /// Hint usage by strategy (empty if no hints used).
  final Map<StrategyType, int> hintStrategyCounts;

  /// Total hints used.
  final int totalHints;

  const AnalysisScreen({
    super.key,
    required this.analysis,
    required this.puzzle,
    this.playerFilledCount = 0,
    this.hintStrategyCounts = const {},
    this.totalHints = 0,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final Set<int> _expandedSteps = {};
  bool _allBoardsExpanded = false;

  PuzzleAnalysis get _analysis => widget.analysis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showPlayerProgress =
        widget.puzzle.completionType == CompletionType.analyzed &&
            widget.playerFilledCount > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle Analysis')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _StrategySummarySection(
            strategyCounts: _analysis.strategyCounts,
            hardestStrategy: _analysis.hardestStrategy,
            totalSteps: _analysis.steps.length,
          ),
          const SizedBox(height: 16),
          _DifficultyBreakdownSection(
            difficulty: _analysis.difficulty,
            breakdown: _analysis.scoreBreakdown,
          ),
          const SizedBox(height: 16),
          _buildStepByStepSection(colorScheme),
          const SizedBox(height: 16),
          _SolveOrderHeatmapSection(
            solveOrder: _analysis.solveOrder,
            puzzle: widget.puzzle,
          ),
          const SizedBox(height: 16),
          _BottleneckSection(
            bottlenecks: _analysis.bottlenecks,
            onTapStep: _scrollToStep,
          ),
          if (showPlayerProgress) ...[
            const SizedBox(height: 16),
            _PlayerProgressSection(
              playerFilledCount: widget.playerFilledCount,
              totalToFill: widget.puzzle.totalToFill,
              hintStrategyCounts: widget.hintStrategyCounts,
              totalHints: widget.totalHints,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepByStepSection(ColorScheme colorScheme) {
    return _SectionCard(
      title: 'Step-by-Step Solution',
      trailing: TextButton.icon(
        onPressed: () {
          setState(() {
            if (_allBoardsExpanded) {
              _expandedSteps.clear();
            } else {
              _expandedSteps.addAll(
                List.generate(_analysis.steps.length, (i) => i),
              );
            }
            _allBoardsExpanded = !_allBoardsExpanded;
          });
        },
        icon: Icon(
          _allBoardsExpanded
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 18,
        ),
        label: Text(_allBoardsExpanded ? 'Hide all' : 'Show all'),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _analysis.steps.length; i++)
            _StepCard(
              key: ValueKey(i),
              stepIndex: i,
              step: _analysis.steps[i],
              puzzle: widget.puzzle,
              allSteps: _analysis.steps,
              isExpanded: _expandedSteps.contains(i),
              hardestStrategy: _analysis.hardestStrategy,
              onToggleBoard: () {
                setState(() {
                  if (_expandedSteps.contains(i)) {
                    _expandedSteps.remove(i);
                  } else {
                    _expandedSteps.add(i);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  void _scrollToStep(int stepIndex) {
    setState(() {
      _expandedSteps.add(stepIndex);
    });
  }
}

// ---------------------------------------------------------------------------
// Section card wrapper
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Strategy Summary
// ---------------------------------------------------------------------------

class _StrategySummarySection extends StatelessWidget {
  final List<StrategyCount> strategyCounts;
  final StrategyType hardestStrategy;
  final int totalSteps;

  const _StrategySummarySection({
    required this.strategyCounts,
    required this.hardestStrategy,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      title: 'Strategy Summary',
      child: Column(
        children: [
          for (final sc in strategyCounts)
            _strategyRow(context, sc, colorScheme),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strategyRow(
    BuildContext context,
    StrategyCount sc,
    ColorScheme colorScheme,
  ) {
    final isHardest = sc.strategy == hardestStrategy;
    final hasGuide = strategyGuides.containsKey(sc.strategy);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: hasGuide
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StrategyWalkthroughScreen(
                            strategy: sc.strategy,
                          ),
                        ),
                      )
                  : null,
              child: Text(
                sc.strategy.label,
                style: TextStyle(
                  fontSize: 14,
                  color: hasGuide
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  decoration:
                      hasGuide ? TextDecoration.underline : null,
                  decorationColor: colorScheme.primary,
                  fontWeight: isHardest ? FontWeight.w600 : null,
                ),
              ),
            ),
          ),
          if (isHardest)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.star_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          Text(
            '${sc.count}',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: isHardest ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Difficulty Breakdown
// ---------------------------------------------------------------------------

class _DifficultyBreakdownSection extends StatelessWidget {
  final Difficulty difficulty;
  final DifficultyScoreBreakdown breakdown;

  const _DifficultyBreakdownSection({
    required this.difficulty,
    required this.breakdown,
  });

  static const _thresholds = [0, 12, 30, 55, 85, 130, 200];
  static const _labels = [
    'Beginner',
    'Easy',
    'Medium',
    'Hard',
    'Expert',
    'Master',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      title: 'Difficulty Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + score
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Score: ${breakdown.totalScore}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Score bar
          _buildScoreBar(colorScheme),
          const SizedBox(height: 16),
          // Components
          _componentRow(
            'Hardest strategy',
            '${breakdown.hardestWeight} x 3',
            breakdown.hardestContribution,
            colorScheme,
          ),
          _componentRow(
            'Advanced strategies',
            '${breakdown.advancedTotal} / 4',
            breakdown.advancedContribution,
            colorScheme,
          ),
          _componentRow(
            'Given penalty',
            '36 - ${breakdown.givenCount}',
            breakdown.givenPenalty,
            colorScheme,
          ),
          _componentRow(
            'Step penalty',
            '${breakdown.stepCount} - 30',
            breakdown.stepPenalty,
            colorScheme,
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${breakdown.totalScore}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${breakdown.givenCount} givens (${81 - breakdown.givenCount} to solve)',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(ColorScheme colorScheme) {
    final score = breakdown.totalScore;
    final maxDisplay = 200;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    // Background segments
                    Row(
                      children: [
                        for (var i = 0; i < _thresholds.length - 1; i++)
                          Expanded(
                            flex: _thresholds[i + 1] - _thresholds[i],
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4 + i * 0.1),
                                border: i < _thresholds.length - 2
                                    ? Border(
                                        right: BorderSide(
                                          color: colorScheme.outlineVariant,
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Score indicator
                    Positioned(
                      left: (score.clamp(0, maxDisplay) / maxDisplay) * width -
                          2,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                flex: _thresholds[i + 1] - _thresholds[i],
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _componentRow(
    String label,
    String formula,
    int value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              formula,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '= $value',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Step card (with collapsible board)
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  final int stepIndex;
  final SolveStep step;
  final Puzzle puzzle;
  final List<SolveStep> allSteps;
  final bool isExpanded;
  final StrategyType hardestStrategy;
  final VoidCallback onToggleBoard;

  const _StepCard({
    super.key,
    required this.stepIndex,
    required this.step,
    required this.puzzle,
    required this.allSteps,
    required this.isExpanded,
    required this.hardestStrategy,
    required this.onToggleBoard,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHardest = step.strategy == hardestStrategy;
    final hasGuide = strategyGuides.containsKey(step.strategy);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number
              SizedBox(
                width: 32,
                child: Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              // Strategy chip
              GestureDetector(
                onTap: hasGuide
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StrategyWalkthroughScreen(
                              strategy: step.strategy,
                            ),
                          ),
                        )
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isHardest
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    step.strategy.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isHardest
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Board toggle
              InkWell(
                onTap: onToggleBoard,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isExpanded
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Description
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              step.description,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          // Board (collapsible, computed on demand)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _StepBoardView(
                stepIndex: stepIndex,
                step: step,
                puzzle: puzzle,
                allSteps: allSteps,
              ),
            ),
          if (stepIndex < allSteps.length - 1)
            Divider(
              height: 8,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}

/// Renders the board state at a given step. Computed on-demand.
class _StepBoardView extends StatelessWidget {
  final int stepIndex;
  final SolveStep step;
  final Puzzle puzzle;
  final List<SolveStep> allSteps;

  const _StepBoardView({
    required this.stepIndex,
    required this.step,
    required this.puzzle,
    required this.allSteps,
  });

  @override
  Widget build(BuildContext context) {
    // Build the board state at this step by replaying all prior placements.
    final boardValues = puzzle.initialBoard.toValues();

    // Apply all placements from previous steps
    for (var i = 0; i < stepIndex; i++) {
      for (final p in allSteps[i].placements) {
        boardValues[p.row][p.col] = p.value;
      }
    }

    // Build empty candidate sets (we don't track full candidates here,
    // but we show involved cells and eliminations from the current step).
    final candidates = List.generate(81, (_) => <int>{});

    // Highlights for the current step
    final highlightCells = step.involvedCells
        .map((c) => (c.row, c.col))
        .toSet();
    final eliminateCandidates = step.eliminations
        .map((e) => (e.row, e.col, e.value))
        .toSet();
    final placeCells = step.placements
        .map((p) => (p.row, p.col, p.value))
        .toSet();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: AspectRatio(
          aspectRatio: 1,
          child: WalkthroughBoardWidget(
            board: boardValues,
            candidates: candidates,
            highlightCells: highlightCells,
            eliminateCandidates: eliminateCandidates,
            placeCells: placeCells,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Solve-Order Heatmap
// ---------------------------------------------------------------------------

class _SolveOrderHeatmapSection extends StatelessWidget {
  final List<int> solveOrder;
  final Puzzle puzzle;

  const _SolveOrderHeatmapSection({
    required this.solveOrder,
    required this.puzzle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final maxOrder = solveOrder.reduce((a, b) => a > b ? a : b);

    return _SectionCard(
      title: 'Solve Order',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                final row = index ~/ 9;
                final col = index % 9;
                final order = solveOrder[index];
                final isGiven = puzzle.initialBoard.getCell(row, col).isGiven;

                // Background color
                Color bgColor;
                Color textColor;
                if (isGiven) {
                  bgColor = colorScheme.surfaceContainerHighest;
                  textColor = colorScheme.onSurfaceVariant;
                } else if (order > 0) {
                  final t = order / maxOrder; // 0..1
                  // Single-hue gradient: light to dark accent
                  bgColor = isDark
                      ? colorScheme.primary.withValues(alpha: 0.15 + t * 0.55)
                      : colorScheme.primary.withValues(alpha: 0.08 + t * 0.45);
                  textColor = t > 0.6
                      ? (isDark ? colorScheme.onPrimary : Colors.white)
                      : colorScheme.onSurface;
                } else {
                  bgColor = colorScheme.surface;
                  textColor = colorScheme.onSurface;
                }

                // Borders
                final thinColor = isDark
                    ? colorScheme.outlineVariant
                    : const Color(0xFFBDBDBD);
                final thickColor =
                    isDark ? colorScheme.outline : const Color(0xFF424242);
                final thin = BorderSide(color: thinColor, width: 0.5);
                final thick = BorderSide(color: thickColor, width: 1.5);

                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: row % 3 == 0 ? thick : thin,
                      left: col % 3 == 0 ? thick : thin,
                      bottom: row == 8 ? thick : BorderSide.none,
                      right: col == 8 ? thick : BorderSide.none,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isGiven ? '' : (order > 0 ? '$order' : ''),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Bottleneck Cells
// ---------------------------------------------------------------------------

class _BottleneckSection extends StatelessWidget {
  final List<BottleneckCell> bottlenecks;
  final void Function(int stepIndex) onTapStep;

  const _BottleneckSection({
    required this.bottlenecks,
    required this.onTapStep,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (bottlenecks.isEmpty) {
      return _SectionCard(
        title: 'Bottleneck Cells',
        child: Text(
          'No advanced bottlenecks - this puzzle uses only basic strategies.',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return _SectionCard(
      title: 'Bottleneck Cells',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cells that required the most advanced techniques:',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final b in bottlenecks)
                InkWell(
                  onTap: () => onTapStep(b.stepIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R${b.row + 1}C${b.col + 1} = ${b.value}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          b.strategy.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Player Progress Summary
// ---------------------------------------------------------------------------

class _PlayerProgressSection extends StatelessWidget {
  final int playerFilledCount;
  final int totalToFill;
  final Map<StrategyType, int> hintStrategyCounts;
  final int totalHints;

  const _PlayerProgressSection({
    required this.playerFilledCount,
    required this.totalToFill,
    required this.hintStrategyCounts,
    required this.totalHints,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = totalToFill > 0
        ? (playerFilledCount / totalToFill * 100).round()
        : 0;

    return _SectionCard(
      title: 'Your Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You solved $playerFilledCount of $totalToFill cells ($pct%)',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalToFill > 0 ? playerFilledCount / totalToFill : 0,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
          if (totalHints > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Hints used: $totalHints',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (hintStrategyCounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final entry in hintStrategyCounts.entries)
                      Text(
                        '${entry.key.label}: ${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
