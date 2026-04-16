import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class PlacesService {
  final String apiKey = ApiConstants.placesApiKey;
  final String baseUrl = ApiConstants.placesBaseUrl;

  Future<List<Map<String, dynamic>>> searchPlacesByMood({
    required String mood,
    required double lat,
    required double lng,
    int radius = 5000, // 5km radius
  }) async {
    final placeTypes = ApiConstants.moodPlaceTypes[mood.toLowerCase()] ?? [];
    List<Map<String, dynamic>> allPlaces = [];

    for (final type in placeTypes) {
      final url = Uri.parse('$baseUrl${ApiConstants.nearbySearch}'
          '?location=$lat,$lng'
          '&radius=$radius'
          '&type=$type'
          '&key=$apiKey');

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final places = List<Map<String, dynamic>>.from(data['results']);
            allPlaces.addAll(places);
          }
        }
      } catch (e) {
        print('Error fetching places for type $type: $e');
      }
    }

    // Remove duplicates based on place_id
    final uniquePlaces = allPlaces.fold<Map<String, Map<String, dynamic>>>(
      {},
      (map, place) {
        final placeId = place['place_id'] as String;
        if (!map.containsKey(placeId)) {
          map[placeId] = place;
        }
        return map;
      },
    );

    return uniquePlaces.values.toList();
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse('$baseUrl${ApiConstants.placeDetails}'
        '?place_id=$placeId'
        '&fields=name,rating,formatted_phone_number,formatted_address,opening_hours,website,price_level,reviews,photos'
        '&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching place details: $e');
      return {};
    }
  }

  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$baseUrl${ApiConstants.placePhotos}'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$apiKey';
  }
} 