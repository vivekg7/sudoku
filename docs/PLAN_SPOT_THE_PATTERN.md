# Spot the Pattern — Game 5 Design

> Training game #5 for the Training Hub. See [PLAN_TRAINING_GAMES.md](PLAN_TRAINING_GAMES.md) for the overall training games architecture.

**One-line pitch:** See a board with candidates, name the strategy that applies — before time runs out.

## Concept

A partially solved 9×9 board is shown with full candidate marks. Exactly one solving strategy applies at the current board state. The player picks the correct strategy from 4 multiple-choice options (1 correct, 3 distractors). Correct answer increments the streak, resets the timer, and loads a new board. Wrong answer or timeout = game over.

This trains the critical bridge skill between "I can fill candidates" and "I can solve advanced puzzles" — recognizing which strategy to apply next. Most players stall not because they can't execute a strategy, but because they can't _see_ that it applies.

## Game Flow

1. Generate a board state where a target strategy applies (see Generation).
2. Display the board with full candidates visible in all empty cells.
3. Show 4 strategy name buttons in a 2×2 grid (1 correct, 3 distractors).
4. Player taps their answer.
5. Correct → streak increments, timer resets, new board loaded.
6. Wrong or timeout → game over → results screen.

```
┌─────────────────────────────────────┐
│  Score: 6           Best: 14        │
│                                     │
│  "Which strategy applies here?"     │
│                                     │
│  ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐
│  │   │   │   │   │   │   │   │   │   │
│  │   (full 9×9 board with           │
│  │    candidates in all empty cells) │
│  │                                   │
│  │                                   │
│  │                                   │
│  │                                   │
│  │                                   │
│  │                                   │
│  └───┴───┴───┴───┴───┴───┴───┴───┴───┘
│                                     │
│  ████████████░░░░░ 8.4s             │
│                                     │
│  ┌─────────────┐ ┌─────────────┐   │
│  │  X-Wing     │ │ Naked Pair  │   │
│  └─────────────┘ └─────────────┘   │
│  ┌─────────────┐ ┌─────────────┐   │
│  │  Swordfish  │ │ Hidden Quad │   │
│  └─────────────┘ └─────────────┘   │
│                                     │
│  ── streak: 6 ──                    │
└─────────────────────────────────────┘
```

---

## Difficulty Modes

| Mode   | Strategies included                                                                                                    | Distractor curve                                                                | Starting time | Decay         | Floor |
| ------ | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------------- | ------------- | ----- |
| Chill  | Beginner + Easy (Hidden/Naked Single, Pointing Pair/Triple, Box/Line Reduction, Naked/Hidden Pair)                     | Rounds 1–5: wide (any tier). Rounds 6+: same tier.                              | 15s           | −0.3s / round | 10s   |
| Quick  | + Medium (Naked/Hidden Triple/Quad, X-Wing, Swordfish, Jellyfish)                                                     | Rounds 1–3: wide. Rounds 4–10: same tier. Rounds 11+: same sub-family.          | 12s           | −0.2s / round | 7s    |
| Sprint | All strategies (+ XY-Wing, XYZ-Wing, Unique Rectangles, Coloring, Chains, Forcing Chain, ALS, Sue de Coq)             | Rounds 1–2: wide. Rounds 3–7: same tier. Rounds 8+: same sub-family.            | 10s           | −0.2s / round | 5s    |

### Strategy Sub-Families

Used for tight (same sub-family) distractor selection:

- **Singles:** Naked Single, Hidden Single
- **Pairs/Tuples:** Naked/Hidden Pair, Triple, Quad
- **Intersections:** Pointing Pair, Pointing Triple, Box/Line Reduction
- **Fish:** X-Wing, Swordfish, Jellyfish
- **Wings:** XY-Wing, XYZ-Wing
- **Unique Rectangles:** Types 1, 2, 3, 4
- **Chains:** Simple Coloring, X-Chain, XY-Chain, AIC, Forcing Chain
- **Advanced Sets:** ALS, Sue de Coq

For sub-families with ≤ 2 members (e.g., Singles, Wings, Advanced Sets), skip sub-family tightening and use same-tier distractors instead.

Timer behavior identical to the other training games: countdown bar that resets on correct answer, accent → yellow → red color transition as time runs low.

---

## Board Generation

### Approach

1. Generate a puzzle at the appropriate difficulty for the mode:
   - **Chill:** Beginner or Easy puzzle.
   - **Quick:** Medium puzzle.
   - **Sprint:** Hard, Expert, or Master puzzle.
2. Run the solver step-by-step.
3. At each step, check if the strategy used is in the mode's strategy pool. If yes, freeze the board at the state _before_ that step was applied — this is the challenge board.
4. The correct answer = that step's strategy type.
5. Use the solver's internal candidate grid at the frozen state (not raw "digits minus peers") — earlier solver steps may have eliminated candidates that basic cross-referencing wouldn't catch.

### Ensuring clean challenges

- **Skip naked/hidden singles in Quick and Sprint.** These are trivially easy to spot and would feel like freebie rounds at higher modes. Only include them in Chill.
- **Skip backtracking steps.** If the solver falls back to backtracking, discard that puzzle and generate a new one.
- **Multiple strategies at the same state:** The solver may find multiple strategies applicable simultaneously. Pick the more advanced one as the correct answer. Exclude all other applicable strategies from the distractor pool — if Hidden Single also applies and appears as a distractor, the player could argue it's correct. Store the full list of applicable strategies for this exclusion check.

