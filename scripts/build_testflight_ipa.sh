#!/usr/bin/env bash
# Build release IPA with API keys for Dart (--dart-define) and native Google Maps (Secrets.xcconfig).
#
# Option A — use your local .env (same keys as development):
#   ./scripts/build_testflight_ipa.sh env
#
# Option B — use release_defines.json (copy from release_defines.json.example, gitignored):
#   ./scripts/build_testflight_ipa.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

write_secrets_xcconfig() {
  local key="${1:-}"
  mkdir -p ios/Flutter
  if [[ -n "$key" ]]; then
    printf 'GOOGLE_MAPS_API_KEY=%s\n' "$key" > ios/Flutter/Secrets.xcconfig
    echo "✅ Wrote ios/Flutter/Secrets.xcconfig (Google Maps native)"
  else
    rm -f ios/Flutter/Secrets.xcconfig
    echo "⚠️  No GOOGLE_MAPS_API_KEY — release maps may fail (set in .env or release_defines.json)"
  fi
}

extract_maps_from_json() {
  python3 -c "
import json
import sys
try:
    with open('$ROOT/release_defines.json') as f:
        d = json.load(f)
    v = d.get('GOOGLE_MAPS_API_KEY') or ''
    if isinstance(v, str):
        sys.stdout.write(v)
except Exception:
    pass
" 2>/dev/null || true
}

MODE="${1:-json}"

if [[ "$MODE" == "env" || "$MODE" == "--from-env" ]]; then
  if [[ ! -f .env ]]; then
    echo "❌ No .env in $ROOT — copy .env.example to .env or use: ./scripts/build_testflight_ipa.sh (with release_defines.json)"
    exit 1
  fi
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  echo "✅ Loaded .env"
  write_secrets_xcconfig "${GOOGLE_MAPS_API_KEY:-}"
  flutter pub get
  ARGS=(build ipa --release)
  ARGS+=(--dart-define=SUPABASE_URL="${SUPABASE_URL:?Set SUPABASE_URL in .env}")
  ARGS+=(--dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY in .env}")
  [[ -n "${GOOGLE_PLACES_API_KEY:-}" ]] && ARGS+=(--dart-define=GOOGLE_PLACES_API_KEY="$GOOGLE_PLACES_API_KEY")
  [[ -n "${OPENAI_API_KEY:-}" ]] && ARGS+=(--dart-define=OPENAI_API_KEY="$OPENAI_API_KEY")
  [[ -n "${OPENWEATHER_API_KEY:-}" ]] && ARGS+=(--dart-define=OPENWEATHER_API_KEY="$OPENWEATHER_API_KEY")
  [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]] && ARGS+=(--dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY")
  flutter "${ARGS[@]}"
  if ! compgen -G "build/ios/ipa/*.ipa" > /dev/null; then
    echo ""
    echo "❌ IPA export failed (often codesign/keychain). Try: open ios/Runner.xcworkspace → Archive → Distribute, or fix keychain."
    echo "   Archive may exist: build/ios/archive/Runner.xcarchive"
    exit 1
  fi
  echo ""
  echo "✅ IPA: build/ios/ipa/"
  exit 0
fi

DEFINES="release_defines.json"
if [[ ! -f "$DEFINES" ]]; then
  echo "Missing $ROOT/$DEFINES"
  echo "Either:"
  echo "  1) Copy release_defines.json.example -> release_defines.json and fill keys, then re-run this script, or"
  echo "  2) Run: ./scripts/build_testflight_ipa.sh env   (uses .env)"
  exit 1
fi

MAPS="$(extract_maps_from_json)"
write_secrets_xcconfig "$MAPS"
flutter pub get
flutter build ipa --release --dart-define-from-file="$DEFINES"
if ! compgen -G "build/ios/ipa/*.ipa" > /dev/null; then
  echo ""
  echo "❌ IPA export failed. Archive may exist: build/ios/archive/Runner.xcarchive"
  exit 1
fi
echo ""
echo "✅ IPA: build/ios/ipa/"
