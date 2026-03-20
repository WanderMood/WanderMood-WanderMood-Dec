# WanderMood — Complete UI Redesign Agent Prompt
## From Prototype to Premium: Screen-by-Screen Specification

---

## AGENT RULES (READ FIRST — NON-NEGOTIABLE)

1. Do NOT delete any files, tables, columns, or edge functions
2. Do NOT refactor working backend logic
3. Do NOT change navigation structure or route names
4. Fix UI only — layout, colors, typography, spacing, animations
5. Follow Moody-007.md and Moody-008.md for component naming
6. Files: `/Users/edviennemerencia/WanderMood-WanderMood-Dec/Moody-007.md`
7. Files: `/Users/edviennemerencia/WanderMood-WanderMood-Dec/Moody-008.md`
8. One screen at a time. Show before/after. Wait for approval before next screen.
9. All changes must be reversible — use feature branches

---

## THE CORE PROBLEM

The app has no design system. Every screen was built independently with different
colors, font sizes, spacing, and component styles. The result feels like a collection
of screens, not a product. The goal of this prompt is to make every screen feel like
it was built by the same person with the same intention.

---

## DESIGN SYSTEM — THE RULES EVERY SCREEN MUST FOLLOW

### Colors

```dart
// ============================================================
// WANDERMOOD COLOR TOKENS
// ============================================================

// Backgrounds
const Color wmCream     = Color(0xFFF5F0E8); // Every screen background
const Color wmWhite     = Color(0xFFFFFFFF); // Cards, modals, bottom sheets
const Color wmParchment = Color(0xFFE8E2D8); // Borders, dividers, input borders

// Brand
const Color wmForest    = Color(0xFF2A6049); // CTAs, selected states, nav active, links
const Color wmForestTint= Color(0xFFEBF3EE); // Selected tile bg, success states

// Urgency / Energy
const Color wmSunset    = Color(0xFFE8784A); // Active-now banner, streaks, urgency ONLY
const Color wmSunsetTint= Color(0xFFFDF0E8); // Overdue rows, streak card bg

// Moody / Info
const Color wmSky       = Color(0xFFA8C8DC); // Moody character, info bubbles, Moody UI
const Color wmSkyTint   = Color(0xFFEDF5F9); // Moody says bg, info card bg

// Dark UI
const Color wmSlate     = Color(0xFF2B2F3A); // Dark banner, dark modals only

// Text
const Color wmCharcoal  = Color(0xFF1E1C18); // All primary text
const Color wmDusk      = Color(0xFF4A4640); // Secondary text
const Color wmStone     = Color(0xFF8C8780); // Metadata, placeholders, captions
const Color wmStoneLight= Color(0xFFB4B0A8); // Disabled text

// Semantic
const Color wmError     = Color(0xFFE05C5C); // Errors, destructive actions ONLY
const Color wmErrorTint = Color(0xFFFDF0EE); // Error bg

// Mood tile colors (keep exactly as-is — do not change these)
const Color wmTileBlij       = Color(0xFFF9D878);
const Color wmTileAvontuurlijk = Color(0xFFF4A89C);
const Color wmTileOntspannen = Color(0xFF78CCB8);
const Color wmTileEnergiek   = Color(0xFFA4CCDC);
const Color wmTileRomantisch = Color(0xFFF0A4C0);
const Color wmTileSociaal    = Color(0xFFD4B898);
const Color wmTileCultureel  = Color(0xFFBEB4D8);
const Color wmTileNieuwsgierig = Color(0xFFE8C4A0);
const Color wmTileGezellig   = Color(0xFFC4A898);
const Color wmTileOpgewonden = Color(0xFFA8D4A8);
const Color wmTileFoodie     = Color(0xFFF0C8A8);
const Color wmTileVerrassing = Color(0xFFC8D4E4);
```

### Typography

