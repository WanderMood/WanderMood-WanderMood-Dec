import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/mood_option.dart';
import '../../home/presentation/screens/dynamic_my_day_provider.dart';

part 'daily_mood_state_provider.freezed.dart';
part 'daily_mood_state_provider.g.dart';

@freezed
class DailyMoodState with _$DailyMoodState {
  const factory DailyMoodState({
    @Default(false) bool hasSelectedMoodToday,
    String? currentMood,
    DateTime? lastMoodSelection,
    @Default([]) List<String> selectedMoods,
    @Default([]) List<EnhancedActivityData> plannedActivities,
    @Default(0) int todayActivitiesCount,
    String? conversationId,
    @Default('') String planProgress,
    String? nextUpActivity,
    DateTime? nextActivityTime,
    @Default(false) bool isInMoodChangeMode, // Track if user is temporarily changing mood
  }) = _DailyMoodState;
}

@riverpod
class DailyMoodStateNotifier extends _$DailyMoodStateNotifier {
  @override
  DailyMoodState build() {
    _initializeDailyState();
    return const DailyMoodState();
  }

  // Initialize daily state by checking preferences and existing activities
  Future<void> _initializeDailyState() async {
    await _loadStateFromPrefs();
    
    // If no mood selection today but there are activities, auto-initialize hub
    if (!state.hasSelectedMoodToday) {
      final activities = await _loadPlannedActivities();
      if (activities.isNotEmpty) {
        print('🎯 Auto-initializing Moody Hub - found ${activities.length} existing activities');
        
        // Get the most common mood from activities (or default to 'foody' based on restaurants)
        final inferredMood = _inferMoodFromActivities(activities);
        
        state = state.copyWith(
          hasSelectedMoodToday: true,
          currentMood: inferredMood,
          lastMoodSelection: MoodyClock.now(),
          selectedMoods: [inferredMood],
          plannedActivities: activities,
          todayActivitiesCount: activities.length,
          planProgress: _generatePlanProgress(activities),
          nextUpActivity: _getNextActivity(activities),
          nextActivityTime: _getNextActivityTime(activities),
        );
        
        // Save this state
        await _saveStateToPrefs();
      }
    }
  }

  // Load state from SharedPreferences
  Future<void> _loadStateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSelectionString = prefs.getString('last_mood_selection');
    final currentMood = prefs.getString('current_mood');
    final selectedMoods = prefs.getStringList('selected_moods') ?? [];
    final conversationId = prefs.getString('conversation_id');

