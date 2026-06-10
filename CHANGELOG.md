# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [2.1.0] — 2026-06-10

### Added

- Keyboard navigation: arrow keys move focus, Return plays, ⌘N starts a new game.
- VoiceOver announcements and SKView accessibility summary.
- Persisted game settings: opponent mode, board size, win length, human side.
- `GameProgress` unit tests; seeded AI randomness for deterministic tests.
- Separate localization keys per theme unlock line; formatted stats line for RTL-friendly locales.
- Accessibility string keys in `Localizable.xcstrings`.

### Changed

- Split `GameScene` into focused modules (`GameScene+HUD`, `GameScene+Keyboard`, `BoardRenderer`, `GameInputHandler`, …).
- `GameModel` deduplicates win-line detection; AI reuses cached line segments.
- Bundle identifier: `com.karakuts.tic-tac-toe`.
- Release workflow runs unit tests before building the DMG.

### Removed

- Unused `makeThemeUnlockCard` HUD builder (legend lives under the board).

## [2.0.2] — 2026

- Stats, themes, sound toggle, AI difficulty, 40-locale String Catalog.
