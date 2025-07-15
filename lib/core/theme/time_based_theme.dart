import 'package:flutter/material.dart';

/// Configuration for time-based theming throughout the app
class TimeBasedTheme {
  static TimeOfDayConfig getConfigForHour(int hour) {
    if (hour >= 5 && hour < 8) {
      return TimeOfDayConfig.earlyMorning;
    } else if (hour >= 8 && hour < 11) {
      return TimeOfDayConfig.lateMorning;
    } else if (hour >= 11 && hour < 14) {
      return TimeOfDayConfig.noon;
    } else if (hour >= 14 && hour < 17) {
      return TimeOfDayConfig.afternoon;
    } else if (hour >= 17 && hour < 20) {
      return TimeOfDayConfig.earlyEvening;
    } else if (hour >= 20 && hour < 23) {
      return TimeOfDayConfig.night;
    } else {
      return TimeOfDayConfig.lateNight;
    }
  }
}

class TimeOfDayConfig {
  final String name;
  final String emoji;
  final IconData icon;
  final List<Color> gradientColors;
  final String defaultSuggestion;
  final List<String> activityTypes;

  const TimeOfDayConfig({
    required this.name,
    required this.emoji,
    required this.icon,
    required this.gradientColors,
    required this.defaultSuggestion,
    required this.activityTypes,
  });

  // Early Morning (5-8 AM)
  static TimeOfDayConfig get earlyMorning => TimeOfDayConfig(
    name: 'Early Morning',
    emoji: '🌅',
    icon: Icons.wb_twilight,
    gradientColors: [
      const Color(0xFFFFA07A), // Light Salmon
      const Color(0xFFFFDAB9), // Peach
      const Color(0xFFFFDAB9).withOpacity(0.8),
    ],
    defaultSuggestion: 'Start your day with energizing activities',
    activityTypes: ['workout', 'meditation', 'breakfast', 'jogging'],
  );

  // Late Morning (8-11 AM)
  static TimeOfDayConfig get lateMorning => TimeOfDayConfig(
    name: 'Morning',
    emoji: '☀️',
    icon: Icons.wb_sunny,
    gradientColors: [
      const Color(0xFFFF9A9E),
      const Color(0xFFFECFEF),
      const Color(0xFFFECFEF).withOpacity(0.8),
    ],
    defaultSuggestion: 'Perfect time for productive activities',
    activityTypes: ['sightseeing', 'shopping', 'museums', 'cafes'],
  );

  // Noon (11 AM-2 PM)
  static TimeOfDayConfig get noon => TimeOfDayConfig(
    name: 'Noon',
    emoji: '🌞',
    icon: Icons.wb_sunny_outlined,
    gradientColors: [
      const Color(0xFFFFE259),
      const Color(0xFFFFA751),
      const Color(0xFFFFA751).withOpacity(0.8),
    ],
    defaultSuggestion: 'Take a break and enjoy lunch',
    activityTypes: ['lunch', 'parks', 'markets', 'galleries'],
  );

  // Afternoon (2-5 PM)
  static TimeOfDayConfig get afternoon => TimeOfDayConfig(
    name: 'Afternoon',
    emoji: '🌤',
    icon: Icons.wb_cloudy,
    gradientColors: [
      const Color(0xFF4facfe),
      const Color(0xFF00f2fe),
      const Color(0xFF00f2fe).withOpacity(0.8),
    ],
    defaultSuggestion: 'Perfect time for outdoor adventures',
    activityTypes: ['attractions', 'sports', 'beaches', 'tours'],
  );

  // Early Evening (5-8 PM)
  static TimeOfDayConfig get earlyEvening => TimeOfDayConfig(
    name: 'Evening',
    emoji: '🌆',
    icon: Icons.nights_stay_outlined,
    gradientColors: [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      const Color(0xFF764ba2).withOpacity(0.8),
    ],
    defaultSuggestion: 'Wind down with something special',
    activityTypes: ['dinner', 'sunset_spots', 'entertainment', 'cultural_events'],
  );

  // Night (8-11 PM)
  static TimeOfDayConfig get night => TimeOfDayConfig(
    name: 'Night',
    emoji: '🌙',
    icon: Icons.nights_stay,
    gradientColors: [
      const Color(0xFF2C3E50),
      const Color(0xFF3498DB),
      const Color(0xFF3498DB).withOpacity(0.8),
    ],
    defaultSuggestion: 'Enjoy the nightlife and entertainment',
    activityTypes: ['bars', 'shows', 'nightlife', 'events'],
  );

  // Late Night (11 PM-5 AM)
  static TimeOfDayConfig get lateNight => TimeOfDayConfig(
    name: 'Late Night',
    emoji: '🌃',
    icon: Icons.bedtime,
    gradientColors: [
      const Color(0xFF0F2027),
      const Color(0xFF203A43),
      const Color(0xFF203A43).withOpacity(0.8),
    ],
    defaultSuggestion: 'Discover late-night hidden gems',
    activityTypes: ['late_dining', 'clubs', '24h_venues', 'stargazing'],
  );
} 