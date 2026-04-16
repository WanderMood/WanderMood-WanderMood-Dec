#!/usr/bin/env python3
"""Insert missing guestDemo* keys from scripts/data/guest_demo_<locale>.json into app_<locale>.arb.

The JSON file is merged as {**en_source, **locale_overrides} so you can omit keys to inherit English.
Run from repo root: python3 scripts/merge_guest_demo_arb.py nl
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ANCHOR = {
    "nl": '  "guestDemoTagEvening": "Avond",\n',
    "de": '  "guestDemoTagEvening": "Abend",\n',
    "fr": '  "guestDemoTagEvening": "Soirée",\n',
    "es": '  "guestDemoTagEvening": "Noche",\n',
}


def keys_in_arb(text: str) -> set[str]:
    return set(re.findall(r'^\s*"([^"]+)"\s*:', text, re.MULTILINE))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("locale", choices=sorted(ANCHOR.keys()))
    args = parser.parse_args()
    loc = args.locale
    root = Path(__file__).resolve().parent.parent
    en_path = root / "scripts/data/guest_demo_en_source.json"
    src = json.loads(en_path.read_text(encoding="utf-8"))
    over_path = root / f"scripts/data/guest_demo_{loc}.json"
    overrides = (
        json.loads(over_path.read_text(encoding="utf-8"))
        if over_path.exists()
        else {}
    )
    merged: dict[str, str] = {**src, **overrides}
    arb_path = root / f"lib/l10n/app_{loc}.arb"
    text = arb_path.read_text(encoding="utf-8")
    existing = keys_in_arb(text)
    anchor = ANCHOR[loc]
    if anchor not in text:
        raise SystemExit(f"Anchor not found for {loc}: {anchor!r}")

    out_lines: list[str] = []
    for key in merged:
        if key in existing:
            continue
        val = merged[key]
        out_lines.append(f"  {json.dumps(key)}: {json.dumps(val, ensure_ascii=False)},\n")
        if key == "guestDemoResultTitleWithMood":
            out_lines.append(
                "  \"@guestDemoResultTitleWithMood\": {\n"
                '    "placeholders": {\n'
                '      "moodLabel": {\n'
                '        "type": "String"\n'
                "      }\n"
                "    }\n"
                "  },\n"
            )

    insert = "".join(out_lines)
    if not insert.strip():
        print(f"{loc}: nothing to insert")
        return
    text = text.replace(anchor, anchor + insert, 1)
    arb_path.write_text(text, encoding="utf-8")
    print(f"{loc}: inserted {len(out_lines)} ARB lines")


if __name__ == "__main__":
    main()
