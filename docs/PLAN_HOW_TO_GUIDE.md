# How to Solve Sudoku — In-App Guide Plan

> A beginner-friendly, scrollable guide that teaches players how to approach and solve Sudoku puzzles from scratch. Focuses on mindset and thinking approach — not specific strategies.

## Why

The app's philosophy is "teach the player to think." The hint system does this during gameplay, but there's nothing for someone who opens the app and doesn't know where to start. This guide bridges that gap — it teaches the *approach*, not the answers.

## Design Decisions

- **Single scrollable page** — short enough that pagination is overkill.
- **Text + static illustrations** — small grid diagrams built with Flutter widgets to illustrate spatial concepts. Not interactive, not images.
- **Accessible from home screen** — a nav button alongside Saved, Stats, PDF, Scan, Settings. Not buried in settings.
- **No auto-open on first install** — respects the player. The button is discoverable enough.
- **No strategy teaching** — this guide covers rules and mindset only. Specific strategies (Hidden Singles, X-Wing, etc.) belong in the future "Interactive Strategy Guide" and "Difficulty & Strategy Reference" features. A pointer to those is included at the end.

---

## Content Outline

### Section 1: What is Sudoku?

**Text:** Sudoku is a number puzzle played on a 9×9 grid. The grid is divided into 9 boxes (3×3 each). Some cells come pre-filled — these are called "givens." Your job is to fill every empty cell with a digit from 1 to 9.

**Illustration:** None — the player is looking at the app, they can see the grid.

### Section 2: The One Rule

**Text:** Every row, column, and box must contain the digits 1 through 9 exactly once. No duplicates allowed. That's it — one rule governs the entire game.

**Illustration:** A highlighted row (or 3×3 box) showing 8 filled digits and one empty cell, making it obvious what the missing digit must be. Visually mark the row/column/box boundaries.

### Section 3: One Puzzle, One Solution

**Text:** Every Sudoku puzzle in this app has exactly one valid solution. This is the most important thing to understand: **there is no guessing.** If you think two different digits could both go in a cell, that means you haven't found enough constraints yet — not that either one works. Every solving technique exists because of this fact. Your job isn't to pick a number that *might* work — it's to find the number that *must* go there.

**Illustration:** None — this is a conceptual point.

### Section 4: How to Think

**Text:** For any empty cell, ask: "What *can't* go here?" Look at the digits already placed in that cell's row, column, and box. Cross them off. If only one digit remains — that's your answer. This is called elimination, and it's the foundation of every Sudoku strategy, from the simplest to the most advanced.

**Illustration:** A small grid section (e.g., 4–5 cells of a row and a 3×3 box intersecting at one cell). Show the placed digits in the row, column, and box. Visually cross out those digits from the candidate list for the target cell, leaving one remaining. Label the step: "This cell sees 1, 2, 4, 5, 6, 7, 8, 9 — so it must be **3**."

### Section 5: Scanning

**Text:** Pick any digit (say 7). Scan the grid — where is 7 already placed? Each placed 7 eliminates its entire row, column, and box for another 7. If a box has no 7 yet, and all but one cell in that box is eliminated, then 7 must go in that remaining cell. Do this for every digit, and you'll make steady progress.

**Illustration:** A partial grid (2–3 boxes / rows) showing digit 7 placed in two rows. Highlight the eliminated cells in a third box, showing that only one cell remains where 7 can go. Use color/shading to show the elimination zones.

### Section 6: When You're Stuck

**Text:**
- **Use pencil marks.** In any empty cell, jot down all the digits that *could* go there (the candidates). As you place digits elsewhere, candidates shrink. Pencil marks make patterns visible that you'd miss otherwise.
- **Use the hint system.** The hint button won't give anything away easily — you need to **long-press and hold** it to activate. It starts with a gentle nudge (which area to look at), and only reveals more if you deliberately ask for it. It's designed to teach you, not spoil the puzzle.
- **Don't guess.** If you're stuck, there's a logical path forward — you just haven't spotted it yet. The hint system will point you in the right direction.

**Illustration:** None — the concepts are self-explanatory and reference app UI the player already has.

