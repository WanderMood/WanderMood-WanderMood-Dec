import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/domain/enums/moody_feature.dart';

/// WanderMood design tokens — demo screen
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);

/// Interactive Demo Screen
///
/// Flow: Splash → Intro → **Demo** → Guest Explore → Signup → Main
class MoodyDemoScreen extends ConsumerStatefulWidget {
  const MoodyDemoScreen({super.key});

  @override
  ConsumerState<MoodyDemoScreen> createState() => _MoodyDemoScreenState();
}

class _MoodyDemoScreenState extends ConsumerState<MoodyDemoScreen>
    with TickerProviderStateMixin {
  bool _showMoodOptions = false;
  String? _selectedMood;
  String? _bouncingKey;
  bool _showContinueCta = false;
  bool _showPostTapTyping = false;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;
  late final AnimationController _pulseController;

  /// Demo mood cards — keep existing hex colors (no gradient).
  static const List<Map<String, dynamic>> _demoMoodConfig = [
    {'key': 'adventurous', 'emoji': '🏃', 'colorHex': '#4CAF50', 'label': 'Avontuurlijk'},
    {'key': 'relaxed', 'emoji': '😌', 'colorHex': '#80CBC4', 'label': 'Ontspannen'},
    {'key': 'romantic', 'emoji': '💕', 'colorHex': '#F8BBD9', 'label': 'Romantisch'},
    {'key': 'cultural', 'emoji': '🎨', 'colorHex': '#B39DDB', 'label': 'Cultureel'},
    {'key': 'foodie', 'emoji': '🍕', 'colorHex': '#FFAB91', 'label': 'Foodie'},
    {'key': 'social', 'emoji': '🎉', 'colorHex': '#FFF59D', 'label': 'Sociaal'},
  ];

  final List<_DemoMessage> _messages = [];
  bool _demoStarted = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_demoStarted && mounted) {
      _demoStarted = true;
      _startDemo();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startDemo() async {
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() {
      _messages.add(
        _DemoMessage(
          text: 'Hé! 👋 Ik ben Moody, je reismaatje.',
          isFromMoody: true,
        ),
      );
    });
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _messages.add(
        _DemoMessage(
          text:
              'Ik help je geweldige plekken ontdekken op basis van hoe je je voelt. Wat is je mood vandaag?',
          isFromMoody: true,
        ),
      );
      _showMoodOptions = true;
    });
  }

  Future<void> _selectMood(String mood) async {
    if (_selectedMood != null) return;
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _bouncingKey = mood);
    await _bounceController.forward(from: 0);
    if (!mounted) return;
    setState(() => _bouncingKey = null);
    _bounceController.reset();

    setState(() {
      _selectedMood = mood;
      _showMoodOptions = false;
      _messages.add(
        _DemoMessage(
          text: _userReplyDutch(mood),
          isFromMoody: false,
        ),
      );
      _showPostTapTyping = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _showPostTapTyping = false;
      _messages.add(
        _DemoMessage(
          text: _moodyResponseDutch(mood),
          isFromMoody: true,
        ),
      );
      _showContinueCta = true;
    });
  }

  String _userReplyDutch(String mood) {
    switch (mood.toLowerCase()) {
      case 'relaxed':
        return 'Ik voel me ontspannen';
      case 'adventurous':
        return 'Ik voel me avontuurlijk';
      case 'romantic':
        return 'Ik voel me romantisch';
      case 'cultural':
        return 'Ik voel me cultureel';
      case 'foodie':
        return 'Ik voel me als een foodie';
      case 'social':
        return 'Ik voel me sociaal';
      default:
        return 'Dit is mijn mood!';
    }
  }

  String _moodyResponseDutch(String mood) {
    switch (mood.toLowerCase()) {
      case 'relaxed':
        return 'Lekker rustig aan doen vandaag? Goed plan! 🌿';
      case 'adventurous':
        return 'Tijd voor avontuur! Ik weet precies wat je nodig hebt 🔥';
      case 'foodie':
        return 'Ik ken de lekkerste plekken in de stad 🍽';
      case 'social':
        return 'Gezelligheid zoeken? Ik regel het! 👥';
      case 'cultural':
        return 'Rotterdam\'s cultuurscene wacht op je 🎭';
      case 'romantic':
        return 'Een romantische dag? Moody heeft je 💕';
      default:
        return 'Mooi! Laten we gaan ontdekken ✨';
    }
  }

  void _onContinue() {
    ref.read(onboardingProgressProvider.notifier).markDemoCompleted();
    ref.read(currentOnboardingStepProvider.notifier).state = OnboardingStep.guestExplore;
    context.go('/guest-explore');
  }

  void _onSignUp() {
    context.go('/auth/magic-link');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: _wmCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMoodySection(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._messages.map((m) => _buildMessage(m, width)),
                          if (_showPostTapTyping) _buildPostTapTypingBubble(),
                        ],
                      ),
                    ),
                    if (_showMoodOptions) ...[
                      const SizedBox(height: 16),
                      _buildMoodTilesBlock(),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_showContinueCta) _buildContinueButtonFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/intro'),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _wmCharcoal,
            style: IconButton.styleFrom(
              foregroundColor: _wmCharcoal,
              backgroundColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _wmSunsetTint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _wmSunset, width: 0.5),
                ),
                child: Text(
                  '▶ Demomodus',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wmSunset,
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _onSignUp,
            style: TextButton.styleFrom(
              foregroundColor: _wmStone,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Overslaan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _wmStone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _wmSky.withValues(alpha: 0.18),
                      blurRadius: 36,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                alignment: Alignment.center,
                scale: _breathScale,
                child: MoodyCharacter(
                  size: 96,
                  mood: _showPostTapTyping ? 'thinking' : 'happy',
                  currentFeature: MoodyFeature.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Moody',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _wmDusk,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodyBubbleContent(String text, double maxW) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxW),
      decoration: BoxDecoration(
        color: _wmSkyTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmSky, width: 0.5),
      ),
      padding: const EdgeInsets.only(left: 8, right: 12, top: 10, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MoodyCharacter(
            size: 32,
            mood: 'idle',
            currentFeature: MoodyFeature.none,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w400,
                color: _wmCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_DemoMessage message, double screenWidth) {
    final maxMoody = screenWidth * 0.82;
    final maxUser = screenWidth * 0.72;

    final bubble = message.isFromMoody
        ? _buildMoodyBubbleContent(message.text, maxMoody)
        : Container(
            constraints: BoxConstraints(maxWidth: maxUser),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: _wmForest,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: _wmWhite,
              ),
            ),
          );

    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isFromMoody ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!message.isFromMoody) const Spacer(),
          bubble,
          if (message.isFromMoody) const Spacer(),
        ],
      ),
    );

    final animated = message.isFromMoody
        ? row
            .animate()
            .fadeIn(duration: 520.ms, curve: Curves.easeOut)
            .slideY(
              begin: 18,
              end: 0,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            )
        : row
            .animate()
            .fadeIn(duration: 520.ms, curve: Curves.easeOut)
            .slideY(
              begin: 18,
              end: 0,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            )
            .slideX(
              begin: 0.1,
              end: 0,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            );

    if (message.isFromMoody) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: animated,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: animated,
    );
  }

  Widget _buildPostTapTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _wmSkyTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmSky, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPulseDot(0),
              const SizedBox(width: 6),
              _buildPulseDot(1),
              const SizedBox(width: 6),
              _buildPulseDot(2),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, curve: Curves.easeOut);
  }

  Widget _buildPulseDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value * 2 * math.pi + index * (math.pi * 0.45);
        final opacity = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(t));
        return Opacity(
          opacity: opacity.clamp(0.35, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _wmSky,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodTilesBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tik om je mood te kiezen:',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: _wmStone,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: _demoMoodConfig
                .map(
                  (config) => AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildMoodCard(config),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButtonFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _wmForest,
              foregroundColor: _wmWhite,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: Text(
              'Ontdek meer →',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _wmWhite,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 250.ms).slideY(begin: 12, end: 0, duration: 280.ms),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    String h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  Widget _buildMoodCard(Map<String, dynamic> config) {
    final String key = config['key'] as String;
    final String emoji = config['emoji'] as String;
    final Color pastelBase = _colorFromHex(config['colorHex'] as String);
    final String label = config['label'] as String;
    const double tileRadius = 20;
    final bool isPressed = _bouncingKey == key;

    Widget card = GestureDetector(
      onTap: _selectedMood != null ? null : () => _selectMood(key),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tileRadius),
          color: pastelBase,
          border: Border.all(
            color: isPressed ? _wmForest : Colors.white.withValues(alpha: 0.6),
            width: isPressed ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(3, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(1, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tileRadius),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ScaleTransition(
      scale: _bouncingKey == key ? _bounceScale : const AlwaysStoppedAnimation(1.0),
      alignment: Alignment.center,
      child: card,
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _DemoMessage {
  final String text;
  final bool isFromMoody;

  _DemoMessage({
    required this.text,
    required this.isFromMoody,
  });
}
