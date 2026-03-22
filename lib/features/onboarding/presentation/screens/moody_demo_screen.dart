import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/domain/enums/moody_feature.dart';

/// WanderMood design tokens — demo screen
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmSunset = Color(0xFFE8784A);
const Color _wmSunsetTint = Color(0xFFFDF0E8);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmCharcoal = Color(0xFF1E1C18);
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
  bool _isTyping = false;
  bool _showMoodOptions = false;
  String? _selectedMood;
  String? _bouncingKey;
  bool _showContinueCta = false;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

  /// Demo mood cards — keep existing hex colors (no gradient).
  static const List<Map<String, dynamic>> _demoMoodConfig = [
    {'key': 'adventurous', 'emoji': '🏃', 'colorHex': '#4CAF50'},
    {'key': 'relaxed', 'emoji': '😌', 'colorHex': '#80CBC4'},
    {'key': 'romantic', 'emoji': '💕', 'colorHex': '#F8BBD9'},
    {'key': 'cultural', 'emoji': '🎨', 'colorHex': '#B39DDB'},
    {'key': 'foodie', 'emoji': '🍕', 'colorHex': '#FFAB91'},
    {'key': 'social', 'emoji': '🎉', 'colorHex': '#FFF59D'},
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
        tween: Tween<double>(begin: 1.0, end: 1.12),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
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
    super.dispose();
  }

  Future<void> _startDemo() async {
    final l10n = AppLocalizations.of(context)!;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_DemoMessage(text: l10n.demoMoodyGreeting, isFromMoody: true));
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_DemoMessage(text: l10n.demoMoodyAskVibe, isFromMoody: true));
      _showMoodOptions = true;
    });
  }

  Future<void> _selectMood(String mood) async {
    if (_selectedMood != null) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    HapticFeedback.mediumImpact();
    setState(() => _bouncingKey = mood);
    _bounceController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _bouncingKey = null);
    _bounceController.reset();

    final moodLabel = _moodLabel(l10n, mood);
    setState(() {
      _selectedMood = mood;
      _showMoodOptions = false;
      _messages.add(
        _DemoMessage(
          text: l10n.demoUserFeeling(moodLabel),
          isFromMoody: false,
        ),
      );
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(
        _DemoMessage(
          text: _getMoodyResponse(l10n, mood),
          isFromMoody: true,
        ),
      );
      _showContinueCta = true;
    });
  }

  String _getMoodyResponse(AppLocalizations l10n, String mood) {
    switch (mood.toLowerCase()) {
      case 'adventurous':
        return l10n.demoMoodyResponseAdventurous;
      case 'relaxed':
        return l10n.demoMoodyResponseRelaxed;
      case 'romantic':
        return l10n.demoMoodyResponseRomantic;
      case 'cultural':
        return l10n.demoMoodyResponseCultural;
      case 'foodie':
        return l10n.demoMoodyResponseFoodie;
      case 'social':
        return l10n.demoMoodyResponseSocial;
      default:
        return l10n.demoMoodyResponseDefault;
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
              child: _buildChatArea(width),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 18, color: _wmSunset),
                    const SizedBox(width: 4),
                    Text(
                      l10n.demoMode,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _wmSunset,
                      ),
                    ),
                  ],
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
              l10n.introSkip,
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

  Widget _buildChatArea(double screenWidth) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        const SizedBox(height: 8),
        Column(
          children: [
            Center(
              child: ScaleTransition(
                alignment: Alignment.center,
                scale: _breathScale,
                child: MoodyCharacter(
                  size: 90,
                  mood: _isTyping ? 'thinking' : 'happy',
                  currentFeature: MoodyFeature.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.demoMoodyName,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _wmStone,
                height: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._messages.map((m) => _buildMessage(m, screenWidth)),
              if (_isTyping) _buildTypingIndicator(),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMessage(_DemoMessage message, double screenWidth) {
    final maxMoody = screenWidth * 0.8;
    final maxUser = screenWidth * 0.7;

    final bubble = message.isFromMoody
        ? Container(
            constraints: BoxConstraints(maxWidth: maxMoody),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _wmWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: _wmSky, width: 3),
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
                color: _wmCharcoal,
              ),
            ),
          )
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
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: _wmWhite,
              ),
            ),
          );

    final animated = Padding(
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
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 20,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );

    if (message.isFromMoody) {
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: animated,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: animated,
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _wmWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmParchment, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 6),
              _buildTypingDot(1),
              const SizedBox(width: 6),
              _buildTypingDot(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _wmForest.withValues(alpha: 0.35 + (value * 0.45)),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showMoodOptions) ...[
              Text(
                l10n.demoTapToSelectMood,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: _wmStone,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.85,
                children: _demoMoodConfig
                    .map((config) => _buildMoodCard(config))
                    .toList(),
              ),
            ] else if (_showContinueCta) ...[
              SizedBox(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.demoExploreMore,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _wmWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: _wmWhite, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    String h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  String _moodLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'adventurous':
        return l10n.demoMoodAdventurous;
      case 'relaxed':
        return l10n.demoMoodRelaxed;
      case 'romantic':
        return l10n.demoMoodRomantic;
      case 'cultural':
        return l10n.demoMoodCultural;
      case 'foodie':
        return l10n.demoMoodFoodie;
      case 'social':
        return l10n.demoMoodSocial;
      default:
        return key;
    }
  }

  Widget _buildMoodCard(Map<String, dynamic> config) {
    final String key = config['key'] as String;
    final String emoji = config['emoji'] as String;
    final Color moodColor = _colorFromHex(config['colorHex'] as String);
    final l10n = AppLocalizations.of(context)!;
    final String label = _moodLabel(l10n, key);
    Widget card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _selectedMood != null ? null : () => _selectMood(key),
        borderRadius: BorderRadius.circular(16),
        splashColor: moodColor.withValues(alpha: 0.2),
        highlightColor: moodColor.withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: moodColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmParchment, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _wmCharcoal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
