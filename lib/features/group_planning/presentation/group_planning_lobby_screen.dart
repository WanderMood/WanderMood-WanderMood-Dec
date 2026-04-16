import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_labels.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_match_grid.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_visuals.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_share_qr_screen.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/settings/presentation/providers/user_preferences_provider.dart';
import 'package:wandermood/core/notifications/notification_copy.dart';
import 'package:wandermood/core/notifications/notification_ids.dart';
import 'package:wandermood/core/services/notification_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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
  final GlobalKey _shareLinkKey = GlobalKey();

  late final AnimationController _pulse;

  static const _charcoal = Color(0xFF1E1C18);
  int _lastMemberCount = 0;
  DateTime? _bothLockedAt;

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
      if (widget.autoShowInvite && _joinCodeDisplay != null && mounted) {
        _shareLink();
      }
    });
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
          .listen((_) async {
            await _refresh();
          }, onError: (_) => _startPollingFallback());

      _sessionSub = supabase
          .from('group_sessions')
          .stream(primaryKey: ['id'])
          .eq('id', widget.sessionId)
          .listen((_) async {
            await _refresh();
          }, onError: (_) => _startPollingFallback());
    } catch (_) {
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
        }
      }
      _lastMemberCount = count;

      final allSubmittedNow = members.length >= 2 &&
          members.every((m) => m.member.hasSubmittedMood);
      if (allSubmittedNow && _bothLockedAt == null) {
        _bothLockedAt = DateTime.now();
        // Trigger plan generation automatically once both moods are in.
        unawaited(_autoGenerateAndNavigate());
      }

      setState(() {
        _session = session;
        _members = members;
        _joinCodeDisplay ??= session.joinCode;
        _error = null;
        _planExists = plan != null;
      });
      if (plan != null && session.status == 'ready') {
        _poll?.cancel();
        _poll = null;
        if (mounted) {
          final startedAt = _bothLockedAt;
          final elapsed = startedAt == null
              ? const Duration(seconds: 2)
              : DateTime.now().difference(startedAt);
          final remaining = const Duration(milliseconds: 1500) - elapsed;
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
      if (mounted) setState(() => _error = e.toString());
      _startPollingFallback();
    }
  }

  Future<void> _autoGenerateAndNavigate() async {
    try {
      if (!mounted) return;
      final repo = ref.read(groupPlanningRepositoryProvider);
      final pos = await ref.read(userLocationProvider.future);
      final lat = pos?.latitude ?? 52.3676;
      final lng = pos?.longitude ?? 4.9041;
      final prefs = ref.read(preferencesProvider);
      await repo.tryGeneratePlanIfComplete(
        sessionId: widget.sessionId,
        latitude: lat,
        longitude: lng,
        communicationStyle: prefs.communicationStyle,
        languageCode: prefs.languagePreference,
      );
      await _refresh();
    } catch (_) {
      // Keep the existing error handling behavior.
    }
  }

  GroupMemberView? _friendMember(List<GroupMemberView> list) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in list) {
      if (m.member.userId != uid) return m;
    }
    return null;
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
      _members.length >= 2 && _members.every((m) => m.member.hasSubmittedMood);

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
    final beforeAt = s.split('@').first.trim();
    final parts = beforeAt.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '?';
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
      return l10n.groupPlanLobbyBuilding;
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

  Future<void> _shareLink() async {
    final code = _joinCodeDisplay;
    if (code == null || code.isEmpty) return;
    await showGroupPlanningShareSheet(
      context,
      sessionId: widget.sessionId,
      joinCode: code,
    );
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

    if (_allSubmitted && !_planExists && _session?.status != 'generating') {
      HapticFeedback.mediumImpact();
      setState(() => _submitting = true);
      try {
        final repo = ref.read(groupPlanningRepositoryProvider);
        final pos = await ref.read(userLocationProvider.future);
        final lat = pos?.latitude ?? 52.3676;
        final lng = pos?.longitude ?? 4.9041;
        final prefs = ref.read(preferencesProvider);
        await repo.tryGeneratePlanIfComplete(
          sessionId: widget.sessionId,
          latitude: lat,
          longitude: lng,
          communicationStyle: prefs.communicationStyle,
          languageCode: prefs.languagePreference,
        );
        await _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupPlanLobbySubmitError('$e'))),
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
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

      final pos = await ref.read(userLocationProvider.future);
      final lat = pos?.latitude ?? 52.3676;
      final lng = pos?.longitude ?? 4.9041;
      final prefs = ref.read(preferencesProvider);

      await repo.tryGeneratePlanIfComplete(
        sessionId: widget.sessionId,
        latitude: lat,
        longitude: lng,
        communicationStyle: prefs.communicationStyle,
        languageCode: prefs.languagePreference,
      );

      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupPlanLobbySubmitError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _primaryLabel(AppLocalizations l10n) {
    if (_session?.status == 'generating') {
      return l10n.groupPlanLobbyBuilding;
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
    return _charcoal;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final code = _joinCodeDisplay ?? '…';
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _charcoal,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _charcoal,
            padding: EdgeInsets.fromLTRB(8, topInset + 4, 8, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
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
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final s = 1.0 + _pulse.value * 0.12;
                        final o = 0.4 + _pulse.value * 0.6;
                        return Transform.scale(
                          scale: s,
                          child: Opacity(
                            opacity: o,
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const MoodyCharacter(size: 34, mood: 'happy'),
                  ],
                ),
                const SizedBox(height: 10),
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
            child: Container(
              decoration: const BoxDecoration(
                color: GroupPlanningUi.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: RefreshIndicator(
                color: GroupPlanningUi.forest,
                onRefresh: _refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 24),
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
                    const SizedBox(height: 14),
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
                    Container(
                      decoration: GroupPlanningUi.cardDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.groupPlanLobbyWhosIn,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GroupPlanningUi.charcoal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MembersList(
                            members: _members,
                            l10n: l10n,
                            pulse: _pulse,
                          ),
                        ],
                      ),
                    ),
                    if (!_currentUserLocked()) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: GroupPlanningUi.cardDecoration(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.moodMatchStepYourMood.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: GroupPlanningUi.stone,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.moodMatchFeelQuestion,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: GroupPlanningUi.charcoal,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.moodMatchPrivateHint(_friendThey(l10n)),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: GroupPlanningUi.stone,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: GroupPlanningUi.softCardDecoration(
                                background: GroupPlanningUi.forestTint,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🌀',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      moodMatchMoodyPickQuoteLine(
                                        l10n,
                                        commStyle,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        height: 1.35,
                                        color: GroupPlanningUi.forest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            GroupPlanningMoodMatchGrid(
                              selectedTag: _selectedMood,
                              onSelect: (tag) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedMood = tag);
                              },
                              enabled: !_submitting,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_currentUserLocked() && !_allSubmitted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: GroupPlanningUi.softCardDecoration(
                          background: const Color(0xFFFFF8E6),
                        ),
                        child: Text(
                          l10n.moodMatchWhileYouWaitHint(_friendThey(l10n)),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.35,
                            color: GroupPlanningUi.forest,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _lockButtonBg(l10n),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
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
                                        l10n.groupPlanLobbyBuilding,
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
    final moodTag = member.member.moodTag;
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
            color: Colors.black.withValues(alpha: 0.03),
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
                if (locked && moodTag != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: groupPlanMoodChipTint(moodTag),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${kMoodMatchMoodEmoji[moodTag] ?? '✨'} ${groupPlanLocalizedMoodTag(l10n, moodTag)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GroupPlanningUi.charcoal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!locked)
            _PulsingBadge(
              label: '● ${l10n.moodMatchLobbyChoosingBadge}',
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
                  '✓ ${l10n.moodMatchLobbyReadyBadge}',
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
            color: Colors.black.withValues(alpha: 0.03),
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
                color: Colors.black.withValues(alpha: 0.06),
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
  const _PulsingBadge({required this.label});

  final String label;

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
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: GroupPlanningUi.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GroupPlanningUi.cardBorder),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: GroupPlanningUi.stone,
          ),
        ),
      ),
    );
  }
}
