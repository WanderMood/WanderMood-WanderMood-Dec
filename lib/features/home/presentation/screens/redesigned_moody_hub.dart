import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/screens/dynamic_my_day_provider.dart';

import 'package:wandermood/features/home/domain/enums/moody_feature.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_chat_sheet.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_feedback_prompt_card.dart';
import 'package:wandermood/features/home/presentation/providers/main_navigation_provider.dart';
import 'package:wandermood/features/home/presentation/providers/explore_intent_provider.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/localization/localized_mood_labels.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/services/moody_hub_message_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/group_planning/domain/group_session_models.dart'
    show GroupSessionRow, GroupMemberView;
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/home/presentation/widgets/mood_change_plan_bottom_sheet.dart';

/// WanderMood v2 design tokens (Moody Hub — active plan)
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFCEEE4);
const double _moodyHubComposerBottomGap = 12;

class RedesignedMoodyHub extends ConsumerStatefulWidget {
  const RedesignedMoodyHub({super.key});

  @override
  ConsumerState<RedesignedMoodyHub> createState() => _RedesignedMoodyHubState();
}

class _RedesignedMoodyHubState extends ConsumerState<RedesignedMoodyHub> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E9DD), // aligned with Moody chat sheet cream
      body: const MoodyChatTabView(),
    );
  }
}

// ---------------------------------------------------------------------------
// STATE A: User HAS an active day plan (redesign — wmCream, no Journey / Quick Actions)
// ---------------------------------------------------------------------------
class _MoodyHubWithPlan extends ConsumerStatefulWidget {
  final List<EnhancedActivityData> activities;
  final DailyMoodState moodState;

  const _MoodyHubWithPlan({
    required this.activities,
    required this.moodState,
  });

  @override
  ConsumerState<_MoodyHubWithPlan> createState() => _MoodyHubWithPlanState();
}

