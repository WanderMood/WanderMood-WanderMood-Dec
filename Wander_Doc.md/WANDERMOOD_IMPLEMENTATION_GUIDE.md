# WanderMood - Implementatie Document

> Een AI-gedreven reisapplicatie die reisaanbevelingen personaliseert op basis van stemming en voorkeuren.

## 1. Technische Specificaties

### 1.1 Ontwikkelomgeving
- Flutter SDK: laatste stabiele versie
- Dart: 3.x
- Minimum OS versies:
  - iOS: 13.0+
  - Android: API level 23 (Android 6.0)+
- IDE: VS Code / Android Studio

### 1.2 Architectuur
- **Frontend**: Flutter met Clean Architecture
  - Presentation Layer
  - Domain Layer
  - Data Layer
- **Backend**: Supabase
  - Real-time Database
  - Authentication
  - Storage
  - Edge Functions
- **State Management**: Riverpod
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth

## 2. Project Structuur

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── providers/
│   ├── config/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── mood_tracking/
│   ├── recommendations/
│   ├── weather/
│   ├── social/
│   └── booking/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── entities/
│   └── repositories/
└── presentation/
    ├── screens/
    ├── widgets/
    └── controllers/
```

## 3. Core Features Implementatie

### 3.1 Authenticatie Module (Supabase Auth)
```dart
// Belangrijkste klassen:
- SupabaseAuthRepository
- UserEntity
- AuthenticationController
- LoginScreen
- RegisterScreen
```

#### Supabase Auth Flow
```dart
// PKCE Auth Flow implementatie
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);

// Sociale login providers
final authService = ref.read(authServiceProvider);
final result = await authService.signInWithProvider(Provider.google);
```

### 3.2 Stemmings Module
```dart
// Kern componenten:
- MoodTrackingRepository
- MoodEntity
- MoodController
- MoodSelectionScreen
- MoodHistoryScreen
```

#### Realtime Mood Updates
```dart
// Supabase Realtime implementatie
final subscription = supabase
  .from('moods')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((List<Map<String, dynamic>> data) {
    // Verwerk realtime mood updates
  });
```

### 3.3 Aanbevelingen Engine
```dart
// Hoofdcomponenten:
- RecommendationService
- PlaceEntity
- RecommendationController
- RecommendationsScreen
```

#### Supabase Edge Functions voor AI
```dart
// API call naar Supabase Edge Function
final response = await supabase.functions.invoke(
  'generate_recommendations',
  body: {
    'mood': currentMood,
    'weather': currentWeather,
    'location': userLocation,
    'preferences': userPreferences,
  },
);
```

### 3.4 Locatie & Explore Module
```dart
// Kern componenten:
- LocationService
- PlacesService
- LocationSelector
- ExploreScreen
```

#### Locatie Default Instellingen
De standaard locatie van de applicatie is gewijzigd van San Francisco naar Rotterdam:

```dart
// Default locatie configuratie in LocationService
final Map<String, dynamic> defaultLocation = {
  'latitude': 51.9244,  // Rotterdam coördinaten
  'longitude': 4.4777,
  'name': 'Rotterdam'
};

// LocationSelector fallback
final rotterdamLocation = Location(
  id: 'rotterdam',
  latitude: 51.9244,
  longitude: 4.4777,
  name: 'Rotterdam'
);

// Explore screen kaarten
Alle attractiekaarten zijn geüpdatet om Rotterdam te weerspiegelen als hoofdlocatie
```

## 4. Database Schema (PostgreSQL)

### 4.1 Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  preferences JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" 
ON users FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Users can update own data" 
ON users FOR UPDATE 
USING (auth.uid() = id);
```

### 4.2 Moods Table
```sql
CREATE TABLE moods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  mood_type TEXT NOT NULL,
  intensity INTEGER CHECK (intensity BETWEEN 1 AND 10),
  notes TEXT,
  weather JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  location GEOGRAPHY(POINT),
  activities TEXT[]
);

-- RLS Policy
ALTER TABLE moods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own moods" 
ON moods FOR ALL 
USING (auth.uid() = user_id);

CREATE POLICY "Users can view shared moods" 
ON moods FOR SELECT 
USING (is_shared = true);
```

### 4.3 Places Table
```sql
CREATE TABLE places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  location GEOGRAPHY(POINT) NOT NULL,
  mood_tags TEXT[],
  weather_suitability TEXT[],
  activities TEXT[],
  photos TEXT[],
  rating DECIMAL(3,1),
  opening_hours JSONB,
  price_level INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for places" 
ON places FOR SELECT 
USING (true);
```

