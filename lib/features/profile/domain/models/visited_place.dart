import 'package:flutter/material.dart';

class VisitedPlace {
  final String id;
  final String userId;
  final String placeName;
  final String? city;
  final String? country;
  final double lat;
  final double lng;
  final String? mood;
  final String? moodEmoji;
  final double? energyLevel;
  final String? notes;
  final DateTime? visitedAt;

  const VisitedPlace({
    required this.id,
    required this.userId,
    required this.placeName,
    this.city,
    this.country,
    required this.lat,
    required this.lng,
    this.mood,
    this.moodEmoji,
    this.energyLevel,
    this.notes,
    this.visitedAt,
  });

  factory VisitedPlace.fromJson(Map<String, dynamic> json) {
    return VisitedPlace(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeName: json['place_name'] as String,
      city: json['city'] as String?,
      country: json['country'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      mood: json['mood'] as String?,
      moodEmoji: json['mood_emoji'] as String?,
      energyLevel: json['energy_level'] != null
          ? (json['energy_level'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      visitedAt: json['visited_at'] != null
          ? DateTime.parse(json['visited_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'place_name': placeName,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        'lat': lat,
        'lng': lng,
        if (mood != null) 'mood': mood,
        if (moodEmoji != null) 'mood_emoji': moodEmoji,
        if (energyLevel != null) 'energy_level': energyLevel,
        if (notes != null) 'notes': notes,
        if (visitedAt != null) 'visited_at': visitedAt!.toIso8601String(),
      };

  /// Serialised for the JS globe — only the fields the globe needs.
  Map<String, dynamic> toGlobeMap() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'place_name': placeName,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (mood != null) 'mood': mood,
        if (moodEmoji != null) 'mood_emoji': moodEmoji,
        if (energyLevel != null) 'energy_level': energyLevel,
        if (notes != null) 'notes': notes,
        if (visitedAt != null) 'visited_at': visitedAt!.toIso8601String(),
      };

  /// Returns the mood accent colour used on the globe marker.
  Color get moodColor {
    switch ((mood ?? '').toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFD600); // Yellow
      case 'adventurous':
        return const Color(0xFFFF5252); // Red/Pink
      case 'relaxed':
        return const Color(0xFF4DD0E1); // Teal
      case 'energetic':
        return const Color(0xFF29B6F6); // Blue
      case 'romantic':
        return const Color(0xFFFF4081); // Pink
      case 'social':
        return const Color(0xFFFFD54F); // Light Yellow
      case 'cultural':
        return const Color(0xFF7E57C2); // Purple
      case 'curious':
        return const Color(0xFFFF7043); // Orange/Salmon
      case 'cozy':
        return const Color(0xFFEF5350); // Red
      case 'excited':
        return const Color(0xFF26A69A); // Green/Teal
      case 'foody':
        return const Color(0xFFFF8A65); // Orange
      case 'surprise':
        return const Color(0xFFFFCA28); // Amber
      // Fallbacks
      case 'joyful':
        return const Color(0xFFFFD600);
      case 'calm':
      case 'peaceful':
        return const Color(0xFF4DD0E1);
      case 'sad':
        return const Color(0xFF42A5F5);
      case 'anxious':
      case 'stressed':
        return const Color(0xFFAB47BC);
      case 'love':
        return const Color(0xFFFF4081);
      case 'nostalgic':
        return const Color(0xFFFF7043);
      // Check-in moods (from Moody Hub)
      case 'great':
        return const Color(0xFFFFD600);
      case 'tired':
        return const Color(0xFF7B68EE);
      case 'amazing':
        return const Color(0xFFFF6B9D);
      case 'okay':
        return const Color(0xFF94A3B8);
      case 'thoughtful':
        return const Color(0xFF6366F1);
      case 'chill':
        return const Color(0xFF12B347);
      default:
        return Colors.white;
    }
  }
}
