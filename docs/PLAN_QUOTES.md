# Quotes Feature — Detailed Plan

> Display an inspirational quote on each puzzle to give the player something meaningful to reflect on during the focused, meditative time spent solving.

## Why

Sudoku solving creates a unique headspace — the player is focused, unhurried, and sitting with the puzzle for 10–60 minutes. Most apps throw quotes at users when they're rushing past them. Here, the quote has time to land and embed itself in the player's mind.

## Core Design

### Quote Collection

- Quotes are bundled locally with the app and **grow incrementally** — starting with ~36 hand-picked quotes, expanding over time.
- No generic or overused filler quotes — every quote should be worth reading twice.
- Authors: famous thinkers, poets, writers, leaders, philosophers.

### Difficulty-Tiered Quotes

Quotes are organized into **3 tiers** that match the puzzle's difficulty level. The tone and depth of the quote should match the headspace the player is likely in.

| Tier       | Difficulties   | Tone                            | Themes                                               |
| ---------- | -------------- | ------------------------------- | ---------------------------------------------------- |
| **Light**  | Beginner, Easy | Fun, encouraging, simple wisdom | Getting started, curiosity, small wins, playfulness  |
| **Medium** | Medium, Hard   | Thoughtful, persistence-themed  | Persistence, patience, problem-solving, growth       |
| **Deep**   | Expert, Master | Philosophy, complexity, mastery | Mastery, deep thinking, discipline, wisdom, stoicism |

- Start with **~12 quotes per tier** (~36 total).
- Adding more quotes later is trivial — just append to the tier with the next available ID.

### Quote–Puzzle Binding

- Each puzzle gets **one quote assigned at generation time**.
- The puzzle stores the **quote ID** (a stable integer, like a database primary key).
- The quote stays the same when the player resumes the puzzle — it becomes _that puzzle's quote_.
- This makes the quote feel intentional, not random. Players may even remember puzzles by their quotes.
- Because the binding is by ID (not by list index or position), adding or reordering quotes never breaks existing puzzles.

### Quote Selection at Generation Time

Quotes are **not** locked to a single tier per difficulty. Instead, each difficulty has a **weighted distribution** across all three tiers — the primary tier dominates, but every tier has a nonzero chance. No quote is ever walled off from any player.

| Difficulty | Light | Medium | Deep |
| ---------- | ----- | ------ | ---- |
| Beginner   | 60%   | 30%    | 10%  |
| Easy       | 50%   | 35%    | 15%  |
| Medium     | 20%   | 55%    | 25%  |
| Hard       | 15%   | 50%    | 35%  |
| Expert     | 10%   | 30%    | 60%  |
| Master     | 10%   | 25%    | 65%  |

Selection steps:

1. Use part of the seed (`seed % 100`) to pick a tier based on the weighted distribution.
2. Use another part of the seed (`seed / 100`) to pick a quote within that tier.
3. Store the chosen quote's `id` in the puzzle state.

### Display

#### Interactive Play

- Shown on the puzzle screen — visible but not distracting. Likely a small, tasteful line above or below the grid.
- Always visible while solving, not hidden behind a tap.

#### PDF Export

- Printed below or above each puzzle grid as a small italic line with attribution.
- Gives each printed page personality and a reason to linger.

## Data Format

Quotes stored as a Dart constant list in the `sudoku_core` package, each entry containing:

- `id` — stable integer, never reused or changed (incremental, like a database primary key)
- `text` — the quote itself
- `author` — attribution
- `tier` — `light`, `medium`, or `deep`

Example:

```dart
const quotes = [
  Quote(id: 1, text: '...', author: '...', tier: QuoteTier.light),
  Quote(id: 2, text: '...', author: '...', tier: QuoteTier.light),
  // ...
  Quote(id: 13, text: '...', author: '...', tier: QuoteTier.medium),
  // ...
];
```

IDs are never reused. If a quote is removed, its ID is retired. New quotes always get the next available ID.

## Future Considerations

- **User favorites**: let the player bookmark quotes they like, viewable separately from puzzle bookmarks.
- **Localization**: if multi-language support is added, quotes could be translated or sourced per language.
