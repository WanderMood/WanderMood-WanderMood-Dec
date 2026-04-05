import 'package:geocoding/geocoding.dart' show Placemark;

/// Picks a user-facing settlement (city/town) from platform geocoder [Placemark]s.
///
/// Avoids treating Dutch provinces or "Netherlands" as the city. Uses every
/// placemark in order (not only the first), since the first hit can be a broad
/// metro while a later entry has the actual [locality] (e.g. Spijkenisse).
String? settlementNameFromPlacemarks(List<Placemark> placemarks) {
  if (placemarks.isEmpty) return null;

  bool isProvinceOrMacroRegion(String s) {
    final l = s.toLowerCase().trim();
    const macro = {
      'zuid-holland',
      'noord-holland',
      'noord-brabant',
      'gelderland',
      'utrecht',
      'overijssel',
      'groningen',
      'friesland',
      'drenthe',
      'limburg',
      'zeeland',
      'flevoland',
      'the netherlands',
      'netherlands',
      'nederland',
      'holland',
      'europe',
    };
    return macro.contains(l);
  }

  String? pick(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.length < 2) return null;
    if (isProvinceOrMacroRegion(t)) return null;
    return t;
  }

  // Prefer locality across all results (often the actual town).
  for (final p in placemarks) {
    final loc = pick(p.locality);
    if (loc != null) return loc;
  }
  for (final p in placemarks) {
    final sub = pick(p.subLocality);
    if (sub != null) return sub;
  }
  for (final p in placemarks) {
    final sub = pick(p.subAdministrativeArea);
    if (sub != null) return sub;
  }
  for (final p in placemarks) {
    final n = pick(p.name);
    if (n != null) return n;
  }
  for (final p in placemarks) {
    final a = pick(p.administrativeArea);
    if (a != null) return a;
  }
  return null;
}
