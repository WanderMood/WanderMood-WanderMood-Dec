import 'package:wandermood/core/models/ai_recommendation.dart';

/// Mood Match plan v2: 3 activities (morning / afternoon / evening), swap pool,
/// owner/guest confirmations, swap requests. Stored in [group_plans.plan_data].
class GroupPlanV2 {
  GroupPlanV2._();

  static const slots = ['morning', 'afternoon', 'evening'];

  static int slotIndex(String slot) {
    switch (slot) {
      case 'morning':
        return 0;
      case 'afternoon':
        return 1;
      case 'evening':
        return 2;
      default:
        return 0;
    }
  }

  static String? slotFromActivity(Map<String, dynamic> a) {
    final s = (a['slot'] ?? a['timeSlot'])?.toString().toLowerCase().trim();
    if (s == 'morning' || s == 'afternoon' || s == 'evening') return s;
    return null;
  }

  static int? durationMinutes(Map<String, dynamic> a) {
    final d = a['duration_minutes'];
    if (d is num) return d.toInt();
    final raw = (a['duration'] ?? '').toString();
    final m = RegExp(r'(\d+)').firstMatch(raw);
    if (m != null) return int.tryParse(m.group(1)!);
    return 60;
  }

  static int slotStartHour(String slot) {
    switch (slot) {
      case 'morning':
        return 9;
      case 'afternoon':
        return 12;
      case 'evening':
        return 17;
      default:
        return 12;
    }
  }

  /// Build [activities] + [swapPool] from explore [recommendations].
  ///
  /// When [singleSlot] is provided, the plan only fills that slot (for the
  /// "owner picked date + part of day" flow). Remaining recommendations are
  /// added to the swap pool for that slot.
  static Map<String, dynamic> buildPlanPayloadFromRecommendations(
    List<AIRecommendation> recs, {
    String? singleSlot,
  }) {
    final jsonList = recs.map((r) => aiRecommendationToActivityMap(r)).toList();
    return buildPlanPayloadFromRawMaps(jsonList, singleSlot: singleSlot);
  }

  static Map<String, dynamic> aiRecommendationToActivityMap(
    AIRecommendation r,
  ) {
    final m = <String, dynamic>{
      'name': r.name,
      'type': r.type,
      'rating': r.rating,
      'description': r.description,
      'duration': r.duration,
      'cost': r.cost,
      'moodMatch': r.moodMatch,
      'timeSlot': r.timeSlot,
      'imageUrl': r.imageUrl,
      'location': r.location,
    };
    final loc = r.location;
    if (loc != null) {
      final pid = loc['placeId'] ?? loc['place_id'];
      if (pid != null && pid.toString().isNotEmpty) {
        m['place_id'] = pid.toString();
      }
    }
    m['duration_minutes'] = durationMinutes(m);
    return m;
  }

  static Map<String, dynamic> buildPlanPayloadFromRawMaps(
    List<Map<String, dynamic>> maps, {
    String? singleSlot,
  }) {
    final activities = <Map<String, dynamic>>[];
    final swapPool = <String, List<dynamic>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
    };

    if (maps.isEmpty) {
      return {
        'activities': activities,
        'swapPool': swapPool,
        'ownerConfirmed': _emptyConfirmMap(singleSlot: singleSlot),
        'guestConfirmed': _emptyConfirmMap(singleSlot: singleSlot),
        'swapRequests': <String, dynamic>{},
        'swapProposals': <String, dynamic>{},
      };
    }

    final targetSlots =
        singleSlot != null ? <String>[singleSlot] : List<String>.from(slots);

    // Assign first N to the target slot(s), preferring matching timeSlot.
    final used = <int>{};
    for (var s = 0; s < targetSlots.length; s++) {
      final slot = targetSlots[s];
      var picked = -1;
      for (var i = 0; i < maps.length; i++) {
        if (used.contains(i)) continue;
        final ts = maps[i]['timeSlot']?.toString().toLowerCase() ?? '';
        if (_slotMatches(ts, slot)) {
          picked = i;
          break;
        }
      }
      if (picked < 0) {
        for (var i = 0; i < maps.length; i++) {
          if (!used.contains(i)) {
            picked = i;
            break;
          }
        }
      }
      if (picked >= 0) {
        used.add(picked);
        final a = Map<String, dynamic>.from(maps[picked]);
        a['slot'] = slot;
        activities.add(a);
      }
    }

    // Remaining recommendations seed the swap pool. When the plan is
    // restricted to one slot, all extras go into that slot's pool.
    for (var i = 0; i < maps.length; i++) {
      if (used.contains(i)) continue;
      final slot = singleSlot ?? slots[i % 3];
      swapPool[slot]!.add(Map<String, dynamic>.from(maps[i]));
    }

