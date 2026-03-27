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

| Mode   | Houses shown  | Starting time | Decay         | Floor |
| ------ | ------------- | ------------- | ------------- | ----- |
| Chill  | Boxes only    | 10s           | −0.2s / round | 7s    |
| Quick  | Boxes only    | 8s            | −0.2s / round | 5s    |
| Sprint | Mixed (all 3) | 5s            | −0.1s / round | 2s    |

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
- **Smart leaderboard selector:** the Training Hub leaderboard defaults to the most recently played game + mode, so the player immediately sees the board they're competing against. Stored via `TrainingStorageService`.
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

## Game 2: Where Does N Go?

**One-line pitch:** A full board, one digit, one cell — find where it goes by elimination.

### Concept

A partially solved 9×9 board is shown. The player is given a digit N and must tap the one cell where it can logically be placed via hidden single elimination. No advanced strategies required — just cross-referencing rows, columns, and boxes to rule out every other cell.

This trains the most important real-game scanning skill: finding where a digit must go by checking what's already placed in the surrounding houses. It's the natural next step after Number Rush — from "what's missing?" to "where does it go?"

### Game Flow

1. Generate a board state where exactly one cell can be solved for digit N using basic elimination.
2. Display prompt: "Where does 5 go in Box 4?" (Chill/Quick) or "Where does 5 go?" (Sprint).
3. Player taps the correct cell directly on the board.
4. Correct → streak increments, timer resets, new board/digit loaded.
5. Wrong tap or timeout → game over → results screen.

```
┌─────────────────────────────────────┐
│  Score: 7           Best: 15        │
│                                     │
│  "Where does 5 go in Box 4?"       │
│                                     │
│  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐
│  │ . │ 3 │ . │ . │ 7 │ . │ . │ 1 │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ 8 │ . │ . │ . │ 3 │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ 5 │ . │ . │ . │ . │ 3 │ . │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ 5 │ . │ . │ . │ . │ . │ 9 │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ . │ 5 │ . │ . │ . │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ 8 │ . │ . │ . │ . │ 5 │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ . │ . │ . │ 5 │ . │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ 5 │ . │ . │ . │ . │ . │ . │ 7 │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ . │ . │ . │ . │ . │ 5 │ . │
│  └───┴───┴───┴───┴───┴───┴───┴───┴───┘
│                                     │
│  ████████████░░░░░ 8.2s             │
│                                     │
│  ── streak: 7 ──                    │
└─────────────────────────────────────┘
```

### Difficulty Modes

| Mode   | Prompt                                  | Houses               | Highlight        | Starting time | Decay         | Floor |
| ------ | --------------------------------------- | -------------------- | ---------------- | ------------- | ------------- | ----- |
| Chill  | "Where does N go in **Box X**?"         | Boxes only           | Yes (target box) | 15s           | −0.3s / round | 10s   |
| Quick  | "Where does N go in **Row/Col/Box X**?" | Boxes, rows, columns | No               | 12s           | −0.2s / round | 7s    |
| Sprint | "Where does N go?"                      | No house hint        | No               | 10s           | −0.2s / round | 5s    |

- **Chill** — Boxes only, target box highlighted with a subtle background tint (accent color at ~10% opacity). The player focuses purely on elimination logic. Generous timer for thinking through cross-references.
- **Quick** — Any house type, no highlight. The player must locate the house and scan it. Standard competitive mode.
- **Sprint** — No house hint at all. The player scans the entire board to find the one cell where N can be placed. Timer starts at Quick's floor. This is where high scores come from.

Timer behavior identical to Number Rush: countdown bar that resets on correct answer, accent → yellow → red color transition as time runs low.

### Board Generation

1. Use the puzzle generator to create a Beginner/Easy puzzle (these rely on hidden singles).
2. Run the solver step-by-step until a hidden single step is found.
3. Freeze the board at that state — this is the challenge board.
4. The target digit N = the digit from the hidden single step. The target cell = where the solver would place it.
5. **Validation:** Confirm that N cannot be placed in any other cell on the board via basic elimination alone (naked singles or hidden singles). If it can, skip this step and advance the solver further until a clean hidden single is found where N has exactly one logical placement.
6. For Sprint mode (no house hint): additionally verify that N has only one hidden-single placement across the _entire board_, not just within one house.

**Avoiding repetition:**

- Don't repeat the same digit N on consecutive rounds.
- Don't reuse the same puzzle — generate a fresh one each round (generation is fast for Beginner/Easy).

