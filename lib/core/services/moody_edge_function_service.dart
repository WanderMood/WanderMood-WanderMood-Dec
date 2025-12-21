import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Service to call the `moody` Edge Function
class MoodyEdgeFunctionService {
  final SupabaseClient _supabase;

  MoodyEdgeFunctionService(this._supabase);

  /// Get explore places from Edge Function
  /// 
  /// Returns 60-80 places based on mood, location, and filters
  Future<List<Place>> getExplore({
    required String mood,
    required String location,
    Map<String, dynamic>? filters,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎯 Calling moody Edge Function: get_explore');
        debugPrint('   mood: $mood');
        debugPrint('   location: $location');
        debugPrint('   filters: $filters');
      }

      final response = await _supabase.functions.invoke(
        'moody',
        body: {
          'action': 'get_explore',
          'mood': mood,
          'location': location,
          'filters': filters ?? {},
        },
      );

      if (kDebugMode) {
        debugPrint('📡 Edge Function response status: ${response.status}');
      }

      if (response.status != 200) {
        final errorData = response.data;
        if (kDebugMode) {
          debugPrint('❌ Edge Function error: Status ${response.status}, Data: $errorData');
        }
        throw Exception('Edge Function returned status ${response.status}: ${errorData ?? 'Unknown error'}');
      }

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData.containsKey('error')) {
        throw Exception(responseData['error'] as String);
      }

      final cards = responseData['cards'] as List<dynamic>?;
      if (cards == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No cards in response, returning empty list');
        }
        return [];
      }

      // Transform Edge Function response to Place objects
      final places = cards.map((card) => _transformCardToPlace(card as Map<String, dynamic>)).toList();

      if (kDebugMode) {
        debugPrint('✅ Edge Function returned ${places.length} places');
        debugPrint('   cached: ${responseData['cached'] ?? false}');
        debugPrint('   total_found: ${responseData['total_found'] ?? 0}');
      }

      return places;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calling moody Edge Function: $e');
      }
      rethrow;
    }
  }

  /// Transform Edge Function card response to Place model
  Place _transformCardToPlace(Map<String, dynamic> card) {
    // Extract location
    final locationData = card['location'] as Map<String, dynamic>? ?? {};
    
    // Extract photo reference and build photo URL if available
    final photoReference = card['photo_reference'] as String?;
    final photos = photoReference != null 
        ? ['https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=${_getGooglePlacesApiKey()}']
        : <String>[];

    // Build address from vicinity or address field
    final address = card['address'] as String? ?? 
                    card['vicinity'] as String? ?? 
                    '';

    // Transform types
    final types = (card['types'] as List<dynamic>?)?.cast<String>() ?? [];

    return Place(
      id: card['id'] as String? ?? '',
      name: card['name'] as String? ?? 'Unknown Place',
      address: address,
      rating: (card['rating'] as num?)?.toDouble() ?? 0.0,
      photos: photos,
      types: types,
      location: PlaceLocation(
        lat: (locationData['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (locationData['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      description: card['description'] as String?,
      priceLevel: card['price_level'] as int?,
      isFree: card['price_level'] == null || card['price_level'] == 0,
    );
  }

  /// Get Google Places API key (for photo URLs)
  /// Note: Photos should ideally be served by Edge Function or use a proxy
  /// For now, we'll leave photos empty since API keys shouldn't be in Flutter
  String _getGooglePlacesApiKey() {
    // TODO: Update Edge Function to return full photo URLs instead of photo_reference
    // For now, return empty string - photos will be empty
    // This is acceptable since Edge Function should handle photo URLs server-side
    return '';
  }
}

