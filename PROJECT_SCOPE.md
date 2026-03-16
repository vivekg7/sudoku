# Sudoku — Project Scope

> This document is for the project owner and Claude Code — not for end users.
> It defines what this project is, what it aims to be, and what it will never become.

## Goal

Build the most complete offline Sudoku app possible — a hobby project by a sudoku nerd, for sudoku nerds. The core philosophy: **teach the player to think**, don't just give them answers. Every feature should respect the player's effort and intelligence.

---

## Platforms

- **Mobile & Desktop** — Cross-platform app built with **Flutter** (Android, iOS, macOS, Windows, Linux).
- **CLI** — A standalone command-line interface app for terminal lovers.
- **Web** — TBD. Either Flutter web export (if the output is optimised enough) or a separate lightweight static site built with a minimal framework. Decision deferred until Flutter web quality can be evaluated.

---

## Core Features

### Puzzle Generation

- All puzzles are generated at runtime — **no hardcoded puzzles**, ever.
- **6 difficulty levels**, tuned by which solving strategies are required.
- Difficulty is determined by the techniques needed to solve, not just the number of givens.

### Solving Engine

- Implements **all known Sudoku solving strategies** (naked singles, hidden singles, pointing pairs, box/line reduction, naked/hidden pairs/triples/quads, X-Wing, Swordfish, Jellyfish, XY-Wing, XYZ-Wing, Unique Rectangles, Chains, Forcing Chains, etc.).
- The solver works step-by-step, identifying which strategy applies at each step — this is the backbone of the hint system.
- Backtracking is only a fallback for validation, not the primary solving path.

### Hint System (Multi-Layer)

- Hints are **not one click away**. They are intentionally buried to respect the player's effort.
- Hints are layered from vague to specific:
  - **Smallest hint**: Direction nudge — e.g., _"Look for 3 in box 4"_ (or row/column, whichever is most relevant — only one).
  - **Medium hint**: Strategy nudge — e.g., _"Try using X-Wing on row 2 and row 7"_ or _"There's a hidden pair in box 5"_.
  - **Largest hint**: Exact answer — e.g., _"You can write 3 in row 4, column 5"_.
- Each layer requires a deliberate action to reveal — progressive disclosure, not a single "show hint" button.

### Interactive Gameplay

- Fill cells, undo/redo, pencil marks / candidate notes.
- Immediate feedback on rule violations (duplicate in row/column/box).
- Highlight related cells (same row, column, box) on selection.
- Keyboard and touch navigation.

### PDF Export & Bulk Puzzle Creation

- Users can generate puzzles in bulk and **export as PDF** for printing.
- PDF layout:
  - Puzzle pages with grids.
  - Hints section at the end (after all puzzles).
  - Each puzzle includes a small **QR code** that, when scanned through the app, opens that exact puzzle for interactive play.

### Player Stats

- Track solve times, completion rates, streaks, and difficulty progression.
- **Track hint usage in detail**: how many hints taken, what layer of hint, what type of strategy was hinted.
- Stats help the player see their growth and identify which techniques they still struggle with.

### Save, Bookmarks & Data Portability

- Save in-progress puzzles and resume later.
- Bookmark puzzles to replay or revisit.
- Export and import puzzles, bookmarks, and stats — allows users to move data across platforms/devices manually (no cloud, no accounts).

### Timer

- Per-puzzle timer with pause support.
- Included in stats tracking.

---

## Future Improvements (May Be Added)

- Accessibility improvements (screen reader support, high contrast).
- Animation and transition polish.
- Theme and UI component polish — refine colours, spacing, and visual consistency across light/dark modes.
- Import a puzzle by clicking a photo or importing an image — OCR extracts the grid for interactive play.
- Puzzle sharing via links or text export.
- Practice mode for specific strategies (e.g., "give me puzzles that require X-Wing").
- Puzzle difficulty rating for user-imported puzzles.
- Localisation / multi-language support.
- **How to Solve Sudoku** — An in-app guide that teaches players how to approach and solve Sudoku puzzles from scratch.
- **Interactive Strategy Guide** — Walkthroughs for every solving strategy with interactive examples the player can step through.
- **Difficulty & Strategy Reference** — An in-app screen explaining all difficulty levels and which strategies are needed to solve each one.

---

## Implemented Extra Features

- **Dark mode / theme customisation** — Settings page with light/dark/system toggle and 6 accent color presets.
- **Inspirational quotes** — 36 hand-picked quotes across 3 tiers with weighted distribution per difficulty. Togglable in settings. See [PLAN_QUOTES.md](PLAN_QUOTES.md).

---

## Will Never Be Implemented

These are permanent, intentional exclusions.

- **Internet Requirement** — The app works fully offline. No server, no backend, no cloud sync, no accounts, no login.
- **Monetisation** — No ads, no in-app purchases, no premium tiers. Ever.
- **Analytics / Tracking** — No telemetry, no cookies, no third-party scripts. Zero data collection.
- **Social Features** — No leaderboards, friend lists, or sharing to social media.
- **Variant Sudoku** — Classic 9x9 only. No Killer, Thermo, Sandwich, Arrow, or other variants.
- **Multiplayer** — No real-time or turn-based multiplayer.
- **Puzzle Sizes Beyond 9x9** — Only standard grids.

---

## Tech Stack

**Language: Dart (everywhere)**

All sudoku logic lives in a shared `sudoku_core` Dart package. Every target — Flutter, CLI, and web — depends on this single package. One language, one test suite, one set of dependencies.

| Platform         | Technology                           | Status                                           |
| ---------------- | ------------------------------------ | ------------------------------------------------ |
| Core logic       | Pure Dart package (`sudoku_core`)    | Decided                                          |
| Mobile & Desktop | Flutter (depends on `sudoku_core`)   | Decided                                          |
| CLI              | Dart CLI (`dart compile exe`)        | Decided                                          |
| Web              | Flutter web or lightweight framework | Deferred — depends on Flutter web output quality |
| PDF export       | TBD                                  | Feature confirmed, library TBD                   |
| QR code          | TBD                                  | Feature confirmed, library TBD                   |

### Project Structure

```
sudoku/
├── packages/
│   └── sudoku_core/            # Pure Dart — all logic lives here
│       ├── lib/src/
│       │   ├── models/         # Board, Cell, Candidate, etc.
│       │   ├── generator/      # Puzzle generation
│       │   ├── solver/         # All solving strategies
│       │   ├── hint/           # Multi-layer hint engine
│       │   └── stats/          # Stats tracking logic
│       └── test/
├── apps/
│   ├── flutter_app/            # Flutter UI (depends on sudoku_core)
│   └── cli/                    # Dart CLI app (depends on sudoku_core)
└── PROJECT_SCOPE.md
```

---

## Design Principles

1. **Offline-first** — Everything works without internet.
2. **Respect the player** — Never make solving easier than the player asks for. Hints are layered and intentional.
3. **Teach, don't tell** — The hint system guides thinking, not just answers.
4. **No bloat** — No tracking, no ads, no accounts. Just sudoku.
5. **Completeness** — If a solving strategy exists, implement it. If a feature makes sense for offline sudoku, include it.

---

## License

GNU General Public License v3 (GPLv3).
