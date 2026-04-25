import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/features/group_planning/data/mood_match_invited_profile.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/domain/group_planning_mode.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_labels.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_match_grid.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_share_qr_screen.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';
import 'package:wandermood/core/notifications/notification_copy.dart';
import 'package:wandermood/core/notifications/notification_ids.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Returns Moody's reaction string for the selected mood tag.
String _moodyReactionForMood(AppLocalizations l10n, String tag) {
  switch (tag) {
    case 'curious':
      return l10n.moodMatchMoodyReactionCurious;
    case 'romantic':
      return l10n.moodMatchMoodyReactionRomantic;
    case 'foody':
      return l10n.moodMatchMoodyReactionFoody;
    case 'relaxed':
      return l10n.moodMatchMoodyReactionRelaxed;
    case 'energetic':
      return l10n.moodMatchMoodyReactionEnergetic;
    case 'cozy':
      return l10n.moodMatchMoodyReactionCozy;
    case 'adventurous':
      return l10n.moodMatchMoodyReactionAdventurous;
    case 'cultural':
      return l10n.moodMatchMoodyReactionCultural;
    case 'social':
      return l10n.moodMatchMoodyReactionSocial;
    case 'excited':
      return l10n.moodMatchMoodyReactionExcited;
    case 'happy':
      return l10n.moodMatchMoodyReactionHappy;
    case 'surprise':
      return l10n.moodMatchMoodyReactionSurprise;
    default:
      return l10n.moodMatchMoodyReactionHappy;
  }
}

/// Mood Match lobby — mood grid, code, members, Moody commentary, generate.
class GroupPlanningLobbyScreen extends ConsumerStatefulWidget {
  const GroupPlanningLobbyScreen({
    super.key,
    required this.sessionId,
    this.joinCode,
    this.autoShowInvite = false,
  });

  final String sessionId;
  final String? joinCode;
  final bool autoShowInvite;

  @override
  ConsumerState<GroupPlanningLobbyScreen> createState() =>
      _GroupPlanningLobbyScreenState();
}