```dart
// ONLY these text styles. No others.

// Screen titles (page headers)
TextStyle wmTitle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w700,
  color: wmCharcoal,
  letterSpacing: -0.5,
);

// Section headers (Morning, Afternoon, etc.)
TextStyle wmSectionHeader = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: wmCharcoal,
);

// Card titles (activity names, place names)
TextStyle wmCardTitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: wmCharcoal,
);

// Body text (descriptions, messages)
TextStyle wmBody = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: wmDusk,
  height: 1.5,
);

// Metadata (time, distance, duration)
TextStyle wmMeta = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w400,
  color: wmStone,
);

// Labels (badges, pills, chips)
TextStyle wmLabel = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: wmCharcoal,
  letterSpacing: 0.2,
);

// CTA buttons
TextStyle wmButton = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: wmWhite,
  letterSpacing: 0.3,
);

// Small captions
TextStyle wmCaption = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w400,
  color: wmStone,
);
```

### Spacing (8px grid — everything is a multiple of 8)

```dart
const double wmSpace4  = 4;
const double wmSpace8  = 8;
const double wmSpace12 = 12;
const double wmSpace16 = 16;
const double wmSpace20 = 20;
const double wmSpace24 = 24;
const double wmSpace32 = 32;
const double wmSpace40 = 40;
const double wmSpace48 = 48;

// Screen padding (horizontal)
const double wmScreenPadding = 20;

// Card padding
const double wmCardPadding = 16;

// Bottom safe area buffer
const double wmBottomBuffer = 24;
```

### Border radius

```dart
const double wmRadiusSm  = 8;   // Badges, pills, chips
const double wmRadiusMd  = 12;  // Input fields, small cards
const double wmRadiusLg  = 16;  // Cards, bottom sheets
const double wmRadiusXl  = 24;  // Large buttons, modal handles
const double wmRadiusFull = 999; // Pill buttons
```

### Buttons

```dart
// PRIMARY — solid Forest, white text, full pill
Container(
  height: 54,
  decoration: BoxDecoration(
    color: wmForest,
    borderRadius: BorderRadius.circular(wmRadiusFull),
  ),
  child: Center(child: Text('Label', style: wmButton)),
)

// SECONDARY — white bg, Forest border, Forest text
Container(
  height: 54,
  decoration: BoxDecoration(
    color: wmWhite,
    border: Border.all(color: wmForest, width: 1.5),
    borderRadius: BorderRadius.circular(wmRadiusFull),
  ),
  child: Center(child: Text('Label', style: wmButton.copyWith(color: wmForest))),
)

// GHOST — no border, no bg, text only (for "Cancel", "Skip", etc.)
TextButton(child: Text('Label', style: wmBody.copyWith(color: wmStone)), ...)

// DANGER — solid Error red, white text
// Use ONLY for destructive actions (Delete, Remove)
```

### Cards

```dart
// Standard activity/place card
Container(
  decoration: BoxDecoration(
    color: wmWhite,
    borderRadius: BorderRadius.circular(wmRadiusLg),
    border: Border.all(color: wmParchment, width: 0.5),
  ),
  ...
)

// No box shadow. Ever. Borders only.
```

### Bottom Sheets / Modals

```dart
// All modals: bottom sheet that slides up with handle indicator
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: wmWhite,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => DraggableScrollableSheet(...)
)

// Handle bar at top of every bottom sheet:
Container(
  width: 40,
  height: 4,
  margin: EdgeInsets.only(top: 12, bottom: 20),
  decoration: BoxDecoration(
    color: wmParchment,
    borderRadius: BorderRadius.circular(2),
  ),
)
```

### Toast / Notification banners

```dart
// Success toast — slides in from bottom, auto-dismisses after 3s
// Background: wmForest, text: white, rounded pill
// Position: above the tab bar (never covers UI)
// Animation: slide up 60px + fade in (200ms), hold 2.5s, slide down + fade out (200ms)

// Error toast — same pattern but background: wmError

// Info toast — background: wmSlate

// Never use Flutter's built-in SnackBar — it looks generic
// Build a custom overlay widget
```

### Transitions between screens

```dart
// Standard push: slide from right (iOS default — keep as-is)
// Modal/sheet: slide up from bottom (see bottom sheet above)
// Loading screens: fade transition (opacity, 300ms)
// Success states: scale + fade in (element scales 0.95→1.0 + opacity 0→1, 250ms)
```

---

## SCREEN REDESIGNS — PRIORITY ORDER

Do these in order. Each screen gets its own branch and PR.

---