class _MoodyHubWithPlanState extends ConsumerState<_MoodyHubWithPlan>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  String _timeGreeting(AppLocalizations l10n) {
    final h = MoodyClock.now().hour;
    if (h < 12) return '${l10n.goodMorning}!';
    if (h < 18) return '${l10n.goodAfternoon}!';
    return '${l10n.goodEvening}!';
  }

  String _apiTimeOfDay() {
    final h = MoodyClock.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  void _openMoodyChat(BuildContext context) {
    showMoodyChatSheet(context, ref);
  }

  void _openChangeMoodSheet(BuildContext context) {
    unawaited(showMoodChangePlanBottomSheet(context));
  }

  Color _moodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'foodie':
      case 'foody':
        return const Color(0xFFF0C8A8); // wmTileFoodie
      case 'cultural':
      case 'cultureel':
        return const Color(0xFFBEB4D8); // wmTileCultureel
      case 'adventurous':
        return const Color(0xFFDC2626);
      case 'relaxed':
        return const Color(0xFF2A6049);
      case 'romantic':
        return const Color(0xFFEC4899);
      case 'energetic':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'foodie':
      case 'foody':
        return '🍽';
      case 'cultural':
      case 'cultureel':
        return '🎭';
      case 'adventurous':
        return '🧭';
      case 'relaxed':
        return '🧘';
      case 'romantic':
        return '💕';
      case 'energetic':
        return '⚡';
      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activities = widget.activities;
    final moods = widget.moodState.selectedMoods;

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 144),
            children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeGreeting(l10n),
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _wmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (moods.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _wmStone,
                          ),
                          children: [
                            TextSpan(text: l10n.moodyHubJourneyPrefix),
                            for (var i = 0; i < moods.length; i++) ...[
                              if (i > 0 && i == moods.length - 1)
                                TextSpan(text: l10n.moodyHubListAnd),
                              if (i > 0 && i < moods.length - 1)
                                TextSpan(text: l10n.moodyHubListComma),
                              TextSpan(
                                text: Localizations.localeOf(context)
                                            .languageCode ==
                                        'nl'
                                    ? localizedMoodDisplayLabel(l10n, moods[i])
                                        .toLowerCase()
                                    : localizedMoodDisplayLabel(l10n, moods[i]),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _moodColor(moods[i]),
                                ),
                              ),
                            ],
                            TextSpan(text: l10n.moodyHubJourneySuffix),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => _openMoodyChat(context),
              child: AnimatedBuilder(
                animation: _breathScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathScale.value,
                    child: child,
                  );
                },
                child: MoodyCharacter(
                  size: 110,
                  mood: 'idle',
                  mouthScaleFactor: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _openMoodyChat(context),
            child: _MoodyHubAiMessageLine(
              moods: moods,
              activitiesCount: activities.length,
              timeOfDay: _apiTimeOfDay(),
              languageCode: Localizations.localeOf(context).languageCode,
            ),
          ),
          const SizedBox(height: 16),
          const MoodMatchHubCard(compact: true),
          const SizedBox(height: 18),
          _MoodyHubMoodCard(
            moods: moods,
            moodColor: _moodColor,
            moodEmoji: _moodEmoji,
            moodLabel: (m) => localizedMoodDisplayLabel(l10n, m),
            onChangeMood: () => _openChangeMoodSheet(context),
                ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _wmForest,
                backgroundColor: _wmWhite,
                side: const BorderSide(color: _wmForest, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => _openChangeMoodSheet(context),
              child: Text(
                l10n.moodyHubChangeMood,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const MoodyFeedbackPromptCard(),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewPadding.bottom +
                _moodyHubComposerBottomGap,
            child: _MoodyChatComposer(
              label: l10n.myDayChatWithMoodyTitle,
              onTap: () => _openMoodyChat(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodyHubAiMessageLine extends ConsumerStatefulWidget {
  const _MoodyHubAiMessageLine({
    required this.moods,
    required this.activitiesCount,
    required this.timeOfDay,
    required this.languageCode,
  });

  final List<String> moods;
  final int activitiesCount;
  final String timeOfDay;
  final String languageCode;

  @override
  ConsumerState<_MoodyHubAiMessageLine> createState() =>
      _MoodyHubAiMessageLineState();
}

class _MoodyHubAiMessageLineState extends ConsumerState<_MoodyHubAiMessageLine>
    with SingleTickerProviderStateMixin {
  String? _message;
  String? _placeQuery;
  bool _loading = true;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(preferencesProvider);
    final prefsMap = <String, dynamic>{
      'communication_style': prefs.communicationStyle,
      'selected_moods': prefs.selectedMoods,
      'travel_interests': prefs.travelInterests,
      'planning_pace': prefs.planningPace,
      'budget_level': prefs.budgetLevel,
      'home_base': prefs.homeBase,
      'travel_styles': prefs.travelStyles,
    };
    final result = await MoodyHubMessageService.fetchHubMessage(
      currentMoods: widget.moods.isEmpty ? ['explorer'] : widget.moods,
      timeOfDay: widget.timeOfDay,
      activitiesCount: widget.activitiesCount,
      languageCode: widget.languageCode,
      userPreferences: prefsMap,
    );
    if (!mounted) return;
    setState(() {
      _message = result?.message;
      _placeQuery = result?.placeQuery;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nl = Localizations.localeOf(context).languageCode == 'nl';
    if (_loading) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.35 + 0.45 * _pulseController.value,
            child: Container(
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
                color: _wmParchment,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        },
      );
    }
    final fallback = nl
        ? 'Ik ben hier en klaar om met je dag mee te bewegen.'
        : 'I am here and ready to shape your day with you.';
    final query = _placeQuery?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            _message ?? fallback,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w400,
              color: _wmDusk,
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                ref.read(exploreSearchIntentProvider.notifier).state = query;
                ref.read(mainTabProvider.notifier).state = 1;
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _wmForest.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _wmForest.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  nl ? 'Toon in Explore: $query' : 'Show in Explore: $query',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _wmForest,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MoodMatchHubCard extends ConsumerStatefulWidget {
  const MoodMatchHubCard({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<MoodMatchHubCard> createState() => _MoodMatchHubCardState();
}

class _MoodMatchHubData {
  const _MoodMatchHubData({
    required this.session,
    required this.hasPlan,
    required this.savedToMyDay,
    required this.friendFirstName,
    required this.totalActive,
  });

  const _MoodMatchHubData.empty()
      : session = null,
        hasPlan = false,
        savedToMyDay = false,
        friendFirstName = null,
        totalActive = 0;

  final GroupSessionRow? session;
  final bool hasPlan;
  final bool savedToMyDay;
  final String? friendFirstName;
  final int totalActive;
}

class _MoodMatchHubCardState extends ConsumerState<MoodMatchHubCard> {
  late Future<_MoodMatchHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MoodMatchHubData> _load() async {
    final repo = ref.read(groupPlanningRepositoryProvider);
    final rows = await repo.fetchActiveSessionsForUser();
    if (rows.isEmpty) return const _MoodMatchHubData.empty();

    // Surface the most actionable session first so a single CTA is honest.
    final sorted = [...rows]..sort((a, b) {
        final cmp = _priority(b).compareTo(_priority(a));
        if (cmp != 0) return cmp;
        return b.session.updatedAt.compareTo(a.session.updatedAt);
      });
    final top = sorted.first;

    String? friendFirstName;
    try {
      final me = Supabase.instance.client.auth.currentUser?.id;
      final members = await repo.fetchMembersWithProfiles(top.session.id);
      if (members.isNotEmpty) {
        final other = members.firstWhere(
          (GroupMemberView m) => me == null || m.member.userId != me,
          orElse: () => members.first,
        );
        friendFirstName = _firstName(other.displayName);
      }
    } catch (_) {
      // Best-effort partner name; fall back to generic copy.
    }

    return _MoodMatchHubData(
      session: top.session,
      hasPlan: top.hasPlan,
      savedToMyDay: top.savedToMyDay,
      friendFirstName: friendFirstName,
      totalActive: rows.length,
    );
  }

  static int _priority(
    ({
      GroupSessionRow session,
      bool hasPlan,
      Map<String, dynamic>? planData,
      bool savedToMyDay,
    }) row,
  ) {
    final s = row.session.status;
    // Waiting on user action → top.
    if (s == 'day_proposed' || s == 'day_counter_proposed') return 5;
    if (row.hasPlan && row.session.completedAt == null) return 4;
    if (s == 'generating' || s == 'ready' || s == 'day_confirmed') return 3;
    if (s == 'waiting') return 2;
    return 1;
  }

  static String? _firstName(String displayName) {
    final t = displayName.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('@')) return t;
    final parts = t.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : t;
  }

  void _openMoodMatch({
    required GroupSessionRow? session,
    required bool hasPlan,
  }) {
    if (session == null) {
      context.go('/group-planning');
      return;
    }
    if (session.completedAt != null || hasPlan) {
      context.go('/group-planning/result/${session.id}');
      return;
    }
    if (session.status == 'day_proposed' ||
        session.status == 'day_counter_proposed') {
      context.go('/group-planning/day-picker/${session.id}');
      return;
    }
    if (session.status == 'generating' ||
        session.status == 'ready' ||
        session.status == 'day_confirmed') {
      context.go('/group-planning/match-loading/${session.id}');
      return;
    }
    context.go('/group-planning/lobby/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_MoodMatchHubData>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final data = snap.data ?? const _MoodMatchHubData.empty();
        final session = data.session;
        final hasActive = session != null;
        final name = data.friendFirstName;

        late final String subtitle;
        late final String cta;
        if (!hasActive) {
          subtitle = l10n.moodMatchHubEmptySub;
          cta = l10n.moodMatchHubCtaStart;
        } else if (data.savedToMyDay ||
            session.completedAt != null ||
            data.hasPlan) {
          subtitle = name == null
              ? l10n.moodMatchHubSubReady
              : l10n.moodMatchHubSubReadyWith(name);
          cta = l10n.moodMatchHubCtaOpenShared;
        } else if (session.status == 'day_proposed' ||
            session.status == 'day_counter_proposed') {
          subtitle = name == null
              ? l10n.moodMatchHubSubDayProposedNoName
              : l10n.moodMatchHubSubDayProposed(name);
          cta = l10n.moodMatchHubCtaReviewShared;
        } else if (session.status == 'waiting') {
          subtitle = name == null
              ? l10n.moodMatchHubSubWaitingJoinNoName
              : l10n.moodMatchHubSubWaitingJoin(name);
          cta = l10n.moodMatchHubCtaResume;
        } else {
          subtitle = name == null
              ? l10n.moodMatchHubSubBuilding
              : l10n.moodMatchHubSubBuildingWith(name);
          cta = l10n.moodMatchHubCtaResume;
        }

        final extraCount =
            data.totalActive > 1 ? data.totalActive - 1 : 0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.compact ? 14 : 16),
          decoration: BoxDecoration(
            color: _wmWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmParchment, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _wmSunsetTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      l10n.moodMatchHubBrandTag,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _wmSunset,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                maxLines: widget.compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: widget.compact ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: _wmCharcoal,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _wmSunset,
                    foregroundColor: _wmWhite,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(
                      vertical: widget.compact ? 10 : 12,
                    ),
                    elevation: 0,
                  ),
                  onPressed: loading
                      ? null
                      : () => _openMoodMatch(
                            session: session,
                            hasPlan: data.hasPlan,
                          ),
                  child: Text(
                    cta,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (extraCount > 0) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.go('/group-planning'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.moodMatchHubMoreSessions(extraCount),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _wmSunset,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _wmSunset,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MoodyHubMoodCard extends StatelessWidget {
  const _MoodyHubMoodCard({
    required this.moods,
    required this.moodColor,
    required this.moodEmoji,
    required this.moodLabel,
    required this.onChangeMood,
  });

  final List<String> moods;
  final Color Function(String) moodColor;
  final String Function(String) moodEmoji;
  final String Function(String) moodLabel;
  final VoidCallback onChangeMood;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (moods.isEmpty) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _wmParchment.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _wmParchment.withValues(alpha: 0.6),
            width: 0.5,
          ),
                  ),
                  child: Row(
                    children: [
            Expanded(
              child: Text(
                l10n.moodyHubNoMoodChosen,
                        style: GoogleFonts.poppins(
                  fontSize: 16,
                          fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                ),
              ),
            ),
            TextButton(
              onPressed: onChangeMood,
                child: Text(
                l10n.moodyHubChangeMood,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                  color: _wmForest,
                ),
              ),
          ),
        ],
      ),
    );
    }

    if (moods.length == 1) {
      final m = moods.first;
      final base = moodColor(m);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: base.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: base.withValues(alpha: 0.6),
            width: 0.5,
          ),
                ),
                child: Row(
                  children: [
            Text(moodEmoji(m), style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                moodLabel(m),
                      style: GoogleFonts.poppins(
                  fontSize: 16,
                        fontWeight: FontWeight.w700,
                  color: _wmCharcoal,
                ),
              ),
            ),
            TextButton(
              onPressed: onChangeMood,
                child: Text(
                l10n.moodyHubChangeMood,
                  style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _wmForest,
                ),
              ),
          ),
        ],
      ),
    );
    }

    final show = moods.take(3).toList();
    final first = moodColor(show.first);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
        color: first.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: first.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
          children: [
                for (final m in show) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                      color: moodColor(m).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      moodLabel(m),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onChangeMood,
                child: Text(
                l10n.moodyHubChangeMood,
                  style: GoogleFonts.poppins(
                  fontSize: 13,
                    fontWeight: FontWeight.w600,
                  color: _wmForest,
                ),
              ),
                ),
              ),
      ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATE B: User has NO active plan (Conversational AI Vibe)
// ---------------------------------------------------------------------------
class _MoodyHubNoPlan extends ConsumerStatefulWidget {
  final String greeting;
  final String emoji;
  /// Resolved locality (e.g. city) when known; null → copy without a hard-coded place name.
  final String? cityLabel;
  final bool cityLoading;

  const _MoodyHubNoPlan({
    required this.greeting,
    required this.emoji,
    required this.cityLabel,
    required this.cityLoading,
  });

  @override
  ConsumerState<_MoodyHubNoPlan> createState() => _MoodyHubNoPlanState();
}

class _MoodyHubNoPlanState extends ConsumerState<_MoodyHubNoPlan>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _noPlanBody(AppLocalizations l10n) {
    if (widget.cityLoading) return l10n.noPlanDayOpenLocating;
    final c = widget.cityLabel?.trim();
    if (c != null && c.isNotEmpty) return l10n.noPlanDayOpenInCity(c);
    return l10n.noPlanDayOpenAroundYou;
  }

  void _openMoodyChat(BuildContext context) {
    showMoodyChatSheet(context, ref);
  }

  void _openChangeMoodFromNoPlan(BuildContext context) {
    unawaited(showMoodChangePlanBottomSheet(context));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Screen 9 background split: sky tint top, cream bottom
        Positioned.fill(
          child: Column(
            children: const [
              Expanded(
                flex: 5,
                child: ColoredBox(color: Color(0xFFEDF5F9)),
              ),
              Expanded(
                flex: 5,
                child: ColoredBox(color: Color(0xFFF5F0E8)),
              ),
            ],
          ),
        ),

        // Main Content
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 104),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              const SizedBox(height: 16),

              // Moody Character Floating
              Center(
                child: GestureDetector(
                  onTap: () => _openMoodyChat(context),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFA8C8DC),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFA8C8DC).withOpacity(
                                  0.35 + (_pulseController.value * 0.15)),
                              blurRadius: 24 + (_pulseController.value * 14),
                              spreadRadius: 6 + (_pulseController.value * 6),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const SizedBox(
                      width: 120,
                      height: 120,
                      child: MoodyCharacter(
                        size: 120,
                        mood: 'happy',
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Chat Bubble
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: GestureDetector(
                  onTap: () => _openMoodyChat(context),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 0,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.greeting,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _noPlanBody(AppLocalizations.of(context)!),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeOut),
              ),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: MoodyFeedbackPromptCard(),
              ),

              const SizedBox(height: 24),

              // Action Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildChatActionChip(
                      icon: Icons.auto_awesome,
                      text: AppLocalizations.of(context)!.noPlanPlanMyWholeDay,
                      gradient: const [Color(0xFF2A6049), Color(0xFF2A6049)],
                      onTap: () => context.pushNamed('moody-standalone'),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 10),
                    const MoodMatchHubCard(compact: true),
                    const SizedBox(height: 12),
                    _buildChatActionChip(
                      icon: Icons.tune_rounded,
                      text: AppLocalizations.of(context)!.moodyHubChangeMood,
                      gradient: const [Color(0xFF2A6049), Color(0xFF2A6049)],
                      onTap: () => _openChangeMoodFromNoPlan(context),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 18),

                    // Plan later button — leave Moody for My Day. When already on
                    // `/main` (Moody tab), goNamed with extra alone often no-ops; set
                    // [mainTabProvider] and use a path with ?tab= so GoRouter rebuilds.
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).maybePop();
                          return;
                        }
                        ref.read(mainTabProvider.notifier).state = 0;
                        if (!context.mounted) return;
                        context.go('/main?tab=0');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.noPlanPlanLater,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom +
              _moodyHubComposerBottomGap,
          child: _MoodyChatComposer(
            label: AppLocalizations.of(context)!.noPlanJustChat,
            onTap: () => _openMoodyChat(context),
          ),
        ),
      ],
    );
  }

  Widget _buildChatActionChip({
    required IconData icon,
    required String text,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MoodyChatComposer extends StatelessWidget {
  const _MoodyChatComposer({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _wmWhite.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _wmWhite.withValues(alpha: 0.72), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: _wmForest, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _wmDusk,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: _wmForest,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Review Sheet (Quick Review for current activity)
// ---------------------------------------------------------------------------
class _ActivityReviewSheet extends ConsumerStatefulWidget {
  final EnhancedActivityData activity;

  const _ActivityReviewSheet({required this.activity});

  @override
  ConsumerState<_ActivityReviewSheet> createState() =>
      _ActivityReviewSheetState();
}

class _ActivityReviewSheetState extends ConsumerState<_ActivityReviewSheet> {
  int _rating = 0;
  String? _selectedEmoji;
  final TextEditingController _noteController = TextEditingController();

  List<_EmojiOption> _emojiOptions(AppLocalizations l10n) => [
        _EmojiOption('🤩', l10n.moodyReviewVibeAmazing),
        _EmojiOption('😊', l10n.moodyReviewVibeGood),
        _EmojiOption('😐', l10n.moodyReviewVibeOkay),
        _EmojiOption('😞', l10n.moodyReviewVibeMeh),
      ];

  String _ratingFeedbackText(AppLocalizations l10n) {
    switch (_rating) {
      case 5:
        return l10n.moodyReviewStarsFeedback5;
      case 4:
        return l10n.moodyReviewStarsFeedback4;
      case 3:
        return l10n.moodyReviewStarsFeedback3;
      case 2:
        return l10n.moodyReviewStarsFeedback2;
      case 1:
        return l10n.moodyReviewStarsFeedback1;
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        widget.activity.rawData['title'] as String? ?? l10n.dayPlanCardActivity;
    final timeStr =
        '${_formatTime(widget.activity.startTime)} – ${_formatTime(widget.activity.endTime)}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.moodyReviewTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7ED), Color(0xFFFFE4E6)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF97316)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('🛍️', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Star rating
                  Text(
                    l10n.moodyReviewHowWasIt,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isActive = star <= _rating;
                      return IconButton(
                        onPressed: () {
                          setState(() => _rating = star);
                        },
                        iconSize: 36,
                        splashRadius: 24,
                        icon: Icon(
                          Icons.star_rounded,
                          color: isActive
                              ? const Color(0xFFFACC15)
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _ratingFeedbackText(l10n),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Emoji vibe
                  Text(
                    l10n.moodyReviewYourVibe,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _emojiOptions(l10n).length,
                    itemBuilder: (context, index) {
                      final option = _emojiOptions(l10n)[index];
                      final selected = option.emoji == _selectedEmoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = selected ? null : option.emoji;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFFEC4899),
                                    ],
                                  )
                                : null,
                            color: selected ? null : Colors.white,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Optional note
                  Text(
                    l10n.moodyReviewOptionalNote,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: l10n.moodyReviewNoteHint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B5CF6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.moodyReviewNoteHelper,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating == 0
                        ? null
                        : () async {
                            final client = Supabase.instance.client;
                            final userId = client.auth.currentUser?.id;
                            if (userId == null) {
                              Navigator.of(context).pop();
                              return;
                            }

                            final raw = widget.activity.rawData;
                            final activityId = (raw['id'] as String?) ??
                                (raw['title'] as String? ?? '');
                            final activityName = raw['title'] as String? ??
                                l10n.dayPlanCardActivity;
                            final placeName = raw['placeName'] as String?;
                            final moodRaw = raw['mood'] as String?;
                            final mood = _selectedEmoji != null
                                ? _mapEmojiToMood(_selectedEmoji!)
                                : (moodRaw ?? 'unknown');

                            final rating = ActivityRating(
                              id: const Uuid().v4(),
                              userId: userId,
                              activityId: activityId,
                              activityName: activityName,
                              placeName: placeName,
                              stars: _rating,
                              tags: _selectedEmoji != null
                                  ? [_mapEmojiToLabel(_selectedEmoji!)]
                                  : [],
                              wouldRecommend: _rating >= 4,
                              notes: _noteController.text.isNotEmpty
                                  ? _noteController.text
                                  : null,
                              completedAt: MoodyClock.now(),
                              mood: mood,
                              googlePlaceId: raw['placeId'] as String?,
                            );

                            await ref
                                .read(activityRatingServiceProvider)
                                .saveRating(rating);

                            // Mark activity as completed in the shared activity status layer
                            ref
                                .read(activityManagerProvider.notifier)
                                .updateActivityStatus(
                                  activityId,
                                  ActivityStatus.completed,
                                );

                            // Refresh providers so My Day and Moody Hub stay in sync
                            ref.invalidate(todayActivitiesProvider);
                            ref.invalidate(
                                timelineCategorizedActivitiesProvider);
                            ref.invalidate(
                              activityRatingForActivityProvider(activityId),
                            );

                            if (!mounted) return;
                            Navigator.of(context).pop();
                            showWanderMoodToast(
                              context,
                              message: l10n.moodyReviewThanksToast,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      backgroundColor: const Color(0xFF2A6049),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded),
                        const SizedBox(width: 8),
                        Text(
                          l10n.moodyReviewSave,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rating == 0
                      ? l10n.moodyReviewNeedStars
                      : l10n.moodyReviewHelpsMoody,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
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

class _EmojiOption {
  final String emoji;
  final String label;
  const _EmojiOption(this.emoji, this.label);
}

String _mapEmojiToMood(String emoji) {
  switch (emoji) {
    case '🤩':
      return 'amazing';
    case '😊':
      return 'good';
    case '😐':
      return 'okay';
    case '😞':
      return 'meh';
    default:
      return 'unknown';
  }
}

String _mapEmojiToLabel(String emoji) {
  switch (emoji) {
    case '🤩':
      return 'Amazing';
    case '😊':
      return 'Good';
    case '😐':
      return 'Okay';
    case '😞':
      return 'Meh';
    default:
      return 'Unknown';
  }
}

// ---------------------------------------------------------------------------
// Exciting Get Ready Sheet (React-style hero, countdown, energy, playlist, shimmer)
// ---------------------------------------------------------------------------
class _ExcitingGetReadySheetContent extends StatefulWidget {
  final EnhancedActivityData activity;
  final DateTime leaveByTime;
  final int tripMinutes;
  final String transportMode;
  final double? weatherTemp;
  final String weatherCondition;
  final String weatherTip;
  final List<String> checklist;
  final String Function(DateTime) formatTime;
  final VoidCallback onOpenDirections;

  const _ExcitingGetReadySheetContent({
    required this.activity,
    required this.leaveByTime,
    required this.tripMinutes,
    required this.transportMode,
    required this.weatherTemp,
    required this.weatherCondition,
    required this.weatherTip,
    required this.checklist,
    required this.formatTime,
    required this.onOpenDirections,
  });

  @override
  State<_ExcitingGetReadySheetContent> createState() =>
      _ExcitingGetReadySheetContentState();
}

class _ExcitingGetReadySheetContentState
    extends State<_ExcitingGetReadySheetContent>
    with SingleTickerProviderStateMixin {
  final Set<int> _checkedIndices = {};
  bool _reminderOn = false;
  Duration? _countdown;
  Timer? _countdownTimer;
  late AnimationController _shimmerController;
  late final String _activityId;

  static const List<String> _checklistEmojis = [
    '💳',
    '📱',
    '🛍️',
    '👟',
    '💧',
    '🪪'
  ];

  @override
  void initState() {
    super.initState();
    _activityId = (widget.activity.rawData['id'] as String?) ??
        (widget.activity.rawData['title'] as String? ?? '');
    _loadPersistedState();
    _updateCountdown();
    _countdownTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _updateCountdown());
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  void _updateCountdown() {
    if (!mounted) return;
    final d = widget.activity.startTime.difference(MoodyClock.now());
    setState(() => _countdown = d.isNegative ? Duration.zero : d);
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('get_ready_state_$_activityId');
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic>? indices =
          decoded['checkedIndices'] as List<dynamic>?;
      final bool reminder = decoded['reminderOn'] as bool? ?? false;
      setState(() {
        _checkedIndices
          ..clear()
          ..addAll(indices?.map((e) => e as int) ?? const <int>[]);
        _reminderOn = reminder;
      });
    } catch (_) {
      // Swallow errors – fallback to default state
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'checkedIndices': _checkedIndices.toList(),
        'reminderOn': _reminderOn,
      };
      await prefs.setString('get_ready_state_$_activityId', jsonEncode(data));
    } catch (_) {
      // Ignore persistence failures for now
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = widget.checklist.length;
    final checked = _checkedIndices.length;
    final energyPercent = total > 0 ? (checked / total).clamp(0.0, 1.0) : 0.0;

    final hours = _countdown != null ? _countdown!.inHours : 0;
    final mins = _countdown != null ? (_countdown!.inMinutes % 60) : 0;

    final rawMood = widget.activity.rawData['mood'] as String?;
    final moodTag =
        (rawMood != null && rawMood.trim().isNotEmpty) ? rawMood : 'adventure';
    final themeKey = _playlistThemeKeyFromActivity(widget.activity.rawData);

    final reminderTime =
        widget.leaveByTime.subtract(const Duration(minutes: 10));

    return WillPopScope(
      onWillPop: () async {
        await _saveState();
        return true;
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Hero
                  _buildHero(l10n, hours, mins, reminderTime),
                  const SizedBox(height: 20),
                  // Energy meter
                  _buildEnergyMeter(l10n, energyPercent),
                  const SizedBox(height: 16),
                  // Weather
                  _buildWeatherCard(l10n),
                  const SizedBox(height: 16),
                  // Checklist
                  _buildChecklist(l10n),
                  const SizedBox(height: 16),
                  // Vibe Playlist
                  _buildVibePlaylist(l10n, moodTag, themeKey),
                  const SizedBox(height: 16),
                  // Reminder
                  _buildReminder(l10n, reminderTime),
                  const SizedBox(height: 16),
                  // Quick actions
                  _buildQuickActions(l10n),
                  const SizedBox(height: 24),
                  // CTA with shimmer
                  _buildShimmerCta(l10n),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(
      AppLocalizations l10n, int hours, int mins, DateTime reminderTime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEA580C), Color(0xFFEC4899), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    l10n.getReadyLetsGo,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.getReadyAdventureStartsIn,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _countdownBox('${hours.clamp(0, 99)}', l10n.getReadyHours),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(':',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                  _countdownBox('${mins.clamp(0, 59)}', l10n.getReadyMins),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.getReadyLeaveBy(
                            widget.formatTime(widget.leaveByTime)),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.getReadyTripSummary(
                            widget.transportMode, widget.tripMinutes),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: widget.onOpenDirections,
                    icon: const Icon(Icons.route_rounded,
                        size: 18, color: Colors.white),
                    label: Text(
                      '${l10n.getReadyRoute} →',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: -4,
            child: SizedBox(
              width: 64,
              height: 64,
              child: MoodyCharacter(
                size: 64,
                mood: 'excited',
                currentFeature: MoodyFeature.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMeter(AppLocalizations l10n, double percent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.getReadyYourAdventureEnergy,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E)),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.getReadyBoostEnergyHint,
            style: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFFB45309)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white70,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(AppLocalizations l10n) {
    final tempStr = widget.weatherTemp != null
        ? '${widget.weatherTemp!.toStringAsFixed(0)}°C, ${widget.weatherCondition}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFEFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌤️', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.getReadyWeatherAt(
                      widget.formatTime(widget.activity.startTime)),
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  tempStr,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.weatherTip,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l10n.getReadyPackEssentials,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.checklist.length, (i) {
            final checked = _checkedIndices.contains(i);
            final emoji =
                i < _checklistEmojis.length ? _checklistEmojis[i] : '✓';
            return InkWell(
              onTap: () {
                setState(() {
                  if (checked) {
                    _checkedIndices.remove(i);
                  } else {
                    _checkedIndices.add(i);
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.checklist[i],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: checked
                                  ? Colors.grey
                                  : const Color(0xFF111827),
                              decoration:
                                  checked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (checked)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                l10n.getReadyChecklistItemReady,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF2A6049),
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      checked
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 24,
                      color: checked
                          ? const Color(0xFF2A6049)
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _playlistThemeKeyFromActivity(Map<String, dynamic> raw) {
    final title = (raw['title'] as String? ?? '').toLowerCase();
    final cat = (raw['category'] as String? ?? '').toLowerCase();
    if (cat.contains('food') ||
        title.contains('restaurant') ||
        title.contains('dinner')) {
      return 'foodie';
    }
    if (cat.contains('culture') || title.contains('museum')) {
      return 'cultural';
    }
    if (cat.contains('shop') || title.contains('shopping')) {
      return 'shopping';
    }
    if (cat.contains('outdoor') || title.contains('park')) {
      return 'outdoor';
    }
    return 'adventure';
  }

  String _localizedPlaylistTheme(AppLocalizations l10n, String key) {
    switch (key) {
      case 'foodie':
        return l10n.getReadyPlaylistThemeFoodie;
      case 'cultural':
        return l10n.getReadyPlaylistThemeCultural;
      case 'shopping':
        return l10n.getReadyPlaylistThemeShopping;
      case 'outdoor':
        return l10n.getReadyPlaylistThemeOutdoor;
      case 'adventure':
      default:
        return l10n.getReadyPlaylistThemeAdventure;
    }
  }

  String _localizedMoodFragment(AppLocalizations l10n, String raw) {
    final m = raw.toLowerCase().trim();
    switch (m) {
      case 'adventure':
      case 'adventurous':
        return l10n.getReadyMoodFragmentAdventure;
      case 'relaxed':
        return l10n.getReadyMoodFragmentRelaxed;
      case 'energetic':
        return l10n.getReadyMoodFragmentEnergetic;
      case 'romantic':
        return l10n.getReadyMoodFragmentRomantic;
      case 'cultural':
      case 'culture':
      case 'cultureel':
        return l10n.getReadyMoodFragmentCultural;
      case 'explorer':
      case 'explore':
        return l10n.getReadyMoodFragmentExplorer;
      case 'foodie':
      case 'food':
        return l10n.getReadyMoodFragmentFoodie;
      default:
        if (raw.isEmpty) return l10n.getReadyMoodFragmentAdventure;
        return raw[0].toUpperCase() +
            (raw.length > 1 ? raw.substring(1).toLowerCase() : '');
    }
  }

  Widget _buildVibePlaylist(
      AppLocalizations l10n, String moodTag, String themeKey) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade100, Colors.pink.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note_rounded,
                color: Color(0xFF9333EA), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.getReadyVibePlaylist,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B21A8)),
                ),
                Text(
                  l10n.getReadyGetInMood(
                      _localizedMoodFragment(l10n, moodTag)),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF7C3AED)),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.getReadyPlaylistLabel(
                      _localizedPlaylistTheme(l10n, themeKey)),
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4C1D95)),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFF9333EA),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _onPlaylistTap(themeKey),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  l10n.getReadyPlay,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminder(AppLocalizations l10n, DateTime reminderTime) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.getReadyNudgeMe,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827)),
        ),
        subtitle: _reminderOn
            ? Text(
                l10n.getReadyReminderAt(widget.formatTime(reminderTime)),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF2A6049)),
              )
            : null,
        value: _reminderOn,
        onChanged: (value) {
          setState(() => _reminderOn = value);
          if (value) {
            showWanderMoodToast(
              context,
              message: l10n.getReadyReminderAt(widget.formatTime(reminderTime)),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.getReadyQuickActions,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _GradientActionChip(
            label: l10n.dayPlanCardDirections,
            icon: Icons.directions_rounded,
            gradient: const [Color(0xFF2A6049), Color(0xFF3D7A5F)],
            onTap: widget.onOpenDirections,
          ),
        ),
      ],
    );
  }

  Future<void> _onPlaylistTap(String themeKey) async {
    final l10n = AppLocalizations.of(context)!;
    final themeWord = _localizedPlaylistTheme(l10n, themeKey);
    final query = l10n.getReadyPlaylistSearchQuery(themeWord);
    final uri = Uri.parse(
      'https://open.spotify.com/search/${Uri.encodeComponent(query)}',
    );
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showPlaylistSnackBar();
      }
    } catch (_) {
      if (mounted) _showPlaylistSnackBar();
    }
  }

  void _showPlaylistSnackBar() {
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(
      context,
      message: l10n.getReadyVibePlaylist,
    );
  }

  Widget _buildShimmerCta(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1.0 + _shimmerController.value * 2, 0),
                      end: Alignment(_shimmerController.value * 2, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white24,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await _saveState();
            if (!mounted) return;
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A6049),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.getReadyPrimaryCta,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.getReadyCantWait,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _GradientActionChip({
    required this.label,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
String _formatTime(DateTime time) {
  final hour =
      time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
