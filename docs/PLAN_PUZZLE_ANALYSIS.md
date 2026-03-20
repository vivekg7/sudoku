# Puzzle Analysis — Plan

> Full post-mortem analysis of any puzzle: strategy breakdown, step-by-step solution walkthrough with interactive board highlights, difficulty scoring details, and solve-flow insights. Activating analysis completes the puzzle — the player trades their solve attempt for full understanding.

## Why

The app already teaches strategies in isolation (Strategy Guide) and gives contextual nudges during play (Hints). But there's no way to see the _complete picture_ of a puzzle — how all the strategies weave together, where the crux is, how the difficulty score was computed, or what the optimal solve path looks like. Analysis fills this gap: a deep, educational autopsy of the puzzle that rewards curiosity over completion.

---

## Core Behavior

- **Available during gameplay** — The player can trigger analysis at any point: mid-solve or after completion.
- **Irreversible** — Activating analysis on an incomplete puzzle fills all remaining cells with the solution and marks the game as complete (not as a "solved" win — as an "analyzed" completion). The puzzle can no longer be played.
- **Confirmation gate** — If the puzzle is incomplete, a confirmation dialog warns the player before proceeding:
  > "Analyze this puzzle? This will reveal the complete solution and end your solve attempt. You won't be able to continue playing this puzzle."
  >
  > [Cancel] [Analyze]
- **No gate if already solved** — If the puzzle is already complete, analysis opens directly with no warning.
- **Stats impact** — An analyzed-but-unsolved puzzle does not count as a win. It records as "analyzed" in stats (separate from "solved" and "abandoned").

---

## Analysis Screen — Sections

The analysis screen is a single scrollable page with distinct sections. Each section has a header and can be collapsed/expanded (all expanded by default).

### 1. Strategy Summary Table

A compact table showing every strategy the solver used, with counts.

```
Strategy              Count
─────────────────────────────
Hidden Single           24
Naked Single            12
Pointing Pair            3
X-Wing                   1
─────────────────────────────
Total steps             40
```