    if (lastSelectionString != null) {
      final lastSelection = DateTime.parse(lastSelectionString);
      final today = MoodyClock.now();
      
      // Check if mood was selected today
      final hasSelectedToday = lastSelection.year == today.year &&
          lastSelection.month == today.month &&
          lastSelection.day == today.day;

      if (hasSelectedToday) {
        // Load planned activities from the existing provider
        final activities = await _loadPlannedActivities();
        
        state = state.copyWith(
          hasSelectedMoodToday: true,
          currentMood: currentMood,
          lastMoodSelection: lastSelection,
          selectedMoods: selectedMoods,
          plannedActivities: activities,
          todayActivitiesCount: activities.length,
          conversationId: conversationId,
          planProgress: _generatePlanProgress(activities),
          nextUpActivity: _getNextActivity(activities),
          nextActivityTime: _getNextActivityTime(activities),
        );
      }
    }
  }

  // Save state to SharedPreferences
  Future<void> _saveStateToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_mood_selection', state.lastMoodSelection?.toIso8601String() ?? '');
    await prefs.setString('current_mood', state.currentMood ?? '');
    await prefs.setStringList('selected_moods', state.selectedMoods);
    await prefs.setString('conversation_id', state.conversationId ?? '');
  }

  // Load planned activities from the existing provider
  Future<List<EnhancedActivityData>> _loadPlannedActivities() async {
    try {
      // Use the existing scheduled activity service
      final container = ProviderContainer();
      final activities = await container.read(todayActivitiesProvider.future);
      return activities;
    } catch (e) {
      print('❌ Error loading planned activities: $e');
      return [];
    }
  }

  // Set mood selection for today
  Future<void> setMoodSelection({
    required String mood,
    required List<String> selectedMoods,
    String? conversationId,
  }) async {
    final now = MoodyClock.now();
    final activities = await _loadPlannedActivities();
    
    state = state.copyWith(
      hasSelectedMoodToday: true,
      currentMood: mood,
      lastMoodSelection: now,
      selectedMoods: selectedMoods,
      plannedActivities: activities,
      todayActivitiesCount: activities.length,
      conversationId: conversationId,
      planProgress: _generatePlanProgress(activities),
      nextUpActivity: _getNextActivity(activities),
      nextActivityTime: _getNextActivityTime(activities),
    );
    
    await _saveStateToPrefs();
  }

  // Update mood (quick switch)
  Future<void> updateMood(String newMood) async {
    state = state.copyWith(
      currentMood: newMood,
      lastMoodSelection: MoodyClock.now(),
    );
    await _saveStateToPrefs();
  }

  // Temporarily enter mood change mode (preserves state for returning)
  Future<void> enterMoodChangeMode() async {
    state = state.copyWith(
      hasSelectedMoodToday: false,
      isInMoodChangeMode: true,
    );
  }

  // Reset mood selection completely (for full reset)
  Future<void> resetMoodSelection() async {
    state = const DailyMoodState();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_mood_selection');
    await prefs.remove('current_mood');
    await prefs.remove('selected_moods');
    await prefs.remove('conversation_id');
  }

  // Return to hub from mood change mode
  Future<void> returnToHub() async {
    if (state.isInMoodChangeMode) {
      final activities = await _loadPlannedActivities();
      
      state = state.copyWith(
        hasSelectedMoodToday: true,
        isInMoodChangeMode: false,
        plannedActivities: activities,
        todayActivitiesCount: activities.length,
        planProgress: _generatePlanProgress(activities),
        nextUpActivity: _getNextActivity(activities),
        nextActivityTime: _getNextActivityTime(activities),
      );
    }
  }

  // Refresh planned activities
  Future<void> refreshActivities() async {
    final activities = await _loadPlannedActivities();
    
    state = state.copyWith(
      plannedActivities: activities,
      todayActivitiesCount: activities.length,
      planProgress: _generatePlanProgress(activities),
      nextUpActivity: _getNextActivity(activities),
      nextActivityTime: _getNextActivityTime(activities),
    );
  }

  // Generate plan progress text
  String _generatePlanProgress(List<EnhancedActivityData> activities) {
    if (activities.isEmpty) return "No activities planned yet";
    
    final upcoming = activities.where((a) => a.status == ActivityStatus.upcoming).length;
    final active = activities.where((a) => a.status == ActivityStatus.activeNow).length;
    final completed = activities.where((a) => a.status == ActivityStatus.completed).length;
    
    if (active > 0) {
      return "$active activity happening now • $upcoming more coming up";
    } else if (upcoming > 0) {
      return "$completed completed • $upcoming activities planned";
    } else if (completed > 0) {
      return "All done! $completed activities completed today";
    } else {
      return "${activities.length} activities planned for today";
    }
  }

  // Get next upcoming activity
  String? _getNextActivity(List<EnhancedActivityData> activities) {
    final upcoming = activities
        .where((a) => a.status == ActivityStatus.upcoming)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcoming.isEmpty) {
      // Check for active activities
      final active = activities.where((a) => a.status == ActivityStatus.activeNow);
      if (active.isNotEmpty) {
        return active.first.rawData['title'] as String?;
      }
      return null;
    }
    
    return upcoming.first.rawData['title'] as String?;
  }

  // Get next activity time
  DateTime? _getNextActivityTime(List<EnhancedActivityData> activities) {
    final upcoming = activities
        .where((a) => a.status == ActivityStatus.upcoming)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return upcoming.isNotEmpty ? upcoming.first.startTime : null;
  }

  // Infer mood from existing activities
  String _inferMoodFromActivities(List<EnhancedActivityData> activities) {
    final activityNames = activities
        .map((a) => a.rawData['title']?.toString().toLowerCase() ?? '')
        .join(' ');
    
    print('🔍 Inferring mood from activities: $activityNames');
    
    // Check for food-related activities
    if (activityNames.contains(RegExp(r'\b(restaurant|food|cafe|dinner|lunch|bar|cuisine)\b'))) {
      return 'Foody';
    }
    
    // Check for romantic activities
    if (activityNames.contains(RegExp(r'\b(romantic|date|couple|wine|sunset)\b'))) {
      return 'Romantic';
    }
    
    // Check for cultural activities
    if (activityNames.contains(RegExp(r'\b(museum|gallery|theater|cultural|art|exhibition)\b'))) {
      return 'Cultural';
    }
    
    // Check for adventure activities
    if (activityNames.contains(RegExp(r'\b(adventure|outdoor|hiking|sports|active|bike)\b'))) {
      return 'Adventurous';
    }
    
    // Check for relaxed activities
    if (activityNames.contains(RegExp(r'\b(spa|relax|park|garden|peaceful|calm)\b'))) {
      return 'Relaxed';
    }
    
    // Default to Happy if can't determine
    return 'Happy';
  }
} 