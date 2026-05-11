import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fire-and-forget analytics for [business_listings] via
/// `track_business_interaction` (views, taps, offer redemptions, check-ins).
///
/// Call sites should use [unawaited] — never block UI or navigation.
class BusinessListingTracker {
  BusinessListingTracker._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Avoid repeated lookups for the same place in one app session.
  static final Map<String, String?> _listingIdCache = <String, String?>{};

  static String _cacheKey(String raw) {
    var t = raw.trim();
    if (t.startsWith('google_')) t = t.substring(7);
    return t;
  }

  /// Resolve [googlePlaceId] to a partner listing UUID, or null.
  static Future<String?> findListingId(String googlePlaceId) async {
    final key = _cacheKey(googlePlaceId);
    if (key.isEmpty) return null;
    if (_listingIdCache.containsKey(key)) {
      return _listingIdCache[key];
    }
    try {
      final result = await _supabase
          .from('business_listings')
          .select('id')
          .eq('place_id', key)
          .inFilter(
              'subscription_status', ['active', 'trialing']).maybeSingle();

      final id = result?['id'] as String?;
      _listingIdCache[key] = id;
      return id;
    } catch (e) {
      debugPrint('BusinessListingTracker: lookup error $e');
      return null;
    }
  }

  /// Place appeared in Explore feed (first visible slice — see Explore screen).
  static Future<void> trackView(String googlePlaceId) async {
    await _track(googlePlaceId, 'view');
  }

  /// User opened place detail (quick sheet or full [PlaceDetailScreen]).
  static Future<void> trackTap(String googlePlaceId) async {
    await _track(googlePlaceId, 'tap');
  }

  static Future<void> trackOfferRedemption(String googlePlaceId) async {
    await _track(googlePlaceId, 'offer_redemption');
  }

  static Future<void> trackCheckin(String googlePlaceId) async {
    await _track(googlePlaceId, 'checkin');
  }

  static Future<void> _track(String googlePlaceId, String type) async {
    try {
      final listingId = await findListingId(googlePlaceId);
      if (listingId == null) return;

      await _supabase.rpc(
        'track_business_interaction',
        params: <String, dynamic>{
          'p_listing_id': listingId,
          'p_interaction_type': type,
        },
      );

      debugPrint('BusinessListingTracker: tracked $type for $googlePlaceId');
    } catch (e) {
      debugPrint('BusinessListingTracker: error tracking $type: $e');
    }
  }
}
