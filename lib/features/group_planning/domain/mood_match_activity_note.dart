/// Client-side Moody-style one-liner until plan activities include [moodyNote] from the backend.
String moodMatchActivityNoteLine(
  String languageCode,
  String placeTypeRaw,
  String? moodTagRaw,
) {
  final type = placeTypeRaw.trim().toLowerCase();
  final mood = (moodTagRaw ?? '').trim().toLowerCase();
  final nl = languageCode.toLowerCase().startsWith('nl');
  final key = '$type|$mood';

  const pairs = <String, (String, String)>{
    'restaurant|cultureel': (
      'The menu shifts with the seasons. Trust it.',
      'De kaart wisselt met de seizoenen. Vertrouw erop.',
    ),
    'restaurant|cultural': (
      'The menu shifts with the seasons. Trust it.',
      'De kaart wisselt met de seizoenen. Vertrouw erop.',
    ),
    'museum|cultureel': (
      'Go slow through the first room — that is where the good stuff is.',
      'Neem de tijd in de eerste zaal — daar zit het goede spul.',
    ),
    'museum|cultural': (
      'Go slow through the first room — that is where the good stuff is.',
      'Neem de tijd in de eerste zaal — daar zit het goede spul.',
    ),
    'cocktail_bar|social': (
      'Ask what the bartender has been tinkering with this week.',
      'Vraag wat de bartender deze week aan het uitproberen is.',
    ),
    'bar|social': (
      'Ask what the bartender has been tinkering with this week.',
      'Vraag wat de bartender deze week aan het uitproberen is.',
    ),
    'cafe|ontspannen': (
      'Sit by the window — people-watching counts as sightseeing.',
      'Ga bij het raam zitten — mensen kijken telt ook als sightseeing.',
    ),
    'cafe|relaxed': (
      'Sit by the window — people-watching counts as sightseeing.',
      'Ga bij het raam zitten — mensen kijken telt ook als sightseeing.',
    ),
    'park|avontuurlijk': (
      'Stretch your legs first; the best corner is usually farther in.',
      'Strek eerst je benen; de mooiste hoek zit vaak verderop.',
    ),
    'park|adventurous': (
      'Stretch your legs first; the best corner is usually farther in.',
      'Strek eerst je benen; de mooiste hoek zit vaak verderop.',
    ),
  };

  final row = pairs[key];
  if (row != null) return nl ? row.$2 : row.$1;

  final fallback = nl
      ? 'Kleine tip: laat de eerste indruk niet je enige oordeel zijn.'
      : 'Small tip: don’t let the first glance be your only verdict.';
  return fallback;
}