### Avoiding repetition

- Don't show the same strategy on consecutive rounds.
- Track a recent-strategy window (last 3) and re-roll if a repeat would occur.
- **Frequency balancing:** Without balancing, Chill would be ~80% Hidden Singles. Track appearance counts per strategy in the current run. When selecting the next board, prefer strategies with lower counts. Cap re-rolls at 5 to avoid lag — use what you have if nothing better comes up.

### Performance

- Beginner/Easy puzzles generate fast — Chill mode is instant.
- Medium+ puzzles are slower. Pre-buffer 3 boards ahead while the player is answering the current round. Generation runs in an isolate or microtask to avoid frame drops.
- If the buffer is empty when needed (rare), show a brief loading shimmer on the board.

---

## Distractor Selection

Given the correct strategy `S` at round `R`:

1. **Determine tightness level** based on mode + round number (from the Difficulty Modes table):
   - **Wide:** any strategy from the mode's full pool (excluding `S`).
   - **Same tier:** strategies from the same difficulty tier as `S`.
   - **Same sub-family:** strategies from the same sub-family as `S`.

2. **Build the candidate pool** at the current tightness level. Remove `S`.

3. **Remove any strategy that also applies** at the current board state (multiple-strategy exclusion).

4. **If the pool has 3+ strategies:** pick 3 at random.

5. **If the pool has fewer than 3:** relax one level (sub-family → same tier → wide) and fill the remaining slots from the broader pool.

6. **Shuffle** the 4 options (correct + 3 distractors) into random positions in the 2×2 grid.

---

## Input & Interaction

- **Answer buttons:** 2×2 grid of strategy name buttons below the timer bar. Buttons use surface container styling.
- **Tap to answer:** one tap, immediate feedback. No confirmation dialog.
- **Correct answer:** brief green flash on the tapped button. Board crossfades to next challenge (200ms).
- **Wrong answer:** brief red flash on the tapped button, correct answer highlighted in green. Then transition to results screen.
- **Timeout:** timer bar pulses red, correct answer highlighted in green. Then transition to results screen.
- All animations respect the global animation toggle.

---

## Results Screen

### Wrong Answer

1. **Board stays visible** with the pattern cells highlighted (using the solver step's highlight data — same cells and candidates that the strategy guide would show).
2. **Correct strategy name** displayed prominently with the strategy guide's intro text below it. E.g.:
   - **"X-Wing"**
   - _"When a candidate appears in exactly two cells in each of two rows, and those cells share the same two columns, you can eliminate that candidate from all other cells in those columns."_
3. **What you tapped** shown dimmed with a small "✗".
4. **Tappable link** to the full strategy walkthrough — "Learn X-Wing →".

### Timeout

Same as wrong answer, but header says "Time's up" instead of showing what was tapped.

### Standard Results (both cases)

- Final streak and total time.
- Leaderboard position (celebration if top 3 / new record).
- Average time per answer.
- **Strategy breakdown:** compact list of strategies that appeared during the run with ✓/✗ marks. E.g.: "✓ Naked Pair · ✓ X-Wing · ✓ Pointing Pair · ✗ Swordfish". Quick read on weak spots.
- **Play Again** (same mode) and **Back to Training** buttons.

---

## Scoring & Leaderboard

- **Score** = streak count (consecutive correct answers).
- **Top 10 leaderboard per mode**, stored in `TrainingStorageService`.
- **Ranking:** higher streak wins. Tiebreaker = lower total time.
- Each entry: `streak`, `totalTimeMs`, `playedAt`.
- Uses default `TrainingScore.compare` (higher-better).
- Best score shown during gameplay.

### Storage

- Key helper: `TrainingStorageService.spotThePatternKey(SpotThePatternMode mode)` → `'spotThePattern_chill'`, etc.
- `setLastPlayedKey()` called before `addScore()`.

---

## Navigation

- Training Hub → "Spot the Pattern" card with Chill / Quick / Sprint mode buttons inline.
- Card sits below Bulls & Cows, replacing one of the locked "Soon" cards.
- **Icon:** `Icons.visibility` (an eye — "spot" the pattern).
- **Card description:** "Name the strategy — can you see it?"
- Tapping a mode goes straight into gameplay.
- Remaining locked card: Candidate Killer stays as the "Soon" placeholder.

---

## UI & Visual Design

Same minimal chrome approach as all training games:

- **Top bar:** Score (current streak) and best score for the mode.
- **Prompt:** "Which strategy applies here?" — always the same, the board is the variable.
- **Board:** Full 9×9 with candidates visible in all empty cells. Uses the existing `BoardWidget`. Given cells styled as givens, solver-placed cells styled as filled values. Candidates use the same small-number rendering as the main game's pencil marks.
- **Timer bar:** Below the board, same horizontal countdown bar as other games.
- **Answer buttons:** 2×2 grid below the timer bar. Strategy names in surface container styled buttons. Accent color on selection.
- **Streak counter:** Below the answer buttons.
- All animations respect the global animation toggle.

---

## Future Extension: Tap the Pattern (Phase 2)

A future difficulty upgrade where, after naming the strategy correctly, the player must also tap the cells involved in the pattern (e.g., the 4 corners of an X-Wing). Two-phase answer: recognition + understanding. Not in scope for the initial implementation — listed here as a designed upgrade path.