### 4.4 User_Places Table (Favorites)
```sql
CREATE TABLE user_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  place_id UUID REFERENCES places(id) NOT NULL,
  is_favorite BOOLEAN DEFAULT false,
  visit_count INTEGER DEFAULT 0,
  last_visited TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, place_id)
);

-- RLS Policy
ALTER TABLE user_places ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own place relationships" 
ON user_places FOR ALL 
USING (auth.uid() = user_id);
```

## 5. API Integraties

### 5.1 Supabase Setup
```dart
// pubspec.yaml
dependencies:
  supabase_flutter: ^2.3.4
  
// Initialisatie in main.dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  debug: false, // Set to true for development
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);

// Environment variabelen in .env bestand
SUPABASE_URL=https://asxaybzfkslzbsqmpbjd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzeGF5Ynpma3NsemJzcW1wYmpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzOTQ1NzYsImV4cCI6MjA1Nzk3MDU3Nn0.dTKzBLI_-kNAAkPFf8_MCvB5lUmwpuwjxJHYZsUYJKM
```

### 5.2 Weer API
- OpenWeatherMap API
- Endpoints voor:
  - Huidige weer
  - Weersvoorspelling
  - Historische weerdata

```dart
// Environment variabelen voor weather API
OPENWEATHER_API_KEY=your_api_key_here
```

### 5.3 Places API
- Google Places API
- Foursquare API
- Endpoints voor:
  - Locatie zoeken
  - Place details
  - Foto's
  - Reviews

```dart
// Environment variabelen voor Google Places API
GOOGLE_MAPS_API_KEY=your_api_key_here
FOURSQUARE_API_KEY=your_api_key_here
```

## 6. UI/UX Specificaties

### 6.1 Kleurenschema
```dart
// Primaire kleuren
primary: #5C6BC0
secondary: #81C784
accent: #FFB74D

// Stemmingskleuren
happy: #FFD700
relaxed: #98FB98
energetic: #FF4500
melancholic: #4682B4
```

### 6.2 Typografie
```dart
// Font families
headings: 'Poppins'
body: 'Roboto'

// Font sizes
h1: 24.0
h2: 20.0
body: 16.0
caption: 14.0
```

## 7. Security Maatregelen

### 7.1 Supabase Security
- Row Level Security (RLS) Policies
```sql
-- Basis RLS implementatie
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE moods ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_places ENABLE ROW LEVEL SECURITY;

-- Voorbeeld van gebruikersspecifieke toegang
CREATE POLICY "Users can only view their own data"
ON users FOR SELECT
USING (auth.uid() = id);

-- Voorbeeld van publieke leestoegang
CREATE POLICY "Public read access for places"
ON places FOR SELECT
USING (true);
```

### 7.2 API Security
- API key beveiliging in .env files
- Rate limiting via Supabase Edge Functions
- Data encryptie voor gevoelige informatie
- PKCE auth flow voor veilige OAuth authenticatie

## 8. Testing Strategie

### 8.1 Unit Tests
```dart
// Voorbeeld test structuur voor Supabase
test('MoodRepository should save mood in Supabase', () async {
  final repository = MoodRepository(mockSupabaseClient);
  // Test implementatie
});
```

### 8.2 Widget Tests
- Core widgets
- Screen widgets
- Custom components

### 8.3 Integration Tests
- User flows
- API integraties
- Database operaties

## 9. Performance Optimalisatie

### 9.1 Caching Strategie
- Lokale database met Hive
- Supabase PostgreSQL cache
- Image caching

### 9.2 Lazy Loading
- Infinite scroll voor lijsten
- Image lazy loading
- On-demand data fetching met Supabase pagination

```dart
// Pagination voorbeeld
final data = await supabase
  .from('places')
  .select()
  .range(0, 9)  // First 10 records
  .order('rating', ascending: false);
```

## 10. Deployment Pipeline

### 10.1 Development
- GitHub voor versiebeheer
- GitHub Actions voor CI/CD
- Automated testing

### 10.2 Supabase CI/CD
- Supabase CLI voor lokale ontwikkeling
- Database migrations via Supabase CLI
- Edge Functions deployment

```bash
# Supabase CLI commando's
supabase start
supabase db push
supabase functions deploy generate_recommendations
```

### 10.3 Release Proces
- Beta testing via TestFlight/Internal Testing
- Staged rollouts
- Automated versioning

---

*Laatste update: April 2025*

## Contact
Voor vragen over de implementatie, neem contact op met het ontwikkelteam. 