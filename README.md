# Sudoku

A comprehensive, fully offline Sudoku app that doesn't just let you play — it teaches you how to think. Built with every known solving strategy, a multi-layer hint system, and no tracking, no ads, no internet required.

## Features

- **Smart Puzzle Generation** — Puzzles are generated on the fly across 6 difficulty levels, tuned by the solving strategies required — not just the number of givens.
- **Full Solving Engine** — Implements all known Sudoku solving strategies, from naked singles to forcing chains and ALS.
- **Multi-Layer Hints** — Hints guide your thinking, not hand you answers. From a gentle nudge ("look for 3 in box 4") to a strategy suggestion to the exact answer — you choose how much help you want.
- **Pencil Marks & Undo/Redo** — Full note-taking and move history support.
- **Number-First Input** — Tap a number first, then tap cells to fill — great for placing all instances of a digit quickly.
- **PDF Export** — Generate puzzles in bulk with optional rough work grids, solve-order hints at the back, and QR codes to open each puzzle in the app.
- **QR Scanner** — Scan printed puzzle QR codes to play them interactively.
- **Player Stats** — Track solve times, streaks, completion rates, and detailed hint usage to see which techniques you're mastering.
- **Save & Bookmark** — Save in-progress puzzles, bookmark favourites, and export/import all your data as JSON.
- **CLI App** — A standalone command-line interface with TUI and classic modes.

## Platforms

| Platform | Technology            | Status |
| -------- | --------------------- | ------ |
| Android  | Flutter               | Ready  |
| iOS      | Flutter               | Ready  |
| macOS    | Flutter               | Ready  |
| Windows  | Flutter               | Ready  |
| Linux    | Flutter               | Ready  |
| CLI      | Dart (`dart compile`) | Ready  |
| Web      | TBD                   | —      |

## Project Structure

```
sudoku/
├── packages/
│   └── sudoku_core/          # Pure Dart — all game logic
│       ├── lib/src/
│       │   ├── models/       # Board, Cell, Puzzle, Move, Difficulty
│       │   ├── generator/    # Puzzle generation with difficulty targeting
│       │   ├── solver/       # 27 solving strategies + backtracking
│       │   ├── hint/         # Multi-layer hint engine
│       │   └── stats/        # Stats, persistence, data export
│       └── test/
├── apps/
│   ├── flutter_app/          # Flutter UI (all platforms)
│   └── cli/                  # Terminal app (TUI + classic modes)
├── PROJECT_SCOPE.md
└── PLAN.md
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)
- [Dart SDK](https://dart.dev/get-dart) (3.11+, included with Flutter)

### Flutter App

```bash
cd apps/flutter_app

# Run on your current platform
flutter run

# Or build a release
flutter build macos    # or apk, ios, windows, linux
```

### CLI

```bash
cd apps/cli

# Run directly
dart run bin/cli.dart

# With a specific difficulty
dart run bin/cli.dart -d hard

# Compile to standalone binary
dart compile exe bin/cli.dart -o sudoku
./sudoku
```

See [CLI README](apps/cli/README.md) for full command reference, key bindings, cross-compilation, and Homebrew setup.

### Running Tests

```bash
# Core logic tests
cd packages/sudoku_core
dart test

# Flutter app tests
cd apps/flutter_app
flutter test
```

## Difficulty Levels

Difficulty is determined by the most advanced solving strategy required — not by the number of givens. Strategies are weighted by how hard they are for humans (e.g., hidden singles are easier to spot than naked singles because you just scan a house for where a digit fits).

| Level    | Strategies Required                                        |
| -------- | ---------------------------------------------------------- |
| Beginner | Hidden Singles, Naked Singles                              |
| Easy     | + Pointing Pairs, Box/Line Reduction, Naked & Hidden Pairs |
| Medium   | + Naked & Hidden Triples/Quads, X-Wing, Swordfish          |
| Hard     | + Jellyfish, XY-Wing, XYZ-Wing, Unique Rectangles          |
| Expert   | + Simple Coloring, X-Chains, XY-Chains, AIC               |
| Master   | + Forcing Chains, ALS, Sue de Coq                          |

## Privacy

Zero data collection. No accounts, no telemetry, no third-party scripts. Everything runs locally on your device.

## License

[GPLv3](LICENSE)
