import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/group_plan_place_mapper.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart'
    show GroupMemberView, GroupPlanRow;
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_labels.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_mood_visuals.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';
import 'package:wandermood/features/places/models/place.dart';
import 'package:wandermood/features/places/presentation/utils/save_explore_place_to_my_day.dart';
import 'package:wandermood/features/places/presentation/widgets/add_place_to_my_day_sheet.dart';
import 'package:wandermood/features/places/presentation/widgets/place_card.dart';
import 'package:wandermood/features/plans/data/services/scheduled_activity_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Change 6 — Shared Mood Match plan with activity reactions.
class GroupPlanningResultScreen extends ConsumerStatefulWidget {
  const GroupPlanningResultScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<GroupPlanningResultScreen> createState() =>
      _GroupPlanningResultScreenState();
}

class _GroupPlanningResultScreenState
    extends ConsumerState<GroupPlanningResultScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _planData;
  List<GroupMemberView> _members = [];
  bool _loading = true;
  String? _error;
  final Set<int> _addedIndices = {};
  int? _addingIndex;

  // Reactions: index → 'love' | 'skip' | 'swap'
  final Map<int, String> _myReactions = {};
  final Map<int, String> _theirReactions = {};

  late final AnimationController _header;

  static const _sunset = Color(0xFFE8784A);

  @override
  void initState() {
    super.initState();
    _header = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _load();
  }

  @override
  void dispose() {
    _header.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(groupPlanningRepositoryProvider);
      final results = await Future.wait([
        repo.fetchPlan(widget.sessionId),
        repo.fetchMembersWithProfiles(widget.sessionId),
      ]);
      final plan = results[0] as GroupPlanRow?;
      final members = results[1] as List<GroupMemberView>;
      if (!mounted) return;
      if (plan == null) {
        setState(() {
          _loading = false;
          _members = members;
          _error = l10n.groupPlanResultNoPlan;
        });
        return;
      }
      await MoodMatchSessionPrefs.clear();
      if (!mounted) return;

      _loadReactions(plan.planData, members);

      setState(() {
        _planData = plan.planData;
        _members = members;
        _loading = false;
      });
      _header.forward(from: 0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _loadReactions(Map<String, dynamic> planData, List<GroupMemberView> members) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final reactions = planData['reactions'] as Map<dynamic, dynamic>? ?? {};
    _myReactions.clear();
    _theirReactions.clear();
    for (final entry in reactions.entries) {
      final userId = entry.key as String;
      final userMap = entry.value as Map<dynamic, dynamic>? ?? {};
      final target = userId == uid ? _myReactions : _theirReactions;
      for (final r in userMap.entries) {
        final idx = int.tryParse(r.key.toString());
        if (idx != null) target[idx] = r.value.toString();
      }
    }
  }

  void _tapReaction(int index, String reaction) {
    HapticFeedback.selectionClick();
    final current = _myReactions[index];
    setState(() {
      if (current == reaction) {
        _myReactions.remove(index); // toggle off
      } else {
        _myReactions[index] = reaction;
      }
    });
    // Fire-and-forget save
    final repo = ref.read(groupPlanningRepositoryProvider);
    repo.updatePlanReaction(
      sessionId: widget.sessionId,
      activityIndex: index,
      reaction: _myReactions[index] ?? '',
    );
  }

  bool _hasConflict(int index) {
    final mine = _myReactions[index];
    final theirs = _theirReactions[index];
    if (mine == null || theirs == null) return false;
    return mine != theirs;
  }

  String _otherName() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    for (final m in _members) {
      if (m.member.userId != uid) {
        final s = m.displayName.trim();
        final beforeAt = s.split('@').first.trim();
        final parts = beforeAt.split(RegExp(r'\s+'));
        return parts.isNotEmpty ? parts.first : '?';
      }
    }
    return '?';
  }

  Future<void> _showAddSheet(Place place, int index) async {
    final user = Supabase.instance.client.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      if (mounted) {
        showWanderMoodToast(context,
            message: l10n.myDayAddSignInRequired, isError: true);
      }
      return;
    }

    final selectedDate = ref.read(selectedMyDayDateProvider);
    final planningDate = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);

    final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
    final occupied =
        await scheduledActivityService.getOccupiedTimeSlotKeysForPlaceOnDate(
      placeId: place.id,
      date: planningDate,
    );

    if (!mounted) return;
    if (occupied.length >= 3) {
      showWanderMoodToast(context,
          message: l10n.exploreAlreadyInDayPlan, isWarning: true);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPlaceToMyDaySheet(
        place: place,
        planningDate: planningDate,
        onTimeSelected: (startTime) async {
          final ok = await saveExplorePlaceToMyDay(
            context: context,
            ref: ref,
            place: place,
            startTime: startTime,
            photoSelectionSeed: 0,
          );
          if (ok && mounted) setState(() => _addedIndices.add(index));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: GroupPlanningUi.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: GroupPlanningUi.charcoal),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/main');
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      l10n.moodMatchTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: GroupPlanningUi.charcoal,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: _loading
                          ? GroupPlanningUi.stone
                          : GroupPlanningUi.charcoal,
                    ),
                    onPressed: _loading ? null : _load,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? _LoadingBody(l10n: l10n)
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: GroupPlanningUi.dusk, fontSize: 14),
                            ),
                          ),
                        )
                      : _buildScrollBody(l10n),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: GroupPlanningUi.forestTint,
                child: Text(
                  l10n.moodMatchResultFooterStrip,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: GroupPlanningUi.forest,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollBody(AppLocalizations l10n) {
    final recs = (_planData?['recommendations'] as List<dynamic>?) ?? [];
    final score = (_planData?['compatibilityScore'] as num?)?.toInt() ?? 78;
    final commStyle = ref.watch(preferencesProvider).communicationStyle;
    final moodyQuote = moodMatchMoodyParagraph(
      l10n,
      score,
      _planData?['moodyMessage'] as String?,
      commStyle,
    );
    final userLoc = ref.watch(userLocationProvider).valueOrNull;

    final withMood = _members.where((m) => m.member.hasSubmittedMood).toList();
    String initialsRow = '';
    String blendChip = l10n.moodMatchTagline;
    if (withMood.length >= 2) {
      final a = withMood[0];
      final b = withMood[1];
      final ia = a.displayName.isNotEmpty ? a.displayName[0].toUpperCase() : '?';
      final ib = b.displayName.isNotEmpty ? b.displayName[0].toUpperCase() : '?';
      initialsRow = '$ia + $ib';
      final ta = a.member.moodTag;
      final tb = b.member.moodTag;
      if (ta != null && tb != null) {
        final e1 = groupPlanMoodEmoji(ta);
        final e2 = groupPlanMoodEmoji(tb);
        final n1 = groupPlanLocalizedMoodTag(l10n, ta);
        final n2 = groupPlanLocalizedMoodTag(l10n, tb);
        blendChip = l10n.moodMatchBlendChip('$e1$e2', '$n1 · $n2');
      }
    }

    final headerSlide = CurvedAnimation(
      parent: _header,
      curve: Curves.easeOutCubic,
    );

    final otherName = _otherName();
    final myCount = _myReactions.length;
    final theirCount = _theirReactions.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.12),
              end: Offset.zero,
            ).animate(headerSlide),
            child: FadeTransition(
              opacity: headerSlide,
              child: _PremiumHeader(
                initialsRow: initialsRow,
                blendChip: blendChip,
                moodyQuote: moodyQuote,
                score: score,
                l10n: l10n,
              ),
            ),
          ),
          // ── Participant status bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _ParticipantStatus(
                    label: l10n.moodMatchFriendYou,
                    reviewed: myCount,
                    total: recs.length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ParticipantStatus(
                    label: otherName,
                    reviewed: theirCount,
                    total: recs.length,
                  ),
                ),
              ],
            ),
          ),
          // ── Activity cards ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              children: recs.asMap().entries.map((entry) {
                final index = entry.key;
                final m = Map<String, dynamic>.from(entry.value as Map);
                final place = placeFromGroupPlanRecommendation(
                  m,
                  sessionId: widget.sessionId,
                  index: index,
                );
                final added = _addedIndices.contains(index);
                final myReaction = _myReactions[index];
                final conflict = _hasConflict(index);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlaceCard(
                      place: place,
                      userLocation: userLoc,
                      photoSelectionSeed: 0,
                      cardMargin: EdgeInsets.zero,
                      showAddToMyDayButton: !added,
                      onAddToMyDayTap: added || _addingIndex != null
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              setState(() => _addingIndex = index);
                              try {
                                await _showAddSheet(place, index);
                              } finally {
                                if (mounted) setState(() => _addingIndex = null);
                              }
                            },
                      onTap: () => context.push('/place/${place.id}'),
                    )
                        .animate()
                        .fadeIn(
                          duration: 320.ms,
                          delay: Duration(milliseconds: 80 * index),
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 320.ms,
                          delay: Duration(milliseconds: 80 * index),
                          curve: Curves.easeOutCubic,
                        ),
                    // Reaction buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: Row(
                        children: [
                          _ReactionChip(
                            emoji: '👍',
                            label: l10n.moodMatchReactionLoveIt,
                            active: myReaction == 'love',
                            onTap: () => _tapReaction(index, 'love'),
                          ),
                          const SizedBox(width: 6),
                          _ReactionChip(
                            emoji: '👎',
                            label: l10n.moodMatchReactionSkip,
                            active: myReaction == 'skip',
                            onTap: () => _tapReaction(index, 'skip'),
                          ),
                          const SizedBox(width: 6),
                          _ReactionChip(
                            emoji: '🔄',
                            label: l10n.moodMatchReactionSwap,
                            active: myReaction == 'swap',
                            onTap: () => _tapReaction(index, 'swap'),
                          ),
                        ],
                      ),
                    ),
                    // Conflict banner
                    if (conflict) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _sunset.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _sunset.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                size: 15, color: _sunset),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.moodMatchConflictBanner(
                                    otherName, place.name),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _sunset,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (added)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Align(
                            key: const ValueKey('added'),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '✓ ${l10n.groupPlanResultAdded}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: GroupPlanningUi.stone,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
          // ── CTAs ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: GroupPlanningUi.primaryCta(
              label: l10n.moodMatchPlanSortedCta,
              onPressed: () =>
                  context.go('/group-planning/day-picker/${widget.sessionId}'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GroupPlanningUi.secondaryCta(
              label: l10n.groupPlanResultBackToApp,
              onPressed: () => context.go('/main'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? GroupPlanningUi.forest.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? GroupPlanningUi.forest.withValues(alpha: 0.4)
                : GroupPlanningUi.cardBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active
                    ? GroupPlanningUi.forest
                    : GroupPlanningUi.stone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantStatus extends StatelessWidget {
  const _ParticipantStatus({
    required this.label,
    required this.reviewed,
    required this.total,
  });

  final String label;
  final int reviewed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: GroupPlanningUi.softCardDecoration(
        background: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GroupPlanningUi.charcoal,
              ),
            ),
          ),
          Text(
            '$reviewed/$total',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: GroupPlanningUi.stone,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.initialsRow,
    required this.blendChip,
    required this.moodyQuote,
    required this.score,
    required this.l10n,
  });

  final String initialsRow;
  final String blendChip;
  final String moodyQuote;
  final int score;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fill = (score / 100).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: GroupPlanningUi.forest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (initialsRow.isNotEmpty)
            Text(
              initialsRow,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Text(
                blendChip,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            moodyQuote,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.25)),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.moodMatchResultCompatLine(
              score,
              moodMatchScoreBucketLabel(l10n, score),
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: GroupPlanningUi.forest,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.groupPlanResultLoadingMoody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: GroupPlanningUi.charcoal,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
