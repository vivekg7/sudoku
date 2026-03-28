# Sudoku — Project Scope

> This document is for the project owner and Claude Code — not for end users.
> It defines what this project is, what it aims to be, and what it will never become.

## Goal

Build the most complete offline Sudoku app possible — a hobby project by a sudoku nerd, for sudoku nerds. The core philosophy: **teach the player to think**, don't just give them answers. Every feature should respect the player's effort and intelligence.

---

## Platforms

- **Mobile & Desktop** — Cross-platform app built with **Flutter** (Android, iOS, macOS, Windows, Linux).
- **CLI** — A standalone command-line interface app for terminal lovers.
- **Web** — TBD. Either Flutter web export (if the output is optimized enough) or a separate lightweight static site built with a minimal framework. Decision deferred until Flutter web quality can be evaluated.

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

- Hints are layered from vague to specific, with graduated friction that increases with each level:
  - **Smallest hint**: Direction nudge — e.g., _"Look for 3 in box 4"_. Requires a 1.5-second long-press on the Hint button.
  - **Medium hint**: Strategy nudge — e.g., _"Try using X-Wing on row 2 and row 7"_. Requires a 10-second cooldown, then a 1.5-second long-press on "More".
  - **Largest hint**: Exact answer — e.g., _"You can write 3 in row 4, column 5"_. Requires a 15-second cooldown, then a confirmation dialog ("Reveal the answer?").
- The friction is intentional: each layer is progressively harder to reach, mirroring that each layer gives progressively more away.

### Interactive Gameplay

- Fill cells, undo/redo, pencil marks / candidate notes.
- Optional feedback on rule violations (duplicate in row/column/box) — togglable via assist settings.
- Optional highlighting of related cells (same row, column, box, same digit) — togglable via assist settings.
- Keyboard and touch navigation.

### PDF Export & Bulk Puzzle Creation

- Users can generate puzzles in bulk and **export as PDF** for printing.
- PDF layout:
  - Puzzle pages with grids.
  - Solve-order hint grids at the end (after all puzzles) showing the sequence in which cells can be solved.
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
- Import a puzzle by clicking a photo or importing an image — OCR extracts the grid for interactive play.
- Puzzle sharing via links or text export.
- Practice mode for specific strategies (e.g., "give me puzzles that require X-Wing").
- Puzzle difficulty rating for user-imported puzzles.
- Localization / multi-language support.
- **Landscape gameplay layout** — Adapt the puzzle screen for landscape orientation, repositioning the board and controls side-by-side for comfortable play on tablets and wide screens.
- **Collapsible home screen navigation** — Reduce the home screen nav buttons to 4 (Saved, Stats, More, Settings). The "More" button expands inline to reveal the remaining items (PDF, Scan, Learn, Strategies) with a "Less" button to collapse. Settings always stays at the end. Animated transition to keep it smooth.
- **Storage scaling** —
  - Add an upper limit to how many in-progress games and bookmarks can be saved, keeping the puzzles file bounded.
  - Split stats into hot data (summary counts + top 20 games per difficulty) and 200-game archive chunks. Hot data loads on startup; archives load on demand.
  - When total data exceeds 20 MB (checked at most once a month), show an option in Settings to delete old archives. Deletion preserves the summary — aggregate counts (games played, etc.) are never reduced.

---

## Implemented Extra Features

