# Changelog

All notable changes to this project will be documented in this file.

## v1.1.0 — 2026-03-15

### New Features

- **Inspirational quotes** — 36 hand-picked quotes across 3 tiers (light, medium, deep) with weighted distribution per difficulty. Shown on the puzzle screen, in PDF exports, and in the CLI.
- **Settings page** — centralized preferences with export/import moved from the home screen.
- **Dark mode** — light, dark, and system theme toggle.
- **Accent colors** — 6 preset color themes (blue, teal, green, purple, orange, red).
- **Configurable hint level** — disable hints entirely, or limit to nudge only, up to strategy, or all three layers.
- **Show/hide timer** — toggle the timer and pause button from settings (stats still recorded).
- **Pencil notes toggle** — disable pencil marks for a cleaner experience.
- **Same-digit highlighting toggle** — disable matching digit highlights on the board.
- **Quotes toggle** — disable quotes on both the game screen and PDF export.
- **Long-press to erase** — long-press a cell to clear its value.
- **About dialog** — app philosophy, version, license, and GitHub link.

### UI Improvements

- Theme-aware app logo built with CustomPainter (adapts to accent color and dark mode).
- App logo replaces title text on the home screen.
- All hardcoded colors replaced with theme-aware values across every screen and widget.
- Full dark mode support for the board grid, cells, number pad, hint panel, and all screens.

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
