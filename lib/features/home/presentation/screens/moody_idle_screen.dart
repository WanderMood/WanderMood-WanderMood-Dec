import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/services/moody_idle_message_service.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Solid base behind frosted glass — one tone per four idle time buckets.
const Map<MoodyIdleState, Color> kIdleBackgroundColors = {
  MoodyIdleState.morning: Color(0xFF2D1B00), // warm sunrise amber
  MoodyIdleState.day: Color(0xFF001A2D), // daylight blue
  MoodyIdleState.evening: Color(0xFF1A0D2E), // dusk purple
  MoodyIdleState.night: Color(0xFF0D1B2A), // night / rest
};

/// Full-screen idle welcome (four [MoodyIdleState] buckets). Wire [onComplete] after
/// the user taps Moody and the wake sequence finishes.
///
/// For [MoodyIdleState.day], pass [dayInterestCategory] with lowercase
/// `outdoor`, `food`, `culture`, `social` — props default to ✨.
class MoodyIdleScreen extends StatefulWidget {
  const MoodyIdleScreen({
    super.key,
    required this.idleState,
    required this.wakeMessage,
    this.dayInterestCategory,
    this.userPreferences,
    this.topInterest,
    this.onComplete,
  });

  final MoodyIdleState idleState;

  /// Shown after the wake animation — must align with [onComplete] (plan vs mood).
  final String wakeMessage;

  /// Optional interest hint for the [MoodyIdleState.day] bucket (floating props).
  final String? dayInterestCategory;

  /// Passed through to `generate_hub_message` as `user_preferences` (optional).
  final Map<String, dynamic>? userPreferences;

  /// e.g. first entry from `user_preference_patterns.top_rated_activities`.
  final String? topInterest;

  final VoidCallback? onComplete;

  /// Prop emoji for the day bucket when [dayInterestCategory] is absent or unknown.
  static String dayPropForInterest(String? category) {
    switch (category?.toLowerCase().trim()) {
      case 'outdoor':
      case 'outdoors':
        return '🌿';
      case 'food':
      case 'foodie':
        return '🍕';
      case 'culture':
      case 'cultural':
        return '🎨';
      case 'social':
        return '👥';
      default:
        return '✨';
    }
  }

  @override
  State<MoodyIdleScreen> createState() => _MoodyIdleScreenState();
}

