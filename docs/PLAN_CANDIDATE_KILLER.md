# Candidate Killer — Game 6 Design

> Training game #6 for the Training Hub. See [PLAN_TRAINING_GAMES.md](PLAN_TRAINING_GAMES.md) for the overall training games architecture.

**One-line pitch:** A board with full candidates — find every elimination a strategy makes, tap them out.

## Concept

A partially solved 9×9 board is shown with full candidate marks. A specific solving strategy applies at the current board state, producing one or more candidate eliminations. The player marks the candidates that should be eliminated by tapping them (digit-first or cell-first, same as the main game). When confident, they tap Submit.

- **All correct (or valid subset)** — streak increments. If any eliminations were missed, a brief interstitial shows them in amber before the next round loads.
- **Any phantom elimination (wrong candidate marked)** — game over immediately. The player marked something that shouldn't be eliminated — they don't understand the strategy.
- **Timeout** — game over.

This trains the hardest skill in advanced Sudoku: looking at a board full of candidates and _seeing_ which ones can be removed. Knowing a strategy's name is easy. Spotting its eliminations on a real board is where players actually stall.

## Game Flow

1. Generate a board state where a strategy produces candidate eliminations.
2. Display the board with full candidates. Highlighting depends on mode (pattern cells / region / nothing).
3. Player marks eliminations using digit-first or cell-first input.
4. Player taps Submit.
5. Validation: any phantom → game over. All valid → streak increments, show missed (if any), load next round.
6. Timeout → game over → results screen.

```
┌─────────────────────────────────────┐
│  Score: 3           Best: 9         │
│                                     │
│  "Find the eliminations"            │
│                                     │
│  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐
│  │   │   │   │   │   │   │   │   │   │
│  │   (full 9×9 board with           │
│  │    candidates in all empty cells) │
│  │                                   │
│  │    marked eliminations shown as   │
│  │    red strikethrough              │
│  │                                   │
│  │                                   │
│  │                                   │
│  └───┴───┴───┴───┴───┴───┴───┴───┴───┘
│                                     │
│  ████████████░░░░░ 18.2s            │
│                                     │
│  ┌───┬───┬───┬───┬───┐             │
│  │ 1 │ 2 │ 3 │ 4 │ 5 │             │
│  ├───┼───┼───┼───┼───┤             │
│  │ 6 │ 7 │ 8 │ 9 │ ✓ │   ← Submit │
│  └───┴───┴───┴───┴───┘             │
│                                     │
│  ── streak: 3 ──                    │
└─────────────────────────────────────┘
```

---

## Difficulty Modes

| Mode   | Strategies                                                                                         | Highlighting                                   | Starting time | Decay          | Floor |
| ------ | -------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------------- | -------------- | ----- |
| Chill  | Easy (Pointing Pair/Triple, Box/Line Reduction, Naked/Hidden Pair)                                 | Pattern cells highlighted (accent tint)         | 25s           | −0.5s / round  | 18s   |
| Quick  | + Medium (Naked/Hidden Triple/Quad, X-Wing, Swordfish)                                             | Region highlighted (affected row/col/box)       | 20s           | −0.4s / round  | 13s   |
| Sprint | All strategies (+ Jellyfish, Wings, URs, Chains, ALS, Sue de Coq)                                 | No hints                                        | 18s           | −0.3s / round  | 10s   |

### What's excluded

- **No singles in any mode.** Naked and Hidden Singles produce placements, not eliminations. They don't fit this game's mechanic.
- **No backtracking steps.** If the solver uses backtracking, discard the puzzle.
- **Skip steps with zero eliminations.** Some solver steps only produce placements — these are useless for this game.

### Highlighting details

- **Chill — pattern cells:** The `involvedCells` from the solver step get an accent background tint (~10% opacity). E.g., for a Naked Pair, the two cells forming the pair are highlighted. The player sees _where_ the pattern is and must figure out _what_ gets eliminated.
- **Quick — region hint:** The row, column, or box where the eliminations occur gets a subtle background tint. Derived from the elimination coordinates — find the house(s) that contain the elimination cells. If eliminations span multiple houses (e.g., an X-Wing across two columns), highlight all affected houses.
- **Sprint — nothing.** Full board, no assistance.

