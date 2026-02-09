# Compilation Errors Fix Guide

## Problem
The app has compilation errors because **code generation hasn't been run**. The Freezed models (Place, Mood, Activity, etc.) require generated code files (`.freezed.dart` and `.g.dart`) that are missing.

## Root Cause
- Models use `@freezed` annotation but generated files don't exist
- Without generated code, Dart can't see the actual properties/methods
- This causes errors like "The getter 'id' isn't defined for the type 'Place'"

## Solution

### Step 1: Run Code Generation
```bash
cd /Users/edviennemerencia/WanderMood-WanderMood-Dec
dart run build_runner build --delete-conflicting-outputs
```

This will generate all missing `.freezed.dart` and `.g.dart` files for:
- `Place` model
- `Mood` model  
- `Activity` model
- `WeatherData`, `WeatherForecast`, `WeatherAlert`, `WeatherLocation`
- `CreateDiaryEntryRequest`
- `UserPreferences`
- And other Freezed models

### Step 2: Verify Generation
After running, check that these files exist:
- `lib/features/places/models/place.freezed.dart`
- `lib/features/places/models/place.g.dart`
- `lib/features/mood/domain/models/mood.freezed.dart`
- `lib/features/mood/domain/models/mood.g.dart`
- `lib/features/mood/domain/models/activity.freezed.dart`
- `lib/features/mood/domain/models/activity.g.dart`
- And others...

### Step 3: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## Models That Need Code Generation

### Place Model
- Location: `lib/features/places/models/place.dart`
- Properties: `id`, `name`, `address`, `location`, `rating`, `photos`, `types`, `openingHours`, etc.
- Generated files needed: `place.freezed.dart`, `place.g.dart`

### Mood Model
- Location: `lib/features/mood/domain/models/mood.dart`
- Missing: `toJson()`, `fromJson()`, `label` property
- Generated files needed: `mood.freezed.dart`, `mood.g.dart`

### Activity Model
- Location: `lib/features/mood/domain/models/activity.dart`
- Missing: `toJson()`, `fromJson()`, `id` property
- Generated files needed: `activity.freezed.dart`, `activity.g.dart`

### Weather Models
- `WeatherData`, `WeatherForecast`, `WeatherAlert`, `WeatherLocation`
- Missing: `toJson()` methods
- Need to add `@JsonSerializable()` or use Freezed

### Other Models
- `CreateDiaryEntryRequest` - needs Freezed code generation
- `UserPreferences` - needs code generation
- `MoodData` - needs `toJson()` method

## Additional Issues to Fix

### 1. CurrentMood Provider
- Location: `lib/features/mood/providers/current_mood_provider.dart`
- Issue: Trying to set `state` on a non-StateNotifier
- Fix: Convert to `StateNotifier` or use different pattern

### 2. Weather Model Properties
- Location: `lib/features/weather/domain/models/weather.dart`
- Missing: `temperature`, `condition` properties
- Fix: Add these properties or update code to use correct property names

### 3. Mood Model Label
- Location: `lib/features/mood/domain/models/mood.dart`
- Missing: `label` property
- Fix: Add `label` property or update code to use correct property name

### 4. BookingsProvider
- Location: `lib/features/places/presentation/screens/booking_confirmation_screen.dart`
- Missing: `bookingsProvider`
- Fix: Create or import the correct provider

### 5. DailyMoodStateNotifierProvider
- Location: `lib/features/places/presentation/screens/booking_confirmation_screen.dart`
- Missing: Import statement
- Fix: Add `import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';`

## Quick Fix Command Sequence

```bash
# 1. Clean build
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Generate code
dart run build_runner build --delete-conflicting-outputs

# 4. If generation fails, try watching mode
dart run build_runner watch --delete-conflicting-outputs

# 5. Build and run
flutter run
```

## Note
The globe integration we just completed is separate from these compilation errors. Once code generation is complete, the globe feature should work fine.