class _MoodyIdleScreenState extends State<MoodyIdleScreen>
    with TickerProviderStateMixin {
  late _IdleCopy _copy;
  late final _IdleVisuals _visuals;
  bool _idleBootstrapDone = false;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  late final AnimationController _tapCtaPulseController;
  late final Animation<double> _tapCtaScale;

  late final AnimationController _wakePopController;
  late final Animation<double> _wakePopScale;

  late final AnimationController _exitFadeController;
  late final Animation<double> _exitFade;

  bool _hintVisible = false;
  bool _verboseTapHint = false;
  bool _woken = false;
  bool _showWakeLine = false;

  /// Filled from edge [MoodyIdleMessageService] when ready; before that, UI uses
  /// [_copy.fallbackMessage] so the first paint is never an empty "shimmer" bar.
  String? _idleAiText;

  @override
  void initState() {
    super.initState();

    _visuals = _IdleVisuals.forState(
      widget.idleState,
      dayEmoji: MoodyIdleScreen.dayPropForInterest(widget.dayInterestCategory),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _tapCtaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _tapCtaScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _tapCtaPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _wakePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wakePopScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 34,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 33,
      ),
    ]).animate(_wakePopController);

    _exitFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade =
        CurvedAnimation(parent: _exitFadeController, curve: Curves.easeOut);

    // After prefs: day 1 = full teaching CTA; day 2+ = one short line.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTapHint());
  }

  Future<void> _revealTapHint() async {
    final verbose = await MoodyIdleChecker.shouldShowVerboseIdleTapHint();
    if (!mounted) return;
    setState(() {
      _verboseTapHint = verbose;
      _hintVisible = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_idleBootstrapDone) return;
    _idleBootstrapDone = true;
    final l10n = AppLocalizations.of(context)!;
    _copy = _IdleCopy.forState(
      l10n,
      widget.idleState,
      wakeMessage: widget.wakeMessage,
    );
    _fetchIdleLine(
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  Future<void> _fetchIdleLine({required String languageCode}) async {
    final msg = await MoodyIdleMessageService.fetchIdleMessage(
      idleState: widget.idleState,
      languageCode: languageCode,
      userPreferences: widget.userPreferences,
      topInterest: widget.topInterest,
    );
    if (!mounted) return;
    final t = msg?.trim();
    if (t == null || t.isEmpty) return;
    setState(() {
      _idleAiText = t;
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _tapCtaPulseController.dispose();
    _wakePopController.dispose();
    _exitFadeController.dispose();
    super.dispose();
  }

  TextStyle get _wmBodyOnDark => GoogleFonts.poppins(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.7),
      );

  /// Prominent CTA on install day; one line afterward.
  Widget _buildTapToContinueCta() {
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = GoogleFonts.poppins(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final shortStyle = GoogleFonts.poppins(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.9),
    );

    return AnimatedOpacity(
      opacity: _hintVisible && !_woken ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: ScaleTransition(
        scale: _tapCtaScale,
        child: _verboseTapHint
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.moodyIdleTapMoodyHint,
                            style: titleStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.moodyIdleTapMoodySub,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.moodyIdleTapMoodyContinueShort,
                  textAlign: TextAlign.center,
                  style: shortStyle,
                ),
              ),
      ),
    );
  }

  Future<void> _onMoodyTap() async {
    if (_woken) return;
    // Haptic on first tap only — same path for all [MoodyIdleState] buckets.
    HapticFeedback.mediumImpact();
    setState(() => _woken = true);
    _breathController.stop();
    _tapCtaPulseController.stop();

    await _wakePopController.forward(from: 0);
    if (!mounted) return;
    setState(() => _showWakeLine = true);

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Prefer handing off (pop) while this route is still opaque. Fading to 0
    // *before* pop matched the splash issue: a blank frame on some iOS builds.
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }
    await _exitFadeController.forward();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Widget _buildIdleMoodyBody() {
    if (_woken) {
      return MoodyCharacter(
        key: ValueKey<bool>(_woken),
        size: 130,
        mood: _copy.awakeMoodLabel,
        mouthScaleFactor: _copy.awakeMouthScale,
        glowOpacityScale: 0.25,
        onTap: _onMoodyTap,
      );
    }
    switch (_visuals.idleAvatar) {
      case _IdleAvatarKind.drowsyOrb:
        return const _DrowsyMoodyOrb(size: 130);
      case _IdleAvatarKind.moodyCharacter:
        return MoodyCharacter(
          key: ValueKey<bool>(_woken),
          size: 130,
          mood: _copy.preWakeMoodLabel,
          mouthScaleFactor: _copy.preWakeMouthScale,
          glowOpacityScale: 0.25,
          onTap: _onMoodyTap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = kIdleBackgroundColors[widget.idleState]!;
    return Scaffold(
      backgroundColor: baseColor,
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_exitFade),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ColoredBox(color: baseColor),
            ),
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        _FloatingIdleProps(emoji: _visuals.propEmoji),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onMoodyTap,
                          child: AnimatedBuilder(
                            animation:
                                Listenable.merge([_breathScale, _wakePopScale]),
                            builder: (context, child) {
                              final scale = _woken
                                  ? _wakePopScale.value
                                  : _breathScale.value;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: _buildIdleMoodyBody(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showWakeLine
                          ? Text(
                              _copy.wakeMessage,
                              key: ValueKey<String>('wake-${widget.idleState}'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _wmBodyOnDark,
                            )
                          : Text(
                              _idleAiText ?? _copy.fallbackMessage,
                              key: ValueKey<String>(
                                'idle-${_idleAiText != null ? 'ai' : 'fb'}-'
                                '${widget.idleState}',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _wmBodyOnDark,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTapToContinueCta(),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Original sleep-only entry; same as [MoodyIdleScreen] in the [MoodyIdleState.night] look.
class MoodySleepScreen extends StatelessWidget {
  const MoodySleepScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MoodyIdleScreen(
      idleState: MoodyIdleState.night,
      wakeMessage: l10n.moodyIdleWelcomeBack,
      onComplete: onComplete,
    );
  }
}

// --- Copy / visuals config -------------------------------------------------

class _IdleCopy {
  const _IdleCopy({
    required this.fallbackMessage,
    required this.wakeMessage,
    required this.preWakeMoodLabel,
    required this.preWakeMouthScale,
    required this.awakeMoodLabel,
    required this.awakeMouthScale,
  });

  final String fallbackMessage;
  final String wakeMessage;
  final String preWakeMoodLabel;
  final double preWakeMouthScale;
  final String awakeMoodLabel;
  final double awakeMouthScale;

  static _IdleCopy forState(
    AppLocalizations l10n,
    MoodyIdleState s, {
    required String wakeMessage,
  }) {
    final nl = l10n.localeName.toLowerCase().startsWith('nl');
    switch (s) {
      case MoodyIdleState.morning:
        return _IdleCopy(
          fallbackMessage: nl
              ? 'Sorry vriend, ik was even koffie halen ☕'
              : 'Sorry friend, I was grabbing a coffee ☕',
          wakeMessage: wakeMessage,
          preWakeMoodLabel: 'idle',
          preWakeMouthScale: 1.0,
          awakeMoodLabel: 'idle',
          awakeMouthScale: 1.0,
        );
      case MoodyIdleState.day:
        return _IdleCopy(
          fallbackMessage: nl
              ? 'Ik was even op pad — klaar voor wat jij nu nodig hebt ✨'
              : 'I was out and about — ready for what you need now ✨',
          wakeMessage: wakeMessage,
          preWakeMoodLabel: 'idle',
          preWakeMouthScale: 1.1,
          awakeMoodLabel: 'idle',
          awakeMouthScale: 1.0,
        );
      case MoodyIdleState.evening:
        return _IdleCopy(
          fallbackMessage: nl
              ? 'Ik was even aan het afbouwen, maar ik ben er weer 🌙'
              : 'I was winding down, but I am back with you 🌙',
          wakeMessage: wakeMessage,
          preWakeMoodLabel: 'idle',
          preWakeMouthScale: 1.0,
          awakeMoodLabel: 'idle',
          awakeMouthScale: 1.0,
        );
      case MoodyIdleState.night:
        return _IdleCopy(
          fallbackMessage: nl
              ? 'Bijna slaapmodus, maar ik ben wakker voor jou 😴'
              : 'Almost in sleep mode, but I am up for you 😴',
          wakeMessage: wakeMessage,
          preWakeMoodLabel: 'sleeping',
          preWakeMouthScale: 1.0,
          awakeMoodLabel: 'idle',
          awakeMouthScale: 1.0,
        );
    }
  }
}

enum _IdleAvatarKind { drowsyOrb, moodyCharacter }

class _IdleVisuals {
  const _IdleVisuals({
    required this.propEmoji,
    required this.idleAvatar,
  });

  final String propEmoji;
  final _IdleAvatarKind idleAvatar;

  static _IdleVisuals forState(
    MoodyIdleState s, {
    required String dayEmoji,
  }) {
    switch (s) {
      case MoodyIdleState.morning:
        return const _IdleVisuals(
          propEmoji: '☕',
          idleAvatar: _IdleAvatarKind.moodyCharacter,
        );
      case MoodyIdleState.day:
        return _IdleVisuals(
          propEmoji: dayEmoji,
          idleAvatar: _IdleAvatarKind.moodyCharacter,
        );
      case MoodyIdleState.evening:
        return const _IdleVisuals(
          propEmoji: '🌙',
          idleAvatar: _IdleAvatarKind.moodyCharacter,
        );
      case MoodyIdleState.night:
        return const _IdleVisuals(
          propEmoji: '💤',
          idleAvatar: _IdleAvatarKind.drowsyOrb,
        );
    }
  }
}

// --- Moody orbs -------------------------------------------------------------

/// Nearly asleep: small eye slits + soft smile.
class _DrowsyMoodyOrb extends StatelessWidget {
  const _DrowsyMoodyOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DrowsyOrbPainter()),
    );
  }
}

class _DrowsyOrbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.15),
        radius: 0.95,
        colors: const [
          Color(0xFF9AAED0),
          Color(0xFF758BB5),
          Color(0xFF4F6B94),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bg);

    final shadow = Paint()
      ..color = const Color(0xFF4F6B94).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(c.dx, c.dy + 3), r * 0.92, shadow);

    final line = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.016)
      ..strokeCap = StrokeCap.round;

    final eyeY = c.dy - r * 0.1;
    final eyeSpread = r * 0.2;
    canvas.drawLine(
      Offset(c.dx - eyeSpread - r * 0.12, eyeY),
      Offset(c.dx - eyeSpread + r * 0.12, eyeY),
      line,
    );
    canvas.drawLine(
      Offset(c.dx + eyeSpread - r * 0.12, eyeY),
      Offset(c.dx + eyeSpread + r * 0.12, eyeY),
      line,
    );

    final mouth = Path()
      ..moveTo(c.dx - r * 0.2, c.dy + r * 0.2)
      ..quadraticBezierTo(
        c.dx,
        c.dy + r * 0.3,
        c.dx + r * 0.2,
        c.dy + r * 0.2,
      );
    canvas.drawPath(mouth, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Floating props ----------------------------------------------------------

class _FloatingIdleProps extends StatelessWidget {
  const _FloatingIdleProps({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _DriftingProp(index: 0, xOffset: -56, emoji: emoji),
        _DriftingProp(index: 1, xOffset: 12, emoji: emoji),
        _DriftingProp(index: 2, xOffset: 64, emoji: emoji),
      ],
    );
  }
}

class _DriftingProp extends StatefulWidget {
  const _DriftingProp({
    required this.index,
    required this.xOffset,
    required this.emoji,
  });

  final int index;
  final double xOffset;
  final String emoji;

  @override
  State<_DriftingProp> createState() => _DriftingPropState();
}

class _DriftingPropState extends State<_DriftingProp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    Future<void>.delayed(Duration(milliseconds: widget.index * 1000), () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dy = -60.0 * Curves.easeOut.transform(t);
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(widget.xOffset, dy),
          child: Opacity(
            opacity: opacity,
            child: Text(
              widget.emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, height: 1),
            ),
          ),
        );
      },
    );
  }
}
