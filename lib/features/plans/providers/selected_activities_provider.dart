import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/activity.dart';

// Provider to manage selected activities globally
final selectedActivitiesProvider = StateNotifierProvider<SelectedActivitiesNotifier, Set<String>>((ref) {
  return SelectedActivitiesNotifier();
});

class SelectedActivitiesNotifier extends StateNotifier<Set<String>> {
  SelectedActivitiesNotifier() : super(<String>{});

  void addActivity(String activityId) {
    state = {...state, activityId};
  }

  void removeActivity(String activityId) {
    state = {...state}..remove(activityId);
  }

  void toggleActivity(String activityId) {
    if (state.contains(activityId)) {
      removeActivity(activityId);
    } else {
      addActivity(activityId);
    }
  }

  bool isSelected(String activityId) {
    return state.contains(activityId);
  }

  void clearAll() {
    state = <String>{};
  }

  List<String> get selectedActivityIds => state.toList();
} 