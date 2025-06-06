# WanderMood Development Documentation

## Project Overview
WanderMood is an AI-driven travel application that personalizes travel recommendations based on user moods and preferences. The app features dynamic time-based interactions and location-aware suggestions.

## Technical Stack

### Frontend
- **Framework**: Flutter (Latest stable version)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **UI Libraries**:
  - flutter_animate
  - google_fonts
  - animated_text_kit
  - flutter_svg
  - lottie
  - simple_animations

### Backend
- **Platform**: Supabase
- **Database**: PostgreSQL
- **Authentication**: Supabase Auth with PKCE flow
- **Storage**: Supabase Storage
- **Real-time**: Supabase Realtime
- **Serverless**: Supabase Edge Functions
- **Security**: Row Level Security (RLS)

### External APIs
- **Places**: Google Places API
- **Weather**: OpenWeatherMap API
- **Maps**: Google Maps API
- **Geocoding**: Geocoding API

## Core Features

### 1. Time-Based Interactions
- **Morning Mode** (7 AM - 12 PM)
  - Personalized morning greetings
  - Daily mood selection
  - Weather-aware suggestions
  
- **Day Mode** (12 PM - 12 AM)
  - Full feature access
  - Location-based recommendations
  - Social interactions
  
- **Night Mode** (12 AM - 7 AM)
  - Sleep-friendly interface
  - Wake-up mood selection
  - Next day planning

### 2. Mood-Based Planning
- **Mood Categories**:
  - Energetic ⚡
  - Peaceful 🌅
  - Adventurous 🚀
  - Creative 🎨
  - Relaxed 😌

- **Planning Algorithm**:
  - Weather consideration
  - Time of day adaptation
  - Location proximity
  - User preferences
  - Historical data

### 3. Location Services
- Real-time location tracking
- Place suggestions based on:
  - Current mood
  - Weather conditions
  - Time of day
  - User preferences
  - Previous visits

### 4. Data Persistence
- **Local Storage**:
  - SharedPreferences for user preferences
  - Hive for offline data
  - Secure storage for sensitive data

- **Cloud Storage (Supabase)**:
  - User profiles in PostgreSQL tables
  - Mood history with real-time updates
  - Favorite places with RLS policies
  - Travel plans with geospatial queries

## Architecture

### Directory Structure
```
lib/
├── core/
│   ├── router/
│   ├── theme/
│   ├── utils/
│   ├── config/
│   ├── providers/
│   └── constants/
├── features/
│   ├── auth/
│   ├── home/
│   ├── mood/
│   ├── places/
│   └── weather/
└── shared/
    ├── widgets/
    └── models/
```

### Key Components

#### 1. Router Configuration
- GoRouter for declarative routing
- Path-based navigation
- Deep linking support
- Authentication guards with Supabase session

#### 2. State Management
- Riverpod providers for:
  - Authentication state (`supabaseClientProvider`)
  - User preferences
  - Mood selection
  - Location data
  - Weather information

#### 3. UI Components
- Custom animated widgets
- Mood selection grid
- Location cards
- Weather displays
- Planning interface

## API Integration

### 1. Supabase Setup
```dart
// Initialize Supabase in main.dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  debug: false, // Set to true for development
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);

// Access client anywhere in the app
final supabase = Supabase.instance.client;

// Using with Riverpod
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

### 2. Authentication
```dart
// Sign in with email and password
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign up
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'name': name},
);

// Social login
final response = await supabase.auth.signInWithOAuth(
  Provider.google,
  redirectTo: 'io.supabase.wandermood://login-callback/',
);

// Sign out
await supabase.auth.signOut();
```

### 3. Database Operations
```dart
// Insert data
final response = await supabase
  .from('moods')
  .insert({
    'user_id': supabase.auth.currentUser!.id,
    'mood_type': 'happy',
    'intensity': 8,
    'notes': 'Feeling great today!',
    'weather': {'temp': 22, 'condition': 'sunny'},
  });