    return {
      'activities': activities,
      'swapPool': swapPool,
      'ownerConfirmed': _emptyConfirmMap(singleSlot: singleSlot),
      'guestConfirmed': _emptyConfirmMap(singleSlot: singleSlot),
      'swapRequests': <String, dynamic>{},
      'swapProposals': <String, dynamic>{},
    };
  }

  static bool _slotMatches(String ts, String slot) {
    if (ts.isEmpty) return false;
    return ts.contains(slot);
  }

  /// When [singleSlot] is set, the slots not in the plan are pre-confirmed
  /// (true) so the "all confirmed" gate doesn't wait on slots that don't
  /// exist for this plan.
  static Map<String, bool> _emptyConfirmMap({String? singleSlot}) {
    if (singleSlot == null) {
      return {
        'morning': false,
        'afternoon': false,
        'evening': false,
      };
    }
    return {
      for (final s in slots) s: s != singleSlot,
    };
  }

  /// Slots that should appear in the result UI for this plan. When the plan
  /// was generated with a `time_slot`, only that slot has an activity.
  static List<String> activeSlotsFor(Map<String, dynamic>? plan) {
    final ts = plan?['time_slot']?.toString();
    if (ts == 'morning' || ts == 'afternoon' || ts == 'evening') {
      return <String>[ts!];
    }
    return List<String>.from(slots);
  }

  /// Slots that actually have an activity row — used for "confirm all" / CTA
  /// counts so a whole-day plan with only one stop is not blocked on 3/3.
  static List<String> slotsRequiringConfirmation(Map<String, dynamic>? plan) {
    if (plan == null) return const [];
    final normalized = normalizePlanData(Map<String, dynamic>.from(plan));
    final seen = <String>{};
    final out = <String>[];
    for (final a in activitiesList(normalized)) {
      final s = slotFromActivity(a);
      if (s == null) continue;
      if (seen.add(s)) out.add(s);
    }
    if (out.isNotEmpty) return out;
    return activeSlotsFor(normalized);
  }

  /// Ensures v2 shape exists; migrates legacy `recommendations` only.
  static Map<String, dynamic> normalizePlanData(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final activities = out['activities'];
    if (activities is List && activities.isNotEmpty) {
      out['swapPool'] ??= {
        'morning': [],
        'afternoon': [],
        'evening': [],
      };
      out['ownerConfirmed'] ??= _emptyConfirmMap();
      out['guestConfirmed'] ??= _emptyConfirmMap();
      out['swapRequests'] ??= <String, dynamic>{};
      out['swapProposals'] ??= <String, dynamic>{};
      out['sentToGuest'] ??= true;
      out['planVersion'] ??= 2;
      return out;
    }

    final recs = out['recommendations'] as List<dynamic>?;
    if (recs == null || recs.isEmpty) {
      out['activities'] = <dynamic>[];
      out['swapPool'] = {
        'morning': [],
        'afternoon': [],
        'evening': [],
      };
      out['ownerConfirmed'] = _emptyConfirmMap();
      out['guestConfirmed'] = _emptyConfirmMap();
      out['swapRequests'] = <String, dynamic>{};
      out['swapProposals'] = <String, dynamic>{};
      out['sentToGuest'] = true;
      out['planVersion'] = 2;
      return out;
    }

    final maps = <Map<String, dynamic>>[];
    for (final r in recs) {
      if (r is Map) maps.add(Map<String, dynamic>.from(r));
    }
    final built = buildPlanPayloadFromRawMaps(maps);
    out['activities'] = built['activities'];
    out['swapPool'] = built['swapPool'];
    // Legacy sessions: treat as already shared; owner "confirmed" picks.
    out['ownerConfirmed'] = {
      'morning': true,
      'afternoon': true,
      'evening': true,
    };
    out['guestConfirmed'] = _emptyConfirmMap();
    out['swapRequests'] = <String, dynamic>{};
    out['swapProposals'] = <String, dynamic>{};
    out['sentToGuest'] = true;
    out['planVersion'] = 2;
    return out;
  }

  static List<Map<String, dynamic>> activitiesList(Map<String, dynamic>? plan) {
    if (plan == null) return [];
    final raw = plan['activities'] as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Resolve the first usable place_id for scheduling. Checks top-level
  /// keys and a nested `location` map; treats empty strings as missing and
  /// skips synthetic `groupplan_*` ids that can't be re-fetched.
  static String? resolvePlaceId(Map<String, dynamic> m) {
    String? pick(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      if (t.isEmpty) return null;
      if (t.startsWith('groupplan_')) return null;
      return t;
    }

    bool looksLikeGooglePlacesRef(String id) {
      if (id.startsWith('google_')) return true;
      if (id.startsWith('ChIJ') || id.startsWith('EhIJ')) return true;
      return false;
    }

    for (final v in [m['place_id'], m['placeId']]) {
      final id = pick(v);
      if (id != null) return id;
    }
    // Skip synthetic `activity_*` rows and short slugs — they are not Google ids
    // and break `/place/:id` + photo resolution (wrong hero / "mock" images).
    final topId = pick(m['id']);
    if (topId != null &&
        !topId.startsWith('activity_') &&
        looksLikeGooglePlacesRef(topId)) {
      return topId;
    }
    final loc = m['location'];
    if (loc is Map) {
      for (final key in ['place_id', 'placeId', 'id']) {
        final id = pick(loc[key]);
        if (id == null) continue;
        if (key == 'id' &&
            (id.startsWith('activity_') || !looksLikeGooglePlacesRef(id))) {
          continue;
        }
        return id;
      }
    }
    return null;
  }

  /// Best-effort hero image for My Day / scheduled rows (direct URL or first photo).
  static String resolveActivityImageUrl(Map<String, dynamic> a) {
    for (final k in <String>[
      'imageUrl',
      'image_url',
      'photoUrl',
      'photo_url',
      'thumbnail',
    ]) {
      final v = a[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final photos = a['photos'];
    if (photos is List) {
      for (final p in photos) {
        if (p is String) {
          final t = p.trim();
          if (t.isNotEmpty) return t;
        }
        if (p is Map) {
          for (final key in ['url', 'photoUri', 'photo_uri', 'uri']) {
            final u = p[key]?.toString().trim();
            if (u != null && u.isNotEmpty) return u;
          }
        }
      }
    }
    return '';
  }

  /// Rows for [GroupPlanningRepository.saveGroupScheduledActivities] when
  /// finishing Mood Match without the separate time-picker step.
  /// Maps may include `time_slot` when the activity is tied to a part of day.
  static List<Map<String, dynamic>> schedulingActivityRows(
    Map<String, dynamic> planData,
  ) {
    final normalized = normalizePlanData(Map<String, dynamic>.from(planData));
    final activities = activitiesList(normalized);
    if (activities.isNotEmpty) {
      return activities.map((a) {
        final slot = slotFromActivity(a);
        return {
          'name': a['name'] ?? a['title'] ?? 'Activity',
          'place_id': resolvePlaceId(a) ?? '',
          'image_url': resolveActivityImageUrl(a),
          'duration_minutes': durationMinutes(a) ?? 60,
          if (slot != null) 'time_slot': slot,
        };
      }).toList();
    }
    final recs = normalized['recommendations'] as List<dynamic>?;
    if (recs == null) return [];
    return recs.take(3).map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      return {
        'name': m['name'] ?? m['title'] ?? 'Activity',
        'place_id': resolvePlaceId(m) ?? '',
        'image_url': resolveActivityImageUrl(m),
        'duration_minutes': (m['duration_minutes'] as num?)?.toInt() ?? 60,
        'time_slot': 'morning',
      };
    }).toList();
  }

  static Map<String, dynamic>? activityForSlot(
    Map<String, dynamic>? plan,
    String slot,
  ) {
    for (final a in activitiesList(plan)) {
      if (slotFromActivity(a) == slot) return a;
    }
    return null;
  }

  static Map<String, List<Map<String, dynamic>>> swapPools(
    Map<String, dynamic>? plan,
  ) {
    final out = <String, List<Map<String, dynamic>>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
    };
    final raw = plan?['swapPool'];
    if (raw is! Map) return out;
    for (final slot in slots) {
      final list = raw[slot] as List<dynamic>?;
      if (list == null) continue;
      for (final e in list) {
        if (e is Map) {
          out[slot]!.add(Map<String, dynamic>.from(e));
        }
      }
    }
    return out;
  }

  static Map<String, bool> boolSlotMap(dynamic raw) {
    final def = _emptyConfirmMap();
    if (raw is! Map) return def;
    for (final slot in slots) {
      final v = raw[slot];
      if (v is bool) def[slot] = v;
    }
    return def;
  }

  static Map<String, dynamic>? swapRequestForSlot(
    Map<String, dynamic>? plan,
    String slot,
  ) {
    final raw = plan?['swapRequests'];
    if (raw is! Map) return null;
    final e = raw[slot];
    if (e is! Map) return null;
    return Map<String, dynamic>.from(e);
  }

  /// User id who created the pending swap for this slot (`requestedBy` in DB).
  static String? swapRequestedByUserId(Map<String, dynamic>? swapReq) {
    if (swapReq == null) return null;
    final v = swapReq['requestedBy'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
