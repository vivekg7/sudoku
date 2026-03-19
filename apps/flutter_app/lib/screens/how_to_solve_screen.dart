import 'package:flutter/material.dart';

import '../widgets/guide/guide_grid_widget.dart';

class HowToSolveScreen extends StatelessWidget {
  const HowToSolveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('How to Solve Sudoku')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Section 1: What is Sudoku? ---
                _SectionHeader('What is Sudoku?'),
                const SizedBox(height: 8),
                _body(
                  "You get a 9×9 grid, split into 9 smaller 3×3 boxes. "
                  "Some numbers are already filled in for you — "
                  "the rest are up to you. Fill every empty cell "
                  "with a number from 1 to 9, and you've solved it. "
                  "Of course, you can't just put any number anywhere "
                  "— there's one rule to follow.",
                  colorScheme,
                ),

                const SizedBox(height: 28),

                // --- Section 2: The One Rule ---
                _SectionHeader('The One Rule'),
                const SizedBox(height: 8),
                _body(
                  'Each row, column, and box must have all the numbers '
                  'from 1 to 9 — no repeats. '
                  "That's the only rule in the entire game.",
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildOneRuleRowIllustration(context),
                const SizedBox(height: 16),
                _buildOneRuleBoxIllustration(context),

                const SizedBox(height: 28),

                // --- Section 3: One Puzzle, One Solution ---
                _SectionHeader('One Puzzle, One Solution'),
                const SizedBox(height: 8),
                _body(
                  'Every puzzle has exactly one solution. '
                  'This is the most important thing to understand: '
                  'there is no guessing in Sudoku.',
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _body(
                  'If you think two numbers could both fit in a cell, '
                  "it means there's more information on the board you "
                  "haven't used yet. Your job isn't to pick a number "
                  "that might work — it's to find the one that must "
                  'go there.',
                  colorScheme,
                ),

                const SizedBox(height: 28),

                // --- Section 4: How to Think ---
                _SectionHeader('How to Think'),
                const SizedBox(height: 8),
                _body(
                  "For any empty cell, ask: \"What can't go here?\" "
                  'Check its row — which numbers are already there? '
                  'Check its column and its box too. '
                  'Cross off everything you see. If only one number '
                  "is left — that's your answer.",
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildEliminationIllustration(context),

                const SizedBox(height: 28),

                // --- Section 5: Scanning ---
                _SectionHeader('Scanning'),
                const SizedBox(height: 8),
                _body(
                  'Pick a number — say 7. Look around the grid: '
                  'where is 7 already placed? Every 7 you find '
                  'rules out its entire row, column, and box '
                  'for placing another 7.',
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _body(
                  'Now look for a box that doesn\'t have a 7 yet. '
                  'If only one empty cell in that box isn\'t ruled out, '
                  'that\'s where 7 goes. '
                  'Do this for each number and you\'ll make steady progress.',
                  colorScheme,
                ),
                const SizedBox(height: 16),
                _buildScanningIllustration(context),

                const SizedBox(height: 28),

                // --- Section 6: When You're Stuck ---
                _SectionHeader("When You're Stuck"),
                const SizedBox(height: 8),
                _bulletPoint(
                  'Use pencil marks. ',
                  'In an empty cell, note down every number that could '
                  'still go there. As you fill in other cells, come back '
                  'and cross numbers off. Pencil marks help you spot '
                  "things you'd miss otherwise.",
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _bulletPoint(
                  'Use the hint system. ',
                  'The hint button needs a long press to activate — '
                  "a quick tap won't do anything. It starts with "
                  'a gentle nudge about which area to look at, '
                  'and only tells you more if you ask. '
                  "It's built to teach, not to spoil.",
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _bulletPoint(
                  "Don't guess. ",
                  "There's always a logical next step — you just "
                  "haven't found it yet. "
                  'Ask for a hint if you need a push.',
                  colorScheme,
                ),

                const SizedBox(height: 32),

                // --- Closing ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "That's all you need to get started. As you play harder "
                    'puzzles, you\'ll discover more advanced techniques — '
                    'the hint system will introduce them to you along the way.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Illustrations ---

  /// Section 2a: A single row with 8 givens and one highlighted empty cell.
  Widget _buildOneRuleRowIllustration(BuildContext context) {
    final accent = Theme.of(context).colorScheme.tertiaryContainer;
    final cells = [
      [
        const GuideCell.given('2'),
        const GuideCell.given('5'),
        const GuideCell.given('1'),
        const GuideCell.given('8'),
        GuideCell(value: '?', bgColor: accent, bold: true),
        const GuideCell.given('3'),
        const GuideCell.given('9'),
        const GuideCell.given('6'),
        const GuideCell.given('4'),
      ],
    ];
    return Center(
      child: GuideGridWidget(
        cells: cells,
        showBoxBorders: false,
        caption: 'This row has 1–9 except 7. The empty cell must be 7.',
      ),
    );
  }

  /// Section 2b: A 3×3 box with 8 givens and one highlighted empty cell.
  Widget _buildOneRuleBoxIllustration(BuildContext context) {
    final accent = Theme.of(context).colorScheme.tertiaryContainer;
    final cells = [
      [
        const GuideCell.given('3'),
        const GuideCell.given('9'),
        const GuideCell.given('1'),
      ],
      [
        const GuideCell.given('6'),
        GuideCell(value: '?', bgColor: accent, bold: true),
        const GuideCell.given('8'),
      ],
      [
        const GuideCell.given('2'),
        const GuideCell.given('4'),
        const GuideCell.given('7'),
      ],
    ];
    return Center(
      child: GuideGridWidget(
        cells: cells,
        showBoxBorders: false,
        caption: 'This box has 1–9 except 5. The empty cell must be 5.',
      ),
    );
  }

  /// Section 4: Full 9×9 grid with ~8 placed digits showing elimination.
  /// Target cell is (4,4) — centre of the grid. Its row, column, and box
  /// together contain 1,2,4,5,6,7,8,9 → only 3 remains.
  Widget _buildEliminationIllustration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final given = colorScheme.surfaceContainerHighest;
    final answer = colorScheme.tertiaryContainer;
    const e = GuideCell.empty();

    // 8 placed digits eliminate 1,2,4,5,6,7,8,9 from centre cell → answer is 3.
    final cells = [
      [e, e, e, e, GuideCell(value: '2', bgColor: given, bold: true), e, e, e, e],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, GuideCell(value: '4', bgColor: given, bold: true), e, GuideCell(value: '9', bgColor: given, bold: true), e, e, e],
      [GuideCell(value: '1', bgColor: given, bold: true), e, e, e, GuideCell(value: '3', bgColor: answer, bold: true), e, e, e, GuideCell(value: '7', bgColor: given, bold: true)],
      [e, e, e, GuideCell(value: '5', bgColor: given, bold: true), e, GuideCell(value: '6', bgColor: given, bold: true), e, e, e],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, e, GuideCell(value: '8', bgColor: given, bold: true), e, e, e, e],
    ];
    return Center(
      child: GuideGridWidget(
        cells: cells,
        cellSize: 34,
        caption:
            'The centre cell sees 1, 2, 4, 5, 6, 7, 8, 9\n'
            'in its row, column, and box — so it must be 3.',
      ),
    );
  }

  /// Section 5: Full 9×9 grid showing scanning. Four 7s placed in different
  /// boxes eliminate all but one cell in box 2 (rows 0–2, cols 3–5).
  /// Target cell: (1,5).
  Widget _buildScanningIllustration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final given = colorScheme.surfaceContainerHighest;
    final answer = colorScheme.tertiaryContainer;
    const e = GuideCell.empty();

    // 7 at (0,2) → eliminates row 0 in box 2
    // 7 at (2,8) → eliminates row 2 in box 2
    // 7 at (4,4) → eliminates col 4 in box 2
    // 7 at (7,3) → eliminates col 3 in box 2
    // Box 2 remaining: only (1,5) → answer!

    final cells = [
      [e, e, GuideCell(value: '7', bgColor: given, bold: true), e, e, e, e, e, e],
      [e, e, e, e, e, GuideCell(value: '7', bgColor: answer, bold: true), e, e, e],
      [e, e, e, e, e, e, e, e, GuideCell(value: '7', bgColor: given, bold: true)],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, e, GuideCell(value: '7', bgColor: given, bold: true), e, e, e, e],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, e, e, e, e, e, e],
      [e, e, e, GuideCell(value: '7', bgColor: given, bold: true), e, e, e, e, e],
      [e, e, e, e, e, e, e, e, e],
    ];
    return Center(
      child: GuideGridWidget(
        cells: cells,
        cellSize: 34,
        caption:
            'Scan for 7: the placed 7s eliminate their rows\n'
            'and columns — only one spot is left in the top-middle box.',
      ),
    );
  }

  // --- Helper widgets ---

  Widget _body(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _bulletPoint(
    String label,
    String text,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '•  ',
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
