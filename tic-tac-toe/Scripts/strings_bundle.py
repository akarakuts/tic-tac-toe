# EN: Per-locale UI strings (37 rows; order matches generate_localizable.KEYS).
# RU: Строки интерфейса по локалям (37 строк; порядок как в generate_localizable.KEYS).

from __future__ import annotations

import json
from pathlib import Path

_PATH = Path(__file__).with_name("bundle_strings.json")
_raw = json.loads(_PATH.read_text(encoding="utf-8"))
S: dict[str, tuple[str, ...]] = {loc: tuple(rows) for loc, rows in _raw.items()}
