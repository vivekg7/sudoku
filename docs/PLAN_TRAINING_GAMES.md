# Training Games — Detailed Plan

> Bite-sized, single-move training games that build the reflexes and pattern recognition needed to solve puzzles faster. Each game isolates one skill and drills it until it becomes second nature.

## Why

The main game teaches strategy through hints _after_ the player gets stuck. Training games flip that — they drill the fundamentals _before_ the player needs them. A player who can instantly spot what's missing in a house will scan faster, eliminate candidates faster, and spend their mental energy on the hard strategies instead of the mechanical ones.

Training games live in a separate "Train" section — they're not puzzles, they're exercises. Short, repeatable, no save state. The player opens one, drills for a few minutes, and comes back to the real game sharper.

---

## Game 1: Number Rush

**One-line pitch:** Eight numbers shown, find the missing one — as fast as you can, as long as you can.

### Concept

A house (box, row, or column) is displayed with 8 of 9 cells filled. The player identifies the missing digit. Each correct answer resets a countdown timer and loads the next house. The game ends when the timer runs out or the player taps the wrong number.

This trains the most fundamental Sudoku skill: instantly recognizing which digit is absent from a set of 8. It's the base layer every other strategy builds on.

### Game Flow

```
┌─────────────────────────────────────┐
│                                     │
│   Score: 12          Best: 27       │
│                                     │
│   ┌───┬───┬───┐                     │
│   │ 3 │ 7 │ 1 │                     │
│   ├───┼───┼───┤      ████░░ 3.2s    │
│   │ 9 │   │ 4 │                     │
│   ├───┼───┼───┤                     │
│   │ 8 │ 2 │ 6 │                     │
│   └───┴───┴───┘                     │
│                                     │
│   ┌───┬───┬───┬───┬───┐            │
│   │ 1 │ 2 │ 3 │ 4 │ 5 │            │
│   ├───┼───┼───┼───┼───┤            │
│   │ 6 │ 7 │ 8 │   │   │            │
│   └───┴───┴───┴───┴───┘            │
│         number pad                  │
│                                     │
│   ── streak: 12 ──                  │
└─────────────────────────────────────┘
```

### House Display

- **Box (3×3 grid)** — default and primary layout. Feels natural, mirrors the real game board. The empty cell sits in its actual grid position.
- **Row / Column (linear strip)** — shown as a horizontal row of 9 cells. Used in harder modes to train linear scanning.
- The empty cell is visually distinct — same style as an empty cell on the real board (no number, maybe a subtle dotted border or background tint).

### Input

- Standard 1–9 number pad at the bottom (same component used in the main game — familiar, no learning curve).
- Only the missing digit is correct. All others are wrong.
- **No candidate filtering** — all 9 buttons always visible. The player's brain does the elimination, not the UI. This is the whole point.

### Timer

- A visible countdown bar that depletes smoothly (not just a number — the player should _feel_ time running out in their peripheral vision).
- Timer starts at a base value and resets on each correct answer.
- **Wrong answer = game over immediately.** No second chances. This forces accuracy under pressure, not just speed.

### Difficulty Modes

The player selects a mode before starting. Modes control what type of house is shown and how much time pressure there is.

| Mode   | Houses shown  | Starting time | Decay          | Floor |
| ------ | ------------- | ------------- | -------------- | ----- |
| Chill  | Boxes only    | 10s           | −0.2s / round  | 7s    |
| Quick  | Boxes only    | 8s            | −0.2s / round  | 5s    |
| Sprint | Mixed (all 3) | 5s            | −0.1s / round  | 2s    |