// Query data
final response = await supabase
  .from('places')
  .select('id, name, location, mood_tags, rating')
  .eq('mood_tags', 'peaceful')
  .order('rating', ascending: false)
  .limit(10);

// Update data
final response = await supabase
  .from('users')
  .update({'preferences': newPreferences})
  .eq('id', supabase.auth.currentUser!.id);

// Delete data
final response = await supabase
  .from('user_places')
  .delete()
  .eq('place_id', placeId)
  .eq('user_id', supabase.auth.currentUser!.id);
```

### 4. Real-time Subscriptions
```dart
// Listen to changes in the moods table
final subscription = supabase
  .from('moods')
  .stream(primaryKey: ['id'])
  .eq('user_id', supabase.auth.currentUser!.id)
  .listen((List<Map<String, dynamic>> data) {
    // Handle real-time updates
  });

// Remember to cancel subscription when not needed
subscription.cancel();
```

### 5. Storage
```dart
// Upload a file
final response = await supabase
  .storage
  .from('profile_images')
  .upload(
    'public/${supabase.auth.currentUser!.id}.jpg',
    file,
    fileOptions: const FileOptions(
      cacheControl: '3600',
      upsert: true,
    ),
  );

// Get a public URL
final url = supabase
  .storage
  .from('profile_images')
  .getPublicUrl('public/${supabase.auth.currentUser!.id}.jpg');

// Download a file
final bytes = await supabase
  .storage
  .from('profile_images')
  .download('public/${supabase.auth.currentUser!.id}.jpg');
```

### 6. Edge Functions
```dart
// Invoke an Edge Function
final response = await supabase
  .functions
  .invoke(
    'generate_recommendations',
    body: {
      'mood': currentMood,
      'weather': currentWeather,
      'location': userLocation,
    },
  );
```

### 7. Places API
- Search radius: 5km
- Result limit: 20 places
- Categories:
  - Attractions
  - Restaurants
  - Activities
  - Cultural sites

### 8. Weather API
- Hourly forecasts
- 5-day predictions
- Weather conditions
- Temperature
- Precipitation

## Security

### Supabase Security
- **Row Level Security (RLS)**: Enforced at the database level to ensure users can only access appropriate data
- **Policies**:
  ```sql
  -- Example: Users can only read their own data
  CREATE POLICY "Users can only access own data"
  ON moods
  FOR SELECT
  USING (auth.uid() = user_id);
  
  -- Example: Users can only insert their own data
  CREATE POLICY "Users can insert own data"
  ON moods
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
  ```

### Authentication
- PKCE flow for secure OAuth
- JWT token management
- Session handling
- Refresh token rotation

### Data Protection
- Encrypted storage
- Secure API calls
- Rate limiting with Supabase Edge Functions
- Input validation

## Performance Optimization

### Caching Strategy
- Place data caching with PostgreSQL
- Image caching with Supabase Storage CDN
- Weather data caching
- Offline support with Hive

### Memory Management
- Image optimization
- Lazy loading
- Resource cleanup
- Background process management

### Query Optimization
- Selective column selection
- Pagination with `range()`
- Indexing important columns
- Efficient joins using relationships

## Testing

### Unit Tests
- Business logic
- Data models
- Supabase API services
- Utils

### Widget Tests
- UI components
- Navigation
- State management
- User interactions

### Integration Tests
- End-to-end flows
- Supabase integration
- Database operations with mocked Supabase client

## Deployment

### Supabase Setup
1. Create Supabase project via dashboard
2. Set up database schema (tables, RLS, etc.)
3. Create storage buckets
4. Deploy Edge Functions
5. Configure authentication providers

### Release Process
1. Version bump
2. Changelog update
3. Asset optimization
4. Build generation
5. Store submission

### Environment Configuration
- Development
  - Local Supabase instance or dev project
  - Debug flags enabled
  - Test data
- Staging
  - Staging Supabase project
  - Release candidate testing
- Production
  - Production Supabase project
  - Optimized performance
  - Real data

## Maintenance

### Monitoring
- Error tracking
- Usage analytics
- Performance metrics
- Supabase health checks
- Edge Functions monitoring

### Updates
- Regular dependency updates
- Security patches
- Feature additions
- Bug fixes
- Supabase migrations

## Supabase Migration Guide

### Migrating from Firebase
1. **Authentication**:
   - Use Supabase Auth with similar providers
   - Implement PKCE flow for OAuth
   - Update UI to handle Supabase auth responses

2. **Database**:
   - Convert Firestore collections to PostgreSQL tables
   - Implement RLS policies for security
   - Use JOINs instead of nested document queries

3. **Storage**:
   - Move files to Supabase Storage
   - Update storage references throughout the app
   - Implement RLS for Supabase Storage buckets

4. **Functions**:
   - Convert Firebase Cloud Functions to Supabase Edge Functions
   - Update function invocation code
   - Test and validate function responses

5. **Real-time**:
   - Replace Firebase listeners with Supabase real-time subscriptions
   - Test real-time performance and reliability
   - Implement appropriate error handling

### Database Migration Checklist
- ✅ Schema creation
- ✅ Data migration
- ✅ Index creation
- ✅ RLS policy implementation
- ✅ Function/trigger creation
- ✅ Testing queries
- ✅ Performance validation

## Profile System

### Recent Enhancements ✅ COMPLETED
The profile system has been significantly enhanced with proper navigation and functionality.

### Features Implemented

#### 1. Profile Navigation Fix
**Issue:** Profile button in bottom navigation was incorrectly showing social hub user profile instead of dedicated ProfileScreen.

**Solution:** Fixed conditional logic in `main_screen.dart`:
```dart
// Before (incorrect)
if (currentIndex == 3) {
  context.push('/social/user-profile');
} else {
  ref.read(mainTabProvider.notifier).state = 4;
}

