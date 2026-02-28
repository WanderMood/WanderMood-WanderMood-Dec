#!/bin/bash
# Run this script for instant globe.html refresh during development.
# Then run: flutter run --dart-define=GLOBE_DEV_SERVER=true
# Edit assets/globe/globe.html and just navigate away/back to the globe screen.
cd "$(dirname "$0")/../assets/globe" && python3 -m http.server 8080
