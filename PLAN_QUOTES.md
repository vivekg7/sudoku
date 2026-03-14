# Quotes Feature — Detailed Plan

> Display an inspirational quote on each puzzle to give the player something meaningful to reflect on during the focused, meditative time spent solving.

## Why

Sudoku solving creates a unique headspace — the player is focused, unhurried, and sitting with the puzzle for 10–60 minutes. Most apps throw quotes at users when they're rushing past them. Here, the quote has time to land and embed itself in the player's mind.

## Core Design

### Quote Collection

- **~1000 hand-picked quotes**, bundled locally with the app.
- Themes: life, motivation, goals, success, philosophy, wisdom, perseverance.
- Authors: famous thinkers, poets, writers, leaders, philosophers.
- No generic or overused filler quotes — every quote should be worth reading twice.

### Quote–Puzzle Binding

- Each puzzle gets **one quote assigned at generation time** (stored as a quote index alongside the puzzle seed/state).
- The quote stays the same when the player resumes the puzzle — it becomes _that puzzle's quote_.
- This makes the quote feel intentional, not random. Players may even remember puzzles by their quotes.

### Display

#### Interactive Play

- Shown on the puzzle screen — visible but not distracting. Likely a small, tasteful line above or below the grid.
- Always visible while solving, not hidden behind a tap.

#### PDF Export

- Printed below or above each puzzle grid as a small italic line with attribution.
- Gives each printed page personality and a reason to linger.

## Data Format

Quotes stored as a simple structured list in the `sudoku_core` package (e.g., JSON or a Dart constant list), each entry containing:

- `text` — the quote itself
- `author` — attribution

## Quote Selection Logic

- A deterministic function maps a puzzle's seed/ID to a quote index, so the same puzzle always gets the same quote.
- No repeat-avoidance needed across puzzles — with 1000 quotes and random distribution, collisions are rare and harmless.

## Future Considerations

- **Theme matching**: heavier philosophical quotes on harder puzzles, lighter motivational ones on easier puzzles.
- **User favourites**: let the player bookmark quotes they like, viewable separately from puzzle bookmarks.
- **Localisation**: if multi-language support is added, quotes could be translated or sourced per language.