- Sorted by solve order (strategies that appear first in the solve are listed first), not alphabetically.
- Each strategy name is a tappable link → opens the corresponding Strategy Walkthrough screen.
- Row for the hardest strategy used is visually accented (this is the strategy that defines the puzzle's difficulty).

### 2. Difficulty Breakdown

Shows how the puzzle's difficulty score was computed — making the scoring system transparent.

- **Difficulty badge** — e.g., "Hard" with the tier color.
- **Score** — The numeric score (e.g., 78) with the tier thresholds shown on a segmented bar so the player can see where this puzzle falls within its tier and how close it is to the next.
- **Score components** — Breakdown of what contributed:
  - Hardest strategy weight (× 3)
  - Advanced strategy total (÷ 4)
  - Given penalty (36 - givenCount, if positive)
  - Step penalty (steps - 30, if positive)
- **Given count** — e.g., "28 givens (53 to solve)"

### 3. Step-by-Step Solution

The core of the analysis — a scrollable list of every solve step in order.

Each step is a card containing:

- **Step number** — "Step 1", "Step 2", etc.
- **Strategy badge** — Pill/chip with the strategy name (tappable → Strategy Walkthrough).
- **Description** — The human-readable description from `SolveStep.description` (e.g., "Hidden Single: R4C5 = 3 (only place for 3 in box 5)").
- **Board toggle** — A "Show board" / "Hide board" toggle button per step. When shown, renders a `WalkthroughBoardWidget` displaying:
  - The board state at that point in the solve (all prior placements applied).
  - Highlighted involved cells (from `SolveStep.involvedCells`).
  - Eliminated candidates (from `SolveStep.eliminations`).
  - Placed values (from `SolveStep.placements`).
- Board is hidden by default to keep the list scannable. The player expands boards for steps they want to study.

**Global board toggle** — A master toggle at the top of the section: "Show all boards" / "Hide all boards" for bulk control.

**Scroll behavior** — Simple `ListView` inside the scrollable page. No pagination. For a 40-step puzzle this is ~40 cards — manageable with lazy rendering (`ListView.builder`).

### 4. Solve-Order Heatmap

A single 9×9 grid colored by when each cell was solved.

- Given cells are neutral gray.
- Solved cells use a single-hue gradient (light→dark) showing solve order. Can revisit with multi-hue spectrum based on user feedback.
- Each cell shows its solve-order number (1, 2, 3... up to N).
- Gives an instant visual feel for the puzzle's flow — where solving starts, where it ends, where bottlenecks are.

### 5. Bottleneck Cells

Highlights the "crux" of the puzzle — the cells that required the most advanced techniques.

- Lists cells that needed the hardest strategy (or strategies above the median difficulty).
- Each entry shows: cell position (R4C5), strategy required, and the value placed.
- Tapping a bottleneck cell scrolls up to the corresponding step in the Step-by-Step section.

### 6. Player Progress Summary (only if puzzle was partially solved)

If the player made progress before analyzing, show a brief summary of their attempt.

- **Cells solved by player** — Count and percentage (e.g., "You solved 31 of 53 cells (58%)").
- **Hint usage recap** — How many hints were used, at what layers, for which strategies. (Data already tracked in `GameState.hintStrategyCounts`.)

---

## Data Model

### New in `sudoku_core`

```dart
/// Complete analysis of a solved puzzle.
class PuzzleAnalysis {
  final List<SolveStep> steps;
  final Map<StrategyType, int> strategyCounts;
  final StrategyType hardestStrategy;
  final int difficultyScore;
  final Difficulty difficulty;
  final DifficultyScoreBreakdown scoreBreakdown;
  final List<int> solveOrder;           // 81 entries, 0 = given, 1..N = solve order
  final List<BottleneckCell> bottlenecks;
}

/// Breakdown of difficulty score components.
class DifficultyScoreBreakdown {
  final int hardestWeight;              // Raw weight of hardest strategy
  final int hardestContribution;        // hardestWeight × 3
  final int advancedTotal;              // Sum of weights > 2
  final int advancedContribution;       // advancedTotal ÷ 4
  final int givenCount;
  final int givenPenalty;               // max(0, 36 - givenCount)
  final int stepCount;
  final int stepPenalty;                // max(0, stepCount - 30)
  final int totalScore;
}

/// A cell that required an advanced technique.
class BottleneckCell {
  final int row;
  final int col;
  final int value;
  final StrategyType strategy;
  final int stepIndex;                  // Index into steps list (for scroll-to)
}
```

### Analysis Generation

A new `PuzzleAnalyzer` class (or static method) in `sudoku_core`:

```dart
class PuzzleAnalyzer {
  /// Generate full analysis from a puzzle's solve result.
  static PuzzleAnalysis analyze(Puzzle puzzle);
}
```

This is a pure transformation of existing `SolveResult` data — no new solving needed. The solver already produces everything; this just aggregates and reshapes it.

### Puzzle State Extension

Add to `Puzzle`:

- `CompletionType completionType` — enum: `solved`, `analyzed`, `abandoned` (currently only `solved` is tracked implicitly; this makes it explicit).

---

## Screen Layout

```
AnalysisScreen (StatefulWidget)
└── Scaffold
    ├── AppBar(title: "Puzzle Analysis")
    └── SingleChildScrollView
        └── Column
            ├── _StrategySummarySection
            │   └── Table with strategy counts + tappable names
            ├── _DifficultyBreakdownSection
            │   ├── Difficulty badge + score
            │   ├── Segmented score bar
            │   └── Score component breakdown
            ├── _StepByStepSection
            │   ├── "Show all boards" / "Hide all boards" toggle
            │   └── Column of _StepCards (lazily built)
            │       └── _StepCard
            │           ├── Step number + strategy chip (tappable)
            │           ├── Description text
            │           └── Collapsible WalkthroughBoardWidget
            ├── _SolveOrderHeatmapSection
            │   └── WalkthroughBoardWidget variant with gradient coloring
            ├── _BottleneckSection
            │   └── List of bottleneck cells (tappable → scrolls to step)
            └── _PlayerProgressSection (conditional)
                ├── Cells solved count + percentage
                └── Hint usage recap
```

---

## Entry Point & Navigation

### Where the button lives

**Game screen AppBar** — An "Analysis" icon button (e.g., `Icons.analytics_outlined`) in the AppBar actions, next to the pause button.

- Always visible (not hidden behind a menu) — it's a primary feature.
- Tapping it triggers the confirmation flow (if puzzle incomplete) or navigates directly (if solved).

### Confirmation Dialog (incomplete puzzle)

```dart
showDialog(
  // ...
  AlertDialog(
    title: Text('Analyze this puzzle?'),
    content: Text(
      'This will reveal the complete solution and end your solve attempt. '
      'You won\'t be able to continue playing this puzzle.',
    ),
    actions: [
      TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
      FilledButton(child: Text('Analyze'), onPressed: () {
        // 1. Fill all remaining cells with solution values
        // 2. Mark puzzle as completionType = analyzed
        // 3. Stop timer
        // 4. Navigate to AnalysisScreen
      }),
    ],
  ),
);
```

### Post-analysis state

After analysis, returning to the game screen shows the completed board (all cells filled). The puzzle is no longer interactive — number pad and pencil mode are disabled. The "Analysis" button remains available to re-open the analysis screen.

---

## Files to Create

| File                                                         | Purpose                                                                     |
| ------------------------------------------------------------ | --------------------------------------------------------------------------- |
| `packages/sudoku_core/lib/src/analysis/puzzle_analysis.dart` | `PuzzleAnalysis`, `DifficultyScoreBreakdown`, `BottleneckCell` data classes |
| `packages/sudoku_core/lib/src/analysis/puzzle_analyzer.dart` | `PuzzleAnalyzer.analyze()` — transforms `SolveResult` into `PuzzleAnalysis` |
| `apps/flutter_app/lib/screens/analysis_screen.dart`          | Full analysis screen with all sections                                      |

## Files to Modify

| File                                                               | Change                                                                           |
| ------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| `packages/sudoku_core/lib/sudoku_core.dart`                        | Export analysis classes                                                          |
| `packages/sudoku_core/lib/src/models/puzzle.dart`                  | Add `CompletionType` enum and field                                              |
| `apps/flutter_app/lib/screens/game_screen.dart`                    | Add Analysis button to AppBar, confirmation dialog, fill-solution logic          |
| `apps/flutter_app/lib/state/game_state.dart`                       | Add `analyzePuzzle()` method (fills solution, stops timer, sets completion type) |
| `apps/flutter_app/lib/widgets/guide/walkthrough_board_widget.dart` | Add gradient background mode for solve-order heatmap (or create a thin wrapper)  |

---

## Reuse

Almost everything needed already exists:

| Component                       | Exists? | Reuse                                                           |
| ------------------------------- | ------- | --------------------------------------------------------------- |
| Step-by-step solve data         | Yes     | `Puzzle.solveResult.steps` — already computed during generation |
| Strategy counts                 | Trivial | Aggregate from `steps.map((s) => s.strategy)`                   |
| Board rendering with highlights | Yes     | `WalkthroughBoardWidget` — used as-is for per-step boards       |
| Tappable strategy links         | Yes     | Same pattern as `HintPanel` layer-2 links                       |
| Difficulty weights & thresholds | Yes     | `Solver.classifyPuzzle` scoring — extract components            |
| Hint usage tracking             | Yes     | `GameState.hintStrategyCounts` + `totalHints`                   |

**New work** is primarily:

- `PuzzleAnalysis` data class + `PuzzleAnalyzer` aggregation logic (~100 lines)
- `AnalysisScreen` UI layout (~400-500 lines)
- Confirmation flow + completion type tracking (~50 lines)
- Solve-order heatmap gradient rendering (~80 lines)

---

## Build Phases

| Phase | Scope                                                     | Notes                                                                                                     |
| ----- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1     | Core data model + analyzer                                | `PuzzleAnalysis`, `PuzzleAnalyzer`, `CompletionType`. Pure Dart, fully testable.                          |
| 2     | Analysis screen — Strategy Summary + Difficulty Breakdown | First two sections. Proves the screen structure and navigation.                                           |
| 3     | Analysis screen — Step-by-Step Solution                   | Core section with collapsible boards. Reuses `WalkthroughBoardWidget`.                                    |
| 4     | Analysis screen — Heatmap + Bottlenecks                   | Visual sections. Heatmap needs gradient rendering.                                                        |
| 5     | Player progress summary                                   | Conditional section. Shows cells solved count + hint usage recap. Lightweight, no solve-order tracking needed. |
| 6     | Entry point + confirmation flow                           | AppBar button, dialog, fill-solution logic, completion type persistence.                                  |

Phase 1 and 6 could be swapped — building the entry point first would let us test the flow end-to-end with a stub analysis screen.

---

## Scope Boundaries

**In scope:**

- Strategy summary table with counts and tappable links
- Difficulty score breakdown with visual bar
- Step-by-step solution with per-step collapsible boards
- Solve-order heatmap
- Bottleneck cell identification
- Player progress summary (if player made progress before analyzing)
- Confirmation dialog for incomplete puzzles
- Completion type tracking (solved / analyzed / abandoned)
- Analysis button in game screen AppBar

**Out of scope:**

- Exporting analysis as PDF or text
- Comparing analysis across multiple puzzles
- "Replay" mode (animated step-through of the solve)
- Strategy practice recommendations based on analysis ("you should practice X-Wing")
- Analysis of user-imported puzzles (future — depends on import feature)

---

## Resolved Decisions

1. **Completion type persistence** — Yes, add `CompletionType` enum. "Analyzed" puzzles should be visually distinct in the saved games list (different icon/badge).

2. **Player solve-order tracking** — Skipped. Too much complexity for limited value. The player progress section only shows cells-solved count and hint usage — no order comparison needed.

3. **Heatmap color scheme** — Single hue (light→dark) for now. Multi-hue spectrum can be revisited based on real user feedback.

4. **Step board state computation** — On-demand: compute board state when a step is expanded, not pre-computed. Most steps stay collapsed so this avoids holding 40+ board snapshots in memory. **Future optimization note:** if users frequently expand many steps or toggle "Show all boards", consider caching computed board states in an LRU cache or pre-computing lazily in a background isolate.
