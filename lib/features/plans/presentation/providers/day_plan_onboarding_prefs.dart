import 'package:shared_preferences/shared_preferences.dart';

/// First-run UX for day plan loading + results (local only).
class DayPlanOnboardingPrefs {
  DayPlanOnboardingPrefs._();

  static const String guidanceSeenKey = 'day_plan_guidance_strip_seen';
  static const String planLoadingCompactKey = 'day_plan_plan_loading_compact';

  static bool shouldShowGuidanceStrip(SharedPreferences prefs) =>
      !(prefs.getBool(guidanceSeenKey) ?? false);

  static Future<void> markGuidanceStripSeen(SharedPreferences prefs) =>
      prefs.setBool(guidanceSeenKey, true);

  /// After the first successful plan load, use a shorter loading screen.
  static bool useCompactPlanLoading(SharedPreferences prefs) =>
      prefs.getBool(planLoadingCompactKey) ?? false;

  static Future<void> markPlanLoadingCompact(SharedPreferences prefs) =>
      prefs.setBool(planLoadingCompactKey, true);
}
