#!/usr/bin/env python3
# EN: Builds Localizable.xcstrings from strings_bundle.S (+ clones / fallback to English).
# RU: Собирает Localizable.xcstrings из strings_bundle.S (+ клоны / запасной английский).

from __future__ import annotations

import json
from pathlib import Path

from strings_bundle import S

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Localizable.xcstrings"

KEYS = [
    "game.button.new_game",
    "game.mode.two_players",
    "game.mode.vs_computer",
    "game.side.crosses",
    "game.side.noughts",
    "game.draw",
    "game.turn.crosses",
    "game.turn.noughts",
    "game.turn.your.crosses",
    "game.turn.your.noughts",
    "game.turn.computer.crosses",
    "game.turn.computer.noughts",
    "game.turn.only.crosses",
    "game.turn.only.noughts",
    "game.win.crosses",
    "game.win.noughts",
    "game.win.you",
    "game.win.computer",
    "game.settings.board",
    "game.settings.win_line",
    "game.settings.ai_difficulty",
    "game.ai.easy",
    "game.ai.medium",
    "game.ai.hard",
    "game.settings.theme",
    "game.theme.classic",
    "game.theme.aurora",
    "game.theme.grove",
    "game.theme.ember",
    "game.theme.locked_badge",
    "game.stats.vs_ai",
    "game.stats.streak",
    "game.stats.best",
    "game.sound.on",
    "game.sound.off",
    "game.theme.unlock.intro",
    "game.theme.unlock.details",
]

REQUIRED_LOCALES = [
    "ar",
    "ca",
    "cs",
    "da",
    "de",
    "el",
    "en",
    "en-AU",
    "en-CA",
    "en-GB",
    "en-IN",
    "es",
    "es-419",
    "fi",
    "fr",
    "fr-CA",
    "he",
    "hi",
    "hr",
    "hu",
    "id",
    "it",
    "ja",
    "ko",
    "ms",
    "nb",
    "nl",
    "pl",
    "pt-BR",
    "pt-PT",
    "ro",
    "ru",
    "sk",
    "sv",
    "th",
    "tr",
    "uk",
    "vi",
    "zh-Hans",
    "zh-Hant",
]

CLONE_FROM_EN = frozenset({"en-AU", "en-CA", "en-GB", "en-IN"})
CLONE_FROM_ES = frozenset({"es-419"})
CLONE_FROM_FR = frozenset({"fr-CA"})


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def row(locale: str) -> tuple[str, ...]:
    if locale in CLONE_FROM_EN:
        return S["en"]
    if locale in CLONE_FROM_ES:
        return S["es"]
    if locale in CLONE_FROM_FR:
        return S["fr"]
    if locale in S:
        return S[locale]
    return S["en"]


def main() -> None:
    for loc, tup in S.items():
        if len(tup) != len(KEYS):
            raise SystemExit(f"strings_bundle.S[{loc!r}] length {len(tup)} != {len(KEYS)}")

    table: dict[str, dict[str, str]] = {}
    for loc in REQUIRED_LOCALES:
        tup = row(loc)
        table[loc] = dict(zip(KEYS, tup))

    strings_out: dict[str, dict] = {}
    for key in KEYS:
        locs = {locale: unit(table[locale][key]) for locale in REQUIRED_LOCALES}
        strings_out[key] = {"localizations": locs}

    doc = {
        "sourceLanguage": "en",
        "strings": strings_out,
        "version": "1.0",
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(REQUIRED_LOCALES)} locales, {len(KEYS)} keys)")


if __name__ == "__main__":
    main()