// After (correct)
ref.read(mainTabProvider.notifier).state = 4; // Always go to ProfileScreen
```

#### 2. Complete Profile Screen Functionality
**Location:** `lib/features/profile/presentation/screens/profile_screen.dart`

**Features:**
- User profile display with avatar and bio
- Day streak tracking
- Follower/following counts
- Profile sharing capability
- Settings menu with proper navigation

#### 3. New Help & Support Screen
**Location:** `lib/features/profile/presentation/screens/help_support_screen.dart`

**Features:**
- **Quick Actions:**
  - Contact Us (email integration)
  - Live Chat (coming soon message)
- **FAQ Section:**
  - Expandable questions and answers
  - Common user inquiries covered
- **App Information:**
  - App version display
  - Privacy Policy navigation
  - Terms of Service navigation
- **Troubleshooting Tools:**
  - Report a Bug functionality
  - Reset App Data option

**Email Integration:**
```dart
Future<void> _launchEmail() async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'support@wandermood.com',
    query: 'subject=WanderMood Support Request',
  );
  
  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
  }
}
```

#### 4. Fixed Settings Navigation
**Issues Fixed:**
- Notifications button incorrectly navigating to PrivacySettingsScreen
- Missing imports for new screens

**Solutions:**
```dart
// Fixed navigation mapping
case 'notifications':
  context.push('/notifications'); // Now uses NotificationsScreen
case 'help':
  context.push('/help-support'); // New HelpSupportScreen
case 'theme':
  context.push('/theme-settings'); // Existing ThemeSettingsScreen
