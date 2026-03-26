# Changelog

All notable changes to this project will be documented in this file.

## v1.5.0 — 2026-03-27

- "Where Does N Go?" training game — find the only cell for a digit on a full board
- Erase-first mode for quick erasing without cell selection
- Swipe navigation in strategy walkthroughs
- Numpad redesigned as two rows with larger buttons
- Portrait-only lock on all devices
- Fix hints ignoring wrong values, stale candidates, input mode deactivation, and Rush leaderboard bugs

---

## v1.4.0 — 2026-03-22

- Training Hub with Number Rush — a timed game to practice speed-placing digits, with difficulty levels and a leaderboard
- Number-first mode now respects pencil/notes mode — tapping cells toggles candidates
- Cells with matching candidates are highlighted when a number is selected
- Erase button exits number-first mode when no cell is selected

---

## v1.3.1 — 2026-03-21

- Auto-save game progress on app suspend/close via lifecycle observer
- Persist pencil mark candidates across save/resume

---

## v1.3.0 — 2026-03-21

- Interactive Strategy Guide with step-through walkthroughs for all 27 strategies
- How to Solve Sudoku beginner guide
- Difficulty & Strategy Reference screen
- Puzzle Analysis with full solve breakdown and candidate notes
- Auto-fill all notes via long-press on Notes button
- Unified confirmation dialogs as bottom sheets with candidate note highlighting
- CLI homepage, PDF export, and timer restore on saved games

---

## v1.2.0 — 2026-03-18

- Circular board layout (new default) with layout picker
- AMOLED theme and 3 new accent colors
- Gameplay animations with settings toggle
- Graduated hint friction (long-press, cooldowns, confirmation)
- Mistake and hint counters on game screen
- Independent assist toggles replacing tiered levels
- Redesigned stats with per-difficulty tabs and leaderboards

---

## v1.1.0 — 2026-03-15

- Dark mode — light, dark, or follow system
- 6 accent color themes
- 90 inspirational quotes from Indian wisdom traditions
- New Settings page with configurable hints, timer, pencil notes, and highlighting
- Long-press to erase a cell
- Full theme-aware UI across all screens
- About dialog with app info and GitHub link

---

## v1.0.0 — 2026-03-15

First release! A fully offline Sudoku app that teaches you how to think.

- 6 difficulty levels tuned by solving strategies, not just given count
- 27 solving strategies — from Naked Singles to Forcing Chains
- Multi-layer hints: nudge → strategy → answer
- Pencil marks, undo/redo, number-first input
- Timer, stats, streaks, and hint usage tracking
- Save, resume, and bookmark puzzles
- PDF export in bulk with rough-work grids and QR code
- Export/import all data as JSON
