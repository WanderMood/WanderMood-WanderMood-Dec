# WanderMood — Loading Screen Redesign
## Prompt for Cursor / Giri

---

## CONTEXT

This is the loading screen shown after the user selects their mood(s) on MoodyHub
and taps "Maak je perfecte plan!". The `moody` edge function is being called in the
background. This screen needs to feel premium, calm, and on-brand — not childish.

The current screen (yellow background, Moody floating, basic spinner, single line of
text) must be replaced entirely.

---

## WHAT TO BUILD

A full-screen loading experience with 4 elements:

### 1. Background
- Color: `#F5F0E8` (Cream — the app's universal background, NOT yellow)
- No gradients, no blobs, no glow effects

### 2. Moody character (centered, upper half)
- Use the existing Moody asset (blue face character)
- Size: 120×120px
- Animation: gentle breathing scale pulse
  - Scale from 1.0 → 1.06 → 1.0
  - Duration: 2.4 seconds per cycle
  - Easing: `Curves.easeInOut`
  - Repeat: infinite
  - Use `AnimationController` with `repeat(reverse: true)`
- NO glow effect, NO shadow, NO outer ring
- Position: centered horizontally, 35% from top of screen

### 3. Loading message (below Moody)
- Font: same as rest of app (Nunito or your current font)
- Size: 17px
- Weight: 500 (medium)
- Color: `#1E1C18` (Charcoal)
- Text-align: center
- Padding: 0 32px
- Gap from Moody: 28px
- Messages cycle every 2.2 seconds using a fade transition (opacity 1→0→1, 300ms)
- Message list is mood-aware (see below)

### 4. Progress indicator
- A thin horizontal bar at the bottom of the screen
- Width: 60% of screen width, centered
- Height: 3px
- Background track color: `#E8E2D8` (Parchment)
- Fill color: `#2A6049` (Forest)
- Animation: fills from 0% to 85% over 6 seconds, then holds at 85% until API returns
- When API returns: quickly fills to 100% (300ms), then screen transitions
- Border radius: 2px (fully rounded)
- Position: 72px from bottom of screen

---

## MOOD-AWARE COPY

Pass the selected mood(s) as a parameter to this screen. Use this map:

```dart
final Map<String, List<String>> loadingMessages = {
  'Blij': [
    'Moody zoekt de zonnigste plekken voor je...',
    'Goede vibes worden geladen...',
    'Bijna klaar — jouw perfecte dag staat klaar ✨',
  ],
  'Avontuurlijk': [
    'Moody jaagt op jouw volgende avontuur...',
    'Een epische route door de stad wordt uitgestippeld...',
    'Wacht even — iets wilds is onderweg 🔥',
  ],
  'Ontspannen': [
    'Moody zoekt jouw perfecte rustige plek...',
    'Een vredige dag wordt samengesteld...',
    'Rustig aan — jouw kalme plan is bijna klaar 🌿',
  ],
  'Energiek': [
    'Moody laadt energie voor je op...',
    'De beste actieve plekken worden gevonden...',
    'Vol energie — jouw dag staat bijna klaar ⚡',
  ],
  'Romantisch': [
    'Moody vindt de meest romantische plekken...',
    'Speciale momenten worden gevonden...',
    'Bijna klaar — een magische dag staat klaar 💕',
  ],
  'Sociaal': [
    'Moody zoekt de gezelligste plekken...',
    'Leuke activiteiten met anderen worden gevonden...',
    'Bijna klaar — een sociale dag staat klaar 👥',
  ],
  'Foodie': [
    'Moody snuffelt de lekkerste plekken op...',
    'De beste eetadressen in Rotterdam worden gevonden...',
    'Bijna klaar — een heerlijke dag staat klaar 🍽',
  ],
  'Cultureel': [
    'Moody duikt in de culturele scene...',
    'Kunst, muziek en cultuur worden opgezocht...',
    'Bijna klaar — een inspirerende dag staat klaar 🎭',
  ],
  'Gezellig': [
    'Moody zoekt de gezelligste hoekjes...',
    'Warme, comfortabele plekken worden gevonden...',
    'Bijna klaar — een gezellige dag staat klaar ☕',
  ],
  'Opgewonden': [
    'Moody zoekt de meest opwindende plekken...',
    'Bijzondere ervaringen worden gevonden...',
    'Bijna klaar — een spannende dag staat klaar 🤩',
  ],
  'Nieuwsgierig': [
    'Moody ontdekt verborgen plekken voor je...',
    'Unieke ervaringen worden gevonden...',
    'Bijna klaar — een ontdekkingstocht staat klaar 🔍',
  ],
  'Verrassing': [
    'Moody kiest iets verrassends voor je...',
    'Een onverwachte dag wordt samengesteld...',
    'Bijna klaar — een verrassende dag staat klaar 😮',
  ],
};

// Fallback for unknown or multiple moods:
final List<String> fallbackMessages = [
  'Moody denkt na...',
  'Jouw dag wordt samengesteld...',
  'Bijna klaar — jouw perfecte plan staat klaar ✨',
];
```

If multiple moods are selected, use the first selected mood's messages.

---

## FLUTTER IMPLEMENTATION STRUCTURE

```dart
class PlanLoadingScreen extends StatefulWidget {
  final List<String> selectedMoods;
  final Future<void> Function() onPlanReady; // callback when API returns

  const PlanLoadingScreen({
    Key? key,
    required this.selectedMoods,
    required this.onPlanReady,
  }) : super(key: key);

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen>
    with TickerProviderStateMixin {

  // 1. Breathing animation controller
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  // 2. Message cycling (index + fade)
  int _messageIndex = 0;
  double _messageOpacity = 1.0;
  Timer? _messageTimer;

  // 3. Progress bar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _apiComplete = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startMessageCycle();
    _startApiCall();
  }

  void _initAnimations() {
    // Breathing
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Progress bar — fills to 85% over 6 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressController.forward();
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      // Fade out
      setState(() => _messageOpacity = 0.0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _messageIndex = (_messageIndex + 1) % _getMessages().length;
            _messageOpacity = 1.0;
          });
        }
      });
    });
  }

  Future<void> _startApiCall() async {
    await widget.onPlanReady();
    // API returned — complete the progress bar
    if (mounted) {
      setState(() => _apiComplete = true);
      _progressController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 300),
      );
      // Brief pause, then navigate
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/my-day');
      }
    }
  }

  List<String> _getMessages() {
    final mood = widget.selectedMoods.isNotEmpty
        ? widget.selectedMoods.first
        : '';
    return loadingMessages[mood] ?? fallbackMessages;
  }

  @override
  void dispose() {
    _breathController.dispose();
    _progressController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // Cream
      body: SafeArea(
        child: Stack(
          children: [
            // Moody + message — centered in upper portion
            Align(
              alignment: const Alignment(0, -0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Moody breathing
                  ScaleTransition(
                    scale: _breathAnimation,
                    child: Image.asset(
                      'assets/images/moody_character.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Cycling message with fade
                  AnimatedOpacity(
                    opacity: _messageOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _getMessages()[_messageIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1C18),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar — fixed near bottom
            Positioned(
              bottom: 72,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 3,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          // Track
                          Container(
                            color: const Color(0xFFE8E2D8),
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              color: const Color(0xFF2A6049),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## WHAT NOT TO DO

- Do NOT use a yellow background — use `#F5F0E8` only
- Do NOT add a glow or halo effect around Moody
- Do NOT use a circular progress spinner (the bar is the indicator)
- Do NOT use a gradient background
- Do NOT add sound effects or haptics on this screen
- Do NOT show a back button — user cannot go back during loading
- Do NOT use bold/heavy typography for the loading messages — weight 500 max
- Do NOT add decorative elements (stars, confetti, sparkles) to this screen
- Do NOT use a different font from the rest of the app

---

## ACCEPTANCE CRITERIA

- [ ] Background is `#F5F0E8` (not yellow, not white)
- [ ] Moody breathes gently (not bouncing, not spinning)
- [ ] Messages cycle every 2.2 seconds with a smooth fade
- [ ] Messages are mood-aware (correct messages for selected mood)
- [ ] Progress bar fills from 0% to 85% over 6 seconds
- [ ] Progress bar jumps to 100% when API returns
- [ ] Screen navigates to MyDay after API completes + 500ms delay
- [ ] No back navigation possible during loading
- [ ] Screen looks good on iPhone SE (small) and iPhone 15 Pro Max (large)