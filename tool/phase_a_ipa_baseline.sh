#!/usr/bin/env bash
# Phase A: print IPA and top Payload assets (re-run after asset or dependency changes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA="${1:-$ROOT/build/ios/ipa/wandermood.ipa}"
if [[ ! -f "$IPA" ]]; then
  echo "No IPA at: $IPA"
  echo "Run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist"
  exit 1
fi
echo "IPA: $IPA"
du -h "$IPA" | head -1
echo "---"
unzip -l "$IPA" 2>/dev/null | awk 'NR>3 {s=$1; f=$4; gsub(/^[ ]+/,"",s); if (s+0>0) print s, f}' | sort -rn | head -15
echo "---"
unzip -l "$IPA" 2>/dev/null | grep -E "App.framework/App$|flutter_assets" | head -5 || true
