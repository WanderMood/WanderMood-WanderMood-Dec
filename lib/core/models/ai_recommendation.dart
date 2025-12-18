class AIRecommendationResponse {
  final bool success;
  final String action;
  final String timestamp;
  final List<AIRecommendation> recommendations;
  final String summary;
  final int availablePlaces;

  AIRecommendationResponse({
    required this.success,
    required this.action,
    required this.timestamp,
    required this.recommendations,
    required this.summary,
    required this.availablePlaces,
  });

  factory AIRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return AIRecommendationResponse(
      success: json['success'] ?? false,
      action: json['action'] ?? '',
      timestamp: json['timestamp'] ?? '',
      summary: json['summary'] ?? '',
      availablePlaces: json['availablePlaces'] ?? 0,
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((item) => AIRecommendation.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'action': action,
      'timestamp': timestamp,
      'summary': summary,
      'availablePlaces': availablePlaces,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
    };
  }
}

class AIRecommendation {
  final String name;
  final String type;
  final double rating;
  final String description;
  final String duration;
  final String cost;
  final String moodMatch;
  final String timeSlot;
  final String? imageUrl;
  final Map<String, dynamic>? location;

  AIRecommendation({
    required this.name,
    required this.type,
    required this.rating,
    required this.description,
    required this.duration,
    required this.cost,
    required this.moodMatch,
    required this.timeSlot,
    this.imageUrl,
    this.location,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      cost: json['cost'] ?? '',
      moodMatch: json['moodMatch'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      imageUrl: json['imageUrl'],
      location: json['location'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'rating': rating,
      'description': description,
      'duration': duration,
      'cost': cost,
      'moodMatch': moodMatch,
      'timeSlot': timeSlot,
      'imageUrl': imageUrl,
      'location': location,
    };
  }
}

class AIChatResponse {
  final bool success;
  final String action;
  final String timestamp;
  final String message;
  final String? conversationId;
  final Map<String, dynamic> contextUsed;

  AIChatResponse({
    required this.success,
    required this.action,
    required this.timestamp,
    required this.message,
    this.conversationId,
    required this.contextUsed,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) {
    return AIChatResponse(
      success: json['success'] ?? false,
      action: json['action'] ?? '',
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '',
      conversationId: json['conversationId'],
      contextUsed: json['contextUsed'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'action': action,
      'timestamp': timestamp,
      'message': message,
      'conversationId': conversationId,
      'contextUsed': contextUsed,
    };
  }
}

class AIPlanResponse {
  final bool success;
  final String action;
  final String timestamp;
  final String message;
  final List<AIPlannedActivity>? activities;

  AIPlanResponse({
    required this.success,
    required this.action,
    required this.timestamp,
    required this.message,
    this.activities,
  });

  factory AIPlanResponse.fromJson(Map<String, dynamic> json) {
    return AIPlanResponse(
      success: json['success'] ?? false,
      action: json['action'] ?? '',
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '',
      activities: (json['activities'] as List<dynamic>?)
          ?.map((item) => AIPlannedActivity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AIPlannedActivity {
  final String name;
  final String time;
  final String duration;
  final String description;
  final String location;
  final String type;

  AIPlannedActivity({
    required this.name,
    required this.time,
    required this.duration,
    required this.description,
    required this.location,
    required this.type,
  });

  factory AIPlannedActivity.fromJson(Map<String, dynamic> json) {
    return AIPlannedActivity(
      name: json['name'] ?? '',
      time: json['time'] ?? '',
      duration: json['duration'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class AIOptimizationResponse {
  final bool success;
  final String action;
  final String timestamp;
  final String message;
  final List<Map<String, dynamic>>? optimizedItinerary;
  final List<String>? changes;

  AIOptimizationResponse({
    required this.success,
    required this.action,
    required this.timestamp,
    required this.message,
    this.optimizedItinerary,
    this.changes,
  });

  factory AIOptimizationResponse.fromJson(Map<String, dynamic> json) {
    return AIOptimizationResponse(
      success: json['success'] ?? false,
      action: json['action'] ?? '',
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '',
      optimizedItinerary: (json['optimizedItinerary'] as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList(),
      changes: (json['changes'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
    );
  }
} 