### SCREEN 1 — Loading screen ("Je plan wordt gemaakt")
**Status: ALREADY SPECIFIED** — see `wandermood_loading_screen_cursor_prompt.md`
**Branch:** `redesign/loading-screen`

---

### SCREEN 2 — MyDay (empty state — new user / no plan yet)

**Current problem:** Shows a background image of Chicago skyline that has nothing
to do with Rotterdam or WanderMood. Completely breaks the brand.

**Fix:**
- Background: `wmCream` — no image, no gradient
- Center of screen: Moody character (80px) + heading "Jouw dag is leeg ✨" (wmTitle)
- Subtext: "Laat Moody een plan maken voor jouw stemming vandaag" (wmBody)
- Primary CTA: "Plan mijn dag met Moody" → navigate to MoodyHub
- Secondary CTA: "Verken activiteiten" → navigate to Explore
- Both buttons use the standard button styles above
- Remove the city skyline background image entirely

---

### SCREEN 3 — MyDay (active state — plan exists)

**Current problems:**
1. `RangeError` debug text is visible in the top-left corner — this must be caught
   and hidden from users (wrap in try/catch, show nothing if error)
2. "My Day" title in neon green — change to `wmCharcoal`
3. The active-now banner uses a gradient (orange→red) — replace with solid
   `wmSunset` (#E8784A)
4. "Mark done or tap more for still here" is instruction text in a UI label position
   — replace with the activity category (e.g. "Food · 90 min") in `wmMeta` style
5. Section headers (Morning, Afternoon, Evening) use neon green — change to
   `wmForest`
6. The in-progress banner uses a gradient (pink→purple) — replace with solid
   `wmSky` (#A8C8DC) and `wmCharcoal` text (it's a calm state, not urgent)

**Fix the in-progress banner:**
```
Background: wmSky
Title: activity name — wmCardTitle in wmCharcoal
Subtitle: "Je bent er nu mee bezig" — wmMeta
Buttons: "Directions" (secondary button) + "In Progress" (primary button in wmForest)
```

---

### SCREEN 4 — MoodyHub (mood selection)

**Current state:** This screen is almost perfect. Only two changes:

1. The CTA button "Maak je perfecte plan!" — change background from neon `#3DB55A`
   to `wmForest` (#2A6049)
2. The italic "vanavond?" headline — change color from neon green to `wmForest`

**Do NOT change:**
- The 12 mood tile colors (they are correct and beautiful)
- The tile layout and sizing
- The Moody character
- The dark slate vibe banner
- The selected state checkmark logic (keep as-is)

---

### SCREEN 5 — Plan result screen (after loading)

**Current problems:**
1. The background is a pastel gradient (pink/purple/blue) — replace with `wmCream`
2. The "JOUW PLAN" badge uses inconsistent styling — replace with a simple pill:
   `wmForestTint` background + `wmForest` text + `wmLabel` style
3. The "Foodie" mood badge (orange pill) is fine — keep as-is
4. "Toevoegen aan Mijn Dag" button at bottom uses neon green — change to `wmForest`
5. "Niets voor jou?" (Not for me) button outline uses neon green — change to
   `wmForest` border + `wmForest` text
6. "Bekijk activiteit" button is hot pink — this is the most inconsistent color in
   the app. Change to `wmSky` background (#A8C8DC) + dark text (#1A3D50)

---

### SCREEN 6 — Explore screen

**Current problems:**
1. "Powered by GetYourGuide" header banner looks like an ad. Move it to a small
   `wmCaption` footer below the cards. Never at the top.
2. Filter chips (All, Food, Culture, Outdoor) — when selected, use `wmForestTint`
   bg + `wmForest` border + `wmForest` text. When unselected: `wmCream` bg +
   `wmParchment` border + `wmStone` text.
3. "65 activities found" text — fine as-is, just make sure color is `wmStone`
4. View toggle buttons (list/grid/map) — selected state bg: `wmForest`, icon: white.
   Unselected: `wmParchment` bg, icon: `wmStone`
5. "Netherlands 🇳🇱" on every card — change to neighbourhood or distance only.
   Never show the country — the user set their city to Rotterdam, they know.

---

### SCREEN 7 — Advanced Filters modal

**Current problems:**
1. Modal background is light green — change to `wmWhite`
2. Filter icon badge (green square with sliders icon) — change to `wmForest` bg
3. Filter category pills (Indoor Only, Outdoor, etc.) currently use random
   pastel backgrounds with no system. Change ALL filter pills to:
   - Unselected: `wmCream` bg + `wmParchment` border + `wmCharcoal` text
   - Selected: `wmForestTint` bg + `wmForest` border + `wmForest` text
4. "Save X filters" button — change from neon green to `wmForest`
5. "Clear All" button — change to `wmStone` text, no border

---

### SCREEN 8 — Place detail screen

**Current problems:**
1. The three info tiles (Duration, Price, Distance) each have different background
   colors (peach, green, blue) — replace all three with the same: `wmCream` bg +
   `wmParchment` border. Use an icon in `wmForest` for each tile. Clean, consistent.
2. Category tags (Food, Nightlife) use purple/orange — replace both with
   `wmForestTint` bg + `wmForest` text + `wmLabel` style
3. "Uitzonderlijk" rating label in `wmForest` text — fine, keep as-is
4. "Routebeschrijving" bottom button — add `wmForest` background + white text

---

### SCREEN 9 — Moody chat screen

**Current problems:**
1. The full-screen gradient background (blue/white/beige) — replace with solid
   `wmSkyTint` (#EDF5F9) for the upper portion, `wmCream` below the chat card
2. Moody's avatar in the header uses a bright green circle — replace with
   `wmSky` (#A8C8DC) background (matches the character color)
3. The 3 large green buttons (Plan mijn hele dag, Vind koffie, Zet me in beweging)
   — change to `wmForest` background
4. "Gewoon chatten" secondary button — `wmWhite` bg + `wmParchment` border +
   `wmCharcoal` text
5. Chat input field border — change focus border color from neon green to `wmForest`

---

### SCREEN 10 — My Agenda (calendar)

**Current problems:**
1. ALL date numbers in neon green — change weekday numbers to `wmCharcoal`
2. Weekend numbers (Sun/Sat) in neon green — change to `wmStone`
3. Selected date circle: neon green → `wmForest`
4. Empty state card is fine structurally — but add a Moody character (48px) above
   the text and change copy to "Geen activiteiten gepland" + "Tik op een dag om
   activiteiten toe te voegen" in `wmBody`
5. "My Agenda" title — change to `wmCharcoal`
6. Activity dots: use `wmSunset` for Moody-generated activities, `wmForest` for
   manually added activities

---

### SCREEN 11 — Profile screen

**Current problems:**
1. Profile avatar border: neon green ring — change to `wmForest`
2. "Lokale modus" / "Op reis" toggle: active state should be `wmForest`, inactive
   should be `wmParchment` with `wmStone` text
3. Stats cards (Check-ins, Plekken, Top stemming): each has different random colors
   (orange circle, purple/blue circle, pink circle). Replace all icons with:
   - Check-ins: `wmSunsetTint` bg + `wmSunset` icon
   - Plekken: `wmSkyTint` bg + `wmSky` icon
   - Top stemming: `wmForestTint` bg + `wmForest` icon
4. "Bewerken" link uses orange color — change to `wmForest`
5. Profile tab in bottom nav shows pink active color — change to `wmForest`

---

### SCREEN 12 — Edit Profile screen

**Current problems:**
1. Screen background is pure white — change to `wmCream`
2. Input field focus border: orange — change to `wmForest`
3. "Save" button (active state): orange/red gradient — change to solid `wmForest`
   background with white text (pill shape, 54px height)
4. "Save" button (disabled state): `wmParchment` bg + `wmStone` text
5. Vibe tags (Spontaneous, Social, Relaxed): red/orange gradient pills — replace
   with `wmForestTint` bg + `wmForest` text. These are selected vibes, not warnings.
6. Bio character counter shows twice ("0/150" appearing twice) — remove the
   duplicate

---

### SCREEN 13 — Share Profile screen

**Current problems:**
1. Profile card uses a pink/purple gradient — replace with solid `wmForest` bg +
   white text. Clean and branded.
2. Social share buttons (Instagram gradient, WhatsApp green, Twitter blue, dark
   Email) each use their brand colors. This is actually acceptable — keep them.
   They represent external platforms where brand color is expected.
3. "QR-code" and "Link kopiëren" cards — change icon badge backgrounds:
   QR = `wmForestTint` + `wmForest` icon
   Link = `wmSkyTint` + `wmSky` icon

---

### SCREEN 14 — Quick Review sheet

**Current problems:**
1. Place preview card uses orange/pink gradient — replace with `wmSunsetTint` bg +
   `wmSunset` border. Matches the urgency/completion theme.
2. Vibe selector tiles (Amazing, Good, Okay, Meh) — currently plain white squares.
   Give them light backgrounds that match the sentiment:
   - Amazing: `wmTileBlij` (#F9D878) bg
   - Good: `wmTileOntspannen` (#78CCB8) bg — desaturated tint
   - Okay: `wmParchment` bg
   - Meh: error tint (#FDF0EE) bg
3. "Save Review" button (disabled): currently grey with grey text — use
   `wmParchment` bg + `wmStone` text
4. "Save Review" button (enabled): `wmForest` bg + white text
5. Star rating icons (empty): change from grey to `wmParchment` (warmer)

---

### SCREEN 15 — Activity Options sheet (the "..." menu)

**Current problems:**
1. Sheet background is very light grey — change to `wmWhite`
2. Icon colors are all `wmForest` except "Still Here" which is amber — make them
   consistent: all `wmForest` except "Mark as Done" which gets a checkmark in
   `wmForest` filled circle, and any destructive action (if any) uses `wmError`
3. Add a thin `wmParchment` divider line between each option row

---

### SCREEN 16 — Weather modal

**Current problems:**
1. Background and card are blue/white — replace with:
   - Modal background: `wmWhite`
   - Temperature text: `wmCharcoal`
   - "Clouds" subtitle: `wmStone`
   - Data rows: standard `wmBody` text with `wmParchment` dividers
2. "Close" button: bright blue pill — replace with `wmForest` pill button

---

### SCREEN 17 — World Globe screen ("Your Journey")

This screen is unique — it has a space/dark theme intentionally. **Do not apply
the WanderMood color system to this screen.** It is a special feature screen with
its own visual identity. The only fixes needed:
1. "Demo" badge top right — change to `wmForestTint` bg + `wmForest` text
2. "Rotate" and "Reset" buttons — change border color from dark grey to a slightly
   lighter grey that reads better against the dark background

---

## QA CHECKLIST

Before considering the redesign done, verify:

```
[ ] Every screen background is wmCream (#F5F0E8)
[ ] No screen uses a gradient background (exception: World Globe)
[ ] All CTA buttons use wmForest (#2A6049), not neon green
[ ] No neon/lime green (#3DB55A or similar) appears anywhere
[ ] Active states all use wmForest or wmSunset (never both on same element)
[ ] All card backgrounds are wmWhite (#FFFFFF)
[ ] Card borders use wmParchment (0.5px)
[ ] No box shadows on cards
[ ] Debug error text (RangeError) is caught and not shown to users
[ ] Dutch/English language is consistent within each screen
[ ] Bottom tab bar: active = wmForest icon + wmForest label
[ ] Bottom tab bar background: wmWhite
[ ] All modal/bottom sheet backgrounds: wmWhite
[ ] Moody character: always uses wmSky (#A8C8DC) accent color
[ ] Toast notifications: custom overlay (not Flutter SnackBar)
[ ] All button heights: 54px (primary), 44px (secondary/ghost)
[ ] Typography: only the defined text styles above — no other font sizes
[ ] Spacing: all padding/margin values are multiples of 4px minimum
```

---

## IMPORTANT NOTES FOR THE AGENT

- The backend is already fixed and secured — do not touch Supabase logic
- Do not change any navigation routes or screen names
- The mood tile colors (12 pastel colors) are perfect — do not change them
- The Moody character asset is perfect — do not change it
- The orange active-now banner is good — just change gradient to solid wmSunset
- When in doubt about a color, use wmForest for interactive elements and wmCream
  for backgrounds
- If something currently works and looks acceptable, leave it alone
- Minimal changes > big refactors