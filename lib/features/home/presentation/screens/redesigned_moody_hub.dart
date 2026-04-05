import 'dart:async';
import 'dart:convert';
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
import 'package:wandermood/features/home/presentation/screens/main_screen.dart';
import 'package:wandermood/features/mood/providers/daily_mood_state_provider.dart';
import 'package:wandermood/features/plans/presentation/screens/plan_loading_screen.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wandermood/core/localization/localized_mood_labels.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wandermood/features/mood/services/activity_rating_service.dart';
import 'package:wandermood/features/mood/models/activity_rating.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/services/moody_hub_message_service.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/services/connectivity_service.dart';
import 'package:wandermood/core/utils/offline_feedback.dart';

/// WanderMood v2 design tokens (Moody Hub — active plan)
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);
const Color _wmDusk = Color(0xFF4A4640);

class RedesignedMoodyHub extends ConsumerStatefulWidget {
  const RedesignedMoodyHub({super.key});

  @override
  ConsumerState<RedesignedMoodyHub> createState() => _RedesignedMoodyHubState();
}

class _RedesignedMoodyHubState extends ConsumerState<RedesignedMoodyHub> {
  String _timeGreeting(AppLocalizations l10n) {
    final hour = MoodyClock.now().hour;
    if (hour < 12) return '${l10n.goodMorning}!';
    if (hour < 17) return '${l10n.goodAfternoon}!';
    return '${l10n.goodEvening}!';
  }

