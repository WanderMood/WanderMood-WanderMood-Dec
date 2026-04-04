/// Inclusion / dietary keys stored in `user_preferences.dietary_restrictions`.
/// Moody v62 reads this array for OpenAI search — keep keys stable.
class InclusionPreferenceEntry {
  const InclusionPreferenceEntry(this.key, this.label);
  final String key;
  final String label;
}

const List<InclusionPreferenceEntry> kInclusionPreferenceEntries = [
  InclusionPreferenceEntry('halal', 'Halal'),
  InclusionPreferenceEntry('vegan', 'Vegan'),
  InclusionPreferenceEntry('vegetarian', 'Vegetarian'),
  InclusionPreferenceEntry('gluten_free', 'Gluten-free'),
  InclusionPreferenceEntry('lgbtq_friendly', 'LGBTQ+ friendly'),
  InclusionPreferenceEntry('black_owned', 'Black-owned'),
  InclusionPreferenceEntry('family_friendly', 'Family-friendly'),
  InclusionPreferenceEntry('kids_friendly', 'Kid-friendly'),
];

Set<String> get kInclusionPreferenceKeySet =>
    kInclusionPreferenceEntries.map((e) => e.key).toSet();

/// Keeps only known keys, in canonical UI order (stable for diffing and tests).
List<String> normalizeInclusionPreferenceKeys(Iterable<String> raw) {
  final wanted = raw.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  return [
    for (final e in kInclusionPreferenceEntries)
      if (wanted.contains(e.key)) e.key,
  ];
}