### Closing

A brief sign-off: "That's all you need to get started. As you play harder puzzles, you'll discover more advanced techniques — the hint system will introduce them to you along the way."

*(When the Strategy Reference feature is built, add a link/button here: "Want to learn specific strategies? See the Strategy Guide.")*

---

## Implementation

### Files to Create

| File | Purpose |
|------|---------|
| `lib/screens/how_to_solve_screen.dart` | Main guide screen — `Scaffold` with `AppBar` + scrollable body |
| `lib/widgets/guide/` | Directory for illustration widgets |
| `lib/widgets/guide/guide_grid_widget.dart` | Reusable small grid illustration widget for sections 2, 4, 5 |

### Files to Modify

| File | Change |
|------|--------|
| `lib/screens/home_screen.dart` | Replace `SingleChildScrollView > Row` nav buttons with `Wrap` (centered). Add "Learn" button with `Icons.school` icon. |

### Home Screen Nav Button Layout Change

The current nav buttons use a horizontal `SingleChildScrollView` wrapping a `Row`. This scrolls on narrow screens but hides overflow.

**Change to:** `Wrap` widget with `alignment: WrapAlignment.center` and `spacing`/`runSpacing` set to match current button gaps (16px horizontal, 12px vertical). This makes buttons flow naturally to a second row on narrow screens, always centered. Remove the `SingleChildScrollView`.

### HowToSolveScreen Structure

```
Scaffold
├── AppBar(title: "How to Solve Sudoku")
└── SingleChildScrollView
    └── Padding
        └── Column(crossAxisAlignment: start)
            ├── _SectionHeader("What is Sudoku?")
            ├── _SectionBody(text)
            ├── SizedBox(height: 24)
            ├── _SectionHeader("The One Rule")
            ├── _SectionBody(text)
            ├── GuideGridWidget(...) // row/box illustration
            ├── SizedBox(height: 24)
            ├── _SectionHeader("One Puzzle, One Solution")
            ├── _SectionBody(text)
            ├── SizedBox(height: 24)
            ├── _SectionHeader("How to Think")
            ├── _SectionBody(text)
            ├── GuideGridWidget(...) // elimination illustration
            ├── SizedBox(height: 24)
            ├── _SectionHeader("Scanning")
            ├── _SectionBody(text)
            ├── GuideGridWidget(...) // scanning illustration
            ├── SizedBox(height: 24)
            ├── _SectionHeader("When You're Stuck")
            ├── _SectionBody(text)
            └── _ClosingText()
```

### GuideGridWidget

A lightweight, purpose-built widget for small illustrative Sudoku grids. **Not** a reuse of `BoardWidget` — that's too heavy and coupled to game state.

**Props:**
- `cells`: 2D list of cell data (value, highlight color, annotation)
- `size`: grid dimensions (e.g., 9×1 for a row, 3×3 for a box, or a partial grid)
- `highlights`: which cells to shade/color for emphasis
- `annotations`: optional labels ("must be 3", crossed-out digits)

**Styling:**
- Uses `SudokuColors` from the app theme for consistency
- Thin borders matching the board aesthetic
- Accent color for highlighted/answer cells
- `onSurfaceVariant` for regular digits, muted for eliminated digits

**Built with:** `Table` + `Container` cells, or `CustomPaint` if border control needs it. Keep it simple — these are small (5–9 cells), not full 81-cell grids.

### Navigation

- Standard `Navigator.of(context).push(MaterialPageRoute(...))` from home screen — same pattern as every other screen.
- No dependencies needed (no `storage`, no `settings`) — the screen is purely static content.

---

## Scope Boundaries

**In scope:**
- The 6 content sections described above
- 3 static grid illustrations (sections 2, 4, 5)
- Home screen "Learn" button + Wrap layout fix
- Consistent theming with rest of app

**Out of scope (future features):**
- Interactive Strategy Guide (separate feature in PROJECT_SCOPE.md)
- Difficulty & Strategy Reference (separate feature in PROJECT_SCOPE.md)
- Interactive/playable example grids
- Animations within the guide
- Localization of guide content
