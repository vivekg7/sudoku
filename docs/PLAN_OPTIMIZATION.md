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

## Phase 2 — Data Representation

### O7. Bitmask candidate representation

**Impact:** Very High · **Effort:** Medium-High

Replace `Set<int> _candidates` in `Cell` with a single `int` bitmask where bit `i` represents candidate `i` (bits 1–9). Values 1–9 map to `1 << 1` through `1 << 9`.

Currently, `.candidates` is accessed 117 times across 19 files, and the getter creates a `Set.unmodifiable` wrapper on every call. Every strategy's inner loop, every backtracking step, and every candidate computation pays this cost.

**Operation comparison:**

| Operation | `Set<int>` (current) | `int` bitmask |
|-----------|---------------------|---------------|
| `contains(v)` | hash lookup + unmodifiable wrapper | `bits & (1 << v) != 0` |
| `add(v)` | hash insert | `bits \|= 1 << v` |
| `remove(v)` | hash delete | `bits &= ~(1 << v)` |
| `length` | O(n) or cached | bit count (~3 ops) |
| `isEmpty` | internal check | `bits == 0` |
| `intersection` | O(n) + heap alloc | `a & b` |
| `union` | O(n) + heap alloc | `a \| b` |
| `clone` | `Set.of(...)` heap alloc | copy the int (free) |
| `iteration` | iterator object | shift loop, no alloc |

**Wins:**
- `Board.clone()` goes from 81 `Set.of()` heap allocations to 81 int copies (zero GC).
- Every strategy inner loop becomes pure integer arithmetic.
- `Set` operations like intersection/union (used heavily by ALS, subsets, unique rectangles) become single bitwise ops.
- Estimated 2–5× faster for the solver overall.

**Touches:** `Cell`, `Board.clone()`, `candidate_helper.dart`, all 19 strategy files, hint engine, tests. The change is mechanical — the API shape stays the same, only the underlying type changes from `Set<int>` to `int`. A `CandidateSet` wrapper type (or extension methods) can keep call sites readable.

**Risk areas:**
- Player-facing pencil marks in Flutter UI — the UI reads `cell.candidates` to render notes. Must ensure the bitmask API is compatible or the UI adapter converts.
- Serialisation — saved puzzles / JSON export may store candidates as lists. Deserialisation must handle both formats for backwards compatibility.
- `Set.unmodifiable` consumers — any code that passes candidates to a `Set<int>` parameter needs updating.
- `cell.candidates.first` / `.toList()` / `.contains()` patterns scattered across strategies — each needs migration to bitmask equivalents.

---

## Status

O1–O6 implemented.

| #   | Optimisation                     | Commit          |
| --- | -------------------------------- | --------------- |
| O1  | Backtracking undo-and-restore    | e5a2f4e         |
| O2  | Static peer index cache          | 6b429d1         |
| O3  | Parallel PDF isolates            | _(this commit)_ |
| O4  | Cached solve result on Puzzle    | _(this commit)_ |
| O5  | Skip early solves in removal     | _(this commit)_ |
| O6  | Lazy iterator-based combinations | _(this commit)_ |
