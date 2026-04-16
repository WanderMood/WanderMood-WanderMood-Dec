/// Outcome of [GroupPlanningRepository.sendMoodMatchInAppInvite].
enum MoodMatchInAppInviteResult {
  /// Row inserted; recipient can see in-app realtime notification.
  delivered,

  /// RPC returned null (e.g. `in_app_notifications` off) — not a hard failure.
  notDeliveredInApp,

  /// Network / server error.
  error,
}