- **Chill** starts generous (10s) and gradually tightens to 7s — eases the player into time pressure. By the time Chill feels easy, the player is ready for Quick.
- **Quick** picks up where Chill's floor leaves off (8s → 5s). The standard competitive mode.
- **Sprint** is the endgame mode. Starts at 5s (Quick's floor) and shrinks to 2s. Mixed house types add cognitive load. This is where high scores come from.

These modes and their parameters should be defined as constants so they're easy to tune later.

### Scoring & Leaderboard

- **Score** = number of correct answers in the current run (i.e., the streak).
- **Best score** (top of current mode's leaderboard) — shown during gameplay so the player has a target.
- **Top 10 leaderboard per mode** — stored persistently. Each entry contains:
  - `streak` — number of correct answers (primary sort, descending).
  - `totalTime` — wall-clock duration from first house shown to game over (tiebreaker: shorter wins).
  - `playedAt` — DateTime when the run happened.
- **Ranking rule:** higher streak always wins. If two runs have the same streak, the one completed in less total time ranks higher.
- Leaderboard is displayed on the Training Hub screen (see below), not inside the gameplay screen — scores belong to the training section, not the game itself.
- Stats are separate from the main puzzle stats. Training game stats live in their own data structure.

### Results Screen (Game Over)

Shown when the timer expires or the player taps wrong:

- **Final score** (streak count) and **total time**.
- **Leaderboard position** — if the run made it into the top 10, show the rank (e.g., "#3 all-time") with a subtle celebration. If it's #1, celebrate more (new record).
- **Average time per answer** for this run.
- If the player answered wrong: show which number they tapped, what the correct answer was, and the house so they can see it.
- **Play Again** button (same mode) and **Back to Training** button.

### Generation

- Pick a random house type (based on mode).
- For a box: pick a random box (0–8), fill with digits 1–9 in shuffled positions, remove one at random.
- For a row/column: same idea — fill 9 cells with 1–9, remove one.
- No solver needed. No dependencies on `sudoku_core` puzzle generation. This is pure random permutation — trivial to generate and guaranteed to have exactly one answer.
- Ensure the missing digit doesn't repeat consecutively (avoid 2+ rounds with the same answer — feels broken even if random).

### UI & Visual Design

- **Minimal chrome.** The screen should be almost entirely the grid + number pad + timer bar. No distractions.
- Use the same cell styling as the main board (respects the selected board layout theme — Circular or Classic).
- Timer bar: horizontal bar below the grid, fills with the accent color, depletes left-to-right. Changes color (accent → yellow → red) as it gets low.
- On correct answer: brief green flash on the cell + grid slides/fades to the next house. Fast transition — under 200ms. The player should never feel like they're waiting.
- On wrong answer: brief red flash, then results screen.
- On timeout: timer bar pulses red, then results screen.
- Animations respect the global animation toggle (if disabled, instant transitions).

### Navigation

- Accessed from a "Train" button on the home screen (joins the existing nav button row).
- Home → Training Hub → tap "Number Rush" card → mode selection (inline) → gameplay.
- The Training Hub is designed to hold more games in the future.

---

## Training Hub Screen

The Training Hub is the home page for all training games — similar in spirit to the app's main home screen. It's the single entry point for every training activity.

### Layout

```
┌─────────────────────────────────────┐
│  ←  Training                        │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🎯 Number Rush                ││
│  │  Find the missing number —     ││
│  │  as fast as you can.           ││
│  │                                ││
│  │  ┌───────┐ ┌───────┐ ┌───────┐││
│  │  │ Chill │ │ Quick │ │Sprint │││
│  │  └───────┘ └───────┘ └───────┘││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🔒 Strategy Snap    (Soon)    ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │  🔒 Candidate Killer (Soon)    ││
│  └─────────────────────────────────┘│
│                                     │
│  ── Leaderboard ──                  │
│                                     │
│  [Chill ▾] (mode selector)         │
│                                     │
│   #1  streak 34  ·  1m 42s  · Today│
│   #2  streak 28  ·  1m 15s  · Mar 3│
│   #3  streak 28  ·  1m 22s  · Feb 8│
│   ...                               │
│                                     │
└─────────────────────────────────────┘
```

### Sections (top to bottom)

1. **Game Cards** — One card per training game. Each card has:
   - Game name and one-line description.
   - Mode selector buttons inline on the card (for Number Rush: Chill / Quick / Sprint). Tapping a mode button goes straight into gameplay — no intermediate screen.
   - Future games show as locked/greyed cards with a "Soon" label. These give the player a sense that more is coming without being intrusive.

2. **Leaderboard** — A single leaderboard section shared across all games (currently only Number Rush).
   - **Game + mode selector** at the top — dropdown or segmented control to pick which game and mode to view. Defaults to the most recently played mode.
   - Shows up to 10 entries, ranked by streak (descending), then total time (ascending).
   - Each entry shows: rank, streak count, total time, and relative date ("Today", "Yesterday", "Mar 3").
   - If the leaderboard is empty (no runs yet), show a subtle empty state: _"No scores yet — play a round to set your first record."_
   - The most recent run is highlighted if it's on the board (subtle accent background).

### Design Notes

- The Training Hub is a scrollable screen, not a tabbed layout. Games at top, leaderboard below — everything visible in one scroll.
- Card design should match the app's existing style (rounded corners, surface container colors, consistent with the settings/stats screens).
- The "Train" button on the main home screen uses a fitness/dumbbell or target icon — something that conveys practice/exercise, distinct from the existing Learn/Strategies icons.
- Back button returns to the main home screen.

---

## Future Game Ideas

> Not designed yet — listed here as candidates for future planning. Each will get its own section when we decide to build it.

### Strategy Snap

Given a real puzzle board state, apply strategy X to fill exactly one cell. Tests whether the player can recognize and execute a specific strategy on demand. Wrong strategy usage gets feedback explaining what they should have done instead.

### Candidate Killer

Given a board with full pencil marks, identify which candidates can be eliminated and by which strategy. Trains the "spotting" skill — the hardest part of advanced solving.

### Where Does N Go?

Given a house with candidates visible, tap the cell where digit N must go. Trains hidden single recognition specifically — the most common and most useful scanning pattern.

### Spot the Pattern

Show a board state, ask "which strategy applies here?" as a multiple-choice question. Pure pattern recognition, no solving required. Good for learning to identify strategy shapes (X-Wing, Pointing Pair, etc.).

---

## Architecture Notes

- Training games live under a `training/` feature directory in the Flutter app.
- Game logic that's purely about training (timer, scoring, streak tracking) stays in the Flutter app — it's UI-game logic, not Sudoku-solving logic. No need to put it in `sudoku_core`.
- **Leaderboard storage:** each game+mode combination stores a JSON list of up to 10 entries, each with `streak` (int), `totalTimeMs` (int), and `playedAt` (ISO 8601 string). Stored via shared preferences under keys like `training_numberRush_chill_leaderboard`. When a new run finishes, insert it into the sorted list and trim to 10.
- Screens: Training Hub, gameplay screen, and results screen. Mode selection is inline on the hub (no separate route).
- Number pad widget is reused from the main game (shared widget, not copy-pasted).

---

## Open Questions

- Should Number Rush have sound effects (tick, ding, buzz)? The main app has no audio currently. If we add sound here, it sets a precedent. **Decision: defer — ship silent first, consider sound as a future enhancement across the whole app.**
- Should training game stats feed into the main stats screen (e.g., "You've practiced 500 houses this week") or stay completely separate? **Leaning separate for now.**
