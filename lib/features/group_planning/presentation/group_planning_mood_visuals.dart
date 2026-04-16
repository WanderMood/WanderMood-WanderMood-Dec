import 'package:flutter/material.dart';

/// Chip tint backgrounds (aligned with product spec + group mood tags).
Color groupPlanMoodChipTint(String tag) {
  switch (tag.toLowerCase()) {
    case 'relaxed':
      return const Color(0xFFD6EAF3); // #A8C8DC tint
    case 'foody':
      return const Color(0xFFFFE4D6); // #E8784A tint
    case 'energetic':
      return const Color(0xFFFFF0D0); // #F4B942 tint
    case 'adventurous':
      return const Color(0xFFD6EDD6); // #7CB87A tint
    case 'cultural':
      return const Color(0xFFE8E4F5); // #9B8EC4 tint
    case 'creative':
      return const Color(0xFFF5E0D4); // Cozy tint per spec
    case 'cozy':
      return const Color(0xFFE8D4C8);
    case 'surprise':
      return const Color(0xFFD8E4ED);
    case 'romantic':
      return const Color(0xFFFFE4EB); // #E88FA0 tint
    case 'social':
      return const Color(0xFFD4F5EA); // #5DCAA5 tint
    default:
      return const Color(0xFFEBF3EE);
  }
}

String groupPlanMoodEmoji(String tag) {
  switch (tag.toLowerCase()) {
    case 'adventurous':
      return '🧭';
    case 'relaxed':
      return '😌';
    case 'social':
      return '👥';
    case 'cultural':
      return '🎭';
    case 'romantic':
      return '💕';
    case 'energetic':
      return '⚡';
    case 'foody':
      return '🍴';
    case 'creative':
      return '✨';
    case 'cozy':
      return '☕';
    case 'surprise':
      return '😲';
    default:
      return '✨';
  }
}

/// Small square / emoji block for result list rows.
Color groupPlanPlaceTypeTint(String type) {
  switch (type.toLowerCase()) {
    case 'restaurant':
    case 'food':
    case 'cafe':
      return const Color(0xFFFFE4D6);
    case 'museum':
    case 'culture':
      return const Color(0xFFE8E4F5);
    case 'park':
    case 'nature':
    case 'outdoor':
      return const Color(0xFFD6EDD6);
    case 'nightlife':
    case 'bar':
      return const Color(0xFFE4D4F8);
    default:
      return const Color(0xFFD6EAF3);
  }
}

String groupPlanPlaceTypeEmoji(String type) {
  switch (type.toLowerCase()) {
    case 'restaurant':
    case 'food':
    case 'cafe':
      return '🍽️';
    case 'museum':
    case 'culture':
      return '🏛️';
    case 'park':
    case 'nature':
    case 'outdoor':
      return '🌿';
    case 'nightlife':
    case 'bar':
      return '🌙';
    default:
      return '📍';
  }
}