Timer is more generous than Spot the Pattern because each round requires multiple taps (finding cells, marking candidates) rather than one button press.

---

## Input & Interaction

### Marking Eliminations

Two input modes, matching the main game:

- **Digit-first (default):** Tap a digit on the numpad to select it. Then tap any cell on the board that contains that candidate — it toggles to "marked for elimination" (shown as red strikethrough). Tap again to unmark. Great for strategies that eliminate the same digit from multiple cells — one numpad tap, then tap-tap-tap across the board.
- **Cell-first:** Tap a cell on the board to select it. Then tap digits on the numpad to toggle those candidates as marked. Good for checking one cell at a time.

The player can freely switch between modes by tapping a cell or a numpad digit at any time — same behavior as the main game's notes mode.

### What's tappable

- Only cells that have candidates are tappable. Filled cells (givens and solver-placed) are inert.
- Only candidates that actually exist in a cell can be marked. If cell R3C5 has candidates {2, 4, 7}, tapping 5 in that cell does nothing.

### Numpad & Submit

- Standard two-row numpad (1–5, 6–9 + Submit).
- Submit button uses a checkmark icon with accent color. Disabled until at least one candidate is marked.
- No undo/redo, no erase button, no pencil toggle. Just the numpad and Submit.

### Visual feedback

- **Unmarked candidates:** default text color, normal rendering.
- **Marked for elimination:** red text with strikethrough. Clearly distinct.
- **Selected digit (digit-first):** numpad button shows accent highlight, and all instances of that digit across the board get a subtle background tint to help the player scan.

---

## Submit Validation & Partial Credit

### Validation algorithm

When the player taps Submit, compare their marked eliminations against the solver step's elimination set:

1. **Phantom check:** For each candidate the player marked, check if it exists in `step.eliminations`. If _any_ marked candidate is not in the set → **game over**. The player eliminated something wrong.
2. **If no phantoms:** The submission is valid. Compare counts:
   - Player marked N candidates, step has M total eliminations.
   - If N == M → **perfect**. Green flash, streak increments, load next round immediately.
   - If N < M → **partial**. Streak still increments, but show the interstitial.

### Partial credit interstitial

When the player found a valid subset but missed some eliminations:

- Board stays visible.
- Player's correct eliminations remain shown in green.
- Missed eliminations appear in amber with a subtle pulse.
- A small banner at the top: "You missed 2 more eliminations."
- A "Continue" button below the board. Tapping it loads the next round and restarts the timer.
- The interstitial has no time limit — the timer is paused. The player can study the missed eliminations as long as they want.

### Timeout

If the timer expires before Submit:

- Game over → results screen.
- Any eliminations the player had marked so far are not evaluated — treated the same as a zero-submission timeout.

---

## Board Generation

### Approach

1. Generate a puzzle at the appropriate difficulty:
   - **Chill:** Easy puzzle.
   - **Quick:** Medium puzzle.
   - **Sprint:** Hard, Expert, or Master puzzle.
2. Run the solver to completion: `Solver().solve(puzzle.initialBoard)`.
3. Discard if the solver used backtracking.
4. Clone the initial board, call `computeCandidates()`, and walk through steps:
   - At each step, check if `step.strategy` is in the mode's pool.
   - Skip if the step has zero eliminations (some steps only produce placements).
   - Check repetition avoidance (last 3 strategies, frequency balancing).
   - If match: freeze the board at the state _before_ this step is applied.
5. Snapshot: board values, isGiven grid, and the solver's candidate grid (81 sets).
6. The answer key = `step.eliminations`.

### Quick mode region hint

To determine which region to highlight in Quick mode, look at the elimination coordinates. Find the house (row, column, or box) that contains all elimination cells. If eliminations span multiple houses (e.g., an X-Wing eliminates across two columns), highlight all affected houses.

### Avoiding repetition

- Don't show the same strategy on consecutive rounds.
- Track a recent-strategy window (last 3) and frequency counts.
- Cap re-rolls at 5 per generation attempt, max 30 attempts total.
- Fallback: relax all constraints and take the first valid step.

