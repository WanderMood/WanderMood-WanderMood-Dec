#!/usr/bin/env bash
# WanderMood — release IPA for TestFlight with all Dart --dart-define keys and
# native Google Maps (ios/Flutter/Secrets.xcconfig).
#
# Usage (recommended — uses repo .env like local dev):
#   ./build_testflight.sh
#
# Optional:
#   CLEAN=1                     → flutter clean before build (forces full recompile)
#   AUTO_INCREMENT_BUILD_NUMBER=1 → pass --build-number from `git rev-list --count HEAD`
#                                    (monotonic per commit; overrides pubspec +N)
#
# Required in .env or environment (release / ApiKeys will throw or break without these):
#   SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY, OPENWEATHER_API_KEY
#
# Strongly recommended:
#   GOOGLE_PLACES_API_KEY  (place photos / device URL rewrite on device)
#
# Optional:
#   OPENAI_API_KEY
#   WANDERMOOD_UNIVERSAL_LINK_BASE  (defaults to https://wandermood.com in Dart)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  echo "✅ Loaded .env from $ROOT/.env"
else
  echo "ℹ️  No .env file — using environment variables only."
fi

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "❌ $name is not set. Add it to .env or export it before running this script."
    exit 1
  fi
}

require_var SUPABASE_URL
require_var SUPABASE_ANON_KEY
require_var GOOGLE_MAPS_API_KEY
require_var OPENWEATHER_API_KEY

write_secrets_xcconfig() {
  mkdir -p ios/Flutter
  printf 'GOOGLE_MAPS_API_KEY=%s\n' "$GOOGLE_MAPS_API_KEY" > ios/Flutter/Secrets.xcconfig
  echo "✅ Wrote ios/Flutter/Secrets.xcconfig (native Google Maps)"
}

write_secrets_xcconfig

echo "✅ API keys: Supabase + Maps + Weather (required); Places/OpenAI/UL base optional"

ARGS=(build ipa --release)
ARGS+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
ARGS+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
ARGS+=(--dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY")
ARGS+=(--dart-define=OPENWEATHER_API_KEY="$OPENWEATHER_API_KEY")

if [[ -n "${GOOGLE_PLACES_API_KEY:-}" ]]; then
  ARGS+=(--dart-define=GOOGLE_PLACES_API_KEY="$GOOGLE_PLACES_API_KEY")
  echo "✅ GOOGLE_PLACES_API_KEY → dart-define"
else
  echo "⚠️  GOOGLE_PLACES_API_KEY missing — Explore / place photos may be limited on device"
fi

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  ARGS+=(--dart-define=OPENAI_API_KEY="$OPENAI_API_KEY")
  echo "✅ OPENAI_API_KEY → dart-define"
else
  echo "ℹ️  OPENAI_API_KEY not set — AI may use offline/mock paths where applicable"
fi

if [[ -n "${WANDERMOOD_UNIVERSAL_LINK_BASE:-}" ]]; then
  ARGS+=(--dart-define=WANDERMOOD_UNIVERSAL_LINK_BASE="$WANDERMOOD_UNIVERSAL_LINK_BASE")
  echo "✅ WANDERMOOD_UNIVERSAL_LINK_BASE → dart-define"
fi

if [[ "${AUTO_INCREMENT_BUILD_NUMBER:-0}" == "1" ]]; then
  BN="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
  ARGS+=(--build-number="$BN")
  echo "✅ Using --build-number=$BN (AUTO_INCREMENT_BUILD_NUMBER=1)"
fi

if [[ "${CLEAN:-0}" == "1" ]]; then
  echo "🧹 CLEAN=1 → flutter clean"
  flutter clean
fi

echo ""
echo "📦 flutter pub get …"
flutter pub get

echo ""
echo "📦 Running flutter build ipa --release (dart-defines not printed — contains secrets) …"
echo ""

flutter "${ARGS[@]}"

if ! compgen -G "build/ios/ipa/*.ipa" > /dev/null; then
  echo ""
  echo "❌ IPA export failed (codesigning / export options). Check Xcode signing or:"
  echo "   open ios/Runner.xcworkspace → Product → Archive"
  echo "   Archive may exist: build/ios/archive/Runner.xcarchive"
  exit 1
fi

echo ""
echo "✅ IPA ready: build/ios/ipa/"
echo ""
echo "Next: Xcode Organizer or Transporter to upload to App Store Connect / TestFlight."
