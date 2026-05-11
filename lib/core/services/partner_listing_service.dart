import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Row from `active_partner_listings` (see Supabase migration).
class PartnerListing {
  final String id;
  final String businessName;
  final String? placeId;
  final String city;
  final List<String> targetMoods;
  final String? activeOffer;
  final String? customDescription;
  final bool isFeaturedThisWeek;
  final bool showNewBadge;
  final bool hasActiveOffer;
  final int totalViews;
  final int totalTaps;
  final int totalCheckins;

  const PartnerListing({
    required this.id,
    required this.businessName,
    this.placeId,
    required this.city,
    required this.targetMoods,
    this.activeOffer,
    this.customDescription,
    required this.isFeaturedThisWeek,
    required this.showNewBadge,
    required this.hasActiveOffer,
    required this.totalViews,
    required this.totalTaps,
    required this.totalCheckins,
  });

  factory PartnerListing.fromJson(Map<String, dynamic> json) {
    final moodsRaw = json['target_moods'];
    final moods = moodsRaw is List
        ? moodsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return PartnerListing(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      placeId: json['place_id'] as String?,
      city: (json['city'] as String?)?.trim() ?? '',
      targetMoods: moods,
      activeOffer: json['active_offer'] as String?,
      customDescription: json['custom_description'] as String?,
      isFeaturedThisWeek: json['is_featured_this_week'] as bool? ?? false,
      showNewBadge: json['show_new_badge'] as bool? ?? false,
      hasActiveOffer: json['has_active_offer'] as bool? ?? false,
      totalViews: (json['total_views'] as num?)?.toInt() ?? 0,
      totalTaps: (json['total_taps'] as num?)?.toInt() ?? 0,
      totalCheckins: (json['total_checkins'] as num?)?.toInt() ?? 0,
    );
  }

  static Set<String> _normMoods(Iterable<String> moods) => moods
      .map((m) => m.trim().toLowerCase())
      .where((m) => m.isNotEmpty)
      .toSet();

  /// Partners whose [targetMoods] intersect [moods] (case-insensitive).
  /// Empty [moods] means no mood filtering.
  bool matchesMoodFilter(List<String> moods) {
    if (moods.isEmpty) return true;
    final want = _normMoods(moods);
    final have = _normMoods(targetMoods);
    if (have.isEmpty) return false;
    return have.intersection(want).isNotEmpty;
  }
}

/// Fetches active partner rows from Supabase (`active_partner_listings`).
class PartnerListingService {
  PartnerListingService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static List<PartnerListing>? _cache;
  static String? _cachedCity;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  static Future<List<PartnerListing>> getForCity(String city) async {
    final c = city.trim();
    if (c.isEmpty) return [];

    if (_cache != null &&
        _cachedCity != null &&
        _cachedCity == c &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    try {
      final data = await _supabase
          .from('active_partner_listings')
          .select()
          .ilike('city', '%$c%');

      final list = (data as List<dynamic>)
          .map((e) => PartnerListing.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      _cache = list;
      _cachedCity = c;
      _cacheTime = DateTime.now();
      return list;
    } catch (e) {
      debugPrint('PartnerListingService: fetch error $e');
      return [];
    }
  }

  static Future<List<PartnerListing>> getMatchingMoods(
    String city,
    List<String> moods,
  ) async {
    final all = await getForCity(city);
    if (moods.isEmpty) return all;
    return all.where((p) => p.matchesMoodFilter(moods)).toList();
  }

  static Future<List<PartnerListing>> getTrending(String city) async {
    final all = await getForCity(city);
    final sorted = [...all]..sort((a, b) {
        final sb = b.totalViews + b.totalTaps + b.totalCheckins;
        final sa = a.totalViews + a.totalTaps + a.totalCheckins;
        return sb.compareTo(sa);
      });
    return sorted.take(8).toList();
  }

  static Future<List<PartnerListing>> getNew(String city) async {
    final all = await getForCity(city);
    return all.where((p) => p.showNewBadge).toList();
  }

  static Future<PartnerListing?> findByPlaceId(String placeId) async {
    final raw = placeId.trim();
    if (raw.isEmpty) return null;

    if (_cache != null) {
      try {
        return _cache!.firstWhere(
          (p) => p.placeId != null && p.placeId!.trim() == raw,
        );
      } catch (_) {}
    }

    try {
      final data = await _supabase
          .from('active_partner_listings')
          .select()
          .eq('place_id', raw)
          .maybeSingle();
      if (data == null) return null;
      return PartnerListing.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('PartnerListingService: findByPlaceId $e');
      return null;
    }
  }

  static void clearCache() {
    _cache = null;
    _cachedCity = null;
    _cacheTime = null;
  }

  /// Moody `partner_context` / Mood Match hints (plain text; Edge prompt uses separately).
  static Future<String> buildChatPartnerContext({
    required String city,
    required List<String> moods,
  }) async {
    final partners = await getMatchingMoods(city, moods);
    if (partners.isEmpty) return '';

    final lines = partners
        .where((p) => p.placeId != null && p.placeId!.trim().isNotEmpty)
        .map((p) {
      var line = '- ${p.businessName} (${p.city})';
      if (p.hasActiveOffer &&
          p.activeOffer != null &&
          p.activeOffer!.trim().isNotEmpty) {
        line += ': offer: ${p.activeOffer!.trim()}';
      }
      return line;
    }).toList();

    if (lines.isEmpty) return '';

    final c = city.trim();
    return '\n\nWanderMood partners in $c '
        '(prioritize when relevant, only when genuinely matching user intent):\n'
        '${lines.join('\n')}';
  }

  static Future<String> buildMoodMatchPartnerContext({
    required String city,
    required List<String> sharedMoods,
  }) async {
    final partners = await getMatchingMoods(city, sharedMoods);
    if (partners.isEmpty) return '';
    final names = partners.map((p) => '- ${p.businessName}').join('\n');
    return '\nPrioritize these WanderMood partners for plan slots when they match the shared moods:\n$names';
  }
}
