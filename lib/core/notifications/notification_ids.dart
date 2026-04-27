/// Stable numeric IDs for all local notifications.
///
/// Scheduled / recurring notifications each own a single slot.
/// Event-triggered per-item notifications use reserved numeric ranges so
/// multiple can coexist without clobbering each other.
abstract class NotificationIds {
  // ── Scheduled / recurring ────────────────────────────────────────────────
  static const int dailyMoodCheckIn     = 1;
  static const int companionMorning     = 2;
  static const int companionAfternoon   = 3;
  static const int companionEvening     = 4;
  static const int reEngagement         = 5;
  static const int weeklyMoodRecap      = 6;
  static const int weekendPlanningNudge = 7;
  static const int generateMyDay        = 8;
  static const int moodFollowUp         = 9;

  // ── Event-triggered (single-slot) ────────────────────────────────────────
  static const int weatherNudge         = 500;
  static const int postTripReflection   = 501;
  static const int socialEngagement     = 502;
  static const int friendActivity       = 503;
  static const int trendingInYourCity   = 504;
  static const int festivalEvent        = 505;
  static const int locationDiscovery    = 506;
  /// Host: friend joined the Mood Match session (one-shot per session).
  static const int moodMatchPartnerJoined = 507;

  /// Geofence-validated visit (celebratory; tiered prefs + caps).
  static const int visitGeofenceFirstCelebrate = 520;
  /// Optional end-of-day digest (planned; wired when scheduler calls it).
  static const int visitDailySummary = 521;

  // ── Event-triggered per-item ranges ──────────────────────────────────────
  // streak milestones  : 100 – 109  (10 milestone levels)
  // achievements       : 200 – 249  (up to 50 achievements)
  // saved activities   : 400 – 499  (up to 100 saved items)
  static const int streakMilestoneBase  = 100;
  static const int achievementBase      = 200;
  static const int savedActivityBase    = 400;

  // Compute a stable ID for a streak milestone day count.
  // Maps milestones [7,14,30,60,90,180,365] → IDs [100..106].
  static int streakMilestoneId(int days) {
    const milestones = [7, 14, 30, 60, 90, 180, 365];
    final index = milestones.indexOf(days);
    return streakMilestoneBase + (index >= 0 ? index : 0);
  }

  // Compute a stable ID for an achievement by list index (0-based).
  static int achievementId(int index) => achievementBase + index;

  // Compute a stable ID for a saved activity by list index (0-based).
  static int savedActivityId(int index) => savedActivityBase + index;
}
