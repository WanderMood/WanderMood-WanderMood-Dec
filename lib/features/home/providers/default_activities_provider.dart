import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for default activities based on time of day
final defaultActivitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Use hardcoded default activities instead of trying to fetch from API
  final hour = MoodyClock.now().hour;
  
  // Create default activities based on time of day
  final List<Map<String, dynamic>> defaultActivities = [];
  
  // Morning activities (6 AM - 12 PM)
  if (hour >= 6 && hour < 12) {
    defaultActivities.addAll([
      {
        'id': 'morning-cafe-1',
        'title': 'Morning Coffee at Cafe Rotterdam',
        'description': 'Start your day with a delicious cup of coffee and breakfast',
        'category': 'food',
        'timeOfDay': 'morning',
        'duration': 60,
        'mood': 'relaxed',
        'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
        'isRecommended': true,
      },
      {
        'id': 'morning-park-1',
        'title': 'Morning Walk in Kralingse Bos',
        'description': 'Enjoy a refreshing morning walk in this beautiful park',
        'category': 'exercise',
        'timeOfDay': 'morning',
        'duration': 90,
        'mood': 'energetic',
        'imageUrl': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80',
        'isRecommended': true,
      },
    ]);
  } 
  // Afternoon activities (12 PM - 5 PM)
  else if (hour >= 12 && hour < 17) {
    defaultActivities.addAll([
      {
        'id': 'afternoon-museum-1',
        'title': 'Visit Kunsthal Rotterdam',
        'description': 'Explore contemporary art and exhibitions',
        'category': 'culture',
        'timeOfDay': 'afternoon',
        'duration': 120,
        'mood': 'curious',
        'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
        'isRecommended': true,
      },
      {
        'id': 'afternoon-market-1',
        'title': 'Markthal Rotterdam',
        'description': 'Explore the iconic food market with local and international cuisine',
        'category': 'food',
        'timeOfDay': 'afternoon',
        'duration': 90,
        'mood': 'social',
        'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
        'isRecommended': true,
      },
    ]);
  } 
  // Evening activities (5 PM - 12 AM)
  else {
    defaultActivities.addAll([
      {
        'id': 'evening-restaurant-1',
        'title': 'Dinner at Restaurant Rotonde',
        'description': 'Enjoy a delicious dinner with a view of the water',
        'category': 'food',
        'timeOfDay': 'evening',
        'duration': 120,
        'mood': 'relaxed',
        'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
        'isRecommended': true,
      },
      {
        'id': 'evening-bar-1',
        'title': 'Drinks at Witte de Withstraat',
        'description': 'Experience Rotterdam\'s vibrant nightlife',
        'category': 'entertainment',
        'timeOfDay': 'evening',
        'duration': 180,
        'mood': 'social',
        'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&q=80',
        'isRecommended': true,
      },
    ]);
  }
  
  return defaultActivities;

}); 