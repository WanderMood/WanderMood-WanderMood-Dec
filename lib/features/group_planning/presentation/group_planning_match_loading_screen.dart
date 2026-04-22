import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:wandermood/features/location/services/location_service.dart'
    as wm_location;
import 'package:wandermood/features/group_planning/data/mood_match_session_prefs.dart';
import 'package:wandermood/features/group_planning/domain/mood_match_copy.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// After the match reveal, user lands here: kick off / wait for `group_plans`
/// generation, then continue to [GroupPlanningResultScreen].
class GroupPlanningMatchLoadingScreen extends ConsumerStatefulWidget {
  const GroupPlanningMatchLoadingScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<GroupPlanningMatchLoadingScreen> createState() =>
      _GroupPlanningMatchLoadingScreenState();
}

class _GroupPlanningMatchLoadingScreenState
    extends ConsumerState<GroupPlanningMatchLoadingScreen> {
  /// Keeps the Moody loader on screen long enough to read (plan often exists immediately).
  static const Duration _kMinLoaderVisible = Duration(milliseconds: 3200);

  bool _working = true;
  String? _error;
  bool _navigated = false;
  DateTime? _loaderVisibleSince;

  /// Bumped on each retry so in-flight polls don’t navigate after dispose/restart.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final gen = ++_generation;
    if (!mounted || gen != _generation) return;

    _loaderVisibleSince = DateTime.now();

    setState(() {
      _working = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(groupPlanningRepositoryProvider);

    try {
      var plan = await repo.fetchPlan(widget.sessionId);
      if (!mounted || gen != _generation) return;
      if (plan != null) {
        unawaited(_goResult(gen));
        return;
      }

      final members = await repo.fetchMembersWithProfiles(widget.sessionId);
      if (!mounted || gen != _generation) return;

      final allMoods = members.length >= 2 &&
          members.every((m) => m.member.hasSubmittedMood);
      if (!allMoods) {
        context.go('/group-planning/lobby/${widget.sessionId}');
        return;
      }

      final pos = await ref.read(userLocationProvider.future);
      final lat = pos?.latitude ??
          (wm_location.LocationService.defaultLocation['latitude'] as double);
      final lng = pos?.longitude ??
          (wm_location.LocationService.defaultLocation['longitude'] as double);
      final locationAsync = ref.read(locationNotifierProvider);
      final rawCity = locationAsync.value?.trim();
      final city = (rawCity != null && rawCity.isNotEmpty)
          ? rawCity
          : (wm_location.LocationService.defaultLocation['name'] as String);
      final prefs = ref.read(preferencesProvider);
      // Owner picked a part of the day in the day picker → restrict the
      // plan to that single slot. When null, Moody plans the whole day.
      final pendingSlot =
          await MoodMatchSessionPrefs.readPendingTimeSlot(widget.sessionId);
      final plannedDateFallback =
          await MoodMatchSessionPrefs.readPlannedDate(widget.sessionId);

      await repo.tryGeneratePlanIfComplete(
        sessionId: widget.sessionId,
        latitude: lat,
        longitude: lng,
        city: city,
        communicationStyle: prefs.communicationStyle,
        languageCode: prefs.languagePreference,
        plannedDateFallback: plannedDateFallback,
        timeSlot: pendingSlot,
      );

      if (!mounted || gen != _generation) return;

      plan = await repo.fetchPlan(widget.sessionId);
      if (!mounted || gen != _generation) return;
      if (plan != null) {
        unawaited(_goResult(gen));
        return;
      }

      // Other device may still be writing the plan — poll briefly.
      for (var n = 0; n < 60; n++) {
        if (!mounted || gen != _generation) return;
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (!mounted || gen != _generation) return;

        try {
          final session = await repo.fetchSession(widget.sessionId);
          if (session.status == 'error') {
            setState(() {
              _working = false;
              _error = l10n.planLoadingErrorService;
            });
            return;
          }
          final p = await repo.fetchPlan(widget.sessionId);
          if (p != null) {
            unawaited(_goResult(gen));
            return;
          }
        } catch (_) {
          // Keep polling unless we exhaust attempts.
        }
      }

      if (!mounted || gen != _generation) return;
      setState(() {
        _working = false;
        _error = l10n.planLoadingErrorNetwork;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _working = false;
        _error = l10n.planLoadingErrorGeneric;
      });
    }
  }

  Future<void> _goResult(int gen) async {
    if (!mounted || gen != _generation || _navigated) return;
    _navigated = true;

    final since = _loaderVisibleSince;
    if (since != null) {
      final elapsed = DateTime.now().difference(since);
      if (elapsed < _kMinLoaderVisible) {
        await Future<void>.delayed(_kMinLoaderVisible - elapsed);
      }
    }

    if (!mounted || gen != _generation) return;
    context.go('/group-planning/result/${widget.sessionId}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_working,
      child: Scaffold(
        backgroundColor: GroupPlanningUi.cream,
        appBar: AppBar(
        backgroundColor: GroupPlanningUi.cream,
        elevation: 0,
        foregroundColor: GroupPlanningUi.charcoal,
        automaticallyImplyLeading: false,
        leading: _working
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () =>
                    context.go('/group-planning/reveal/${widget.sessionId}'),
              ),
        title: Text(
          moodMatchMatchLoadingAppBarTitle(l10n),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: GroupPlanningUi.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.05,
                  colors: [
                    Colors.white,
                    GroupPlanningUi.cream,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MoodyCharacter(
                    size: 72,
                    mood: 'happy',
                    glowOpacityScale: 1.1,
                  ),
                  const SizedBox(height: 28),
                  if (_working) ...[
                    Text(
                      moodMatchPlanBuildingMessage(l10n),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: GroupPlanningUi.charcoal,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.moodMatchPlanBuildSub,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: GroupPlanningUi.stone,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: GroupPlanningUi.forest,
                      ),
                    ),
                  ] else if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: GroupPlanningUi.stone,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GroupPlanningUi.primaryCta(
                      label: l10n.planLoadingTryAgain,
                      onPressed: () => unawaited(_run()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
