import 'package:flutter/foundation.dart';
import '../../mood/domain/models/mood.dart';
import '../../weather/domain/models/weather.dart';

/// Manages contextual information for smart recommendations
class ContextManager {
  
  /// Get current time-based context
  static TimeContext getCurrentTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday;
    final isWeekend = dayOfWeek >= 6;
    
    TimeOfDay timeOfDay;
    if (hour >= 6 && hour < 12) {
      timeOfDay = TimeOfDay.morning;
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = TimeOfDay.afternoon;
    } else if (hour >= 17 && hour < 22) {
      timeOfDay = TimeOfDay.evening;
    } else {
      timeOfDay = TimeOfDay.night;
    }
    
    return TimeContext(
      currentHour: hour,
      timeOfDay: timeOfDay,
      isWeekend: isWeekend,
      dayOfWeek: dayOfWeek,
    );
  }
  
  /// Get weather-based recommendations
  static WeatherContext getWeatherContext(Weather? weather) {
    if (weather == null) {
      return WeatherContext(
        isGoodForOutdoor: true,
        weatherType: WeatherType.unknown,
        temperature: null,
        recommendation: 'Check both indoor and outdoor options',
      );
    }
    
    final temp = weather.temperature;
    final condition = weather.condition.toLowerCase();
    
    // Determine weather type
    WeatherType weatherType;
    bool isGoodForOutdoor;
    String recommendation;
    
    if (condition.contains('rain') || condition.contains('storm')) {
      weatherType = WeatherType.rainy;
      isGoodForOutdoor = false;
      recommendation = 'Perfect weather for cozy indoor activities ☔';
    } else if (condition.contains('snow')) {
      weatherType = WeatherType.snowy;
      isGoodForOutdoor = temp > 0;
      recommendation = isGoodForOutdoor 
        ? 'Beautiful snowy day for winter activities ❄️'
        : 'Too cold - try warm indoor spots 🔥';
    } else if (condition.contains('cloud')) {
      weatherType = WeatherType.cloudy;
      isGoodForOutdoor = temp > 15;
      recommendation = 'Great day for both indoor and outdoor activities ☁️';
    } else {
      weatherType = WeatherType.sunny;
      isGoodForOutdoor = temp > 10;
      recommendation = temp > 20 
        ? 'Perfect day to be outside! ☀️'
        : 'Nice day - layer up for outdoor fun 🧥';
    }
    
    return WeatherContext(
      isGoodForOutdoor: isGoodForOutdoor,
      weatherType: weatherType,
      temperature: temp,
      recommendation: recommendation,
    );
  }
  
  /// Get mood-based context and suggestions
  static MoodContext getMoodContext(Mood? userMood) {
    if (userMood == null) {
      return MoodContext(
        energyLevel: EnergyLevel.medium,
        socialPreference: SocialPreference.flexible,
        activityType: ActivityType.mixed,
        moodDescription: 'Ready for anything',
      );
    }
    
    // Map mood to context
    EnergyLevel energyLevel;
    SocialPreference socialPreference;
    ActivityType activityType;
    String moodDescription;
    
    switch (userMood.label.toLowerCase()) {
      case 'excited':
      case 'energetic':
      case 'adventurous':
        energyLevel = EnergyLevel.high;
        socialPreference = SocialPreference.social;
        activityType = ActivityType.active;
        moodDescription = 'Ready for high-energy adventures!';
        break;
        
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        energyLevel = EnergyLevel.low;
        socialPreference = SocialPreference.solo;
        activityType = ActivityType.relaxing;
        moodDescription = 'Perfect time for peaceful moments';
        break;
        
      case 'social':
      case 'happy':
      case 'cheerful':
        energyLevel = EnergyLevel.medium;
        socialPreference = SocialPreference.social;
        activityType = ActivityType.social;
        moodDescription = 'Great vibes for social activities!';
        break;
        
      case 'curious':
      case 'thoughtful':
      case 'inspired':
        energyLevel = EnergyLevel.medium;
        socialPreference = SocialPreference.flexible;
        activityType = ActivityType.cultural;
        moodDescription = 'Perfect for discovering new things';
        break;
        
      default:
        energyLevel = EnergyLevel.medium;
        socialPreference = SocialPreference.flexible;
        activityType = ActivityType.mixed;
        moodDescription = 'Open to various experiences';
    }
    
    return MoodContext(
      energyLevel: energyLevel,
      socialPreference: socialPreference,
      activityType: activityType,
      moodDescription: moodDescription,
    );
  }
  
  /// Combine all contexts into comprehensive recommendations
  static SmartContext createSmartContext({
    Mood? userMood,
    Weather? weather,
    String? userLocation,
  }) {
    final timeContext = getCurrentTimeContext();
    final weatherContext = getWeatherContext(weather);
    final moodContext = getMoodContext(userMood);
    
    // Generate contextual recommendations
    final recommendations = _generateContextualRecommendations(
      timeContext,
      weatherContext,
      moodContext,
    );
    
    return SmartContext(
      timeContext: timeContext,
      weatherContext: weatherContext,
      moodContext: moodContext,
      recommendations: recommendations,
      userLocation: userLocation,
    );
  }
  
  static List<String> _generateContextualRecommendations(
    TimeContext timeContext,
    WeatherContext weatherContext,
    MoodContext moodContext,
  ) {
    final recommendations = <String>[];
    
    // Time-based recommendations
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        if (timeContext.isWeekend) {
          recommendations.add('Weekend brunch spots');
          recommendations.add('Morning market visits');
        } else {
          recommendations.add('Quick coffee stops');
          recommendations.add('Energizing morning walks');
        }
        break;
        
      case TimeOfDay.afternoon:
        recommendations.add('Perfect lunch timing');
        recommendations.add('Museum and gallery visits');
        if (weatherContext.isGoodForOutdoor) {
          recommendations.add('Outdoor activities');
        }
        break;
        
      case TimeOfDay.evening:
        recommendations.add('Dinner reservations');
        recommendations.add('Evening entertainment');
        if (timeContext.isWeekend) {
          recommendations.add('Nightlife options');
        }
        break;
        
      case TimeOfDay.night:
        recommendations.add('Late-night eateries');
        recommendations.add('Night entertainment');
        break;
    }
    
    // Weather-based recommendations
    if (!weatherContext.isGoodForOutdoor) {
      recommendations.add('Indoor alternatives');
      recommendations.add('Cozy indoor spaces');
    } else {
      recommendations.add('Make the most of good weather');
    }
    
    // Mood-based recommendations
    switch (moodContext.energyLevel) {
      case EnergyLevel.high:
        recommendations.add('High-energy activities');
        recommendations.add('Adventure experiences');
        break;
      case EnergyLevel.low:
        recommendations.add('Relaxing environments');
        recommendations.add('Peaceful spots');
        break;
      case EnergyLevel.medium:
        recommendations.add('Flexible activity options');
        break;
    }
    
    return recommendations.take(5).toList(); // Limit to top 5
  }
}