```

### Profile Screen Menu Options
1. **Achievements** - Trophy icon, shows user progress
2. **Notifications** - Bell icon, manages notification preferences  
3. **Language** - Globe icon, language selection
4. **Theme** - Paintbrush icon, theme customization
5. **Privacy** - Lock icon, privacy settings
6. **Help & Support** - Question mark icon, comprehensive help system
7. **Legal** - Document icon, terms and privacy
8. **About** - Info icon, app information

### Profile Data Structure
```dart
class UserProfile {
  final String id;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final int dayStreak;
  final int followerCount;
  final int followingCount;
  final String? favoritmood;
  final Map<String, dynamic>? preferences;
  // ... other fields
}
```

### Theme Settings Integration
The profile system includes the enhanced theme settings with:
- Local-first theme storage
- Offline capability
- Network sync when available
- Debug information display
- Comprehensive error handling

## Future Enhancements
1. Geospatial queries for better location-based recommendations
2. Social features with shared RLS policies
3. Advanced PostgreSQL features (Full Text Search, PostGIS)
4. Supabase Edge Functions for AI processing
5. Realtime collaborative features
6. **Profile System:**
   - Social profile sharing
   - Achievement system expansion
   - Custom profile themes
   - Profile analytics dashboard

## Theme System

### Implementation Status: 🔶 PARTIALLY WORKING
The dark theme system has been implemented but is currently experiencing UI brightness detection issues.

### Architecture
```
lib/core/
├── theme/
│   └── app_theme.dart           # Light and dark theme definitions
└── presentation/
    └── providers/
        ├── app_theme_provider.dart      # Network-dependent theme provider (deprecated)
        └── local_theme_provider.dart    # Offline-first theme provider

lib/features/profile/presentation/screens/
└── theme_settings_screen.dart   # Theme selection UI

lib/core/presentation/widgets/
└── swirl_background.dart       # Theme-aware background component
```

### Current Status
**✅ Working:**
- Theme preference saving/loading locally (SharedPreferences)
- Theme selection UI with proper state management
- Local theme provider with offline-first approach
- Theme-aware background gradients and components
- Debug information showing correct theme mode

**🔶 Partially Working:**
- Theme preference syncing to Supabase profile (works when network available)
- MaterialApp theme switching (saves correctly but UI doesn't update)

**❌ Not Working:**
- Visual theme switching - UI remains in light mode despite `ThemeMode.dark` being set
- UI brightness detection (shows `Brightness.light` even when `ThemeMode.dark`)

### Theme Providers

#### 1. LocalThemeProvider (Primary - Offline-First)
```dart
final localThemeProvider = StateNotifierProvider<LocalThemeNotifier, ThemeMode>((ref) {
  return LocalThemeNotifier();
});
```

**Features:**
- Stores theme preference in SharedPreferences
- Works completely offline
- Provides immediate theme switching
- Supports 'system', 'light', 'dark' modes
- Includes debug logging

**Usage:**
```dart
// Watch current theme
final themeMode = ref.watch(localThemeProvider);

// Change theme
await ref.read(localThemeProvider.notifier).setTheme(ThemeMode.dark);
```

#### 2. AppThemeProvider (Deprecated - Network Dependent)
```dart
final appThemeProvider = Provider<ThemeMode>((ref) {
  // Depends on profileProvider - requires network
});
```

**Status:** Deprecated due to network dependency issues

### Theme Definitions

#### Light Theme
```dart
static ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF12B347),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    // ... additional configurations
  );
}
```

#### Dark Theme
```dart
static ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    // ... dark-specific configurations
  );
}
```

### Background Gradients
The app uses custom gradient backgrounds that adapt to theme:

```dart
// Light mode gradient
colors: [
  Color(0xFFFFFDF5), // Warm cream yellow
  Color(0xFFFFF3E0), // Slightly darker warm yellow
]

// Dark mode gradient  
colors: [
  Color(0xFF0D1117), // Very dark blue-gray
  Color(0xFF161B22), // Slightly lighter dark gray
]
```

### Current Issue Investigation

**Debug Logs Show:**
```
🎨 Local Theme: Saved theme preference: dark
🎨 ThemeSettingsScreen: currentTheme=ThemeMode.dark, brightness=Brightness.light
🏗️ App: Building with themeMode: ThemeMode.dark
```

**Problem:** Despite `ThemeMode.dark` being set correctly, `Theme.of(context).brightness` returns `Brightness.light`, preventing the UI from actually switching to dark mode.

**Potential Causes:**
1. MaterialApp theme configuration issue
2. Theme inheritance problems in widget tree
3. SwirlBackground component not detecting theme changes
4. System theme override affecting detection

**Debugging Steps Implemented:**
- Added comprehensive logging in app.dart and theme settings
- Created debug info card showing all theme states
- Temporarily forced `ThemeMode.dark` in app.dart for testing
- Added platform brightness detection logging

### Theme Settings Screen Features

**UI Components:**
- System theme option (follows device settings)
- Light theme option
- Dark theme option with proper icons
- Selection state with checkmarks
- Debug information card showing current state

**Functionality:**
- Immediate local theme updates
- Graceful network sync fallback
- Toast notifications for theme changes
- Error handling for network failures

### Network Sync Behavior
```dart
// Primary: Update local theme (always works)
await ref.read(localThemeProvider.notifier).setThemeFromString(value);