**Performance note:** Beginner/Easy puzzles generate quickly since they only need basic strategies. If generation per round causes noticeable lag, pre-generate a small buffer (3–5 boards ahead) while the player is solving the current one.

### UI Layout

Same minimal chrome approach as Number Rush:

- **Top bar:** Score (current streak) and best score for the mode.
- **Prompt:** Large, clear text — "Where does 5 go in Box 4?" or "Where does 5 go?"
- **Board:** Full 9×9 board using the existing `BoardWidget`. Cells show filled digits only — no candidates visible (the player does elimination mentally). Given cells styled as givens, solver-placed cells styled as filled values.
- **Timer bar:** Below the board, same horizontal countdown bar as Number Rush.
- **Streak counter:** Below the timer.

No numpad — the player taps directly on the board.

### Interaction

- All empty cells are tappable.
- Correct cell → brief green flash on the cell, digit appears, then board transitions to next challenge (200ms crossfade).
- Wrong cell → brief red flash, game over → results screen. Show the correct cell highlighted and explain: "5 goes here — Row 3 and Box 6 already have a 5, leaving only this cell."
- Timeout → timer bar pulses red, game over → results screen (same correct-cell reveal).
- All animations respect the global animation toggle. When disabled: instant transitions.

### Scoring & Leaderboard

Identical structure to Number Rush:

- Score = streak count (consecutive correct taps).
- Top 10 leaderboard per mode, stored in the same `TrainingStorageService`.
- Ranking: higher streak wins, tiebreaker = lower total time.
- Each entry: `streak`, `totalTimeMs`, `playedAt`.

### Results Screen

Same layout as Number Rush results:

- Final streak and total time.
- Leaderboard position (with celebration if top 3 / new record).
- Average time per answer.
- **If wrong:** show the board with the correct cell highlighted in green and the tapped cell in red. Brief explanation of why that cell is the answer.
- **Play Again** (same mode) and **Back to Training** buttons.

### Navigation

- Training Hub → "Where Does N Go?" card with Chill / Quick / Sprint mode buttons inline.
- Card sits below Number Rush, above the coming-soon games.
- Card description: "Spot the only cell where a digit can go."
- Tapping a mode goes straight into gameplay (no intermediate screen).
- The leaderboard mode selector gains the new game's modes.

---

## Game 3: Candidate Fill

**One-line pitch:** Fill in every candidate for a region — get it perfect or go home.

### Concept

A full 9×9 board is shown with a highlighted target region (box, row, or column). The player must correctly mark all candidates for every empty cell in that region. Notes mode is always on — the interaction mirrors the main game exactly. When the player is confident, they tap Submit. If every candidate in every cell is correct (no missed, no extras), the streak increments, the timer resets, and a new region loads. Any mistake = game over.

This trains the foundational skill that unlocks all advanced strategies: building accurate candidate lists by cross-referencing rows, columns, and boxes. A player who can do this quickly and flawlessly will spot naked pairs, hidden triples, and X-Wings naturally — because they'll actually _see_ the candidates.

### Game Flow

1. Generate a partially solved board and select a target region with 3–6 empty cells.
2. Display the full board with the target region highlighted. Non-target cells are visible but not selectable.
3. Player fills candidates using the familiar numpad interaction (numpad-first or cell-first).
4. Player taps Submit when done.
5. All correct → streak increments, timer resets, new board + region loaded.
6. Any error → game over → results screen showing exactly what went wrong.

```
┌─────────────────────────────────────┐
│  Score: 4            Best: 11       │
│                                     │
│  "Fill candidates for Box 5"       │
│                                     │
│  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐
│  │ . │ 3 │ . │ . │ 7 │ . │ . │ 1 │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ 8 │ . │ . │ . │ 3 │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ 5 │ . │ . │ . │ . │ 3 │ . │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ 5 │▒▒▒│▒▒▒│▒▒▒│ . │ . │ 9 │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ . │▒▒▒│▒▒▒│▒▒▒│ . │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ 8 │ . │▒▒▒│▒▒▒│▒▒▒│ 5 │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ . │ . │ . │ 5 │ . │ . │ . │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ 5 │ . │ . │ . │ . │ . │ . │ 7 │
│  ├───┼───┼───┼───┼───┼───┼───┼───┼───┤
│  │ . │ . │ . │ . │ . │ . │ . │ 5 │ . │
│  └───┴───┴───┴───┴───┴───┴───┴───┴───┘
│                                     │
│  ████████████░░░░░ 22.5s            │
│                                     │
│  ┌───┬───┬───┬───┬───┐             │
│  │ 1 │ 2 │ 3 │ 4 │ 5 │             │
│  ├───┼───┼───┼───┼───┤             │
│  │ 6 │ 7 │ 8 │ 9 │ ✓ │   ← Submit │
│  └───┴───┴───┴───┴───┘             │
│                                     │
│  ── streak: 4 ──                    │
└─────────────────────────────────────┘
```

