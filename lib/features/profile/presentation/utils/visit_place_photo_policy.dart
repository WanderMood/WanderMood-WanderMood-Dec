/// Stock / decorative URLs must not be shown as if they were venue photos (e.g. App Review).
bool isStockOrDecorativeImageUrl(String? raw) {
  final u = raw?.trim().toLowerCase() ?? '';
  if (u.isEmpty) return true;
  if (u.contains('unsplash.com')) return true;
  if (u.contains('source.unsplash')) return true;
  if (u.contains('picsum.photos')) return true;
  return false;
}
