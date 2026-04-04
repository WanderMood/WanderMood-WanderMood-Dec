#!/usr/bin/env python3
"""Merge scripts/l10n_batch_translations.tsv into app_de, app_es, app_fr, app_nl.

Source file: tab-separated, UTF-8, first row is the header:

  key	de	es	fr	nl

For each row, updates all four locale ARBs and copies @key placeholder metadata
from lib/l10n/app_en.arb when present.

Usage (from repo root):
  python3 scripts/merge_l10n_batch.py
  flutter gen-l10n
"""

from __future__ import annotations

import copy
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N = ROOT / "lib" / "l10n"
TSV_PATH = ROOT / "scripts" / "l10n_batch_translations.tsv"
EN_PATH = L10N / "app_en.arb"

HEADER_LOCALES = ("de", "es", "fr", "nl")


def load_tsv() -> tuple[list[str], list[tuple[str, ...]]]:
    with TSV_PATH.open(encoding="utf-8", newline="") as f:
        rows_list = list(csv.reader(f, delimiter="\t"))
    if not rows_list:
        raise SystemExit("Empty TSV")
    header = rows_list[0]
    expected_rest = list(HEADER_LOCALES)
    if header[0] != "key" or list(header[1:]) != expected_rest:
        want = "key\t" + "\t".join(HEADER_LOCALES)
        raise SystemExit(f"Expected header {want!r}, got {header!r}")
    rows: list[tuple[str, ...]] = []
    for i, parts in enumerate(rows_list[1:], start=2):
        if not parts or (len(parts) == 1 and not parts[0].strip()):
            continue
        if len(parts) != 5:
            raise SystemExit(
                f"Line {i}: expected 5 columns, got {len(parts)}: {parts[:2]!r}…"
            )
        rows.append(tuple(parts))
    return header, rows


def main() -> None:
    _, rows = load_tsv()
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))

    for col_idx, code in enumerate(HEADER_LOCALES, start=1):
        path = L10N / f"app_{code}.arb"
        data = json.loads(path.read_text(encoding="utf-8"))
        for parts in rows:
            key = parts[0]
            val = parts[col_idx]
            data[key] = val
            meta_key = f"@{key}"
            if meta_key in en:
                data[meta_key] = copy.deepcopy(en[meta_key])
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Updated {path} ({len(rows)} keys)")

    print("Done.")


if __name__ == "__main__":
    main()
