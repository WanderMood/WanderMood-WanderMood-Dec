import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';

/// Fallback count when RPC fails or is unavailable (e.g. before go-live).
const int _kFallbackTravelerCount = 12000;

/// Formatted fallback for UI when count is loading or failed.
const String kFallbackTravelerCountFormatted = '12,000+';

/// Fetches total number of profiles (travelers) from Supabase.
/// Used on signup screen for "Join X travelers in {city}!".
final travelerCountProvider = FutureProvider<int>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final result = await client.rpc('get_traveler_count');
    if (result == null) return _kFallbackTravelerCount;
    if (result is int) return result;
    if (result is num) return result.toInt();
    return _kFallbackTravelerCount;
  } catch (_) {
    return _kFallbackTravelerCount;
  }
});

/// Formats count for display: e.g. 1234 → "1,000+", 12500 → "12,000+".
String formatTravelerCount(int count) {
  if (count < 1000) return count.toString();
  final thousands = (count / 1000).floor();
  return '${_formatInt(thousands * 1000)}+';
}

String _formatInt(int n) {
  if (n < 1000) return n.toString();
  final parts = <String>[];
  while (n >= 1000) {
    parts.insert(0, (n % 1000).toString().padLeft(3, '0'));
    n ~/= 1000;
  }
  parts.insert(0, n.toString());
  return parts.join(',');
}
