import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../domain/models/achievement.dart';
import '../domain/models/streak.dart';

// State class for gamification
class GamificationState {
  final List<Achievement> achievements;
  final Streak streak;
  final bool showConfetti;
  final String? lastUnlockedAchievementId;
  
  GamificationState({
    List<Achievement>? achievements,
    Streak? streak, 
    this.showConfetti = false,
    this.lastUnlockedAchievementId,
  }) : 
    achievements = achievements ?? AchievementPresets.getDefaultAchievements(),
    streak = streak ?? Streak();
  
  GamificationState copyWith({
    List<Achievement>? achievements,
    Streak? streak,
    bool? showConfetti,
    String? lastUnlockedAchievementId,
  }) {
    return GamificationState(
      achievements: achievements ?? this.achievements,
      streak: streak ?? this.streak,
      showConfetti: showConfetti ?? this.showConfetti,
      lastUnlockedAchievementId: lastUnlockedAchievementId,
    );
  }
}

// Provider for gamification state
class GamificationNotifier extends StateNotifier<GamificationState> {
  final SharedPreferences prefs;
  
  GamificationNotifier(this.prefs) : super(GamificationState()) {
    _loadState();
  }
  
  // Load state from shared preferences
  Future<void> _loadState() async {
    final achievementsJson = prefs.getString('achievements');
    final streakJson = prefs.getString('streak');
    
    if (achievementsJson != null) {
      try {
        final achievementsData = jsonDecode(achievementsJson) as List;
        final achievements = achievementsData
          .map((data) => Achievement(
            id: data['id'] as String,
            title: data['title'] as String,
            description: data['description'] as String,
            icon: data['icon'] as String,
            color: Color(data['color'] as int),
            category: AchievementCategory.values[data['category'] as int],
            requiredValue: data['requiredValue'] as int,
            currentValue: data['currentValue'] as int,
            unlocked: data['unlocked'] as bool,
            unlockedAt: data['unlockedAt'] != null 
              ? DateTime.parse(data['unlockedAt'] as String) 
              : null,
            reward: data['reward'] as String,
          ))
          .toList();
          
        state = state.copyWith(achievements: achievements);
      } catch (e) {
        // Fallback to default achievements on error
        if (kDebugMode) debugPrint('Error loading achievements: $e');
      }
    }
    
    if (streakJson != null) {
      try {
        final streakData = jsonDecode(streakJson);
        final activityDatesRaw = streakData['activityDates'] as List;
        final activityDates = activityDatesRaw
          .map((date) => DateTime.parse(date as String))
          .toList();
          
        final streak = Streak(
          currentStreak: streakData['currentStreak'] as int,
          bestStreak: streakData['bestStreak'] as int,
          lastActivityDate: DateTime.parse(streakData['lastActivityDate'] as String),
          activityDates: activityDates,
        );
        
        state = state.copyWith(streak: streak);
      } catch (e) {
        // Fallback to default streak on error
        if (kDebugMode) debugPrint('Error loading streak: $e');
      }
    }
  }
  
  // Save state to shared preferences
  Future<void> _saveState() async {
    try {
      // Save achievements
      final achievementsData = state.achievements.map((achievement) => {
        'id': achievement.id,
        'title': achievement.title,
        'description': achievement.description,
        'icon': achievement.icon,
        'color': achievement.color.value,
        'category': achievement.category.index,
        'requiredValue': achievement.requiredValue,
        'currentValue': achievement.currentValue,
        'unlocked': achievement.unlocked,
        'unlockedAt': achievement.unlockedAt?.toIso8601String(),
        'reward': achievement.reward,
      }).toList();
      
      await prefs.setString('achievements', jsonEncode(achievementsData));
      
      // Save streak
      final streakData = {
        'currentStreak': state.streak.currentStreak,
        'bestStreak': state.streak.bestStreak,
        'lastActivityDate': state.streak.lastActivityDate.toIso8601String(),
        'activityDates': state.streak.activityDates
          .map((date) => date.toIso8601String())
          .toList(),
      };
      
      await prefs.setString('streak', jsonEncode(streakData));
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving gamification state: $e');
    }
  }
  
  // Record app visit and update streak
  Future<void> recordAppVisit() async {
    final newStreak = state.streak.recordActivity();
    state = state.copyWith(streak: newStreak);
    
    // Check for streak milestone achievements
    _updateStreakAchievements();
    
    await _saveState();
  }
  
  // Update achievement progress
  Future<void> updateAchievement(String id, {required int progress}) async {
    final achievements = [...state.achievements];
    final index = achievements.indexWhere((a) => a.id == id);
    
    if (index == -1) return;
    
    final achievement = achievements[index];
    final newValue = achievement.currentValue + progress;
    
    // Check if achievement is newly unlocked
    final wasUnlocked = achievement.unlocked;
    final isNowUnlocked = newValue >= achievement.requiredValue;
    
    // Only show celebration if the achievement was just unlocked
    final shouldCelebrate = !wasUnlocked && isNowUnlocked;
    
    achievements[index] = achievement.copyWith(
      currentValue: newValue,
      unlocked: isNowUnlocked,
      unlockedAt: isNowUnlocked && achievement.unlockedAt == null 
        ? DateTime.now() 
        : achievement.unlockedAt,
    );
    
    state = state.copyWith(
      achievements: achievements,
      showConfetti: shouldCelebrate,
      lastUnlockedAchievementId: shouldCelebrate ? id : null,
    );
    
    if (shouldCelebrate) {
      // Reset confetti after 5 seconds
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(showConfetti: false);
        }
      });
    }
    
    await _saveState();
  }
  
  // Update streak-related achievements
  void _updateStreakAchievements() {
    final streakMasterIndex = state.achievements.indexWhere((a) => a.id == 'streak_master');
    
    if (streakMasterIndex >= 0) {
      final streakAchievement = state.achievements[streakMasterIndex];
      
      if (!streakAchievement.unlocked && state.streak.currentStreak >= streakAchievement.requiredValue) {
        // Current streak has reached the required value
        updateAchievement('streak_master', progress: state.streak.currentStreak);
      }
    }
  }
  
  // Dismiss the achievement celebration
  void dismissCelebration() {
    state = state.copyWith(showConfetti: false);
  }
}

// Create the providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GamificationNotifier(prefs);
}); 
 
 
 