- **Dark mode / theme customization** — Settings page with light/dark/AMOLED/system toggle and 9 accent color presets. Centralized theme with `SudokuColors` extension for consistent semantic colors across light, dark, and AMOLED modes.
- **Inspirational quotes** — 90 hand-picked quotes across 3 tiers (Light, Medium, Deep) displayed on the puzzle screen as a subtle banner. Each puzzle gets one quote bound at generation time via a seed-based weighted distribution — lighter quotes favor easier puzzles, deeper quotes favor harder ones, but any quote can appear at any difficulty. The quote ID is stored in the puzzle state so it persists across sessions. Togglable in settings. Full design rationale in [docs/PLAN_QUOTES.md](docs/PLAN_QUOTES.md).
- **Board layout selection** — Two board layouts selectable in settings: Circular (default, circular cells with tick-mark grid lines and no outer border) and Classic (traditional rectangular grid with full borders). Layout picker uses a bottom sheet with visual preview cards.
- **Animation & transition polish** — Smooth, intentional animations throughout gameplay: cell background color transitions (200ms), value placement scale+fade (150ms), hint panel entrance/exit with AnimatedSize (300ms) and level color crossfade (250ms), puzzle solved celebration with board scale pulse and accent overlay (700ms), board fade-in on new game (400ms), conflict flash pulse on error cells (300ms), number pad active button scale (150ms) and completed button fade (150ms), pencil mode toggle scale (150ms), and pause screen entrance with fade+scale (300ms). All animations use `easeOutCubic` curves and are togglable in Settings > Appearance (enabled by default). When disabled, all `Duration.zero` — identical to pre-animation behavior.
- **How to Solve Sudoku** — A beginner-friendly scrollable guide accessible from the home screen ("Learn" button). Covers what Sudoku is, the one rule, why there's no guessing, elimination thinking, scanning, and tips for when stuck (including hint system usage). Includes static grid illustrations (9×9, 3×3, single row) built with a lightweight `GuideGridWidget`. Home screen nav buttons use `Wrap` for responsive layout on narrow screens. Full design rationale in [docs/PLAN_HOW_TO_GUIDE.md](docs/PLAN_HOW_TO_GUIDE.md).
- **Difficulty & Strategy Reference** — A scrollable screen showing all 6 difficulty levels (Beginner → Master) with a description of what each level feels like to solve and the strategies it requires. Strategy names are tappable chips that open the corresponding walkthrough. Accessible from the Strategy Guide screen and the How to Solve guide. Data lives as constants in `sudoku_core`.
- **Interactive Strategy Guide** — Step-through walkthroughs for all 27 solving strategies, grouped by difficulty tier (Beginner → Master). Each walkthrough has a frozen example board with candidate marks and 6–8 narrated steps showing highlights, eliminations, and placements. Swipe navigation between steps with slide transitions. Accessible from the home screen ("Strategies" button), linked from the How to Solve guide, and strategy names in layer-2 hints are tappable links to the relevant walkthrough. Guide data lives as constants in `sudoku_core`; a generic `WalkthroughBoardWidget` renders any strategy. Full design rationale in [docs/PLAN_STRATEGY_GUIDE.md](docs/PLAN_STRATEGY_GUIDE.md).
- **Training Hub** — A dedicated "Train" section accessible from the home screen with bite-sized timed games that drill Sudoku fundamentals. Each game has three difficulty modes (Chill, Quick, Sprint) with progressive time decay, and a personal top-10 leaderboard per mode. Six games implemented: **Number Rush** (find the missing digit in a house), **Where Does N Go?** (find the only cell where a digit can be placed via hidden single elimination), **Candidate Fill** (mark every candidate in a region perfectly), **Bulls & Cows** (crack a secret 4-digit code with logic and elimination), **Spot the Pattern** (identify which solving strategy applies to a board with full candidates — multiple choice with adaptive distractors), and **Candidate Killer** (find every candidate elimination a strategy makes — tap them out with digit-first or cell-first input, partial credit for valid subsets, game over on any wrong elimination). Full design rationale in [docs/PLAN_TRAINING_GAMES.md](docs/PLAN_TRAINING_GAMES.md).
- **Puzzle Analysis** — Full solve breakdown accessible from the game screen after solving a puzzle. Shows step-by-step strategy usage, strategy summary with counts and difficulty scoring, solve-order heatmap, and bottleneck identification (cells requiring specific advanced strategies).
- **Erase-first mode** — Toggle erase mode from the number pad to quickly erase cells by tapping them directly, without selecting a cell first. Mirrors the number-first input pattern.
- **Auto-fill notes** — Long-press the Notes button to auto-fill all valid candidates for every empty cell in one action. Togglable in Settings > Gameplay.
- **Portrait-only orientation lock** — App locked to portrait mode on all platforms (Android, iOS, iPad) for a consistent gameplay experience.
- **Redesigned number pad** — Two-row layout (1–5 top, 6–9 + erase bottom) with larger buttons for easier tapping.

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
| PDF export       | `pdf` + `printing` (Dart/Flutter)    | Decided                                          |
| QR code          | `mobile_scanner` + `pdf` Barcode API | Decided                                          |

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
│       │   ├── quotes/         # Inspirational quote data & tiers
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
