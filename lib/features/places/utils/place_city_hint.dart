/// Best-effort city label from a formatted address (NL/EU-friendly).
/// Used to group saved places that span multiple cities in one collection.
String placeCityHint(String address) {
  var parts = address
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'Other';

  const countries = {
    'netherlands',
    'the netherlands',
    'nederland',
    'nl',
    'belgium',
    'belgië',
    'belgie',
    'germany',
    'deutschland',
    'france',
    'united kingdom',
    'uk',
    'usa',
    'united states',
  };
  while (parts.isNotEmpty) {
    final last = parts.last.toLowerCase();
    if (countries.contains(last)) {
      parts = parts.sublist(0, parts.length - 1);
      continue;
    }
    break;
  }
  if (parts.isEmpty) return 'Other';

  final lastSeg = parts.last;
  // Dutch postcode + city: "3011 Rotterdam", "2511 AB Den Haag"
  final pc = RegExp(r'^\d{4}\s*[A-Za-z]{0,2}\s+(.+)$').firstMatch(lastSeg);
  if (pc != null) {
    return _normalizeCityLabel(pc.group(1)!);
  }
  return _normalizeCityLabel(lastSeg);
}

String _normalizeCityLabel(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'Other';
  // Drop redundant region suffix sometimes present: "Rotterdam, Zuid-Holland" already split
  return t;
}
