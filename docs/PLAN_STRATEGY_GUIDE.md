# Interactive Strategy Guide — Plan

> Step-through walkthroughs for every Sudoku solving strategy, with a frozen example board, candidate marks, and narrated steps. Navigatable from the home screen, the How to Solve guide, and tappable strategy names in hints.

## Why

The app teaches strategies through hints during gameplay, but hints are contextual — you see them once and move on. There's no way to study a strategy on its own, revisit it, or understand it before encountering it in a puzzle. This guide fills that gap: a reference you can browse anytime and a learning tool you can reach mid-game when a hint mentions a strategy you don't know.

## Design Decisions

- **Step-through walkthrough (passive)** — The user taps Next/Previous to walk through the logic. Read-only, no interaction with the board. Teaches by showing, not by quizzing.
- **Flat list grouped by difficulty** — All 27 strategies (Backtracking excluded) listed on one scrollable screen with 6 difficulty section headers. Simple, scannable, no hidden content.
- **Candidates shown as pencil marks** — The walkthrough board renders small candidate digits in cells, matching how the player sees them in gameplay.
- **Data lives in sudoku_core** — Strategy guide content (boards, candidates, steps) is defined as Dart constants in the core package. One generic walkthrough widget in Flutter renders any strategy.
- **Three entry points** — Home screen button, link from How to Solve guide, tappable strategy names in layer-2 hints.
- **Built one strategy at a time, shipped all at once** — 6 phases by difficulty tier, each tested before moving on.

---

## Content Outline

Each strategy walkthrough has:

- **Intro** — One sentence explaining what the strategy is.
- **Board** — A frozen 9×9 puzzle state with placed digits and candidates. Just enough context to show the pattern.
- **Steps (6–8)** — Each step has a caption and visual changes (highlight cells, accent candidates, eliminate candidates, place digits). Steps build cumulatively so the user sees the logic unfold.

---

## Data Model (in sudoku_core)

New directory: `packages/sudoku_core/lib/src/guide/`

```dart
/// A complete walkthrough for one strategy.
class StrategyGuide {
  final StrategyType strategy;
  final String intro;
  final List<List<int>> board;          // 9×9, 0 = empty
  final List<Set<int>> candidates;      // 81 entries (row-major), candidate sets
  final List<GuideStep> steps;
}

/// One step in the walkthrough.
class GuideStep {
  final String caption;
  final Set<(int, int)> highlightCells;
  final Set<(int, int, int)> highlightCandidates;  // (row, col, digit)
  final Set<(int, int, int)> eliminateCandidates;   // (row, col, digit)
  final Set<(int, int, int)> placeCells;            // (row, col, digit)
}
```

A `Map<StrategyType, StrategyGuide> strategyGuides` registry provides lookup. All data is `const`.

---

## Screens

### StrategyGuideScreen (list)

```
Scaffold
├── AppBar(title: "Strategy Guide")
└── SingleChildScrollView
    └── Column
        ├── _DifficultyHeader("Beginner")
        ├── ListTile(Hidden Single, intro subtitle) → tap → walkthrough
        ├── ListTile(Naked Single, intro subtitle) → tap → walkthrough
        ├── _DifficultyHeader("Easy")
        ├── ... all 27 strategies grouped by tier ...
        ├── _DifficultyHeader("Master")
        └── ListTile(Sue de Coq, intro subtitle) → tap → walkthrough
```

### StrategyWalkthroughScreen (single strategy)

```
Scaffold
├── AppBar(title: strategy label)
└── Column
    ├── Expanded
    │   └── Center
    │       └── WalkthroughBoardWidget (9×9, read-only)
    │           - Placed digits (gray)
    │           - Candidate pencil marks in empty cells
    │           - Highlighted cells (accent color)
    │           - Eliminated candidates (red/strikethrough)
    │           - Placed digits from step (green)
    ├── Caption card
    │   └── Step caption text (animated crossfade between steps)
    └── Step controls
        └── Row: [Previous] [step "3 of 7"] [Next]
```

Step 0 shows the initial board with the intro as caption. Each subsequent step applies highlights/eliminations/placements cumulatively.

---

## Files to Create

