#!/usr/bin/env bash
# Builds a release IPA with secrets baked via --dart-define-from-file.
# Debug/local: use .env + flutter run. TestFlight/App Store: use this script.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEFINES="release_defines.json"
if [[ ! -f "$DEFINES" ]]; then
  echo "Missing $ROOT/$DEFINES"
  echo "Copy release_defines.json.example -> release_defines.json and fill in real keys (file is gitignored)."
  exit 1
fi
flutter build ipa --release --dart-define-from-file="$DEFINES"
