class CheckIn {
  final String id;
  final String userId;
  final String? mood;
  final List<String> activities;
  final List<String> reactions;
  final String? text;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // For storing things like "bought new clothes"

  CheckIn({
    required this.id,
    required this.userId,
    this.mood,
    required this.activities,
    required this.reactions,
    this.text,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mood': mood,
      'activities': activities,
      'reactions': reactions,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata ?? {},
    };
  }

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mood: json['mood'] as String?,
      activities: List<String>.from(json['activities'] ?? []),
      reactions: List<String>.from(json['reactions'] ?? []),
      text: json['text'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Extract key information from text for memory
  Map<String, dynamic> extractKeyInfo() {
    final info = <String, dynamic>{};
    final lowerText = (text ?? '').toLowerCase();
    
    // Check for common things users mention
    if (lowerText.contains('bought') || lowerText.contains('purchased') || lowerText.contains('got new')) {
      if (lowerText.contains('clothes') || lowerText.contains('outfit') || lowerText.contains('shirt') || lowerText.contains('dress')) {
        info['bought_clothes'] = true;
      }
    }
    if (lowerText.contains('tried') || lowerText.contains('wore') || lowerText.contains('wearing')) {
      if (lowerText.contains('clothes') || lowerText.contains('outfit')) {
        info['tried_clothes'] = true;
      }
    }
    if (lowerText.contains('slept') || lowerText.contains('sleep')) {
      info['mentioned_sleep'] = true;
    }
    if (lowerText.contains('work') || lowerText.contains('job') || lowerText.contains('office')) {
      info['mentioned_work'] = true;
    }
    if (lowerText.contains('friend') || lowerText.contains('friends') || lowerText.contains('met')) {
      info['mentioned_friends'] = true;
    }
    
    return info;
  }
}


