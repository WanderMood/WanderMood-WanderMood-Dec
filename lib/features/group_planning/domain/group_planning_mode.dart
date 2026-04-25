/// Planning mode stored in [group_plans.plan_data] under [kPlanDataPlanningModeKey].
enum GroupPlanningMode {
  /// Classic Mood Match — AI generates a day plan from matched moods.
  moodMatch,

  /// Place Together — seeded from a specific Explore place; no AI day plan.
  placeTogether;

  /// Value written to / read from [group_plans.plan_data].
  String get planDataValue => switch (this) {
        GroupPlanningMode.moodMatch => 'mood_match',
        GroupPlanningMode.placeTogether => 'place_together',
      };
}

/// Key in [group_plans.plan_data] that stores the [GroupPlanningMode].
const String kPlanDataPlanningModeKey = 'planning_mode';

/// Read [GroupPlanningMode] from a plan-data map. Defaults to [GroupPlanningMode.moodMatch].
GroupPlanningMode groupPlanningModeFromPlanData(Map<String, dynamic>? planData) {
  final raw = planData?[kPlanDataPlanningModeKey] as String?;
  if (raw == GroupPlanningMode.placeTogether.planDataValue) {
    return GroupPlanningMode.placeTogether;
  }
  return GroupPlanningMode.moodMatch;
}
