# Implementation Plan

> Checkboxes track progress. `[x]` = done, `[ ]` = pending.
> This file is the source of truth for where we left off.

---

## Phase 1: Project Setup

- [x] Initialise monorepo structure (`packages/`, `apps/`)
- [x] Create `sudoku_core` Dart package with `pubspec.yaml`
- [x] Create `cli` Dart app with dependency on `sudoku_core`
- [x] Create `flutter_app` Flutter project with dependency on `sudoku_core`
- [x] Verify all three build: `dart test` on core, `dart compile exe` on CLI, `flutter build` on app

---

## Phase 2: Core Models

- [x] `Cell` — value, candidates (pencil marks), given vs user-filled, position (row, col, box)
- [x] `Board` — 9x9 grid of cells, access by row/col/box, clone/snapshot
- [x] `Move` — represents a user or solver action (set value, toggle candidate, etc.)
- [x] `MoveHistory` — undo/redo stack of moves
- [x] `Puzzle` — board + solution + difficulty + metadata
- [x] Unit tests for all models

---

## Phase 3: Solver — Basic Strategies

Build the step-by-step solver. Each strategy returns a `SolveStep` describing what it found and where.

- [x] Define `SolveStep` model (strategy used, cells affected, candidates eliminated, value placed)
- [x] Define `Strategy` interface / base class
- [x] Naked Singles
- [x] Hidden Singles
- [x] Naked Pairs
- [x] Hidden Pairs
- [x] Naked Triples
- [x] Hidden Triples
- [x] Naked Quads
- [x] Hidden Quads
- [x] Pointing Pairs / Pointing Triples (box–line reduction)
- [x] Box/Line Reduction (claiming)
- [x] Unit tests for each strategy (known puzzle states → expected step)

---

## Phase 4: Solver — Intermediate Strategies

- [x] X-Wing
- [x] Swordfish
- [x] Jellyfish
- [x] XY-Wing
- [x] XYZ-Wing
- [x] Unique Rectangles (Type 1, 2, 3, 4)
- [x] Unit tests for each

---

## Phase 5: Solver — Advanced Strategies

- [x] Simple Colouring
- [x] X-Chains
- [x] XY-Chains
- [x] Alternating Inference Chains (AIC)
- [x] Forcing Chains
- [x] Almost Locked Sets (ALS)
- [x] Sue de Coq
- [x] Backtracking (fallback only — used for validation, not hints)
- [x] Unit tests for each

---

## Phase 6: Step-by-Step Solver Engine

- [x] `Solver` class that iterates strategies in order of difficulty
- [x] Returns an ordered list of `SolveStep`s from start to finish
- [x] Classify puzzle difficulty based on hardest strategy required
- [x] Define 5–6 difficulty levels with strategy thresholds
- [x] Full integration tests: give a puzzle, verify complete solve path

---

## Phase 7: Puzzle Generator

- [x] Generate a complete valid board (random fill with backtracking)
- [x] Remove clues symmetrically while ensuring unique solution
- [x] Difficulty targeting: generate → solve → check if difficulty matches → retry or adjust
- [x] Bulk generation support (generate N puzzles, optionally parallelised with isolates)
- [x] Tests: generated puzzles have unique solutions, match requested difficulty

---

## Phase 8: Hint System

- [x] Given current board state, determine the next `SolveStep`
- [x] **Layer 1 (nudge)**: extract region + digit from `SolveStep` — e.g., "Look for 3 in box 4"
- [x] **Layer 2 (strategy)**: extract strategy name + region — e.g., "Hidden pair in box 5"
- [x] **Layer 3 (answer)**: full placement — e.g., "Write 3 in R4C5"
- [x] `Hint` model with layers, linked to the underlying `SolveStep`
- [x] Tests: verify each layer exposes progressively more information

---

## Phase 9: Stats & Persistence

- [x] `GameStats` model — solve time, difficulty, hints taken (per layer, per strategy), completion status
- [x] `StatsStore` — accumulate stats across games, compute aggregates (streaks, averages, per-strategy breakdown)
- [x] `PuzzleStore` — save/load in-progress puzzles, bookmarks
- [x] Serialisation (JSON) for all stored data
- [x] Export/import all data as a single file (for cross-device portability)
- [x] Tests for serialisation round-trips and stat aggregation

---

## Phase 10: CLI App

- [x] New game: select difficulty, play interactively in terminal
- [x] Board rendering (ASCII grid with candidates)
- [x] Input: select cell, enter value, toggle candidate
- [x] Undo/redo
- [x] Hint command (progressive layers)
- [x] Timer display
- [x] Auto-solve / show solution
- [x] Stats display
- [x] Save/load game

---

## Phase 11: Flutter App — Core Gameplay

- [ ] Board widget (9x9 grid, highlight selected cell + related cells)
- [ ] Number input (tap/keyboard)
- [ ] Pencil mark mode
- [ ] Undo/redo buttons
- [ ] Rule violation highlighting
- [ ] New game screen (difficulty selection)
- [ ] Timer widget with pause

---

## Phase 12: Flutter App — Hints & Teaching

- [ ] Hint button (intentionally tucked away, not prominent)
- [ ] Progressive hint reveal UI (tap once → nudge, tap again → strategy, again → answer)
- [ ] Visual highlighting of cells/regions referenced by the hint
- [ ] Hint usage tracking wired into stats

---

## Phase 13: Flutter App — Stats & Data

- [ ] Stats screen (solve times, streaks, difficulty progression, hint breakdown by layer/strategy)
- [ ] Saved games list (resume in-progress, replay bookmarked)
- [ ] Export/import data (file picker, share sheet)

---

## Phase 14: PDF Export & QR Codes

- [ ] PDF generation library integration
- [ ] Puzzle grid rendering to PDF
- [ ] Bulk generation UI (select count + difficulty)
- [ ] Hints section at end of PDF
- [ ] QR code generation per puzzle (encodes puzzle data, app opens it for interactive play)
- [ ] QR scanning / deep link handling in Flutter app

---

## Phase 15: Polish & Release Prep

- [ ] Error handling and edge cases
- [ ] Performance profiling (bulk generation, large stat stores)
- [ ] Platform-specific testing (Android, iOS, macOS, Windows, Linux)
- [ ] App icons and splash screen
- [ ] CLI `--help` and documentation
- [ ] Update README with install/usage instructions