class _GroupPlanningLobbyScreenState
    extends ConsumerState<GroupPlanningLobbyScreen>
    with TickerProviderStateMixin {
  Timer? _poll;
  StreamSubscription<List<Map<String, dynamic>>>? _membersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionSub;
  List<GroupMemberView> _members = [];
  GroupSessionRow? _session;
  String? _joinCodeDisplay;
  String? _selectedMood;
  bool _submitting = false;
  bool _lockingAnimation = false;
  String? _error;
  bool _planExists = false;
  GroupPlanRow? _planRow;
  List<MoodMatchInvitedProfile> _invitedProfiles = const [];
  final GlobalKey _shareLinkKey = GlobalKey();

  late final AnimationController _pulse;

  int _lastMemberCount = 0;
  DateTime? _bothLockedAt;
  bool _navigatedToNextStep = false;

  @override
  void initState() {
    super.initState();
    _joinCodeDisplay = widget.joinCode;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _startRealtime();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if ((widget.joinCode == null || widget.joinCode!.trim().isEmpty) &&
          (_joinCodeDisplay == null || _joinCodeDisplay!.trim().isEmpty)) {
        final p = await MoodMatchSessionPrefs.read();
        if (p.sessionId == widget.sessionId &&
            p.joinCode != null &&
            p.joinCode!.trim().isNotEmpty &&
            mounted) {
          setState(() => _joinCodeDisplay = p.joinCode!.trim().toUpperCase());
        }
      }
      await _refresh();
      await _loadInvitedProfiles();
      if (widget.autoShowInvite && _joinCodeDisplay != null && mounted) {
        _shareLink();
      }
    });
  }

  Future<void> _loadInvitedProfiles() async {
    final list =
        await MoodMatchSessionPrefs.readInvitedProfiles(widget.sessionId);
    if (!mounted) return;
    setState(() => _invitedProfiles = list);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _membersSub?.cancel();
    _sessionSub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startPollingFallback() {
    if (_poll != null) return;
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  void _startRealtime() {
    try {
      final supabase = Supabase.instance.client;
      _membersSub = supabase
          .from('group_session_members')
          .stream(primaryKey: ['id'])
          .eq('session_id', widget.sessionId)
          .listen(
            (_) async {
              await _refresh();
            },
            onError: (Object e, StackTrace st) {
              debugPrint('[Lobby] members stream error: $e\n$st');
              _startPollingFallback();
            },
          );

      _sessionSub = supabase
          .from('group_sessions')
          .stream(primaryKey: ['id'])
          .eq('id', widget.sessionId)
          .listen(
            (_) async {
              await _refresh();
            },
            onError: (Object e, StackTrace st) {
              debugPrint('[Lobby] session stream error: $e\n$st');
              _startPollingFallback();
            },
          );
    } catch (e, st) {
      debugPrint('[Lobby] realtime subscribe failed: $e\n$st');
      _startPollingFallback();
    }
  }

  Future<void> _refresh() async {
    final repo = ref.read(groupPlanningRepositoryProvider);
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final session = await repo.fetchSession(widget.sessionId);
      if (!session.expiresAt.isAfter(DateTime.now()) ||
          session.status == 'expired' ||
          session.status == 'error') {
        await MoodMatchSessionPrefs.clear();
      } else {
        await MoodMatchSessionPrefs.save(
          sessionId: widget.sessionId,
          joinCode: session.joinCode,
        );
      }
      final members = await repo.fetchMembersWithProfiles(widget.sessionId);
      final plan = await repo.fetchPlan(widget.sessionId);
      if (!mounted) return;

      final count = members.length;
      if (count >= 2 && _lastMemberCount < 2) {
        final friend = _friendMember(members);
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null && session.createdBy == uid) {
          final fname = friend != null
              ? _firstName(friend.displayName)
              : l10n.moodMatchPartnerJoinedNotifNameFallback;
          unawaited(
            _maybeShowPartnerJoinedLocalNotification(
              sessionId: widget.sessionId,
              firstName: fname,
            ),
          );
          unawaited(
            MoodMatchSessionPrefs.clearInvitedProfiles(widget.sessionId),
          );
          if (mounted) {
            setState(() => _invitedProfiles = const []);
          }
        }
      }
      _lastMemberCount = count;

      final isPlaceTogether = plan != null &&
          groupPlanningModeFromPlanData(plan.planData) ==
              GroupPlanningMode.placeTogether;
      final allSubmittedNow = members.length >= 2 &&
          (isPlaceTogether ||
              members.every((m) => m.member.hasSubmittedMood));
      if (allSubmittedNow && _bothLockedAt == null) {
        _bothLockedAt = DateTime.now();
      }

      final revealDone =
          await MoodMatchSessionPrefs.readRevealCompleted(widget.sessionId);
      if (!mounted) return;

      setState(() {
        _session = session;
        _members = members;
        _joinCodeDisplay ??= session.joinCode;
        _error = null;
        _planExists = plan != null;
        _planRow = plan;
      });

      if (_navigatedToNextStep || !mounted) return;

      void resumeGo(String path) {
        _navigatedToNextStep = true;
        _poll?.cancel();
        _poll = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(path);
        });
      }

      // Resume where the user left off (cold start resets in-memory flags).
      // Place-together keeps a seeded plan in `group_plans` from the start;
      // do not jump to result until the shared day flow has run.
      if (plan != null && !isPlaceTogether) {
        resumeGo('/group-planning/result/${widget.sessionId}');
        return;
      }

      if (session.status == 'generating' ||
          session.status == 'ready' ||
          session.status == 'day_confirmed') {
        if (!isPlaceTogether) {
          resumeGo('/group-planning/match-loading/${widget.sessionId}');
          return;
        }
      }

      if (session.status == 'day_proposed') {
        resumeGo('/group-planning/day-picker/${widget.sessionId}');
        return;
      }

      if (isPlaceTogether &&
          allSubmittedNow &&
          session.status == 'waiting') {
        if (!revealDone) {
          unawaited(
            MoodMatchSessionPrefs.markRevealCompleted(widget.sessionId),
          );
        }
        resumeGo('/group-planning/day-picker/${widget.sessionId}');
        return;
      }

      if (allSubmittedNow && revealDone && session.status == 'waiting') {
        resumeGo('/group-planning/day-picker/${widget.sessionId}');
        return;
      }

      // First time both moods are in → compatibility reveal; not again after
      // [MoodMatchSessionPrefs.markRevealCompleted].
      if (allSubmittedNow && !revealDone && !isPlaceTogether) {
        _navigatedToNextStep = true;
        _poll?.cancel();
        _poll = null;
        if (mounted) {
          final startedAt = _bothLockedAt;
          final elapsed = startedAt == null
              ? const Duration(milliseconds: 0)
              : DateTime.now().difference(startedAt);
          final remaining = const Duration(milliseconds: 800) - elapsed;
          if (remaining.isNegative) {
            context.go('/group-planning/reveal/${widget.sessionId}');
          } else {
            Future.delayed(remaining, () {
              if (mounted) {
                context.go('/group-planning/reveal/${widget.sessionId}');
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final cleaned = raw.startsWith('Exception: ')
            ? raw.substring('Exception: '.length)
            : raw.startsWith('Bad state: ')
                ? raw.substring('Bad state: '.length)
                : raw;
        setState(() => _error = cleaned);
      }
      _startPollingFallback();
    }
  }

  GroupMemberView? _friendMember(List<GroupMemberView> list) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in list) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  GroupMemberView? _meMember() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId == uid) return m;
    }
    return null;
  }

  /// Only the owner who has already sent an in-app invite should see the
  /// "Waiting for @name" pill — and only while the invitee hasn't joined yet.
  bool _shouldShowInvitedPill() {
    if (_invitedProfiles.isEmpty) return false;
    if (_friendMember(_members) != null) return false;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    final createdBy = _session?.createdBy;
    if (createdBy != null && createdBy != uid) return false;
    return true;
  }

  /// One-shot device notification for the session host when a second member joins.
  Future<void> _maybeShowPartnerJoinedLocalNotification({
    required String sessionId,
    required String firstName,
  }) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final key = 'mood_match_partner_join_notif_$sessionId';
      if (prefs.getBool(key) == true) return;

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await NotificationService.instance.show(
        NotificationIds.moodMatchPartnerJoined,
        NotificationCopy(
          title: l10n.moodMatchPartnerJoinedNotifTitle(firstName),
          body: l10n.moodMatchPartnerJoinedNotifBody,
          payload: 'wm_nav_mm_lobby:$sessionId',
        ),
      );
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  bool get _allSubmitted =>
      _members.length >= 2 &&
      (_isPlaceTogetherSession ||
          _members.every((m) => m.member.hasSubmittedMood));

  bool get _isPlaceTogetherSession {
    if (_planRow == null) return false;
    return groupPlanningModeFromPlanData(_planRow!.planData) ==
        GroupPlanningMode.placeTogether;
  }

  String? _waitingOtherDisplayName() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid && !m.member.hasSubmittedMood) {
        return m.displayName;
      }
    }
    return null;
  }

  bool _currentUserLocked() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    for (final m in _members) {
      if (m.member.userId == uid) return m.member.hasSubmittedMood;
    }
    return false;
  }

  String _firstName(String displayName) {
    final s = displayName.trim();
    if (s.isEmpty) return '?';
    if (s.startsWith('@')) {
      final u = s.substring(1).trim();
      if (u.isNotEmpty) {
        final parts = u.split(RegExp(r'\s+'));
        if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
      }
    }
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '?';
  }

  String _friendThey(AppLocalizations l10n) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) {
        return _firstName(m.displayName);
      }
    }
    return l10n.moodMatchFriendThey;
  }

  String _headerTitle(AppLocalizations l10n) {
    if (_session?.status == 'generating') {
      return moodMatchPlanBuildingMessage(l10n);
    }
    if (_allSubmitted) {
      return l10n.moodMatchLobbyEveryoneReadyTitle;
    }
    final w = _waitingOtherDisplayName();
    if (w != null) {
      return l10n.groupPlanLobbyTitleWaitingName(_firstName(w));
    }
    if (_members.length < 2) {
      return l10n.groupPlanLobbyTitleWaitingFriend;
    }
    return l10n.groupPlanLobbyTitleWaitingFriend;
  }

  String _headerSubtitle(AppLocalizations l10n) {
    if (_session?.status == 'generating') {
      return l10n.moodMatchLobbyBuildingSubtitle;
    }
    if (_allSubmitted) {
      return l10n.moodMatchLobbyEveryoneReadySubtitle;
    }
    return l10n.moodMatchLobbyWaitingSubtitle;
  }

  // ── Change 1: Mood confirmation popup ─────────────────────────────────────

  String _liveStatusText(AppLocalizations l10n) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (_members.length < 2) {
      return l10n.groupPlanLobbyWaitingFriend;
    }
    for (final m in _members) {
      if (m.member.userId != uid) {
        if (m.member.hasSubmittedMood) {
          return l10n.moodMatchLiveUpdateLocked(_firstName(m.displayName));
        }
        return l10n.moodMatchLiveUpdatePicking(_firstName(m.displayName));
      }
    }
    return l10n.groupPlanLobbyWaitingFriend;
  }

  Future<void> _showMoodConfirmDialog(String moodTag) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final emoji = kMoodMatchMoodEmoji[moodTag] ?? '✨';
    final moodLabel = groupPlanLocalizedMoodTag(l10n, moodTag);
    final otherName = _friendThey(l10n);
    final reaction = _moodyReactionForMood(l10n, moodTag);

    final confirmed = await GroupPlanningUi.showBlurredDialog<bool>(
      context: context,
      child: Builder(
        builder: (ctx) => Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFDF8F1),
                  GroupPlanningUi.cream,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: GroupPlanningUi.moodMatchShadow(0.25),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GroupPlanningUi.forestTint,
                    border: Border.all(
                      color: GroupPlanningUi.forest.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 38),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.moodMatchLockInVibeTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: GroupPlanningUi.charcoal,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF08A5C), Color(0xFFE05C3A)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE05C3A).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    moodLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GroupPlanningUi.forestTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: MoodyCharacter(size: 28, mood: 'happy'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reaction,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: GroupPlanningUi.forest,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: GroupPlanningUi.stone.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.moodMatchPrivacyNoteLockIn(otherName),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.stone,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2A6049),
                          Color(0xFF3A7E5E),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GroupPlanningUi.forest.withValues(alpha: 0.40),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(ctx).pop(true),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🔒',
                                style: TextStyle(
                                  fontSize: 20,
                                  height: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.moodMatchLockInVibeBtn,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(false),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      l10n.moodMatchChangeMind,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: GroupPlanningUi.stone,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            GroupPlanningUi.stone.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _submitMood();
    } else {
      if (mounted) setState(() => _selectedMood = null);
    }
  }

  Future<void> _shareLink() async {
    final code = _joinCodeDisplay;
    if (code == null || code.isEmpty) return;
    await showGroupPlanningShareSheet(
      context,
      sessionId: widget.sessionId,
      joinCode: code,
      sessionDisplayTitle: _session?.title?.trim(),
    );
    if (!mounted) return;
    await _loadInvitedProfiles();
  }

  Future<void> _submitMood() async {
    final l10n = AppLocalizations.of(context)!;
    final mood = _selectedMood;
    if (mood == null && !_allSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupPlanLobbyPickMoodSnack)),
      );
      return;
    }

    // Both moods are in, but no plan yet → user just needs to continue to the
    // reveal. Plan generation now happens AFTER the date is picked, in the
    // match-loading screen. The auto-router in [_refresh] also handles this,
    // but we add a hard fallback here in case realtime missed an update.
    if (_allSubmitted && !_planExists && _session?.status != 'generating') {
      HapticFeedback.mediumImpact();
      final revealDone =
          await MoodMatchSessionPrefs.readRevealCompleted(widget.sessionId);
      if (!mounted) return;
      if (revealDone) {
        context.go('/group-planning/day-picker/${widget.sessionId}');
      } else {
        context.go('/group-planning/reveal/${widget.sessionId}');
      }
      return;
    }

    if (mood == null) return;

    if (!_allSubmitted && !_currentUserLocked()) {
      setState(() => _lockingAnimation = true);
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _lockingAnimation = false);
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      await repo.submitMood(sessionId: widget.sessionId, moodTag: mood);
      // No plan generation here — the owner must pick a day first so Moody
      // can plan against the right date / time slot. _refresh will pick up
      // both moods via realtime and navigate to /reveal.
      await _refresh();
    } catch (e) {
      if (mounted) {
        GroupPlanningUi.showErrorSnack(
          context,
          l10n,
          e,
          fallback: l10n.groupPlanLobbySubmitError(''),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _primaryLabel(AppLocalizations l10n) {
    if (_session?.status == 'generating') {
      return moodMatchPlanBuildingButtonLabel(l10n);
    }
    if (_allSubmitted && !_planExists && _session?.status != 'generating') {
      return l10n.groupPlanLobbyGenerateCta;
    }
    if (_lockingAnimation) {
      return l10n.groupPlanLobbyLockingIn;
    }
    if (_currentUserLocked() && !_allSubmitted) {
      final w = _waitingOtherDisplayName();
      if (w != null) return l10n.groupPlanLobbyWaitingLockIn(_firstName(w));
      return l10n.groupPlanLobbyWaitingFriendJoin;
    }
    final m = _selectedMood;
    if (m != null) {
      return '🔒 ${l10n.moodMatchLockBtn(groupPlanLocalizedMoodTag(l10n, m))}';
    }
    return l10n.moodMatchSelectMoodButton;
  }

  bool _primaryEnabled() {
    if (_submitting) return false;
    if (_lockingAnimation) return false;
    if (_session?.status == 'generating') return false;
    if (_allSubmitted && !_planExists && _session?.status != 'generating') {
      return true;
    }
    if (_currentUserLocked() && !_allSubmitted) return false;
    return _selectedMood != null;
  }

  Color _lockButtonBg(AppLocalizations l10n) {
    if (_primaryEnabled() &&
        !_allSubmitted &&
        _selectedMood != null &&
        _session?.status != 'generating') {
      return GroupPlanningUi.forest;
    }
    if (_allSubmitted && !_planExists && _session?.status != 'generating') {
      return GroupPlanningUi.forest;
    }
    return GroupPlanningUi.moodMatchDeepMuted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final code = _joinCodeDisplay ?? '…';
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: GroupPlanningUi.moodMatchDeep,
            padding: EdgeInsets.fromLTRB(8, topInset + 4, 8, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                      onPressed: () => context.go('/group-planning'),
                    ),
                    Expanded(
                      child: Text(
                        _headerTitle(l10n),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(
                  _headerSubtitle(l10n),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _TeamHeroStrip(
                  me: _meMember(),
                  friend: _friendMember(_members),
                  invitedFallback:
                      _invitedProfiles.isNotEmpty ? _invitedProfiles.last : null,
                  pulse: _pulse,
                ),
                if (_shouldShowInvitedPill())
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _InvitedWaitingPill(
                      l10n: l10n,
                      profile: _invitedProfiles.last,
                      onNudge: _shareLink,
                    ),
                  ),
                const SizedBox(height: 8),
                // Moody's tip used to live in a separate green card inside the
                // cream body, adding scroll height. Pulling it into the hero
                // frees up the body so all 12 mood tiles fit above the fold.
                if (!_currentUserLocked())
                  _HeroMoodyTipBubble(
                    message: moodMatchMoodyPickQuoteLine(l10n, commStyle),
                  )
                else
                  _TeamHeroStatusLine(
                    text: _liveStatusText(l10n),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          code,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.robotoMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      KeyedSubtree(
                        key: _shareLinkKey,
                        child: IconButton(
                          icon: const Text(
                            '📤',
                            style: TextStyle(fontSize: 20),
                          ),
                          color: Colors.white,
                          onPressed: _shareLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: GroupPlanningUi.cream,
              elevation: 8,
              shadowColor: GroupPlanningUi.moodMatchShadow(0.35),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: RefreshIndicator(
                color: GroupPlanningUi.forest,
                onRefresh: _refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(22, 8, 22, bottomInset + 20),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GroupPlanningUi.stone.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (!_currentUserLocked() && !_isPlaceTogetherSession) ...[
                      // No more white card wrapper around the grid — that was
                      // pushing the final row of moods below the fold. We now
                      // render the caps tag + big title inline on cream, then
                      // the grid, so all 12 tiles land in one viewport.
                      Text(
                        l10n.moodMatchStepYourMood.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: GroupPlanningUi.forest,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moodMatchFeelQuestionForNow(l10n),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GroupPlanningUi.charcoal,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l10n.moodMatchPrivateHint(l10n.moodMatchFriendThey),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: GroupPlanningUi.stone,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      GroupPlanningMoodMatchGrid(
                        selectedTag: _selectedMood,
                        onSelect: (tag) async {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMood = tag);
                          await _showMoodConfirmDialog(tag);
                        },
                        enabled: !_submitting,
                      ),
                    ],
                    if (!_currentUserLocked() && _isPlaceTogetherSession) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.groupPlanTogetherTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: GroupPlanningUi.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.moodMatchLobbyWaitingSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: GroupPlanningUi.stone,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (_currentUserLocked() && !_allSubmitted && !_isPlaceTogetherSession) ...[
                      const SizedBox(height: 14),
                      _WaitingPreviewCard(
                        l10n: l10n,
                        friend: _friendMember(_members),
                        invitedFallback: () {
                          if (_invitedProfiles.isEmpty) return null;
                          final f = _friendMember(_members);
                          if (f == null) return _invitedProfiles.last;
                          for (final p in _invitedProfiles) {
                            if (p.id == f.member.userId) return p;
                          }
                          return null;
                        }(),
                        friendFirstName: () {
                          final f = _friendMember(_members);
                          if (f != null) return _firstName(f.displayName);
                          if (_invitedProfiles.isNotEmpty) {
                            return _invitedProfiles.last.firstName;
                          }
                          return l10n.moodMatchFriendThey;
                        }(),
                        pulse: _pulse,
                      ),
                    ],
                    // CTA is only shown in transitional states — picking a
                    // mood now triggers the lock-in dialog directly, and the
                    // "waiting for match" status is surfaced above as a live
                    // status card, so the big bottom button would otherwise
                    // be redundant (and created a big beige gap).
                    if (_session?.status == 'generating' ||
                        _submitting ||
                        (_allSubmitted &&
                            !_planExists &&
                            _session?.status != 'generating')) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _lockButtonBg(l10n),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _primaryEnabled() ? _submitMood : null,
                            child: Center(
                              child: _session?.status == 'generating'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          moodMatchPlanBuildingButtonLabel(
                                              l10n),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _submitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _primaryLabel(l10n),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_session?.status == 'error') ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.groupPlanLobbyPlanFailed,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.l10n,
    required this.showTypingDots,
    required this.pulse,
    required this.enableJoinBounce,
  });

  final GroupMemberView member;
  final AppLocalizations l10n;
  final bool showTypingDots;
  final AnimationController pulse;
  final bool enableJoinBounce;

  @override
  Widget build(BuildContext context) {
    final locked = member.member.hasSubmittedMood;
    final avatar = member.avatarUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GroupPlanningUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _Bouncy(
                enabled: enableJoinBounce,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: GroupPlanningUi.forestTint,
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? Text(
                          member.displayName.isNotEmpty
                              ? member.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: GroupPlanningUi.forest,
                          ),
                        )
                      : null,
                ),
              ),
              if (showTypingDots)
                Positioned(
                  right: -4,
                  bottom: -6,
                  child: _TypingDots(pulse: pulse),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.moodMatchStatusMoodLocked,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: GroupPlanningUi.forest,
                    ),
                  ),
                ] else if (showTypingDots) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.moodMatchStatusPickingMood,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: GroupPlanningUi.stone,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!locked)
            _PulsingBadge(
              label: '● ${l10n.moodMatchLobbyChoosingBadge}',
              amber: true,
            )
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GroupPlanningUi.forest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ ${l10n.moodMatchBadgeLocked}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.members,
    required this.l10n,
    required this.pulse,
  });

  final List<GroupMemberView> members;
  final AppLocalizations l10n;
  final AnimationController pulse;

  GroupMemberView? _me(List<GroupMemberView> list) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in list) {
      if (m.member.userId == uid) return m;
    }
    return list.isNotEmpty ? list.first : null;
  }

  GroupMemberView? _friend(List<GroupMemberView> list) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in list) {
      if (m.member.userId != uid) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = _me(members);
    final friend = _friend(members);
    final showFriendTyping = friend != null &&
        !friend.member.hasSubmittedMood &&
        (friend.member.moodTag == null || friend.member.moodTag!.isEmpty);

    return Column(
      children: [
        if (me != null)
          _MemberRow(
            member: me,
            l10n: l10n,
            showTypingDots: false,
            pulse: pulse,
            enableJoinBounce: false,
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
                    .animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: friend == null
              ? _FriendPlaceholderRow(pulse: pulse, l10n: l10n)
              : KeyedSubtree(
                  key: ValueKey(friend.member.userId),
                  child: _MemberRow(
                    member: friend,
                    l10n: l10n,
                    showTypingDots: showFriendTyping,
                    pulse: pulse,
                    enableJoinBounce: true,
                  ),
                ),
        ),
      ],
    );
  }
}

