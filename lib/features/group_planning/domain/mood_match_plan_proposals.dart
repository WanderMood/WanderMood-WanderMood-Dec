import 'package:wandermood/features/group_planning/domain/group_plan_v2.dart';

/// `group_plans.plan_data` proposal helpers (day + swap). No DB tables.
class MoodMatchPlanProposals {
  MoodMatchPlanProposals._();

  static Map<String, dynamic>? dayProposalMap(Map<String, dynamic>? plan) {
    final raw = plan?['dayProposal'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  static bool dayProposalPendingForUser(
    Map<String, dynamic>? plan,
    String? userId,
  ) {
    if (userId == null || plan == null) return false;
    final m = dayProposalMap(plan);
    if (m == null) return false;
    if ((m['status'] ?? '').toString() != 'pending') return false;
    return (m['addressedTo'] ?? '').toString() == userId;
  }

  static bool dayProposalWaitingOnOther(
    Map<String, dynamic>? plan,
    String? userId,
  ) {
    if (userId == null || plan == null) return false;
    final m = dayProposalMap(plan);
    if (m == null) return false;
    if ((m['status'] ?? '').toString() != 'pending') return false;
    return (m['proposedBy'] ?? '').toString() == userId;
  }

  static Map<String, dynamic>? swapProposalSlotMap(
    Map<String, dynamic>? plan,
    String slot,
  ) {
    final raw = plan?['swapProposals'];
    if (raw is! Map) return null;
    final e = raw[slot];
    if (e is! Map) return null;
    return Map<String, dynamic>.from(e);
  }

  /// First slot (morning → evening) with a pending swap where [userId] must respond.
  static String? pendingSwapSlotForResponder(
    Map<String, dynamic>? plan,
    String userId,
    String ownerId,
    String? guestUserId,
  ) {
    if (plan == null) return null;
    final sp = plan['swapProposals'];
    if (sp is Map) {
      for (final slot in GroupPlanV2.slots) {
        final m = swapProposalSlotMap(plan, slot);
        if (m == null) continue;
        if ((m['status'] ?? '').toString() != 'pending') continue;
        if ((m['addressedTo'] ?? '').toString() == userId) return slot;
      }
    }
    final guest = guestUserId;
    if (guest == null) return null;
    for (final slot in GroupPlanV2.slots) {
      final req = GroupPlanV2.swapRequestForSlot(plan, slot);
      if (req == null) continue;
      final by = GroupPlanV2.swapRequestedByUserId(req);
      if (by == null) continue;
      final addressedTo = by == ownerId ? guest : ownerId;
      if (addressedTo == userId) return slot;
    }
    return null;
  }
}
