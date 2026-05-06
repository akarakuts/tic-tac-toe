# tic-tac-toe

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Russian / Русский: [README.ru.md](README.ru.md)

Repository: **https://github.com/akarakuts/tic-tac-toe**

```bash
git clone https://github.com/akarakuts/tic-tac-toe.git
cd tic-tac-toe
```

A native **macOS** tic-tac-toe (n-in-a-row on a square grid) built with **SpriteKit** and **Swift**. Two players share one screen, or one player can face the computer. The UI supports flexible board sizes, win conditions, unlockable board themes, and persistent statistics versus the AI.

## Features

- **Board size** — from **3×3** up to **6×6**, chosen in the left settings column.
- **Win condition** — line length to win from **3** to **6**; values larger than the board edge are disabled (must be ≤ board size). Wins count along rows, columns, and both diagonals.
- **Two-player mode** — alternating moves on a single board (✕ starts).
- **Versus computer** — minimax with alpha–beta pruning; choose whether you play as crosses (✕) or noughts (○).
  - On **3×3** with three-in-a-row and **Hard** difficulty, the AI can search deep enough for effectively optimal play. **Easy** and **Medium** always cap lookahead (weaker, more human-feeling).
  - On **larger boards**, search is depth-limited with a positional heuristic; immediate win and (usually) block moves still apply. **Easy** sometimes skips a block or plays randomly; **Medium** occasionally picks a near-best move.
- **AI difficulty** — **Easy**, **Medium**, and **Hard** (shown in the left column). In **Two-player mode** these controls stay visible but are **disabled**; in **Versus computer** they are active. Choice is saved between launches.
- **Board themes** — **Classic** plus three palettes (**Aurora**, **Grove**, **Ember**) layered on system light/dark appearance and accent colour (`BoardAppearance.swift`).
  - **Classic** is always available.
  - Unlocks apply only to finished games **vs computer**: **Aurora** after your **first** win vs AI; **Grove** after **5** cumulative wins vs AI; **Ember** after a **best win streak** of **3** (current streak resets on loss or draw). A short unlock legend is shown **under the board**.
- **Statistics** — footer line with **W–L–D** vs AI, **current streak**, and **best streak**; updated when a vs-AI round ends. Stored with other progress in **UserDefaults**.
- **Sound** — optional move / win / error feedback (`GameSoundFX`); **Sound on/off** toggle is persisted.
- **Layout** — controls live in a **left column** (labels above pill groups); the **grid** uses the remaining area. HUD and the left panel scale with the window, and the theme unlock legend sits **under the board**.
- **Localization** — UI strings live in **`Localizable.xcstrings`** (String Catalog): **40 locale identifiers** aligned with typical macOS language choices (including regional variants such as `en-GB`, `es-419`, `fr-CA`). Source rows are edited in **`tic-tac-toe/Scripts/write_bundle.py`** / **`bundle_strings.json`** and regenerated into the catalog with the scripts below; the running app follows the **system language**.
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

## Regenerating localized strings

After editing translations in `tic-tac-toe/Scripts/write_bundle.py` (or the generated `bundle_strings.json`), refresh the String Catalog from the **Scripts** directory:

```bash
cd tic-tac-toe/Scripts
python3 write_bundle.py          # refreshes bundle_strings.json from write_bundle.py
python3 generate_localizable.py  # writes ../Localizable.xcstrings
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
| `tic-tac-toe/TicTacToeAI.swift` | Minimax AI, difficulty caps, tactical win/block moves |
| `tic-tac-toe/GameScene.swift` | SpriteKit scene: layout, grid, input, HUD, theme/stat controls |
| `tic-tac-toe/GameProgress.swift` | Persisted stats, streaks, unlocks, difficulty, sound flag |
| `tic-tac-toe/BoardAppearance.swift` | `BoardVisualStyle`, palettes for themes |
| `tic-tac-toe/GameSoundFX.swift` | Optional AVFoundation UI sounds |
| `tic-tac-toe/ViewController.swift` | `SKView` hosting the scene, sizing / scale mode |
| `tic-tac-toe/L10n.swift` | Localized string accessors |
| `tic-tac-toe/Localizable.xcstrings` | String Catalog (generated; see Scripts) |
| `tic-tac-toe/Scripts/write_bundle.py` | Authoring translations → `bundle_strings.json` |
| `tic-tac-toe/Scripts/generate_localizable.py` | Builds `Localizable.xcstrings` from the bundle |
| `tic-tac-toe/Scripts/strings_bundle.py` | Loads `bundle_strings.json` for the generator |

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either **version 3** of the License, or (at your option) any later version.

See the [`LICENSE`](LICENSE) file for the complete GPLv3 text.

## Releases

Pushing a **version tag** triggers GitHub Actions: a **Release** is created (with auto-generated notes), and a **`tic-tac-toe-<tag>-macOS.dmg`** is attached — open the DMG, drag **tic-tac-toe.app** to **Applications**. The build is **unsigned**; on first launch you may need **Open** from the context menu in Finder.