// Secondary: Sync to profile (when network available)
try {
  await ref.read(profileProvider.notifier).updateProfile(
    themePreference: value,
  );
  print('🎨 Theme synced to profile successfully');
} catch (e) {
  print('🎨 Could not sync theme to profile (offline): $e');
  // Continue - local theme still works
}
```

### Next Steps for Theme System
1. **PRIORITY: Fix UI brightness detection**
   - Investigate MaterialApp theme switching mechanism
   - Test with forced dark mode to isolate issue
   - Check theme inheritance in widget tree

2. **Enhance theme-aware components**
   - Ensure all screens respect theme changes
   - Update card colors, text colors, and icons
   - Test navigation bar theming

3. **Improve system theme detection**
   - Better platform brightness handling
   - Automatic theme switching based on time
   - User preference overrides

4. **Performance optimization**
   - Reduce theme change rebuilds
   - Cache theme-related computations
   - Optimize gradient rendering

## Known Issues
1. **CRITICAL: Dark theme UI not applying** - Theme mode saves correctly but UI brightness remains light
2. Some places not found in Places API (Hotel New York, Witte Huis)
3. Occasional weather data refresh delays
4. Location accuracy in dense urban areas
5. Supabase real-time subscription reconnection needs improvement
6. Initial authentication can be slow on first app launch
7. Asset loading failures for fallback images (`assets/images/fallbacks/`)
8. Network connectivity issues affecting Supabase sync

## Supabase Specific Considerations

### Rate Limits
- Be aware of Supabase Free tier limitations:
  - Database: 500MB storage
  - Auth: 50K MAU
  - Storage: 1GB total
  - Edge Functions: 500K invocations/month
  - Realtime: 2 concurrent connections

### Best Practices
1. **Database**:
   - Use prepared statements for better security
   - Keep RLS policies simple for performance
   - Index frequently queried columns
   - Use views for complex queries

2. **Authentication**:
   - Implement proper error handling for auth state changes
   - Use JWT claims for additional user permissions
   - Test social auth flows thoroughly on all platforms

3. **Storage**:
   - Optimize image sizes before upload
   - Use CDN caching for better performance
   - Implement proper error handling for uploads/downloads

4. **Edge Functions**:
   - Keep functions small and focused
   - Cache expensive calculations
   - Implement proper error handling and retries
   - Use typed responses for better developer experience

## Quick Start Guide

### Setup
1. Clone the repository
2. Run `flutter pub get`
3. Create `.env` file with required API keys:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key
   OPENWEATHER_API_KEY=your_openweather_api_key
   ```
4. Run `flutter run`

### Supabase CLI
For local development and migrations:
```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Initialize project
supabase init

# Start local development
supabase start

# Create a migration
supabase migration new create_tables

# Apply migrations
supabase db push

# Generate TypeScript types
supabase gen types typescript --local > lib/types/supabase.ts
```

### Troubleshooting
1. **Authentication issues**:
   - Verify Supabase URL and anon key
   - Check for proper redirects in OAuth flows
   - Validate RLS policies

2. **Database query issues**:
   - Check for proper column names
   - Verify RLS policies allow the operation
   - Test queries in Supabase dashboard

3. **Real-time issues**:
   - Verify table has `REPLICA IDENTITY FULL`
   - Check subscription format
   - Test with Supabase dashboard

## Support
- GitHub Issues
- Supabase Discord community
- Documentation
- Community forums
- Email support

## Technical Resources
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/installing)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Flutter Documentation](https://docs.flutter.dev/)