class _FriendPlaceholderRow extends StatelessWidget {
  const _FriendPlaceholderRow({required this.pulse, required this.l10n});

  final AnimationController pulse;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: pulse, curve: Curves.easeInOut);
    final alpha = Tween<double>(begin: 0.45, end: 0.85).animate(t);
    final scale = Tween<double>(begin: 0.98, end: 1.02).animate(t);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GroupPlanningUi.cardBorder),
        boxShadow: [
          BoxShadow(
            color: GroupPlanningUi.moodMatchShadow(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) => Opacity(
              opacity: alpha.value,
              child: Transform.scale(
                scale: scale.value,
                child: _DashedCircle(
                  size: 48,
                  child: Text(
                    '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: GroupPlanningUi.stone,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.groupPlanLobbyWaitingFriend,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: GroupPlanningUi.stone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter:
          _DashedCirclePainter(color: GroupPlanningUi.cardBorder, stroke: 1.6),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final r = (size.shortestSide / 2) - stroke / 2;
    const dashCount = 16;
    const gap = 0.35;
    for (var i = 0; i < dashCount; i++) {
      final start = (i / dashCount) * 2 * 3.141592653589793;
      final sweep = (2 * 3.141592653589793 / dashCount) * (1 - gap);
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: r),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

class _Bouncy extends StatelessWidget {
  const _Bouncy({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, t, _) {
        final s = 1.0 + (0.2 * (1 - (t - 1).abs()).clamp(0.0, 1.0));
        return Transform.scale(scale: s, child: child);
      },
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value; // 0..1
        double dotOpacity(int i) {
          final phase = (t + (i * 0.12)) % 1.0;
          final v = (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
          return 0.3 + (0.7 * v);
        }

        Widget dot(int i) => Opacity(
              opacity: dotOpacity(i),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: GroupPlanningUi.forest,
                  shape: BoxShape.circle,
                ),
              ),
            );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: GroupPlanningUi.cardBorder),
            boxShadow: [
              BoxShadow(
                color: GroupPlanningUi.moodMatchShadow(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot(0),
              const SizedBox(width: 4),
              dot(1),
              const SizedBox(width: 4),
              dot(2),
            ],
          ),
        );
      },
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge({required this.label, this.amber = false});

  final String label;
  final bool amber;

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.amber ? const Color(0xFFFFF3CD) : GroupPlanningUi.cream;
    final fg = widget.amber ? const Color(0xFF8B6900) : GroupPlanningUi.stone;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GroupPlanningUi.cardBorder),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Compact three-up hero: [me-avatar] ──── [Moody] ──── [friend-avatar]
/// Replaces the old "Wie doet mee" card so step 1 of 2 lands above the fold.
class _TeamHeroStrip extends StatelessWidget {
  const _TeamHeroStrip({
    required this.me,
    required this.friend,
    required this.invitedFallback,
    required this.pulse,
  });

  final GroupMemberView? me;
  final GroupMemberView? friend;
  final MoodMatchInvitedProfile? invitedFallback;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HeroAvatar(member: me, isMe: true, pulse: pulse),
        const _HeroConnector(),
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (context, _) => Transform.scale(
                scale: 1.0 + pulse.value * 0.10,
                child: Opacity(
                  opacity: 0.45 + pulse.value * 0.55,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: MoodyCharacter(size: 28, mood: 'happy'),
              ),
            ),
          ],
        ),
        const _HeroConnector(),
        _HeroAvatar(
          member: friend,
          invitedFallback: invitedFallback,
          isMe: false,
          pulse: pulse,
        ),
      ],
    );
  }
}