| File                                                               | Purpose                                                 |
| ------------------------------------------------------------------ | ------------------------------------------------------- |
| `packages/sudoku_core/lib/src/guide/strategy_guide.dart`           | `StrategyGuide` and `GuideStep` data classes            |
| `packages/sudoku_core/lib/src/guide/strategy_guides.dart`          | Registry map + all guide data constants                 |
| `apps/flutter_app/lib/screens/strategy_guide_screen.dart`          | Strategy list screen                                    |
| `apps/flutter_app/lib/screens/strategy_walkthrough_screen.dart`    | Step-through walkthrough screen                         |
| `apps/flutter_app/lib/widgets/guide/walkthrough_board_widget.dart` | 9×9 read-only board with candidates and step highlights |

## Files to Modify

| File                                                    | Change                                                                |
| ------------------------------------------------------- | --------------------------------------------------------------------- |
| `packages/sudoku_core/lib/sudoku_core.dart`             | Export guide classes                                                  |
| `apps/flutter_app/lib/screens/home_screen.dart`         | Add "Strategies" nav button (between Learn and Settings)              |
| `apps/flutter_app/lib/screens/how_to_solve_screen.dart` | Make closing text link to strategy guide screen                       |
| `apps/flutter_app/lib/widgets/hint_panel.dart`          | Make strategy name tappable in layer-2 hints, navigate to walkthrough |

---

## Entry Points

1. **Home screen** — "Strategies" button with `Icons.menu_book_outlined` in the nav row, between Learn and Settings.
2. **How to Solve guide** — Closing card becomes tappable, navigates to strategy guide list.
3. **Hint panel** — Layer-2 hint text: strategy name becomes a tappable link. Pushes walkthrough screen onto nav stack (game screen stays underneath). Uses `Hint.step.strategy` to determine which strategy to open.

---

## WalkthroughBoardWidget

A new read-only 9×9 board widget purpose-built for the guide. Not a reuse of `BoardWidget` (too coupled to `GameState`).

**Renders:**

- Placed digits in cells (bold, gray background)
- Candidate pencil marks in empty cells (small digits in a 3×3 sub-grid within each cell)
- Step-based visual states per cell/candidate:
  - **Highlighted cell** — Accent background color
  - **Highlighted candidate** — Accent text color
  - **Eliminated candidate** — Red with strikethrough
  - **Placed digit** — Green background (answer)

**Props:**

- `board`: 9×9 grid of placed values
- `candidates`: 81 candidate sets
- `highlightCells`, `highlightCandidates`, `eliminateCandidates`, `placeCells` — from current step (accumulated)

Uses `SudokuColors` for theming consistency.

---

## Build Phases

Each phase: author guide data for the strategies, test walkthroughs, then move on.

| Phase | Difficulty | Strategies                                                                  | Count | Notes                                                                          |
| ----- | ---------- | --------------------------------------------------------------------------- | ----- | ------------------------------------------------------------------------------ |
| 1     | Beginner   | Hidden Single, Naked Single                                                 | 2     | Also builds all infrastructure (data model, screens, widgets, nav, hint links) |
| 2     | Easy       | Pointing Pair, Pointing Triple, Box/Line Reduction, Naked Pair, Hidden Pair | 5     |                                                                                |
| 3     | Medium     | Naked Triple, Hidden Triple, Naked Quad, Hidden Quad, X-Wing, Swordfish     | 6     |                                                                                |
| 4     | Hard       | Jellyfish, XY-Wing, XYZ-Wing, Unique Rectangle Types 1–4                    | 7     |                                                                                |
| 5     | Expert     | Simple Coloring, X-Chain, XY-Chain, AIC                                    | 4     |                                                                                |
| 6     | Master     | Forcing Chain, Almost Locked Set, Sue de Coq                                | 3     |                                                                                |

---

## Scope Boundaries

**In scope:**

- 27 strategy walkthroughs (all except Backtracking)
- Strategy list screen grouped by difficulty
- Step-through walkthrough screen with read-only board
- Candidate rendering in walkthrough board
- Three entry points (home, how-to-solve, hints)
- Guide data as constants in sudoku_core

**Out of scope:**

- Practice/try-it-yourself mode (future enhancement)
- Generating example boards automatically (all hand-crafted)
- Difficulty & Strategy Reference screen (separate feature in PROJECT_SCOPE.md — explains which strategies each difficulty requires, distinct from teaching how strategies work)
- Animations in walkthrough steps (keep it simple — instant transitions)
