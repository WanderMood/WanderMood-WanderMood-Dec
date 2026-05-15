import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_providers.dart';
import 'package:wandermood/features/group_planning/presentation/group_planning_ui.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/plan_met_vriend_plan_card.dart';
import 'package:wandermood/l10n/app_localizations.dart';

final planMetVriendPlansProvider =
    FutureProvider.autoDispose<List<PlanMetVriendPlanListItem>>((ref) {
  return ref.read(planMetVriendServiceProvider).listMyFriendPlans();
});

class PlanMetVriendPlansScreen extends ConsumerStatefulWidget {
  const PlanMetVriendPlansScreen({super.key});

  @override
  ConsumerState<PlanMetVriendPlansScreen> createState() =>
      _PlanMetVriendPlansScreenState();
}

class _PlanMetVriendPlansScreenState
    extends ConsumerState<PlanMetVriendPlansScreen> {
  String? _deletingSessionId;
  int _tabIndex = 0;
  bool _tabIndexInitialized = false;

  Future<void> _confirmDelete(PlanMetVriendPlanListItem plan) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.planMetVriendDeleteInviteTitle),
        content: Text(
          plan.isHost
              ? l10n.planMetVriendDeleteInviteBodyHost
              : l10n.planMetVriendDeleteInviteBodyGuest,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.planMetVriendDeleteInviteConfirm,
              style: const TextStyle(color: Color(0xFFE05C5C)),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deletingSessionId = plan.sessionId);
    try {
      await ref.read(planMetVriendServiceProvider).cancelFriendPlan(
            sessionId: plan.sessionId,
            isHost: plan.isHost,
            groupRepo: ref.read(groupPlanningRepositoryProvider),
          );
      ref.invalidate(planMetVriendPlansProvider);
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.planMetVriendDeleteInviteSuccess,
        );
      }
    } catch (_) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: l10n.planMetVriendDeleteInviteError,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _deletingSessionId = null);
    }
  }

  void _openPlan(PlanMetVriendPlanListItem plan) {
    if (plan.cardKind == PlanMetVriendPlanCardKind.waiting && plan.isHost) {
      context.pushNamed(
        'wishlist-pending-plan',
        pathParameters: {'sessionId': plan.sessionId},
        extra: plan,
      );
      return;
    }
    context.pushNamed(
      'wishlist-day-picker',
      pathParameters: {'sessionId': plan.sessionId},
    );
  }

  void _maybeSelectCompletedTab(List<PlanMetVriendPlanListItem> plans) {
    if (_tabIndexInitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabIndexInitialized) return;
      final active = plans.where((p) => !p.isCompleted).length;
      final completed = plans.where((p) => p.isCompleted).length;
      setState(() {
        _tabIndexInitialized = true;
        if (active == 0 && completed > 0) _tabIndex = 1;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(planMetVriendPlansProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(planMetVriendPlansProvider);
    final safeTop = MediaQuery.paddingOf(context).top;
    const sheetOverlap = 26.0;
    final heroHeight = safeTop + 248.0;

    return Scaffold(
      backgroundColor: GroupPlanningUi.moodMatchDeep,
      body: async.when(
        loading: () => Stack(
          fit: StackFit.expand,
          children: [
            _HeroHeader(l10n: l10n, safeTop: safeTop, heroHeight: heroHeight),
            Positioned(
              top: heroHeight - sheetOverlap,
              left: 0,
              right: 0,
              bottom: 0,
              child: const _CreamSheet(
                child: Center(
                  child: CircularProgressIndicator(
                    color: GroupPlanningUi.forest,
                  ),
                ),
              ),
            ),
            _BackButton(safeTop: safeTop),
          ],
        ),
        error: (e, _) => Stack(
          fit: StackFit.expand,
          children: [
            _HeroHeader(l10n: l10n, safeTop: safeTop, heroHeight: heroHeight),
            Positioned(
              top: heroHeight - sheetOverlap,
              left: 0,
              right: 0,
              bottom: 0,
              child: _CreamSheet(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.planMetVriendPlansLoadError,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: GroupPlanningUi.stone,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(planMetVriendPlansProvider),
                          style: FilledButton.styleFrom(
                            backgroundColor: GroupPlanningUi.forest,
                          ),
                          child: Text(l10n.planMetVriendPickDateDone),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _BackButton(safeTop: safeTop),
          ],
        ),
        data: (plans) {
          _maybeSelectCompletedTab(plans);
          final activePlans =
              plans.where((p) => !p.isCompleted).toList(growable: false);
          final completedPlans =
              plans.where((p) => p.isCompleted).toList(growable: false);
          final visiblePlans =
              _tabIndex == 0 ? activePlans : completedPlans;

          return Stack(
            fit: StackFit.expand,
            children: [
              _HeroHeader(
                l10n: l10n,
                safeTop: safeTop,
                heroHeight: heroHeight,
              ),
              Positioned(
                top: heroHeight - sheetOverlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: _CreamSheet(
                  child: RefreshIndicator(
                    color: GroupPlanningUi.forest,
                    onRefresh: () async {
                      ref.invalidate(planMetVriendPlansProvider);
                      await ref.read(planMetVriendPlansProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: GroupPlanningUi.stone
                                  .withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        _InfoCard(l10n: l10n),
                        const SizedBox(height: 18),
                        GroupPlanningActiveCompletedToggle(
                          activeLabel: l10n.moodMatchHubTabActive,
                          completedLabel: l10n.moodMatchHubTabCompleted,
                          selectedIndex: _tabIndex,
                          onSelected: (i) => setState(() => _tabIndex = i),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tabIndex == 0
                              ? l10n.planMetVriendPlansTabActiveHint
                              : l10n.planMetVriendPlansTabCompletedHint,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: GroupPlanningUi.charcoal,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (visiblePlans.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: Text(
                                _tabIndex == 0
                                    ? (plans.isEmpty
                                        ? l10n.planMetVriendPlansEmpty
                                        : l10n.planMetVriendPlansTabActiveEmpty)
                                    : l10n.planMetVriendPlansTabCompletedEmpty,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: GroupPlanningUi.stone,
                                ),
                              ),
                            ),
                          )
                        else
                          ...visiblePlans.map((plan) {
                            final isDeleting =
                                _deletingSessionId == plan.sessionId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Dismissible(
                                key: ValueKey(plan.sessionId),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => _confirmDelete(plan)
                                    .then((_) => false),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE05C5C),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                child: PlanMetVriendPlanCard(
                                  plan: plan,
                                  isBusy: isDeleting,
                                  onTap: isDeleting
                                      ? null
                                      : () => _openPlan(plan),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              _BackButton(safeTop: safeTop),
            ],
          );
        },
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.l10n,
    required this.safeTop,
    required this.heroHeight,
  });

  final AppLocalizations l10n;
  final double safeTop;
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    const sheetOverlap = 26.0;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: heroHeight + sheetOverlap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GroupPlanningUi.moodMatchDeepSurface,
              GroupPlanningUi.moodMatchDeep,
            ],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, safeTop + 48, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBFD8FF).withValues(alpha: 0.2),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const MoodyCharacter(
                  size: 72,
                  mood: 'happy',
                  glowOpacityScale: 0.42,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.planMetVriendPlansTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.planMetVriendPlansHeroSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.planMetVriendPlansHeroHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE6DA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GroupPlanningUi.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GroupPlanningUi.forestTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: GroupPlanningUi.forest,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planMetVriendPlansInfoTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: GroupPlanningUi.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.planMetVriendPlansInfoBody,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.4,
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

class _CreamSheet extends StatelessWidget {
  const _CreamSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      child: Material(
        color: GroupPlanningUi.cream,
        elevation: 14,
        shadowColor: GroupPlanningUi.moodMatchDeep.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        child: child,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.safeTop});

  final double safeTop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: safeTop + 4,
      left: 4,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/main');
          }
        },
      ),
    );
  }
}
