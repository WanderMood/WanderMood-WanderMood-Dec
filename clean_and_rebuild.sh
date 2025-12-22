#!/bin/bash

# Flutter Clean and Rebuild Script
# Run this script to completely clean and rebuild the project

set -e  # Exit on error

echo "🧹 Step 1: Cleaning Flutter build..."
flutter clean

echo "📦 Step 2: Getting Flutter dependencies..."
flutter pub get

echo "🗑️  Step 3: Cleaning iOS build artifacts..."
cd ios
rm -rf Pods Podfile.lock .symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "📱 Step 4: Reinstalling CocoaPods..."
export LANG=en_US.UTF-8
pod deintegrate 2>/dev/null || true
pod install

echo "✅ Step 5: Building Flutter app..."
cd ..
flutter build ios --no-codesign

echo "✅ Clean and rebuild complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Product → Clean Build Folder (Shift+Cmd+K)"
echo "3. Product → Build (Cmd+B)"

