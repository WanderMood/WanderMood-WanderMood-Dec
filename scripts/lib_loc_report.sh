#!/usr/bin/env bash
# Hand-maintained Dart LOC for lib/ (excludes l10n codegen + *.g.dart + *.freezed.dart).
# Usage: ./scripts/lib_loc_report.sh [N]   — prints top N files by line count (default 40).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

N="${1:-40}"

find lib -name '*.dart' \
  ! -path 'lib/l10n/*' \
  ! -name '*.g.dart' \
  ! -name '*.freezed.dart' \
  -print0 \
  | xargs -0 wc -l \
  | grep -v ' total$' \
  | sort -nr \
  | head -n "$N"