// Data classes for context information

class TimeContext {
  final int currentHour;
  final TimeOfDay timeOfDay;
  final bool isWeekend;
  final int dayOfWeek;
  
  TimeContext({
    required this.currentHour,
    required this.timeOfDay,
    required this.isWeekend,
    required this.dayOfWeek,
  });
}

enum TimeOfDay { morning, afternoon, evening, night }

class WeatherContext {
  final bool isGoodForOutdoor;
  final WeatherType weatherType;
  final double? temperature;
  final String recommendation;
  
  WeatherContext({
    required this.isGoodForOutdoor,
    required this.weatherType,
    required this.temperature,
    required this.recommendation,
  });
}

enum WeatherType { sunny, cloudy, rainy, snowy, unknown }

class MoodContext {
  final EnergyLevel energyLevel;
  final SocialPreference socialPreference;
  final ActivityType activityType;
  final String moodDescription;
  
  MoodContext({
    required this.energyLevel,
    required this.socialPreference,
    required this.activityType,
    required this.moodDescription,
  });
}

enum EnergyLevel { low, medium, high }
enum SocialPreference { solo, flexible, social }
enum ActivityType { relaxing, cultural, social, active, mixed }

class SmartContext {
  final TimeContext timeContext;
  final WeatherContext weatherContext;
  final MoodContext moodContext;
  final List<String> recommendations;
  final String? userLocation;
  
  SmartContext({
    required this.timeContext,
    required this.weatherContext,
    required this.moodContext,
    required this.recommendations,
    this.userLocation,
  });
  
  /// Get a summary of current context for UI display
  String getContextSummary() {
    final time = _getTimeDescription();
    final weather = weatherContext.recommendation;
    final mood = moodContext.moodDescription;
    
    return '$time $weather $mood';
  }
  
  String _getTimeDescription() {
    switch (timeContext.timeOfDay) {
      case TimeOfDay.morning:
        return timeContext.isWeekend ? 'Relaxed weekend morning.' : 'Productive morning.';
      case TimeOfDay.afternoon:
        return 'Perfect afternoon timing.';
      case TimeOfDay.evening:
        return timeContext.isWeekend ? 'Fun weekend evening!' : 'Lovely evening ahead.';
      case TimeOfDay.night:
        return 'Late night vibes.';
    }
  }
} 