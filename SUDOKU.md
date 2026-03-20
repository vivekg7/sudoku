# Sudoku — Rules & Solving Strategies

> Internal reference for contributors and the solving engine.

---

## What is Sudoku?

Sudoku is a logic-based number-placement puzzle played on a 9x9 grid, divided into nine 3x3 boxes. Some cells are pre-filled with digits (called **givens** or **clues**). The goal is to fill every empty cell with a digit from 1 to 9 so that the constraints below are satisfied.

---

## What Makes a Valid Sudoku?

A completed Sudoku is **valid** if and only if:

1. **Row constraint** — Each row contains the digits 1–9 exactly once.
2. **Column constraint** — Each column contains the digits 1–9 exactly once.
3. **Box constraint** — Each 3x3 box contains the digits 1–9 exactly once.

A Sudoku **puzzle** (i.e. the starting grid with clues) is considered valid if:

- It has **exactly one solution**.
- The givens do not violate any of the three constraints above.

---

## What Makes a Sudoku Invalid?

A Sudoku is **invalid** if any of the following are true:

- A digit appears more than once in the same row, column, or box.
- A cell is empty and has **no legal candidates** (no digit can be placed without breaking a constraint).
- The puzzle has **zero solutions** (unsolvable) or **more than one solution** (ambiguous).

---

## Terminology

| Term                   | Meaning                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Cell**               | A single square in the grid, identified by row and column (e.g. R4C5).                                    |
| **Row / Column / Box** | The three unit types — a group of 9 cells that must each contain 1–9.                                     |
| **Unit**               | Generic term for any row, column, or box.                                                                 |
| **Peers**              | All cells that share a unit with a given cell (20 peers per cell).                                        |
| **Givens / Clues**     | The pre-filled digits provided at the start.                                                              |
| **Candidates**         | The set of digits still possible for an unsolved cell (also called pencil marks or notes).                |
| **Elimination**        | Removing a candidate from a cell based on logical deduction.                                              |
| **Placement**          | Determining the final value of a cell.                                                                    |
| **Conjugate pair**     | Two cells in a unit that are the only places for a particular digit — if one is true, the other is false. |
| **Strong link**        | A link between two candidates where exactly one must be true (e.g. a conjugate pair).                     |
| **Weak link**          | A link between two candidates where at least one must be false (they can see each other).                 |
| **Chain**              | A sequence of cells connected by alternating strong and weak links.                                       |

---

## Solving Strategies

Strategies are listed in approximate order of difficulty, from easiest to hardest.

### Basic — Singles

| Strategy          | Description                                                                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Hidden Single** | A digit can only go in one cell within a row, column, or box — even though that cell has other candidates. Easiest for humans: just scan a house for where a digit fits. |
| **Naked Single**  | A cell has only one candidate left — it must be that digit. Harder to spot than hidden singles because it requires eliminating all other candidates first.               |

### Basic — Subsets

| Strategy          | Description                                                                                                                |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Naked Pair**    | Two cells in a unit share the same two candidates — those digits can be eliminated from all other cells in that unit.      |
| **Hidden Pair**   | Two digits in a unit appear only in the same two cells — all other candidates can be removed from those cells.             |
| **Naked Triple**  | Three cells in a unit have candidates drawn from the same three digits — eliminate those digits from the rest of the unit. |
| **Hidden Triple** | Three digits in a unit are confined to the same three cells — remove all other candidates from those cells.                |
| **Naked Quad**    | Four cells in a unit have candidates drawn from the same four digits — eliminate those digits from the rest of the unit.   |
| **Hidden Quad**   | Four digits in a unit are confined to the same four cells — remove all other candidates from those cells.                  |

### Basic — Intersections

| Strategy                          | Description                                                                                                                                          |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pointing Pair/Triple**          | A digit's candidates within a box are confined to a single row or column — eliminate that digit from the rest of that row or column outside the box. |
| **Box/Line Reduction (Claiming)** | A digit's candidates within a row or column are confined to a single box — eliminate that digit from the rest of that box.                           |

