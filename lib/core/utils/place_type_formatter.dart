/// Human-readable Google / Places API type slugs for UI (Explore, My Day, Mood Match).
String formatPlaceType(String type, {String languageCode = 'en'}) {
  final raw = type.trim().toLowerCase();
  if (raw.isEmpty) return '';

  final nl = languageCode.toLowerCase().startsWith('nl');

  const enExceptions = <String, String>{
    'art_museum': 'Art museum',
    'coffee_shop': 'Coffee shop',
    'cocktail_bar': 'Cocktail bar',
    'live_music_venue': 'Live music venue',
    'restaurant': 'Restaurant',
    'museum': 'Museum',
    'night_club': 'Night club',
  };
  const nlExceptions = <String, String>{
    'art_museum': 'Kunstmuseum',
    'coffee_shop': 'Koffiehuis',
    'cocktail_bar': 'Cocktailbar',
    'live_music_venue': 'Livemuziekplek',
    'restaurant': 'Restaurant',
    'museum': 'Museum',
    'night_club': 'Nachtclub',
  };
  final ex = nl ? nlExceptions : enExceptions;
  if (ex.containsKey(raw)) return ex[raw]!;

  final spaced = raw.replaceAll('_', ' ').trim();
  if (spaced.isEmpty) return '';
  return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
}