### Input

Mirrors the main game's Notes mode — always on, no toggle needed.

- **Numpad-first mode** (default): tap a number on the pad, then tap empty cells in the target region to toggle that candidate in/out. Great for "let me place all the 3s" sweeps.
- **Cell-first mode**: tap an empty cell in the target region, then tap numbers on the pad to toggle candidates. Great for "let me figure out this one cell" thinking.
- Tapping a non-target cell does nothing (no selection, no highlight).
- **Submit button** sits where the erase button normally would (bottom-right of the numpad grid). Tapping Submit locks in the answer and triggers validation.
- **No undo/redo, no erase button, no hints, no pencil toggle.** Just the numpad and Submit. Clean.

### Difficulty Modes

| Mode   | Region type            | Empty cells | Board fill   | Starting time | Decay          | Floor |
| ------ | ---------------------- | ----------- | ------------ | ------------- | -------------- | ----- |
| Chill  | Boxes only             | 3–4         | ~55% filled  | 45s           | −1.0s / round  | 30s   |
| Quick  | Boxes, rows, columns   | 4–5         | ~45% filled  | 35s           | −0.8s / round  | 20s   |
| Sprint | Boxes, rows, columns   | 5–6         | ~35% filled  | 25s           | −0.5s / round  | 15s   |

- **Chill** — Boxes only, fewer empty cells, generous time. The player learns the mechanic and builds confidence. A filled board means fewer candidates per cell, so the mental load is lighter.
- **Quick** — Any region type, more empty cells. Rows and columns are harder than boxes because the player must scan more of the board. Standard competitive mode.
- **Sprint** — Sparser board means more candidates per cell, more cells per region, and less time. This is where high scores come from.

Timer behavior identical to the other games: countdown bar, accent → yellow → red color transition, resets on correct submission.

**Timer tuning rationale:** Candidate Fill needs significantly more time per round than Number Rush (one digit) or Where Does N Go? (one tap). A region with 5 empty cells averaging 3–4 candidates each means ~15–20 individual taps. The 45s/35s/25s starting times account for this while still creating pressure at higher streaks.

### Generation

1. Use the puzzle generator to create a Beginner/Easy puzzle (same as Where Does N Go?).
2. Run the solver partway to get a partially solved board state — the amount of solving controls board fill level:
   - **Chill (~55% filled)**: solve more steps before freezing.
   - **Quick (~45% filled)**: solve fewer steps.
   - **Sprint (~35% filled)**: freeze early, close to the initial puzzle state.
3. Pick a random target region (based on mode — box only or any house type).
4. Count empty cells in that region. If outside the mode's range (e.g., only 2 empty cells for Chill which needs 3–4), pick a different region. If no region qualifies, generate a new puzzle.
5. Compute the correct candidate set for each empty cell in the target region — this is the answer key. For each empty cell, valid candidates = digits 1–9 minus digits already present in the cell's row, column, and box.
6. **Validation:** Ensure every empty cell in the target region has at least 2 candidates. A cell with only 1 candidate is a naked single — too trivial and feels like a freebie. If any cell has only 1 candidate, pick a different region or regenerate.

**Avoiding repetition:**

- Don't reuse the same region type (box/row/column) on consecutive rounds.
- Don't reuse the same region index (e.g., Box 5 twice in a row).
- Generate a fresh puzzle each round — generation is fast for Beginner/Easy.

**Performance note:** Same as Where Does N Go? — if per-round generation causes lag, pre-generate a small buffer (2–3 boards ahead) while the player is solving.

### Scoring & Leaderboard

Identical structure to Number Rush and Where Does N Go?:

- **Score** = streak count (consecutive perfect regions).
- **Top 10 leaderboard per mode**, stored in `TrainingStorageService`.
- **Ranking:** higher streak wins, tiebreaker = lower total time.
- Each entry: `streak`, `totalTimeMs`, `playedAt`.
- Best score shown during gameplay so the player has a target.

