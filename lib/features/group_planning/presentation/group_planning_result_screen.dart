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

/// Shared Mood Match plan — Explore-style [PlaceCard] rows + premium header.
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

  late final AnimationController _header;

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

  Future<void> _showAddSheet(Place place, int index) async {
    final user = Supabase.instance.client.auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.myDayAddSignInRequired,
          isError: true,
        );
      }
      return;
    }

    final selectedDate = ref.read(selectedMyDayDateProvider);
    final planningDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final scheduledActivityService = ref.read(scheduledActivityServiceProvider);
    final occupied =
        await scheduledActivityService.getOccupiedTimeSlotKeysForPlaceOnDate(
      placeId: place.id,
      date: planningDate,
    );

    if (!mounted) return;
    if (occupied.length >= 3) {
      showWanderMoodToast(
        context,
        message: l10n.exploreAlreadyInDayPlan,
        isWarning: true,
      );
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
          if (ok && mounted) {
            setState(() => _addedIndices.add(index));
          }
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
                                color: GroupPlanningUi.dusk,
                                fontSize: 14,
                              ),
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
      final ia =
          a.displayName.isNotEmpty ? a.displayName[0].toUpperCase() : '?';
      final ib =
          b.displayName.isNotEmpty ? b.displayName[0].toUpperCase() : '?';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                                if (mounted) {
                                  setState(() => _addingIndex = null);
                                }
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
          const SizedBox(height: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
