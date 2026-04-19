/// Ephemeral routing hints after an FCM tap (consumed once on target screen).
class MoodMatchPushIntent {
  MoodMatchPushIntent._();

  static String? _pendingSwapSlot;
  static bool _pendingDayProposalSheet = false;

  static void setPendingSwapSlot(String? slot) {
    final s = slot?.trim() ?? '';
    _pendingSwapSlot = s.isEmpty ? null : s;
  }

  static void setPendingDayProposalSheet() => _pendingDayProposalSheet = true;

  static String? takePendingSwapSlot() {
    final s = _pendingSwapSlot;
    _pendingSwapSlot = null;
    return s;
  }

  static bool takePendingDayProposalSheet() {
    final v = _pendingDayProposalSheet;
    _pendingDayProposalSheet = false;
    return v;
  }
}
