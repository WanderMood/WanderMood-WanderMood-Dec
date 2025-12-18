import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'check_in_service.dart';
import '../models/check_in.dart';

final moodyHubContentServiceProvider = Provider<MoodyHubContentService>((ref) {
  final checkInService = ref.read(checkInServiceProvider);
  return MoodyHubContentService(checkInService);
});

enum ContentPillar {
  tripIdea,
  eventFestival,
  softReflection,
  packingPrep,
  socialNudge,
}

class MomentCard {
  final String intro;
  final String title;
  final String? subtitle;
  final ContentPillar pillar;
  final String emoji;

  MomentCard({
    required this.intro,
    required this.title,
    this.subtitle,
    required this.pillar,
    required this.emoji,
  });
}

class MoodyHubContentService {
  final CheckInService _checkInService;
  static const String _visitCountKey = 'moody_hub_visit_count';
  static const String _lastVisitDateKey = 'moody_hub_last_visit_date';

  MoodyHubContentService(this._checkInService);

  /// Get the current visit count
  Future<int> getVisitCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_visitCountKey) ?? 0;
  }

  /// Increment visit count (call this when hub opens)
  Future<void> incrementVisitCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastVisit = prefs.getString(_lastVisitDateKey);
    
    // Only increment once per day
    if (lastVisit != today) {
      final currentCount = await getVisitCount();
      await prefs.setInt(_visitCountKey, currentCount + 1);
      await prefs.setString(_lastVisitDateKey, today);
    }
  }

  /// Select which content pillar to show based on mood, time, and visit count
  Future<ContentPillar> selectContentPillar({
    required String mood,
    required int hour,
  }) async {
    final visitCount = await getVisitCount();
    final checkIns = await _checkInService.getRecentCheckIns(limit: 5);
    
    // Rotate through pillars based on visit count
    final rotationIndex = visitCount % 5;
    
    // Time-based adjustments
    if (hour >= 20 || hour < 6) {
      // Evening/night: Favor reflection and social
      return rotationIndex.isEven ? ContentPillar.softReflection : ContentPillar.socialNudge;
    }
    
    if (hour >= 6 && hour < 12) {
      // Morning: Favor trip ideas and events
      return rotationIndex.isEven ? ContentPillar.tripIdea : ContentPillar.eventFestival;
    }
    
    // Default rotation through all pillars
    switch (rotationIndex) {
      case 0:
        return ContentPillar.tripIdea;
      case 1:
        return ContentPillar.eventFestival;
      case 2:
        return ContentPillar.softReflection;
      case 3:
        return ContentPillar.packingPrep;
      case 4:
        return ContentPillar.socialNudge;
      default:
        return ContentPillar.tripIdea;
    }
  }

  /// Generate a moment card based on mood, pillar, and context
  Future<MomentCard> generateMomentCard({
    required String mood,
    required int hour,
    String? location,
  }) async {
    final pillar = await selectContentPillar(mood: mood, hour: hour);
    final checkIns = await _checkInService.getRecentCheckIns(limit: 3);
    final visitCount = await getVisitCount();
    
    // Get previous check-in context
    final lastCheckIn = checkIns.isNotEmpty ? checkIns.first : null;
    final hasRecentActivity = lastCheckIn != null && 
        DateTime.now().difference(lastCheckIn.timestamp).inHours < 24;
    
    switch (pillar) {
      case ContentPillar.tripIdea:
        return _generateTripIdeaMoment(mood, location, visitCount);
        
      case ContentPillar.eventFestival:
        return _generateEventMoment(mood, location, hour);
        
      case ContentPillar.softReflection:
        return _generateReflectionMoment(mood, lastCheckIn, hour);
        
      case ContentPillar.packingPrep:
        return _generatePackingMoment(mood, hour);
        
      case ContentPillar.socialNudge:
        return _generateSocialMoment(mood, lastCheckIn);
    }
  }

  MomentCard _generateTripIdeaMoment(String mood, String? location, int visitCount) {
    final intros = [
      "I wouldn't normally suggest this but...",
      "Random thought...",
      "I saved this for a day like today.",
      "You know what fits your vibe?",
      "This popped into my head...",
    ];
    
    final moodToTitle = {
      'adventurous': 'this hidden gem is calling you 🗺️',
      'exploring': 'this city fits you perfectly 🏙️',
      'cultural': 'this museum + you = magic ✨',
      'chill': 'this quiet spot is perfect for you 🍃',
      'social': 'this market has your energy 🎉',
      'romantic': 'this sunset view is everything 🌅',
      'foodie': 'this local spot is a must-try 🍜',
      'active': 'this trail is waiting for you 🥾',
    };
    
    final intro = intros[visitCount % intros.length];
    final title = moodToTitle[mood.toLowerCase()] ?? 'this place fits your vibe today';
    
    return MomentCard(
      intro: intro,
      title: title,
      subtitle: location != null ? 'Perfect for $location explorers' : null,
      pillar: ContentPillar.tripIdea,
      emoji: '🎒',
    );
  }

  MomentCard _generateEventMoment(String mood, String? location, int hour) {
    final intros = [
      "Something's happening...",
      "I just found out about this...",
      "You're gonna want to see this...",
      "Happening right now:",
    ];
    
    final timeBasedTitles = {
      'morning': "morning market vibes you'd love 🌅",
      'afternoon': 'afternoon event that fits you ☀️',
      'evening': "tonight's scene is your vibe ✨",
      'night': 'late-night energy you need to see 🌙',
    };
    
    String timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }
    
    return MomentCard(
      intro: intros[Random().nextInt(intros.length)],
      title: timeBasedTitles[timeOfDay]!,
      pillar: ContentPillar.eventFestival,
      emoji: '🎉',
    );
  }

  MomentCard _generateReflectionMoment(String mood, CheckIn? lastCheckIn, int hour) {
    if (lastCheckIn != null && lastCheckIn.activities.isNotEmpty) {
      return MomentCard(
        intro: "Thinking about your day...",
        title: "who would you bring here next time? 🫂",
        subtitle: "Your vibe attracts your tribe",
        pillar: ContentPillar.softReflection,
        emoji: '🧠',
      );
    }
    
    if (hour >= 20) {
      return MomentCard(
        intro: "Before you call it a day...",
        title: "what made you smile today? 😌",
        subtitle: "Small moments matter",
        pillar: ContentPillar.softReflection,
        emoji: '✨',
      );
    }
    
    return MomentCard(
      intro: "Quick thought...",
      title: "what's one thing you want to do today? 💭",
      subtitle: "Make it happen",
      pillar: ContentPillar.softReflection,
      emoji: '🧠',
    );
  }

  MomentCard _generatePackingMoment(String mood, int hour) {
    if (hour >= 5 && hour < 10) {
      return MomentCard(
        intro: "Before you head out...",
        title: "got everything you need? 🎒",
        subtitle: "Water, snacks, good vibes",
        pillar: ContentPillar.packingPrep,
        emoji: '🧳',
      );
    }
    
    return MomentCard(
      intro: "Pro tip for tomorrow...",
      title: "plan ahead, stress less 📋",
      subtitle: "Future you will thank you",
      pillar: ContentPillar.packingPrep,
      emoji: '🧳',
    );
  }

  MomentCard _generateSocialMoment(String mood, CheckIn? lastCheckIn) {
    final intros = [
      "Random question...",
      "I'm curious...",
      "Just wondering...",
    ];
    
    if (lastCheckIn != null && lastCheckIn.mood == 'social') {
      return MomentCard(
        intro: intros[Random().nextInt(intros.length)],
        title: "who's your adventure buddy today? 👯",
        subtitle: "Tag them and make it happen",
        pillar: ContentPillar.socialNudge,
        emoji: '🫂',
      );
    }
    
    return MomentCard(
      intro: intros[Random().nextInt(intros.length)],
      title: "solo or with someone special? 💚",
      subtitle: "Both are perfect",
      pillar: ContentPillar.socialNudge,
      emoji: '🫂',
    );
  }

  /// Determine if "Your Day's Flow" should be shown
  Future<bool> shouldShowDayFlow({required bool hasActivities}) async {
    if (!hasActivities) return false;
    
    final visitCount = await getVisitCount();
    // Show on 2 out of 3 visits
    return visitCount % 3 != 2;
  }

  /// Generate interpretive commentary for Day's Flow
  String generateDayFlowCommentary({
    required int morningCount,
    required int afternoonCount,
    required int eveningCount,
    required String mood,
    required int hour,
  }) {
    final total = morningCount + afternoonCount + eveningCount;
    
    if (total == 0) {
      return "Your day is wide open... want a suggestion? ✨";
    }
    
    // Morning packed
    if (morningCount >= 3 && afternoonCount <= 1) {
      return "Your morning is packed — maybe slow down this afternoon? 😌";
    }
    
    // Afternoon gap
    if (morningCount > 0 && afternoonCount == 0 && eveningCount > 0) {
      return "You've got space here... perfect for something spontaneous 🎯";
    }
    
    // Evening empty
    if (hour < 17 && eveningCount == 0) {
      return "This evening looks perfect for ${_getMoodActivity(mood)} ✨";
    }
    
    // Balanced day
    if (morningCount > 0 && afternoonCount > 0 && eveningCount > 0) {
      return "Your day is flowing beautifully 🌊";
    }
    
    return "Looking good! You've got ${total} ${total == 1 ? 'activity' : 'activities'} planned 💚";
  }

  String _getMoodActivity(String mood) {
    final activities = {
      'adventurous': 'exploration',
      'exploring': 'discovering something new',
      'cultural': 'a museum visit',
      'chill': 'relaxing',
      'social': 'meeting friends',
      'romantic': 'a sunset walk',
      'foodie': 'trying new flavors',
      'active': 'getting moving',
    };
    
    return activities[mood.toLowerCase()] ?? 'something you love';
  }
}

