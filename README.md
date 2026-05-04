# tic-tac-toe

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Russian / Русский: [README.ru.md](README.ru.md)

Repository: **https://github.com/akarakuts/tic-tac-toe**

```bash
git clone https://github.com/akarakuts/tic-tac-toe.git
cd tic-tac-toe
```

A native **macOS** tic-tac-toe (n-in-a-row on a square grid) built with **SpriteKit** and **Swift**. Two players share one screen, or one player can face the computer. The UI supports flexible board sizes and win conditions.

## Features

- **Board size** — from **3×3** up to **6×6**, chosen in the left settings column.
- **Win condition** — line length to win from **3** to **6**; values larger than the board edge are disabled (must be ≤ board size). Wins count along rows, columns, and both diagonals.
- **Two-player mode** — alternating moves on a single board (✕ starts).
- **Versus computer** — minimax with alpha–beta pruning; choose whether you play as crosses (✕) or noughts (○). On **3×3** with three-in-a-row the AI searches the full game tree (perfect play). On **larger boards** search is depth-limited with a positional heuristic and immediate win / forced-block moves so the game stays responsive.
- **Layout** — controls (board size, win length, mode, side vs AI, **New game**) sit in a **left column**; the **grid expands** to use the remaining window area. The window resizes with the content view so nothing is clipped off-screen.
- **Localization** — UI strings in **English** and **Russian** via `Localizable.xcstrings`; the active language follows the system locale.
- **Polish** — Animated marks, highlighted winning line, light feedback on draws and outcomes.

## Requirements

- macOS (see Xcode project for deployment target and SDK)
- Xcode with Swift 5+ and String Catalog support

## Building & running

1. Open `tic-tac-toe.xcodeproj` in Xcode.
2. Select the **tic-tac-toe** scheme and **My Mac**.
3. Run (**⌘R**).

Command-line build:

```bash
xcodebuild -scheme "tic-tac-toe" -destination 'platform=macOS' build
```

## Testing

Unit tests live in the **tic-tac-toeTests** target (Swift Testing). Example:

```bash
xcodebuild -scheme "tic-tac-toe" -destination 'platform=macOS' -only-testing:tic-tac-toeTests test
```

Core rules are covered in `GameModel` tests; AI behaviour (including non–3×3 boards) is covered in `TicTacToeAITests`.

## Project layout

| Path | Role |
|------|------|
| `tic-tac-toe/GameModel.swift` | Board state, moves, dynamic win-line detection |
| `tic-tac-toe/TicTacToeAI.swift` | Minimax AI, opponent mode, depth limits on large grids |
| `tic-tac-toe/GameScene.swift` | SpriteKit scene: layout, grid, input, HUD, effects |
| `tic-tac-toe/ViewController.swift` | `SKView` hosting the scene, sizing / scale mode |
| `tic-tac-toe/L10n.swift` | Localized string accessors |
| `tic-tac-toe/Localizable.xcstrings` | English & Russian strings |

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either **version 3** of the License, or (at your option) any later version.

See the [`LICENSE`](LICENSE) file for the complete GPLv3 text.

## Releases

Pushing a **version tag** triggers GitHub Actions: a **Release** is created (with auto-generated notes), and a **`tic-tac-toe-<tag>-macOS.dmg`** is attached — open the DMG, drag **tic-tac-toe.app** to **Applications**. The build is **unsigned**; on first launch you may need **Open** from the context menu in Finder.