  String _getTimeEmoji() {
    final hour = MoodyClock.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  String _getCityName() {
    final city = ref.read(locationNotifierProvider).value;
    return city ?? 'Rotterdam';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayActivities = ref.watch(todayActivitiesProvider);
    final dailyMoodState = ref.watch(dailyMoodStateNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // wmCream — QA / design system
      body: todayActivities.when(
        data: (activities) {
          final nonCancelled = activities
              .where((a) => a.status != ActivityStatus.cancelled)
              .toList();

          if (nonCancelled.isNotEmpty) {
            return _MoodyHubWithPlan(
              activities: nonCancelled,
              moodState: dailyMoodState,
            );
          }
          return _MoodyHubNoPlan(
            greeting: _timeGreeting(l10n),
            emoji: _getTimeEmoji(),
            city: _getCityName(),
          );
        },
        loading: () => _MoodyHubNoPlan(
          greeting: _timeGreeting(l10n),
          emoji: _getTimeEmoji(),
          city: _getCityName(),
        ),
        error: (_, __) => _MoodyHubNoPlan(
          greeting: _timeGreeting(l10n),
          emoji: _getTimeEmoji(),
          city: _getCityName(),
        ),
      ),
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

    final morningActivities =
        activities.where((a) => a.startTime.hour < 12).toList();
    final afternoonActivities = activities
        .where((a) => a.startTime.hour >= 12 && a.startTime.hour < 18)
        .toList();
    final eveningActivities =
        activities.where((a) => a.startTime.hour >= 18).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
          const SizedBox(height: 12),
          _MoodyHubAiMessageLine(
            moods: moods,
            activitiesCount: activities.length,
            timeOfDay: _apiTimeOfDay(),
            languageCode: Localizations.localeOf(context).languageCode,
          ),
          const SizedBox(height: 24),
          _MoodyHubMoodCard(
            moods: moods,
            moodColor: _moodColor,
            moodEmoji: _moodEmoji,
            moodLabel: (m) => localizedMoodDisplayLabel(l10n, m),
            onChangeMood: () => context.pushNamed('moody-standalone'),
                ),
                const SizedBox(height: 16),
          _JouwDagVandaagCard(
            morningCount: morningActivities.length,
            afternoonCount: afternoonActivities.length,
            eveningCount: eveningActivities.length,
            onViewMyDay: () {
                      ref.read(mainTabProvider.notifier).state = 0;
                    },
                  ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _wmForest,
                foregroundColor: _wmWhite,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () => _openMoodyChat(context),
              child: Text(
                l10n.myDayChatWithMoodyTitle,
            style: GoogleFonts.poppins(
              fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
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
                  onPressed: () => context.pushNamed('moody-standalone'),
                  child: Text(
                    l10n.moodyHubChangeMood,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                  onPressed: () {
                    ref.read(mainTabProvider.notifier).state = 1;
                  },
                  child: Text(
                    l10n.myDayQuickAddActivity,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const MoodyFeedbackPromptCard(),
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
      _message = result;
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
    final l10n = AppLocalizations.of(context)!;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
        _message ?? l10n.moodyHubFallbackAiMessage,
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

class _JouwDagVandaagCard extends StatelessWidget {
  const _JouwDagVandaagCard({
    required this.morningCount,
    required this.afternoonCount,
    required this.eveningCount,
    required this.onViewMyDay,
  });

  final int morningCount;
  final int afternoonCount;
  final int eveningCount;
  final VoidCallback onViewMyDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String actWord(int n) =>
        n == 1 ? l10n.moodyHubActivitySingular : l10n.moodyHubActivityPlural;
    final meta = GoogleFonts.poppins(
      fontSize: 13,
      height: 1.35,
      color: _wmStone,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _wmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wmParchment, width: 0.5),
        ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
            l10n.moodyHubYourDayToday,
                    style: GoogleFonts.poppins(
              fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _wmCharcoal,
                    ),
                  ),
          const SizedBox(height: 12),
                  Text(
            '🌅 ${l10n.timeLabelMorning} · $morningCount ${actWord(morningCount)}',
            style: meta,
          ),
          const SizedBox(height: 6),
          Text(
            '☀️ ${l10n.timeLabelAfternoon} · $afternoonCount ${actWord(afternoonCount)}',
            style: meta,
          ),
          const SizedBox(height: 6),
          Text(
            '🌙 ${l10n.timeLabelEvening} · $eveningCount ${actWord(eveningCount)}',
            style: meta,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onViewMyDay,
              style: TextButton.styleFrom(
                foregroundColor: _wmForest,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '${l10n.dayPlanViewMyDay} →',
                style: GoogleFonts.poppins(
                  fontSize: 14,
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
  final String city;

  const _MoodyHubNoPlan({
    required this.greeting,
    required this.emoji,
    required this.city,
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

  Future<void> _openPlanLoadingAfterMood({
    required String mood,
    required List<String> selectedMoods,
  }) async {
    ref.read(dailyMoodStateNotifierProvider.notifier).setMoodSelection(
          mood: mood,
          selectedMoods: selectedMoods,
        );
    final ok = await ref.read(connectivityServiceProvider).isConnected;
    if (!mounted) return;
    if (!ok) {
      showOfflineSnackBar(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanLoadingScreen(selectedMoods: selectedMoods),
      ),
    );
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Moody Character Floating
              Center(
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
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Chat Bubble
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                        AppLocalizations.of(context)!
                            .noPlanDayOpen(widget.city),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.5,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
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
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildChatActionChip(
                            icon: Icons.coffee,
                            text: AppLocalizations.of(context)!
                                .noPlanFindMeCoffee,
                            gradient: const [
                              Color(0xFF2A6049),
                              Color(0xFF2A6049)
                            ],
                            onTap: () {
                              unawaited(_openPlanLoadingAfterMood(
                                mood: 'Relaxed',
                                selectedMoods: const ['Relaxed'],
                              ));
                            },
                          ).animate().fadeIn(delay: 700.ms).slideY(
                              begin: 0.2, end: 0, curve: Curves.easeOut),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildChatActionChip(
                            icon: Icons.directions_run,
                            text:
                                AppLocalizations.of(context)!.noPlanGetMeMoving,
                            gradient: const [
                              Color(0xFF2A6049),
                              Color(0xFF2A6049)
                            ],
                            onTap: () {
                              unawaited(_openPlanLoadingAfterMood(
                                mood: 'Energetic',
                                selectedMoods: const ['Energetic'],
                              ));
                            },
                          ).animate().fadeIn(delay: 800.ms).slideY(
                              begin: 0.2, end: 0, curve: Curves.easeOut),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Just chat button
                    GestureDetector(
                      onTap: () => showMoodyChatSheet(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: const Color(0xFFE8E2D8), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF1E1C18), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.noPlanJustChat,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1C18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 900.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 12),

                    // Plan later button
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).maybePop();
                          return;
                        }
                        // Fallback for root route: send user back to main home tab.
                        context.goNamed('main', extra: {'tab': 0});
                      },
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
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
              
              const Spacer(flex: 3),
            ],
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
        Row(
          children: [
            Expanded(
              child: _GradientActionChip(
                label: l10n.getReadyQuickShare,
                icon: Icons.ios_share_rounded,
                gradient: const [Color(0xFFEA580C), Color(0xFFF59E0B)],
                onTap: _onShareTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientActionChip(
                label: l10n.getReadyQuickCalendar,
                icon: Icons.event_rounded,
                gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                onTap: _onCalendarTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientActionChip(
                label: l10n.getReadyQuickParking,
                icon: Icons.local_parking_rounded,
                gradient: const [Color(0xFF9333EA), Color(0xFF7C3AED)],
                onTap: _onParkingTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onShareTap() {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.activity.rawData['title'] as String? ??
        l10n.getReadyShareTitleFallback;
    final time = widget.formatTime(widget.activity.startTime);
    final message = l10n.getReadyShareInvite(title, time);
    Share.share(message);
  }

  Future<void> _onCalendarTap() async {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.activity.rawData['title'] as String? ??
        l10n.getReadyCalendarEventTitleFallback;
    final start = widget.activity.startTime.toUtc();
    final end = widget.activity.endTime.toUtc();
    final startStr = _formatIso8601Utc(start);
    final endStr = _formatIso8601Utc(end);
    final details = widget.activity.rawData['description'] as String? ??
        l10n.getReadyCalendarEventDetailsFallback;
    final location = widget.activity.rawData['address'] as String? ??
        widget.activity.rawData['location'] as String? ??
        '';

    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=$startStr/$endStr'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(location.toString())}',
    );
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showCalendarSnackBar();
      }
    } catch (_) {
      if (mounted) _showCalendarSnackBar();
    }
  }

  String _formatIso8601Utc(DateTime utc) {
    final y = utc.year;
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  void _showCalendarSnackBar() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showWanderMoodToast(
      context,
      message: l10n.getReadyCalendarOpenHint(l10n.getReadyQuickCalendar),
    );
  }

  void _onParkingTap() async {
    final loc = widget.activity.rawData['location'] as String?;
    Uri url;
    if (loc != null && loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=parking%20near%20$lat,$lng');
        } else {
          url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=parking');
        }
      } else {
        url = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=parking');
      }
    } else {
      url =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=parking');
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
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
