/// Single place to map every stored / UI variant of communication tone into the
/// four keys used across Mood Match copy, notifications, and onboarding.
///
/// [PreferencesScreen] persists capitalized labels (`Playful`, `Calm`, …).
/// Onboarding and APIs use lowercase buckets (`energetic`, `direct`, …).
String canonicalCommunicationStyleKey(String? raw) {
  final k = (raw ?? 'friendly').trim().toLowerCase();
  switch (k) {
    case 'professional':
      return 'professional';
    case 'energetic':
      return 'energetic';
    case 'direct':
      return 'direct';
    case 'friendly':
      return 'friendly';
    // Profile → Preferences screen (`_communicationOptions`)
    case 'playful':
      return 'energetic';
    case 'calm':
      return 'professional';
    case 'practical':
      return 'direct';
    default:
      return 'friendly';
  }
}

/// Maps canonical or legacy DB values to [PreferencesScreen] chip labels
/// (`Friendly`, `Playful`, `Calm`, `Practical`).
String profileCommunicationStyleChipLabel(String? rawFromDb) {
  final c = canonicalCommunicationStyleKey(rawFromDb);
  switch (c) {
    case 'energetic':
      return 'Playful';
    case 'professional':
      return 'Calm';
    case 'direct':
      return 'Practical';
    case 'friendly':
    default:
      return 'Friendly';
  }
}