class _HeroConnector extends StatelessWidget {
  const _HeroConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 1.2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.28),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({
    required this.member,
    this.invitedFallback,
    required this.isMe,
    required this.pulse,
  });

  final GroupMemberView? member;
  final MoodMatchInvitedProfile? invitedFallback;
  final bool isMe;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    if (member == null && invitedFallback == null) {
      // Friend not yet joined → dashed outline + ? inside, pulsing.
      return AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final opacity = 0.55 + pulse.value * 0.45;
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.8,
                ),
              ),
              child: Text(
                '?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          );
        },
      );
    }

    final m = member;
    final invite = invitedFallback;
    final avatar = m?.avatarUrl ?? invite?.imageUrl;
    final locked = m?.member.hasSubmittedMood == true;
    final emoji = locked
        ? (kMoodMatchMoodEmoji[m?.member.moodTag ?? ''] ?? '✨')
        : null;
    final initial = m != null
        ? (m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?')
        : ((invite?.firstName.trim().isNotEmpty ?? false)
            ? invite!.firstName.trim()[0].toUpperCase()
            : '?');

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: locked
                    ? GroupPlanningUi.forest
                    : Colors.white.withValues(alpha: 0.55),
                width: locked ? 2.4 : 1.6,
              ),
              boxShadow: locked
                  ? [
                      BoxShadow(
                        color: GroupPlanningUi.forest.withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? WmNetworkImage(
                      avatar,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _HeroAvatarInitial(
                        label: initial,
                      ),
                    )
                  : _HeroAvatarInitial(label: initial),
            ),
          ),
          if (emoji != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: GroupPlanningUi.moodMatchShadow(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroAvatarInitial extends StatelessWidget {
  const _HeroAvatarInitial({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GroupPlanningUi.forestTint,
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: GroupPlanningUi.forest,
        ),
      ),
    );
  }
}

