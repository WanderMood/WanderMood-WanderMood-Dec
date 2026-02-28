import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/gyg_link.dart';

/// Fetches GetYourGuide affiliate links from Supabase.
/// Caches results per destination in memory to avoid re-fetching.
class GygLinksService {
  GygLinksService(this._supabase);

  final SupabaseClient _supabase;

  static final Map<String, List<GygLink>> _cache = {};
  static const int _maxLinks = 5;

  /// Fetch up to 5 links for the given destination.
  /// [destination] is normalized (trimmed, lowercased) before querying.
  Future<List<GygLink>> fetchLinks(String destination) async {
    final normalized = destination.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    if (_cache.containsKey(normalized)) {
      debugPrint('📋 GYG: Using cached links for $normalized');
      return _cache[normalized]!;
    }

    try {
      final rows = await _supabase
          .from('gyg_links')
          .select('destination, type, url')
          .eq('destination', normalized)
          .eq('is_active', true)
          .limit(_maxLinks)
          .order('type');

      final links = (rows as List)
          .map((r) => GygLink.fromJson(r as Map<String, dynamic>))
          .toList();

      _cache[normalized] = links;
      debugPrint('✅ GYG: Fetched ${links.length} links for $normalized');
      return links;
    } catch (e) {
      debugPrint('❌ GYG: Error fetching links for $normalized: $e');
      return [];
    }
  }

  /// Clear cache (e.g. for testing or manual refresh).
  static void clearCache() {
    _cache.clear();
  }
}
