# Fix Xcode Archive Errors for TestFlight

## Problem
When archiving in Xcode, you're getting:
- `'Flutter/Flutter.h' file not found` in GeolocatorPlugin
- `(fatal) could not build module 'geolocator_apple'`
- `(fatal) could not build module 'Test'`

This is a common Flutter iOS build issue where Flutter framework headers aren't being found during archive builds.

## Solution Steps

### Step 1: Clean Everything

Open Terminal and run these commands:

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

# Clean Flutter build
flutter clean

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock .symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*
pod deintegrate

# Go back to project root
cd ..
```

### Step 2: Set Terminal Encoding (Fix CocoaPods Error)

The CocoaPods error about UTF-8 encoding needs to be fixed first:

```bash
# Add to your ~/.zshrc file
echo 'export LANG=en_US.UTF-8' >> ~/.zshrc
source ~/.zshrc
```

### Step 3: Reinstall Flutter Dependencies

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

# Get Flutter packages
flutter pub get

# Install iOS pods
cd ios
pod install --repo-update
cd ..
```

### Step 4: Fix Xcode Build Settings

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **IMPORTANT:** Open `.xcworkspace`, NOT `.xcodeproj`

2. **Select Runner target** → **Build Settings** tab

3. **Search for "Framework Search Paths"** and ensure it includes:
   ```
   $(inherited)
   $(PROJECT_DIR)/Flutter
   $(PROJECT_DIR)/Flutter/Flutter.framework
   ```

4. **Search for "Header Search Paths"** and ensure it includes:
   ```
   $(inherited)
   $(PROJECT_DIR)/Flutter
   $(PROJECT_DIR)/Flutter/Flutter.framework/Headers
   ```

5. **Search for "Other Linker Flags"** and ensure it includes:
   ```
   $(inherited)
   -framework Flutter
   ```

### Step 5: Fix Podfile (If Needed)

Check `ios/Podfile` and ensure it has:

```ruby
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix deployment target warnings
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

### Step 6: Build from Xcode (Not Flutter CLI)

**For Archive builds, always use Xcode:**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Product** → **Scheme** → **Runner**
3. Select **Any iOS Device (arm64)** (not a simulator)
4. Select **Product** → **Archive**
5. Wait for archive to complete

### Step 7: Alternative - Build IPA via Flutter CLI

If Xcode archive still fails, try building IPA directly:

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM

flutter build ipa --release \
  --dart-define=SUPABASE_URL="https://oojpipspxwdmiyaymldo.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your_anon_key_here" \
  --dart-define=GOOGLE_PLACES_API_KEY="your_places_key_here" \
  --dart-define=OPENAI_API_KEY="your_openai_key_here" \
  --dart-define=OPENWEATHER_API_KEY="your_weather_key_here"
```

This will create an IPA file at:
```
build/ios/ipa/wandermood.ipa
```

You can then upload this IPA to App Store Connect via:
- **Transporter app** (macOS App Store)
- **Xcode Organizer** (Window → Organizer → Archives)
- **App Store Connect** web interface

## Common Issues & Fixes

### Issue: "Flutter/Flutter.h not found"
**Fix:** Ensure you opened `.xcworkspace`, not `.xcodeproj`

### Issue: Pod install fails with encoding error
**Fix:** Set `export LANG=en_US.UTF-8` in your terminal profile

### Issue: Archive succeeds but upload fails
**Fix:** Ensure you're using the correct signing certificate and provisioning profile

### Issue: "Module 'geolocator_apple' not found"
**Fix:** 
1. Clean build folder (Product → Clean Build Folder in Xcode)
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
3. Reinstall pods: `cd ios && pod install`

## Verification Checklist

Before archiving, verify:

- [ ] Opened `Runner.xcworkspace` (not `.xcodeproj`)
- [ ] Selected "Any iOS Device (arm64)" scheme
- [ ] All pods installed successfully (`pod install` completed without errors)
- [ ] Flutter framework is linked in Build Phases
- [ ] Signing & Capabilities are configured correctly
- [ ] API keys are set via `--dart-define` or in Xcode build settings

## Quick Fix Script

Save this as `fix_archive.sh` and run it:

```bash
#!/bin/bash

cd /Users/edviennemerencia/WanderMood_july15th_9PM

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "🧹 Cleaning iOS build..."
cd ios
rm -rf Pods Podfile.lock .symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*
cd ..

echo "📦 Getting Flutter packages..."
flutter pub get

echo "📦 Installing iOS pods..."
cd ios
export LANG=en_US.UTF-8
pod install --repo-update
cd ..

echo "✅ Done! Now open ios/Runner.xcworkspace in Xcode and archive."
```

Make it executable:
```bash
chmod +x fix_archive.sh
./fix_archive.sh
```

## Still Having Issues?

If the above doesn't work:

1. **Check Flutter version:**
   ```bash
   flutter --version
   flutter doctor -v
   ```

2. **Update Flutter:**
   ```bash
   flutter upgrade
   ```

3. **Check Xcode version:**
   - Should be Xcode 15.0 or later
   - Run `xcodebuild -version`

4. **Verify CocoaPods:**
   ```bash
   pod --version
   sudo gem install cocoapods
   ```

5. **Try building from Flutter CLI instead:**
   ```bash
   flutter build ipa --release
   ```