### Performance

- Pre-buffer 3 boards ahead while the player is working on the current round.
- Easy puzzles generate fast; Medium+ may need the buffer.
- If buffer is empty, show a loading shimmer on the board.

---

## Results Screen

### Game Over — Phantom Elimination (wrong candidate marked)

1. **Board stays visible** with full detail:
   - **Pattern cells** highlighted with accent tint (from `step.involvedCells`).
   - **Correct eliminations** the player marked shown in green.
   - **Phantom eliminations** (player marked, shouldn't have) shown in red strikethrough.
   - **Missed eliminations** (player didn't mark, should have) shown in amber.
2. **Strategy name** displayed prominently in accent color.
3. **`step.description`** — the solver's human-readable explanation of what the strategy found and what it eliminates.
4. **Strategy intro text** from `strategyGuides[strategy]?.intro`.
5. **Tappable link:** "Learn {strategy} →" opens the walkthrough screen.

### Game Over — Timeout

Same layout as phantom, but:

- Header says "Time's up" instead of "Wrong elimination."
- All correct eliminations shown in green (the full set from `step.eliminations`).
- No phantom/missed breakdown since nothing was submitted.

### Standard Results (both cases)

- Final streak and total time.
- Leaderboard position (celebration if top 3 / new record).
- Average time per round.
- **Round breakdown:** compact list showing each round's strategy with a checkmark for perfect or a partial indicator (e.g., "✓ Naked Pair" or "⟳ X-Wing (4/6)") showing how many eliminations were found out of total.
- **Play Again** (same mode) and **Back to Training** buttons.

---

## Scoring & Leaderboard

- **Score** = streak count (consecutive rounds without a phantom elimination). Partial credit rounds count toward streak.
- **Top 10 leaderboard per mode**, stored in `TrainingStorageService`.
- **Ranking:** higher streak wins. Tiebreaker = lower total time.
- Each entry: `streak`, `totalTimeMs`, `playedAt`.
- Uses default `TrainingScore.compare` (higher-better).
- Best score shown during gameplay.

### Storage

- Key helper: `TrainingStorageService.candidateKillerKey(CandidateKillerMode mode)` → `'candidateKiller_chill'`, etc.
- `setLastPlayedKey()` called before `addScore()`.

---

## Navigation

- Training Hub → "Candidate Killer" card with Chill / Quick / Sprint mode buttons inline.
- Card replaces the remaining locked "Soon" placeholder.
- **Icon:** `Icons.content_cut` (scissors — cutting candidates).
- **Card description:** "Find every elimination — no mistakes allowed."
- Tapping a mode goes straight into gameplay.

---

## UI & Visual Design

Same minimal chrome approach as all training games:

- **Top bar:** Score (current streak) and best score for the mode.
- **Prompt:** Always shows the strategy name ("Find the eliminations from Naked Pair") in all modes. This is necessary because multiple strategies can apply at the same board state — without naming the strategy, the player could correctly apply a different strategy and have valid eliminations rejected as phantoms. The difficulty scaling comes from the board highlighting (pattern cells / region / nothing), not from hiding the strategy name.
- **Board:** Full 9×9 with candidates visible in all empty cells. Uses `WalkthroughBoardWidget` for the base board, with a custom overlay layer for the player's marked eliminations. Given cells styled as givens, solver-placed cells styled as filled values.
- **Timer bar:** Between board and numpad, same horizontal countdown bar as other games (accent → yellow → red).
- **Numpad:** Two-row layout (1–5, 6–9 + Submit). Submit button uses a checkmark icon with accent color. Disabled until at least one candidate is marked.
- **Streak counter:** Below the numpad.
- On correct submission (perfect): brief green flash on the board, then crossfade to next round (200ms).
- On correct submission (partial): board transitions to interstitial (missed candidates in amber, "Continue" button).
- On phantom elimination: brief red flash on phantom candidates, then results screen.
- On timeout: timer bar pulses red, then results screen.
- All animations respect the global animation toggle.
