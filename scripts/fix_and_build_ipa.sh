#!/usr/bin/env bash
# One-shot fix: unlock keychain for codesign, then build the TestFlight IPA.
# Run this from the project root:
#   ./scripts/fix_and_build_ipa.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

echo ""
echo "=== Step 1: Fix keychain access for codesign ==="
echo "Enter your macOS LOGIN PASSWORD (the one you use to unlock your Mac)."
echo "It won't echo. This is needed once so codesign can re-sign frameworks."
echo ""
read -rs -p "macOS login password: " KP
echo ""

# Unlock keychain
security unlock-keychain -p "$KP" "$KEYCHAIN" 2>&1 && echo "✅ Keychain unlocked" || {
  echo "❌ Wrong password or keychain error. Try again."
  exit 1
}

# Grant apple-tool / codesign access to all private keys — fixes
# the 'replacing existing signature' / AppAuth.framework error.
security set-key-partition-list \
  -S "apple-tool:,apple:,codesign:" \
  -s -k "$KP" "$KEYCHAIN" \
  2>&1 | grep -v "^security:" || true

echo "✅ Keychain partition list set (codesign can now access Apple Distribution key)"

# Clear the password from memory
KP=""
unset KP

echo ""
echo "=== Step 2: Load .env and build IPA ==="

if [[ ! -f .env ]]; then
  echo "❌ No .env found in $ROOT"
  echo "   Copy .env.example → .env and fill in your keys."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a
echo "✅ Loaded .env"

# Write native Google Maps key
if [[ -n "${GOOGLE_MAPS_API_KEY:-}" ]]; then
  mkdir -p ios/Flutter
  printf 'GOOGLE_MAPS_API_KEY=%s\n' "$GOOGLE_MAPS_API_KEY" > ios/Flutter/Secrets.xcconfig
  echo "✅ Wrote ios/Flutter/Secrets.xcconfig"
fi

flutter pub get

ARGS=(build ipa --release)
ARGS+=(--dart-define=SUPABASE_URL="${SUPABASE_URL:?Set SUPABASE_URL in .env}")
ARGS+=(--dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY in .env}")
[[ -n "${GOOGLE_PLACES_API_KEY:-}" ]] && ARGS+=(--dart-define=GOOGLE_PLACES_API_KEY="$GOOGLE_PLACES_API_KEY")
[[ -n "${OPENAI_API_KEY:-}" ]]        && ARGS+=(--dart-define=OPENAI_API_KEY="$OPENAI_API_KEY")
[[ -n "${OPENWEATHER_API_KEY:-}" ]]   && ARGS+=(--dart-define=OPENWEATHER_API_KEY="$OPENWEATHER_API_KEY")
[[ -n "${GOOGLE_MAPS_API_KEY:-}" ]]   && ARGS+=(--dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY")

flutter "${ARGS[@]}"

if compgen -G "build/ios/ipa/*.ipa" > /dev/null; then
  echo ""
  echo "✅ IPA ready: build/ios/ipa/"
  ls -lh build/ios/ipa/*.ipa
  echo ""
  echo "Upload to TestFlight: open Transporter.app, drag the .ipa in, click Deliver."
else
  echo ""
  echo "❌ IPA export still failed."
  echo "   Check Xcode: make sure you're signed into your Apple account in"
  echo "   Xcode → Settings → Accounts (so it can download the App Store profile)."
  echo "   Archive still available: build/ios/archive/Runner.xcarchive"
  echo "   You can also do: open build/ios/archive/Runner.xcarchive"
  echo "   then Xcode Organizer → Distribute App → App Store Connect."
  exit 1
fi
