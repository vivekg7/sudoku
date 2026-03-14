# Puzzle Generation — Performance Optimization Plan

> Master difficulty takes considerably longer to generate, and bulk PDF generation (6+ puzzles) is painfully slow on Android. This plan targets the root causes.

---

## Bottleneck Analysis

### 1. Backtracking clones the entire board at every recursion level

`backtracking.dart:71,124` — Both `_solve()` and `_countSolutions()` call `board.clone()` for **every candidate attempt**. With Master puzzles having ~60 empty cells, this creates hundreds of deep copies (81 cells × candidate sets each). This is the single biggest source of allocation and GC pressure.

### 2. Double-solving during clue removal

`puzzle_generator.dart:191–204` — For each symmetric pair removal, the generator runs **both** `Backtracking.countSolutions()` AND `Solver.solve()` (all 23 strategies). That's ~40 pairs × 2 full solves ≈ 80 expensive operations per generation attempt.

### 3. `peers()` rebuilds a list on every call

`board.dart:61–68` — Creates a `Set`, adds 3 houses (allocating 3 unmodifiable lists), converts to `List`. Called hundreds of times during backtracking and strategy application. Peer indices are **static** — they only depend on grid geometry and never change.

### 4. PDF generates all puzzles sequentially in one isolate

`pdf_service.dart:51–54` — A single `compute()` isolate generates all puzzles in a `for` loop. 6 Master puzzles × 30–60 s each = minutes of blocking work on one core while the rest sit idle.

### 5. PDF solves each puzzle a second time for solve order

`pdf_service.dart:59` — Calls `Solver.solve()` again to compute solve order, even though generation already solved the puzzle during difficulty classification. The solve result is discarded and recomputed.

### 6. `combinations()` eagerly allocates all results

`strategy_utils.dart:2–17` — ALS calls `combinations(emptyCells, 4)` which can produce 126+ lists per house × 27 houses, all allocated upfront into a single `List<List<T>>`.

---

## Optimization Plan

Listed in priority order — highest impact first.

### O1. Backtracking: undo-and-restore instead of clone

**Impact:** Very High · **Effort:** Medium

Instead of cloning the board for each candidate attempt, set the value, propagate candidate removals, then **undo** them on backtrack. Track changes in a small undo list rather than copying 81 cells.

Applies to `_solve()`, `_countSolutions()`, and `_fillRemaining()` in the generator.

### O2. Cache peer indices statically

**Impact:** High · **Effort:** Low

Pre-compute a `static final List<List<(int, int)>> _peerIndices` table (81 entries, each listing 20 peer coordinates). `peers()` then returns cells by index lookup — no Set, no List allocation.

### O3. PDF: parallelise puzzle generation across isolates

**Impact:** High · **Effort:** Low

Instead of one `compute()` call generating N puzzles sequentially, spawn `min(N, Platform.numberOfProcessors)` isolates each generating a subset. All puzzles generate concurrently.

### O4. PDF: pass solve result through from generation

**Impact:** Medium · **Effort:** Low

Have `PuzzleGenerator.generate()` return the `SolveResult` alongside the `Puzzle` (or attach it to `Puzzle`). `_computeSolveOrder` then reads the cached steps instead of re-solving.

### O5. Skip `solver.solve()` early in clue removal

**Impact:** Medium · **Effort:** Low

During `_removeCluesToDifficulty`, if the current given count is still well above `givenRange.max` for the target difficulty, the puzzle is almost certainly easier than target. Skip the full `solver.solve()` call and only run it once givens drop into the target range. Still run `countSolutions()` every time to preserve uniqueness.

### O6. Iterator-based combinations

**Impact:** Medium · **Effort:** Medium

Replace `List<List<T>> combinations()` with an `Iterable<List<T>>` that yields one combination at a time. Strategies that find a result early (common case) avoid generating the remaining combinations. Eliminates bulk allocation in ALS, naked/hidden subsets, and fish.

---

## Implementation Order

```
O2 (peer cache)  →  O1 (backtracking undo)  →  O5 (skip early solves)
                                               →  O4 (cache solve result)
                                               →  O3 (parallel isolates)
                                               →  O6 (lazy combinations)
```

O2 first because it's the easiest win and unblocks cleaner undo logic in O1. O1 next as the single biggest performance gain. O3–O6 are independent of each other and can be done in any order.
