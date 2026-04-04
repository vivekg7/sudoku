# Share Puzzle — Design

## Goal

Let players share a puzzle as a scannable QR code so others can play the same puzzle in the app.

## Entry Points

1. **Pause screen** — "Share" button below the existing "Resume" button.
2. **Saved games list** — share icon on each puzzle tile.

Both open the same bottom sheet.

## Bottom Sheet Layout

A taller-than-usual modal bottom sheet:

- Small share icon at top
- **"Share Puzzle"** title
- Subtitle: difficulty label (e.g., "Medium")
- **Large QR code** (~200x200 lp), centered, with padding
- Two action buttons side by side:
  - **"Copy Code"** (outlined) — copies the 83-char text code to clipboard, shows snackbar
  - **"Share Image"** (filled) — renders QR to PNG, opens system share sheet

## QR Data Format

Same encoding used in PDF export:

```
S<difficulty_index><81-char-initial-board>
```

Example: `S2530080007000050360000040290800075000070008000700350006084050000002000070000005..`

Always encodes the **initial board** (givens only) — recipient gets a fresh unsolved puzzle.

## Technical Approach

### Packages

- `barcode` (already transitive via `pdf`) — generate QR code matrix
- `share_plus: ^12.0.2` (new) — share PNG via platform share sheet
- `path_provider` (already installed) — temp file for share image

### QR Rendering

Use `barcode` package's `Barcode.qrCode().make()` to get the module matrix, then render with a `CustomPainter`. Wrap in a `RepaintBoundary` for PNG capture.

### Share Image Flow

1. `RepaintBoundary` wraps QR code + difficulty label
2. `boundary.toImage()` → `image.toByteData(format: ImageByteFormat.png)`
3. Write to temp file via `path_provider`
4. `Share.shareXFiles([XFile(path)])` from `share_plus`

### Copy Code Flow

1. Build string: `'S${puzzle.difficulty.index}${puzzle.initialBoard.toFlatString()}'`
2. `Clipboard.setData(ClipboardData(text: code))`
3. Show snackbar: "Puzzle code copied"

## Files to Create/Modify

- **New**: `lib/widgets/share_puzzle_sheet.dart` — the bottom sheet widget + QR painter
- **Modify**: `lib/screens/game_screen.dart` — add Share button to pause screen
- **Modify**: `lib/screens/saved_games_screen.dart` — add share action to puzzle tiles
- **Modify**: `pubspec.yaml` — add `share_plus: ^12.0.2`

## No Core Changes

Purely a Flutter UI feature. No changes to `sudoku_core`.
