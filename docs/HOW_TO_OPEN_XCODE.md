# How to Open Xcode Workspace - Exact Steps

## Method 1: From Finder (Easiest)

1. **Open Finder**
2. **Navigate to:** `/Users/edviennemerencia/WanderMood_july15th_9PM/ios/`
3. **Look for:** `Runner.xcworkspace` (it looks like a blue folder/workspace icon)
4. **Double-click** `Runner.xcworkspace`
5. Xcode will open automatically

## Method 2: From Xcode (If Already Open)

1. **Close Xcode completely:**
   - Press `Cmd + Q` (or Xcode → Quit Xcode)

2. **Reopen Xcode:**
   - Click the Xcode icon in your Dock, or
   - Press `Cmd + Space` and type "Xcode"

3. **When Xcode opens, you'll see the welcome screen:**
   - Click **"Open Existing Project..."** (or **"Open..."**)
   - Navigate to: `/Users/edviennemerencia/WanderMood_july15th_9PM/ios/`
   - Select **`Runner.xcworkspace`** (NOT `Runner.xcodeproj`)
   - Click **"Open"**

## Method 3: From Terminal

```bash
cd /Users/edviennemerencia/WanderMood_july15th_9PM/ios
open Runner.xcworkspace
```

## Important Notes

⚠️ **Always open `.xcworkspace`, NEVER `.xcodeproj`**

- ✅ **Correct:** `Runner.xcworkspace` (blue icon, includes CocoaPods)
- ❌ **Wrong:** `Runner.xcodeproj` (white icon, won't work with CocoaPods)

## Visual Guide

The workspace file is located at:
```
/Users/edviennemerencia/WanderMood_july15th_9PM/
  └── ios/
      └── Runner.xcworkspace  ← Open this one!
```

## After Opening

Once Xcode opens:
1. Wait for indexing to complete (progress bar at top)
2. Select an iOS Simulator from the device dropdown (top toolbar)
3. Press `Cmd + B` to build