### Results Screen (Game Over)

Shown when the player submits with any error, or the timer runs out (unsubmitted work counts as all wrong).

**Standard results (same as other games):**

- Final streak and total time.
- Leaderboard position (celebration if top 3 / new record).
- Average time per region.
- **Play Again** (same mode) and **Back to Training** buttons.

### Game-Over Feedback

When the game ends on an incorrect submission, the results screen shows the target region with a detailed error breakdown:

**Visual overlay on the region:**

- **Correct candidates** the player entered — shown in the default text color. No highlight needed, these are fine.
- **Missed candidates** (player didn't enter, but should have) — shown in **green** with a subtle "+" indicator. These are candidates the player forgot.
- **Phantom candidates** (player entered, but shouldn't have) — shown in **red** with a strikethrough. These are candidates the player added incorrectly.

**Per-error explanations:**

Below the region, a scrollable list of short explanations for each error:

- For a **phantom** candidate: _"5 can't go in R4C5 — 5 is already in column 5."_
- For a **missed** candidate: _"You missed 2 in R5C4 — no 2 in row 5, column 4, or box 5."_

Explanations reference the specific row, column, or box that blocks or allows the candidate. This teaches the player _why_ they were wrong, not just _that_ they were wrong.

**Summary line:** _"4 missed, 1 phantom — 17 of 22 candidates correct (77%)."_ Gives the player a sense of how close they were.

If the timer ran out (no submission): show the correct candidates for all cells with a message _"Time's up — here's what the candidates should be."_ No error highlighting since nothing was submitted.

### UI & Visual Design

Same minimal chrome approach as the other training games:

- **Top bar:** Score (current streak) and best score for the mode.
- **Prompt:** Large, clear text — "Fill candidates for Box 5" or "Fill candidates for Row 3".
- **Board:** Full 9×9 using the existing `BoardWidget`. Target region has a subtle accent background tint (~10% opacity). Non-target cells are visible but dimmed slightly and not selectable. Given cells styled as givens, solver-placed cells styled as filled values.
- **Numpad:** Two-row layout (1–5, 6–9 + Submit). Submit button uses a checkmark icon with accent color. No undo, redo, erase, or pencil toggle.
- **Timer bar:** Below the board, same horizontal countdown bar as other games.
- **Streak counter:** Below the timer.
- **Candidate display:** Same small-number rendering as the main game's pencil marks. Players see their work building up in real time — familiar and satisfying.
- On correct submission: brief green flash on the region, then board crossfades to the next challenge (200ms).
- On wrong submission: brief red flash on cells with errors, then results screen with the full error breakdown.
- On timeout: timer bar pulses red, then results screen.
- All animations respect the global animation toggle.

### Navigation

- Training Hub → "Candidate Fill" card with Chill / Quick / Sprint mode buttons inline.
- Card sits below "Where Does N Go?", above the coming-soon games.
- Card description: "Mark every candidate in a region — perfectly."
- Tapping a mode goes straight into gameplay (no intermediate screen).
- The leaderboard mode selector gains the new game's modes.

---

## Game 4: Bulls & Cows

**One-line pitch:** Crack a secret 4-digit code using logic and elimination — in as few guesses as possible.

### Concept

The app generates a secret 4-digit number. The player guesses a 4-digit number, and the app responds with how many **bulls** (correct digit in correct position) and **cows** (correct digit in wrong position). The player uses these hints to narrow down possibilities and guess again. The game ends when the player gets 4 bulls (all correct).

This trains the core Sudoku skill of **elimination thinking** — using partial information to systematically rule out possibilities. Every bull/cow response is a constraint, just like every filled cell on a Sudoku board constrains what can go elsewhere.

### Game Flow

1. App generates a secret 4-digit number (digits 0–9).
2. Player enters a 4-digit guess.
3. App shows the result: X bulls, Y cows.
4. Player guesses again, informed by all previous results.
5. When the player gets 4 bulls — puzzle solved. Show results.
6. If max guesses reached without solving — game over, secret revealed.

```
┌─────────────────────────────────────┐
│  ←  Bulls & Cows                    │
│                                     │
│  Guess the 4-digit number           │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  #1   1 2 3 4    1B 1C      │   │
│  │  #2   5 6 7 8    0B 2C      │   │
│  │  #3   1 6 3 9    2B 1C      │   │
│  │  #4   _  _  _  _            │   │
│  └──────────────────────────────┘   │
│                                     │
│  ████████████░░░░░ 18.2s            │
│                                     │
│  ┌───┬───┬───┬───┬───┐             │
│  │ 1 │ 2 │ 3 │ 4 │ 5 │             │
│  ├───┼───┼───┼───┼───┤             │
│  │ 6 │ 7 │ 8 │ 9 │ 0 │             │
│  └───┴───┴───┴───┴───┘             │
│       ┌────┐  ┌────┐                │
│       │ ⌫  │  │ ✓  │                │
│       └────┘  └────┘                │
│                                     │
│  ── guess 4 of 10 ──               │
└─────────────────────────────────────┘
```

### Input

- **0–9 number pad** — two rows (1–5, 6–9 + 0). Includes 0 unlike the Sudoku numpad.
- **Backspace button** — deletes the last entered digit.
- **Submit button** (checkmark) — submits the guess when all 4 digits are entered. Disabled until 4 digits are filled.
- Player taps digits to fill left-to-right into 4 slots. Each slot shows the digit or an underscore placeholder.
- **No cell selection** — always fills the next empty slot. Simple, linear input.
- In Chill/Quick modes (no repeats): if a digit is already in the current guess, the button is disabled — prevents invalid guesses. In Sprint (repeats allowed): all buttons always active.

### Difficulty Modes

| Mode   | Repeats allowed | Timer per guess | Max guesses |
| ------ | --------------- | --------------- | ----------- |
| Chill  | No              | None            | 10          |
| Quick  | No              | 30s             | 10          |
| Sprint | Yes             | 20s             | 12          |

- **Chill** — No repeating digits, no timer. Pure logic, no pressure. Max 10 guesses gives a generous ceiling — most games with no-repeat codes are solvable in 6–7 guesses.
- **Quick** — Same no-repeat constraint, but 30 seconds per guess adds time pressure. Forces faster deduction.
- **Sprint** — Repeats allowed makes the possibility space much larger (10,000 vs 5,040 combinations). 20s per guess and 12 max guesses. This is where mastery shows.

**Timer behavior:** The timer resets on each guess submission (not cumulative). If it runs out, the current guess is forfeited — counts as a wasted guess with no hint (an empty row marked "—"). Timer bar uses the same accent → yellow → red transition. No timer in Chill mode — the bar is hidden.

**Max guesses:** If the player reaches the limit without solving, game over — the secret number is revealed.

### Generation

- **No repeats (Chill, Quick):** Pick 4 distinct digits from 0–9 in random order. 5,040 possible codes.
- **Repeats allowed (Sprint):** Pick 4 digits independently from 0–9. 10,000 possible codes.
- No solver needed — pure random generation, instant.
- No dependencies on `sudoku_core`.

### Bull/Cow Calculation

For a guess `G` and secret `S`, both length 4:
1. **Bulls:** Count positions where `G[i] == S[i]`.
2. **Cows:** For each digit 0–9, count `min(occurrences in G, occurrences in S)` — then subtract bulls. This handles repeated digits correctly in Sprint mode.

### Scoring & Leaderboard

**Per-puzzle scoring** — different from the streak-based model of the other training games.

- **Score** = number of guesses taken to solve (lower is better).
- **Top 10 leaderboard per mode**, stored in `TrainingStorageService`.
- **Ranking:** fewer guesses wins. Tiebreaker = shorter total time (from first guess shown to solve).
- Each entry: `guesses` (int), `totalTimeMs` (int), `playedAt` (DateTime).
- If the player didn't solve (ran out of guesses), no score is recorded — only solved puzzles make the leaderboard.

**Storage note:** The existing `TrainingScore` uses `streak` (higher is better). Bulls & Cows needs `guesses` (lower is better). Options:
- Add a `BullsAndCowsScore` class with reversed comparison (cleanest).
- Or reuse `TrainingScore` with a `lowerIsBetter` flag on the storage key.

The leaderboard display shows "X guesses" instead of "X streak" for this game.

### Results Screen (Solved)

- **Header:** "Cracked it!" with a celebration icon.
- **Guess count** displayed large — "3 guesses" (primary metric).
- **Total time** and **average time per guess**.
- **Leaderboard position** (if made top 10, with celebration for new record).
- **Full guess history** shown as a compact scrollable list for review.
- **Play Again** (same mode) and **Back to Training** buttons.

### Results Screen (Failed)

- **Header:** "Not this time" with the secret number revealed large.
- **Full guess history** shown so the player can review their logic.
- **No leaderboard entry** — only solved puzzles qualify.
- **Play Again** and **Back to Training** buttons.

### Guess History Display

- Scrollable list showing all previous guesses with their bull/cow results.
- Each row: guess number, the 4 digits (spaced), and the result (e.g., "1B 2C").
- Bulls count shown in **green**, cows count shown in **amber** — gives visual feedback at a glance.
- The current guess row sits at the bottom with underscore placeholders.
- Timed-out guesses show "—" with no bull/cow result.
- On correct guess (4B 0C): the row flashes green, then transitions to results screen.

### UI & Visual Design

Same minimal chrome approach as the other training games:

- **Top bar:** Game title, close button.
- **Prompt:** "Guess the 4-digit number" (always visible).
- **Guess history:** Scrollable list, most recent at bottom. Each row styled as a card-like strip.
- **Current guess:** 4 large digit slots at the bottom of the history, filling left-to-right with each tap.
- **Timer bar:** Below the guess area. Hidden in Chill mode. Same accent → yellow → red style as other games.
- **Number pad:** Two rows (1–5, 6–9 + 0) + backspace and submit buttons below.
- **Guess counter:** "guess 4 of 10" below the timer bar.
- All animations respect the global animation toggle.

### Navigation

- Training Hub → "Bulls & Cows" card with Chill / Quick / Sprint mode buttons inline.
- Card sits below Candidate Fill, above the locked games.
- Card description: "Crack a secret code with logic and elimination."
- Tapping a mode goes straight into gameplay.
- The leaderboard shows "X guesses" instead of "X streak" for this game.

---

## Future Game Ideas

> Not designed yet — listed here as candidates for future planning. Each will get its own section when we decide to build it.

### Strategy Snap

Given a real puzzle board state, apply strategy X to fill exactly one cell. Tests whether the player can recognize and execute a specific strategy on demand. Wrong strategy usage gets feedback explaining what they should have done instead.

### Candidate Killer

Given a board with full pencil marks, identify which candidates can be eliminated and by which strategy. Trains the "spotting" skill — the hardest part of advanced solving.

### ~~Where Does N Go?~~ → Moved to full design (Game 2 above)

### Spot the Pattern

Show a board state, ask "which strategy applies here?" as a multiple-choice question. Pure pattern recognition, no solving required. Good for learning to identify strategy shapes (X-Wing, Pointing Pair, etc.).

### ~~Candidate Fill~~ → Moved to full design (Game 3 above)

### Chain Tracer

Given a board state where a specific chain-based strategy applies (X-Chain, XY-Chain, or AIC), the player must trace the chain by tapping cells in the correct order from start to finish. The game highlights the starting cell and the candidate in question — the player follows the logical links. Correct chain = the elimination or placement is revealed. Wrong tap = the game shows where the chain should have gone next. This drills the sequential reasoning that makes chains and AICs feel impossible to most players — turning an abstract concept into a physical, tap-by-tap exercise. Depends on the strategy walkthrough data already in `sudoku_core` for example boards.

### House Sweep

A full 9×9 board is shown with several deliberate rule violations (duplicate digits in rows, columns, or boxes). The player must tap every cell that breaks a rule within a time limit. Trains the verification and proofreading skill — the ability to quickly scan a completed or near-completed board and catch errors. Useful for players who often finish puzzles only to realize they made a mistake 20 moves ago. Modes could vary by number of violations (3, 5, 8) and time pressure.

### Minesweeper Mini-Puzzles

Small grid (5×5 or 6×6) with number clues indicating how many mines surround each revealed cell. The player must flag all mines and reveal all safe cells using pure elimination logic — the same constraint-based reasoning that drives Sudoku. Unlike full Minesweeper, puzzles are pre-generated to be solvable without guessing (no 50/50 coin flips). Modes could vary by grid size and mine density. Trains the skill of reading numeric constraints and deducing what must be true — directly applicable to candidate elimination in Sudoku.

### Nonograms (Picross)

Small grid (5×5 to 10×10) with number clues per row and column indicating the lengths of consecutive filled runs. The player fills or marks cells using elimination — if a run of 4 must fit in 5 cells, the middle 3 are guaranteed filled. Puzzles are always logically solvable. Trains the same "what _must_ be true given these constraints?" thinking that underpins every Sudoku strategy. Modes could vary by grid size (5×5, 8×8, 10×10) and time pressure.

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
