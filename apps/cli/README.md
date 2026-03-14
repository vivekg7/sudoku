# Sudoku CLI

Play Sudoku in the terminal with full solving engine, progressive hints, and stats tracking.

## Quick Start

```bash
# Run directly
dart run bin/cli.dart

# With a specific difficulty (beginner, easy, medium, hard, expert, master)
dart run bin/cli.dart -d medium

# Compile to a standalone binary (builds for your current OS and architecture only)
dart compile exe bin/cli.dart -o sudoku
./sudoku -d easy
```

## Cross-Compiling for Other Platforms

`dart compile exe` builds for your current OS and architecture only. To build for other Linux targets, use Docker (with QEMU for ARM emulation):

```bash
# Linux x86_64
docker run --rm -v "$PWD":/app -w /app dart:stable dart compile exe bin/cli.dart -o sudoku-linux-x86_64

# Linux ARM64 (e.g. Raspberry Pi 4/5, ARM servers)
docker run --rm --platform linux/arm64 -v "$PWD":/app -w /app dart:stable dart compile exe bin/cli.dart -o sudoku-linux-arm64

# Linux ARM32 (e.g. Raspberry Pi Zero/3)
docker run --rm --platform linux/arm/v7 -v "$PWD":/app -w /app dart:stable dart compile exe bin/cli.dart -o sudoku-linux-arm32
```

For macOS, you'll need to compile natively on the target architecture — Docker can't produce macOS binaries.

## Publishing to Homebrew

1. Compile the binary and create a GitHub release with the binary attached.
2. Create a tap repo (e.g. `your-username/homebrew-sudoku`) with a formula file `sudoku.rb`:

```ruby
class Sudoku < Formula
  desc "Play Sudoku in the terminal with hints and stats"
  homepage "https://github.com/your-username/sudoku"
  url "https://github.com/your-username/sudoku/releases/download/v1.0.0/sudoku-macos-arm64.tar.gz"
  sha256 "YOUR_SHA256_HERE"

  def install
    bin.install "sudoku"
  end
end
```

3. Users install with: `brew install your-username/sudoku/sudoku`

Generate the sha256 with `shasum -a 256 sudoku-macos-arm64.tar.gz`.

## Commands

All commands are case-insensitive. Abbreviations are shown in parentheses.

| Command               | Example     | What it does                           |
| --------------------- | ----------- | -------------------------------------- |
| `go <RC>` (`g`)       | `go 35`     | Select row 3, col 5                    |
| `set <value>` (`s`)   | `set 7`     | Place 7 at cursor                      |
| `set <RC> <value>`    | `set 35 7`  | Place 7 at R3C5                        |
| `<RC> <value>`        | `35 7`      | Shorthand: place 7 at R3C5             |
| `clear` (`c`)         | `clear`     | Clear cursor cell                      |
| `clear <RC>`          | `clear 35`  | Clear cell at R3C5                     |
| `note <value>` (`n`)  | `note 4`    | Toggle candidate 4 at cursor           |
| `note <RC> <value>`   | `note 35 4` | Toggle candidate 4 at R3C5             |
| `candidates`          |             | Toggle candidate display               |
| `undo` (`u`)          |             | Undo last move                         |
| `redo` (`r`)          |             | Redo last undone move                  |
| `hint`                |             | Get a hint (tap again for more detail) |
| `solve`               |             | Reveal the full solution               |
| `timer`               |             | Show elapsed time                      |
| `pause` / `resume`    |             | Pause or resume timer                  |
| `stats`               |             | Show game stats                        |
| `help` (`h`)          |             | Show command help                      |
| `quit` / `exit` (`q`) |             | Exit (offers to save)                  |

## Flags

| Flag                   | Short | What it does                                                  |
| ---------------------- | ----- | ------------------------------------------------------------- |
| `--difficulty <level>` | `-d`  | Set difficulty (beginner, easy, medium, hard, expert, master) |
| `--import <string>`    |       | Import puzzle from 81-char string (0 = empty)                 |
| `--load <file>`        | `-l`  | Load a saved game from JSON file                              |
| `--save-file <file>`   | `-s`  | Set save file path (default: `sudoku_save.json`)              |
| `--stats`              |       | View accumulated stats and exit                               |
| `--help`               | `-h`  | Show usage and exit                                           |
