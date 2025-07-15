import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/mood.dart';

part 'current_mood_provider.g.dart';

@riverpod
class CurrentMood extends _$CurrentMood {
  @override
  Mood? build() {
    debugPrint('🌈 Building CurrentMood provider');
    // Default mood - ensure it matches a key in _moodToActivityTypes map
    return Mood(
      id: 'default',
      userId: 'default_user',
      label: 'Social',
      emoji: '😊',
      createdAt: DateTime.now(),
      energyLevel: 0.8,
      activities: ['restaurants', 'bars', 'cafes'],
      isShared: false,
      note: 'Ready to socialize and have fun',
    );
  }

  void setMood(Mood mood) {
    debugPrint('🌈 Setting mood to: ${mood.label}');
    state = mood;
  }
} 