/// Single-line status under the team hero strip — keeps continuity while
/// saving the vertical space of the old "Wie doet mee" card.
class _TeamHeroStatusLine extends StatelessWidget {
  const _TeamHeroStatusLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.82),
          height: 1.3,
        ),
      ),
    );
  }
}

/// Owner-side pill shown while an invited person hasn't joined yet.
class _InvitedWaitingPill extends StatelessWidget {
  const _InvitedWaitingPill({
    required this.l10n,
    required this.profile,
    required this.onNudge,
  });

  final AppLocalizations l10n;
  final MoodMatchInvitedProfile profile;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    final label = profile.displayLabel;
    final initial = label.replaceAll('@', '').trim().isNotEmpty
        ? label.replaceAll('@', '').trim()[0].toUpperCase()
        : '?';
    final imageUrl = profile.imageUrl?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? WmNetworkImage(
                      imageUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        initial,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      initial,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.moodMatchInvitedWaitingTag,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l10n.moodMatchInvitedWaitingBody(profile.firstName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onNudge,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.moodMatchInvitedWaitingNudge,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rich "waiting for match to lock in" state shown after the current user has
/// locked in. Shows the friend's avatar + name so it's obvious WHO we're
/// waiting on; when the friend has also locked a mood, the emoji gets blurred
/// as a teaser so the reveal moment stays intact.
class _WaitingPreviewCard extends StatelessWidget {
  const _WaitingPreviewCard({
    required this.l10n,
    required this.friend,
    this.invitedFallback,
    required this.friendFirstName,
    required this.pulse,
  });

  final AppLocalizations l10n;
  final GroupMemberView? friend;

  /// When the invitee has not joined `group_session_members` yet, we still
  /// have their avatar from the in-app invite flow (local prefs).
  final MoodMatchInvitedProfile? invitedFallback;
  final String friendFirstName;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final locked = friend?.member.hasSubmittedMood == true;
    final friendEmoji = locked
        ? (kMoodMatchMoodEmoji[friend?.member.moodTag ?? ''] ?? '✨')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                GroupPlanningUi.forestTint,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: GroupPlanningUi.forest.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: GroupPlanningUi.forest.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WaitingFriendAvatar(
                friend: friend,
                invitedFallback: invitedFallback,
                pulse: pulse,
                locked: locked,
                friendEmoji: friendEmoji,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: pulse,
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (locked
                                      ? GroupPlanningUi.forest
                                      : const Color(0xFFE8784A))
                                  .withValues(alpha: 0.55 + pulse.value * 0.45),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (locked
                                  ? l10n.moodMatchWaitingTeaserTag
                                  : l10n.moodMatchStepAlmostTag)
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: locked
                                ? GroupPlanningUi.forest
                                : const Color(0xFFE8784A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      moodMatchWaitingPreviewHeadline(
                        l10n,
                        friendFirstName: friendFirstName,
                        locked: locked,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: GroupPlanningUi.charcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locked
                          ? l10n.moodMatchWaitingTeaserSub
                          : l10n.moodMatchWaitingOnSub(friendFirstName),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: GroupPlanningUi.stone,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.moodMatchWaitingQuietHint,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: GroupPlanningUi.stone,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Avatar used in the lobby waiting card. When the friend has also locked in
/// a mood we overlay a BLURRED emoji badge — same avatar, different story,
/// preserves the "reveal" moment for the result screen.
class _WaitingFriendAvatar extends StatelessWidget {
  const _WaitingFriendAvatar({
    required this.friend,
    this.invitedFallback,
    required this.pulse,
    required this.locked,
    required this.friendEmoji,
  });

  final GroupMemberView? friend;
  final MoodMatchInvitedProfile? invitedFallback;
  final AnimationController pulse;
  final bool locked;
  final String? friendEmoji;

  String? _avatarUrl() {
    final f = friend;
    if (f != null) {
      final u = f.avatarUrl?.trim();
      if (u != null && u.isNotEmpty) return u;
      final inv = invitedFallback;
      if (inv != null && inv.id == f.member.userId) {
        final iu = inv.imageUrl?.trim();
        if (iu != null && iu.isNotEmpty) return iu;
      }
      return null;
    }
    final iu = invitedFallback?.imageUrl?.trim();
    if (iu != null && iu.isNotEmpty) return iu;
    return null;
  }

  String _initialLabel() {
    final f = friend;
    if (f != null) {
      final dn = f.displayName.trim();
      if (dn.isNotEmpty) return dn[0].toUpperCase();
    }
    final inv = invitedFallback;
    if (inv != null) {
      final name = inv.fullName?.trim();
      if (name != null && name.isNotEmpty) return name[0].toUpperCase();
      final u = inv.username?.trim();
      if (u != null && u.isNotEmpty) return u[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final url = _avatarUrl();
    final initial = _initialLabel();

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, child) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (locked
                            ? GroupPlanningUi.forest
                            : const Color(0xFFE8784A))
                        .withValues(alpha: 0.25 + pulse.value * 0.45),
                    width: 2.2,
                  ),
                ),
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: url != null
                      ? SizedBox.expand(
                          child: WmNetworkImage(
                            url,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, __, ___) =>
                                _WaitingAvatarInitial(label: initial),
                          ),
                        )
                      : _WaitingAvatarInitial(label: initial),
                ),
              ),
            ),
          ),
          if (friendEmoji != null)
            Positioned(
              right: -4,
              bottom: -4,
              child: ClipOval(
                child: ImageFilteredWidget(
                  // Blurred mood emoji as a teaser — you know they're locked
                  // in, but the actual vibe stays hidden until the reveal.
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GroupPlanningUi.moodMatchShadow(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      friendEmoji!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaitingAvatarInitial extends StatelessWidget {
  const _WaitingAvatarInitial({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GroupPlanningUi.forestTint,
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: GroupPlanningUi.forest,
        ),
      ),
    );
  }
}

/// Applies a gaussian blur to its child — keeps the lobby teaser readable as
/// a silhouette-of-emoji without spoiling the actual mood choice.
class ImageFilteredWidget extends StatelessWidget {
  const ImageFilteredWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
      child: child,
    );
  }
}

/// Moody-voice tip bubble shown in the dark hero (not in the white body).
/// Keeps Moody's copy close to the Moody character so we save body height.
class _HeroMoodyTipBubble extends StatelessWidget {
  const _HeroMoodyTipBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🌀', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
