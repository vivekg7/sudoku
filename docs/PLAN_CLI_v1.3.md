# CLI App v1.3 - Catch-Up Plan

## Current State

The CLI app is **broken** (28 compile errors) due to the `MoveHistory` API change in `sudoku_core`:
`undo()`/`redo()` now return `List<Move>?` instead of `Move?`.

Beyond the breakage, the CLI has fallen behind the Flutter app across several features added in recent commits.

---

## Phase 1: Fix Build (Critical)

### 1.1 Update undo/redo in `game.dart` and `tui_game.dart`

Both files access `move.row`, `move.previousValue` etc. directly on what is now a `List<Move>`.

**game.dart** `_handleUndo()` / `_handleRedo()` (lines 280-320):

- `puzzle.history.undo()` returns `List<Move>?`
- Iterate in reverse for undo, forward for redo
- Move cursor to first/last move's position

**tui_game.dart** `_handleUndo()` / `_handleRedo()` (lines 303-347):

- Same changes as game.dart

**Verification:** `dart analyze` in `apps/cli` passes with 0 errors.

---

## Phase 2: Feature Parity (High Priority)

### 2.1 Auto-fill all candidates (`f` key in TUI, `fill` command in classic)

Both modes already have manual `note` commands. Add a bulk fill:

- Compute valid candidates for every empty cell (same bitmask logic as `computeCandidates` in sudoku_core)
- Push as a single batch via `puzzle.history.pushAll(moves)` for single-undo
- TUI: bind to `f` key with status message "Filled all candidates."
- Classic: add `fill` command

### 2.2 Puzzle Analysis (`analyze` command / `!` key)

The core already has `PuzzleAnalyzer.analyze()`. Wire it up:

- Classic: `analyze` command - fill solution, print step-by-step breakdown (strategy, cells, placements)
- TUI: `!` key with confirmation prompt, then print analysis to stdout after exiting TUI
- Set `puzzle.completionType = CompletionType.analyzed`
- Store analysis result for post-game display

### 2.3 Mistake count tracking

Both modes detect conflicts but don't count them persistently:

- Add `int _mistakeCount = 0` to both game classes
- Increment when a placed value creates a conflict
- Include in `toGameStats()` via `mistakeCount: _mistakeCount`
- Show in `stats` output

### 2.4 Completion type tracking

Currently `_handleSolve()` / `_solvePuzzle()` reveal the solution but don't mark how the game ended:

- Set `puzzle.completionType = CompletionType.solved` when player solves naturally (already implied by `puzzle.isSolved`)
- Set `puzzle.completionType = CompletionType.analyzed` when analysis is used
- Pass `completionType: puzzle.completionType?.name` to `toGameStats()`

### 2.5 Richer GameStats

Current `toGameStats()` only passes basic fields. Add:

```dart
mistakeCount: _mistakeCount,
completionType: puzzle.completionType?.name,
boardLayout: 'cli',
assistLevel: 'none',
notesEnabled: true,
showTimer: true,
```

---

## Phase 3: Quality of Life (Medium Priority)

### 3.1 Auto-remove candidates from peers

When placing a value, remove that digit from all peer candidates (like the Flutter assist toggle):

- Add `--auto-remove` flag (default off to keep CLI experience pure)
- When enabled, call `board.removeCandidateFromPeers(row, col, value)` after placing
- Record `removedPeerCandidates` in the Move for proper undo
- Both game.dart and tui_game.dart undo/redo must restore these (iterate `move.removedPeerCandidates`)

### 3.2 Candidate highlighting in TUI

TUI already highlights same-digit for filled cells. Extend to candidates:

- When cursor is on a filled cell, highlight matching candidate digits in other cells
- In `tui_renderer.dart`, when rendering candidate digits, check if the digit matches the selected cell's value
- Use a distinct style (bold + primary color) for matching candidates

### 3.3 Pause blocks all input (TUI)

TUI already blocks most input when paused, but classic mode only pauses the timer. Align:

- Classic: skip all commands except `resume` and `quit` when paused
- Both: hide board content when paused (prevent peeking)

---

## Phase 4: Nice to Have (Low Priority)

### 4.1 `--analyze` flag for non-interactive analysis

Run analysis on a puzzle string without playing:

```
sudoku --analyze --import "003020600..."
```

Print strategy breakdown, difficulty score, and bottleneck cells.

### 4.2 Strategy reference (`strategies` command)

Print available strategies with descriptions, grouped by difficulty. Data already exists in `sudoku_core` strategy guides.

### 4.3 Hint cooldown visual

Show remaining cooldown between hint layers in status message (e.g., "Hint available in 8s"). Currently hints are instant in CLI - could add friction to match Flutter behavior, but this may hurt CLI UX since there's no visual timer. Consider making this opt-in.

---

## File Change Summary

| File                          | Phase   | Changes                                                                     |
| ----------------------------- | ------- | --------------------------------------------------------------------------- |
| `lib/src/game.dart`           | 1, 2, 3 | Fix undo/redo, add fill/analyze/mistake tracking, auto-remove               |
| `lib/src/tui_game.dart`       | 1, 2, 3 | Fix undo/redo, add fill/analyze/mistake tracking, auto-remove, key bindings |
| `lib/src/tui_renderer.dart`   | 3       | Candidate highlighting, pause screen                                        |
| `lib/src/board_renderer.dart` | 3       | Pause screen for classic mode                                               |
| `bin/cli.dart`                | 2, 4    | CompletionType in stats recording, --analyze flag, --auto-remove flag       |

## Verification

After each phase:

- `dart analyze` in `apps/cli` - zero errors
- Manual test: TUI mode and classic mode both launch and play through
- Undo/redo works for single moves and batch fill
- Stats file records new fields correctly
