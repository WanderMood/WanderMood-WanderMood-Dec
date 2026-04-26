#!/usr/bin/env python3
"""
Resize and recompress large JPEGs bundled under assets/images/.

- Max long edge: 1920 (enough for @3x phone full-width backgrounds).
- Quality: 82, optimized Huffman, progressive (smaller for same quality).

Run from repo root: python3 tool/compress_bundle_jpegs.py
"""
from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image, ImageOps
except ImportError as e:
    print("Install Pillow: pip install pillow", file=sys.stderr)
    raise e

REPO = Path(__file__).resolve().parents[1]
ASSETS = REPO / "assets" / "images"
MAX_EDGE = 1920
QUALITY = 82
# Skip tiny JPEGs (favicons / already-tiny); avoids needless re-encode.
MIN_BYTES_TO_TOUCH = 80 * 1024


def process(path: Path) -> tuple[int, int, str]:
    before = path.stat().st_size
    with Image.open(path) as im:
        im = ImageOps.exif_transpose(im)
        w, h = im.size
        m = max(w, h)
        if m <= MAX_EDGE and before < MIN_BYTES_TO_TOUCH:
            return before, before, f"{w}x{h} (skip, small file)"
        if m > MAX_EDGE:
            r = MAX_EDGE / m
            new_w, new_h = int(w * r), int(h * r)
            im = im.resize((new_w, new_h), Image.Resampling.LANCZOS)
        else:
            new_w, new_h = w, h
        if im.mode not in ("RGB", "L"):
            bg = (255, 255, 255) if im.mode in ("RGBA", "P", "PA") else None
            if bg is not None and im.mode == "RGBA":
                b = Image.new("RGB", im.size, bg)
                b.paste(im, mask=im.split()[-1])
                im = b
            else:
                im = im.convert("RGB")
        elif im.mode == "L":
            im = im.convert("RGB")
        im.save(
            path,
            format="JPEG",
            quality=QUALITY,
            subsampling=2,
            optimize=True,
            progressive=True,
        )
    after = path.stat().st_size
    return before, after, f"{w}x{h} -> {new_w}x{new_h}"


def main() -> int:
    if not ASSETS.is_dir():
        print("Missing", ASSETS, file=sys.stderr)
        return 1
    total_before = 0
    total_after = 0
    n = 0
    for p in sorted(ASSETS.rglob("*.jpg")) + sorted(ASSETS.rglob("*.jpeg")):
        if p.is_file() and p.stat().st_size > 0:
            b, a, dim = process(p)
            if b == a and "skip" in dim:
                continue
            total_before += b
            total_after += a
            n += 1
            if a != b:
                pct = 100.0 * (1 - a / b) if b else 0
                print(f"{p.relative_to(REPO)}: {b} -> {a} bytes (-{pct:.0f}%)  {dim}")
            else:
                print(f"{p.relative_to(REPO)}: {b} bytes  {dim}")
    saved = total_before - total_after
    print(
        f"\n JPEG files: {n},  {total_before/1e6:.1f} MB -> {total_after/1e6:.1f} MB  "
        f"saved {saved/1e6:.1f} MB"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