### Intermediate — Fish

| Strategy      | Description                                                                                                                                                                                              |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **X-Wing**    | A digit appears in exactly two positions in each of two rows, and those positions align on the same two columns — eliminate that digit from the rest of those columns (and vice versa for columns/rows). |
| **Swordfish** | The X-Wing idea extended to three rows and three columns — a digit's candidates form a grid pattern that allows eliminations along the covering columns (or rows).                                       |
| **Jellyfish** | The fish pattern extended to four rows and four columns.                                                                                                                                                 |

### Intermediate — Wings

| Strategy     | Description                                                                                                                                                                             |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **XY-Wing**  | A pivot cell with two candidates sees two wing cells that each share one candidate with the pivot — any cell that sees both wings can have their common non-pivot candidate eliminated. |
| **XYZ-Wing** | Like XY-Wing but the pivot has three candidates, and cells that see all three (pivot + wings) can have the shared candidate eliminated.                                                 |

### Intermediate — Uniqueness

| Strategy                      | Description                                                                                                                                                                                                                                                         |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Unique Rectangle (Type 1)** | Four cells in two rows, two columns, and two boxes form a rectangle with the same two candidates — if three corners are bivalue, the fourth must not hold both digits (otherwise two solutions exist), so extra candidates in the fourth corner allow eliminations. |
| **Unique Rectangle (Type 2)** | Three corners of the rectangle are bivalue; the fourth has one extra candidate — that extra candidate can be eliminated from peers that see all cells containing it in the rectangle.                                                                               |
| **Unique Rectangle (Type 3)** | The rectangle has extra candidates that form a naked subset with other cells in the unit, allowing eliminations.                                                                                                                                                    |
| **Unique Rectangle (Type 4)** | One of the two rectangle digits is confined to the two non-bivalue cells within their shared unit — the other rectangle digit can be eliminated from those cells.                                                                                                   |

### Advanced — Coloring & Chains

| Strategy                              | Description                                                                                                                                                                                                                 |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Simple Coloring**                   | Assign two colors to a digit's conjugate pairs — if two cells of the same color see each other, that color is false; any uncolored cell that sees both colors can have the digit eliminated.                                |
| **X-Chain**                           | A chain of cells connected by alternating strong and weak links on a single digit — the digit can be eliminated from any cell that sees both ends of the chain.                                                             |
| **XY-Chain**                          | A chain of bivalue cells connected by alternating strong and weak links across multiple digits — the starting and ending digits allow eliminations in cells that see both chain endpoints.                                  |
| **Alternating Inference Chain (AIC)** | A generalized chain using strong and weak links on any candidates — if the chain starts and ends with strong links on the same candidate, that candidate can be placed or eliminated depending on what the endpoints share. |
| **Forcing Chain**                     | Assume a candidate is true, then assume it is false — if both assumptions lead to the same conclusion (a placement or elimination), that conclusion must be true.                                                           |

### Advanced — Set-Based

| Strategy                    | Description                                                                                                                                                                                      |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Almost Locked Set (ALS)** | A group of N cells with N+1 candidates — two ALS groups that share a restricted common candidate can force eliminations on any other common candidate visible to both groups.                    |
| **Sue de Coq**              | An intersection of a box and a line contains candidates that split into two subsets, each locking with an ALS outside the intersection — candidates not part of either subset can be eliminated. |

### Fallback

| Strategy         | Description                                                                                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Backtracking** | A brute-force depth-first search — try a candidate, recurse, and backtrack on contradiction. Used only for validation and puzzle generation, never for hints. |

---

## What This App Will Never Suggest

**Bifurcation (Trial & Error)** — Pick a candidate, assume it's correct, keep solving, and backtrack if you hit a contradiction. Some players do this on paper when stuck between two options. It "works", but it replaces logic with guessing. Every situation where bifurcation seems necessary can be resolved by a chain or coloring strategy instead. This app exists to teach those strategies — not to shortcut past them.
