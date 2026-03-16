#!/bin/bash
# Convenience script to run WanderMood in development.
# Reads .env and passes all keys via --dart-define so they are
# NOT bundled as an asset in the app binary.

set -euo pipefail

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found. Copy .env.example to .env and fill in your keys."
  exit 1
fi

DART_DEFINES=""
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ "$key" =~ ^#.*$ ]] && continue
  [[ -z "$key" ]] && continue
  # Trim whitespace
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  DART_DEFINES="$DART_DEFINES --dart-define=$key=$value"
done < "$ENV_FILE"

echo "Starting WanderMood with dart-define keys..."
flutter run $DART_DEFINES "$@"
