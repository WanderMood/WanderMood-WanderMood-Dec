import 'dart:convert';

/// Short stable digest for active Explore filters (named slugs + hard filter map).
/// Empty when nothing is selected — matches Edge [filterIntelDigest] semantics.
String moodyExploreFilterDigest(
  List<String> named,
  Map<String, dynamic> hard,
) {
  final n = named.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
    ..sort();
  final h = Map<String, dynamic>.from(hard)
    ..removeWhere((_, v) => v == null);
  if (n.isEmpty && h.isEmpty) return '';
  final payload = '${n.join('|')}|${jsonEncode(h)}';
  var x = 0;
  for (var i = 0; i < payload.length; i++) {
    x = ((x << 5) - x) + payload.codeUnitAt(i);
    x &= 0x7fffffff;
  }
  return 'fi${x.abs().toRadixString(36)}';
}
