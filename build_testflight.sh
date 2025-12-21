#!/bin/bash
# Build script for TestFlight with API keys
# Usage: ./build_testflight.sh

set -e  # Exit on error

echo "🚀 Building WanderMood for TestFlight..."
echo ""

# Check if keys are provided via environment variables or prompt
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ ERROR: SUPABASE_URL and SUPABASE_ANON_KEY must be set"
  echo ""
  echo "Set them as environment variables:"
  echo "  export SUPABASE_URL='your_url'"
  echo "  export SUPABASE_ANON_KEY='your_key'"
  echo "  ./build_testflight.sh"
  echo ""
  echo "Or provide them inline:"
  echo "  SUPABASE_URL='your_url' SUPABASE_ANON_KEY='your_key' ./build_testflight.sh"
  exit 1
fi

# Optional keys (with defaults)
GOOGLE_PLACES_KEY=${GOOGLE_PLACES_API_KEY:-""}
OPENAI_KEY=${OPENAI_API_KEY:-""}
OPENWEATHER_KEY=${OPENWEATHER_API_KEY:-""}

echo "✅ Using provided API keys"
echo ""

# Build command
BUILD_CMD="flutter build ipa --release"

# Add required keys
BUILD_CMD="$BUILD_CMD --dart-define=SUPABASE_URL=\"$SUPABASE_URL\""
BUILD_CMD="$BUILD_CMD --dart-define=SUPABASE_ANON_KEY=\"$SUPABASE_ANON_KEY\""

# Add optional keys if provided
if [ -n "$GOOGLE_PLACES_KEY" ]; then
  BUILD_CMD="$BUILD_CMD --dart-define=GOOGLE_PLACES_API_KEY=\"$GOOGLE_PLACES_KEY\""
  echo "✅ Google Places API key provided"
else
  echo "⚠️  Google Places API key not provided (places features will be limited)"
fi

if [ -n "$OPENAI_KEY" ]; then
  BUILD_CMD="$BUILD_CMD --dart-define=OPENAI_API_KEY=\"$OPENAI_KEY\""
  echo "✅ OpenAI API key provided"
else
  echo "⚠️  OpenAI API key not provided (AI features will use mock responses)"
fi

if [ -n "$OPENWEATHER_KEY" ]; then
  BUILD_CMD="$BUILD_CMD --dart-define=OPENWEATHER_API_KEY=\"$OPENWEATHER_KEY\""
  echo "✅ OpenWeather API key provided"
else
  echo "⚠️  OpenWeather API key not provided (weather features will be limited)"
fi

echo ""
echo "📦 Building IPA..."
echo ""

# Execute build
eval $BUILD_CMD

echo ""
echo "✅ Build complete! IPA file is in: build/ios/ipa/"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Product → Archive"
echo "3. Distribute App → TestFlight"
echo ""

