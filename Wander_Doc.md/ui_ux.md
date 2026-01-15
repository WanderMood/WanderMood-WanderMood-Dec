# WanderMood - UI/UX Implementatie Documentatie

> Een gedetailleerd document voor de UI/UX implementatie van de WanderMood app, gebaseerd op het voorgestelde design.

## 🎨 Kleurenschema

### Basis Kleuren Configuratie
```dart
class AppColors {
  // Primaire kleuren
  static const primaryGreen = Color(0xFF4CAF50);      // Groene buttons
  static const primaryPink = Color(0xFFFFC0CB);       // Roze achtergrond gradient start
  static const primaryYellow = Color(0xFFFFFACD);     // Gele achtergrond gradient end
  
  // Secundaire kleuren
  static const textDark = Color(0xFF333333);          // Donkere tekst
  static const textLight = Color(0xFF666666);         // Lichte tekst
  static const iconGrey = Color(0xFF9E9E9E);         // Iconen kleur
  
  // Mood kleuren
  static const adventureMood = Color(0xFFB2EBF2);    // Lichtblauw voor Adventure
  static const relaxMood = Color(0xFFE1BEE7);        // Lavendel voor Relax
  static const romanticMood = Color(0xFFFFCDD2);     // Zachtroze voor Romantic
  static const energeticMood = Color(0xFFFFF9C4);    // Lichtgeel voor Energetic
  
  // Gradient
  static const gradientStart = primaryPink;
  static const gradientEnd = primaryYellow;
}
```

## 📱 Screen Implementaties

### 1. Splash Screen
```dart
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientEnd,
          ],
        ),
      ),
      child: Center(
        child: Text('WanderMood', style: AppTypography.logo),
      ),
    );
  }
}
```

### 2. Authentication Screens

#### 2.1 Login Screen
- Email/wachtwoord input velden
- "Forgot Password" link
- Social login opties
- Gradient achtergrond
- Sign In button

#### 2.2 Password Reset Screen
- Email input veld
- Reset instructies
- Bevestigingsmelding
- Terug naar login optie

### 3. Home Screen met Mood Selection

#### 3.1 Mood Grid Layout
```dart
class MoodSelectionWidget extends StatelessWidget {
  final List<MoodOption> moodOptions = [
    MoodOption('Adventure', Icons.hiking, AppColors.adventureMood),
    MoodOption('Relax', Icons.spa, AppColors.relaxMood),
    MoodOption('Romantic', Icons.favorite, AppColors.romanticMood),
    MoodOption('Energetic', Icons.flash_on, AppColors.energeticMood),
  ];
}
```

#### 3.2 Weather Integration
- Weer iconen
- Temperatuur weergave
- 7-daagse voorspelling

### 4. Booking/Listing Screen
- Gefilterde accommodatielijst
- Prijs range slider
- Faciliteiten filter
- Kamertype selector

### 5. Explore Screen
#### 5.1 Header Redesign
```dart
// Top section with Explore title and location selector
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Explore Title with branded styling
      Text(
        'Explore',
        style: GoogleFonts.museoModerno(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF12B347),
        ),
      ),
      
      // Location Selector
      GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LocationSelector(
                onLocationSelected: (location) {
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rotterdam',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ],
  ),
)
```

#### 5.2 Advanced Search Bar
- Intelligente zoekbalk met suggesties
- Voice search ondersteuning
- Recent searches weergave
- Suggestion chips

#### 5.3 Category Filters
- Horizontaal scrollbare categorie chips
- Rotterdam-specifieke categorieën
- Actieve filter indicator

#### 5.4 Trending Sectie
```dart
// Trending section header with animations
Text(
  '🔥 Trending',
  style: GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
).animate(
  onPlay: (controller) => controller.repeat(reverse: true),
).shimmer(
  duration: const Duration(seconds: 3),
  color: const Color(0xFF12B347).withOpacity(0.3),
)
```

#### 5.5 Attractions Cards
- 10 Rotterdam attracties met dynamische inhoud
- Afstand indicator vanaf huidige locatie
- Categorieën en activiteiten tags
- Interactieve favorites en share knoppen

## �� Custom Components

### 1. Gradient Background
```dart
class GradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
    );
  }
}
```

### 2. Custom Button
```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(text),
      onPressed: onPressed,
    );
  }
}
```

### 3. Mood Selection Grid
```dart
class MoodGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) => MoodCard(
        mood: moodOptions[index],
      ),
    );
  }
}
```

## 📝 Typography

```dart
class AppTypography {
  static const logo = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static const heading = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static const bodyText = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    color: AppColors.textLight,
  );
}
```

## 📁 Assets Structuur

```
assets/
├── fonts/
│   ├── Poppins-Bold.ttf
│   ├── Poppins-SemiBold.ttf
│   └── Roboto-Regular.ttf
├── icons/
│   ├── mood_icons/
│   └── facility_icons/
└── images/
    └── logo.png
```

## 🚀 Implementatie Roadmap

### Fase 1: Basis UI Setup
- [x] Implementeer gradient background
- [ ] Setup font configuratie
- [ ] Maak basis custom components

### Fase 2: Authentication Screens
- [ ] Login screen
- [ ] Password reset
- [ ] Social login integratie

### Fase 3: Mood Selection
- [ ] Implementeer mood grid
- [ ] Animaties voor mood selectie
- [ ] Weer integratie

### Fase 4: Booking Interface
- [ ] Listing cards
- [ ] Filter implementatie
- [ ] Booking flow

## 🎯 Design Guidelines

### 1. Spacing
- Padding: 16px standaard
- Margin tussen secties: 24px
- Grid spacing: 10px

### 2. Radius
- Buttons: 25px
- Cards: 15px
- Input velden: 10px

### 3. Shadows
```dart
final BoxShadow standardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 10,
  offset: Offset(0, 4),
);
```

### 4. Animaties
- Mood selectie: Scale animation (0.95 -> 1.0)
- Page transitions: Fade + slide
- Button feedback: Ripple effect

## 📱 Responsive Design

### Breakpoints
```dart
class Breakpoints {
  static const double mobile = 360;
  static const double tablet = 768;
  static const double desktop = 1024;
}
```

### Adaptieve Layouts
- Gebruik `LayoutBuilder`
- Flexibele grid systemen
- Responsive spacing

## 🔍 Accessibility

### Richtlijnen
- Minimum touch target: 44x44px
- Kleurcontrast ratio: 4.5:1
- Ondersteun screen readers
- Schaalbare tekst

## 📊 Performance Guidelines

- Lazy loading voor images
- Geoptimaliseerde assets
- Efficiënte rebuilds
- Caching strategie

---

*Laatste update: [DATUM]*

## Contact
Voor UI/UX gerelateerde vragen, neem contact op met het design team. 