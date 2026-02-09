import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/domain/enums/moody_feature.dart';

/// Interactive Demo Screen
/// 
/// This screen shows users how "Talk to Moody" works with a simulated conversation.
/// Users can interact with Moody to see the value before signing up.
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
  bool _showActivities = false;
  String? _tappedMoodKey; // For tap animation on mood cards
  
  late AnimationController _fadeController;

  /// Rainbow colors for chat bubble left borders (bright & vibrant)
  static const List<Color> _rainbowBubbleColors = [
    Color(0xFFFF6B6B), // coral red
    Color(0xFFFF9F43), // vibrant orange
    Color(0xFFFECA57), // sunny yellow
    Color(0xFF1DD1A1), // mint green
    Color(0xFF00D2D3), // bright teal
    Color(0xFF54A0FF), // sky blue
    Color(0xFFA55EEA), // bright purple
    Color(0xFFFD79A8), // hot pink
    Color(0xFFFDCB6E), // sunflower
  ];

  /// Demo mood cards – vibrant, light palette (matching main app vibe but brighter). Label is localized via l10n.
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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
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
    _fadeController.dispose();
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
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    setState(() => _tappedMoodKey = mood);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _tappedMoodKey = null);
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() {
      _selectedMood = mood;
      _showMoodOptions = false;
      _messages.add(_DemoMessage(text: l10n.demoUserFeeling(mood), isFromMoody: false));
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final response = _getMoodyResponse(l10n, mood);
    setState(() {
      _isTyping = false;
      _messages.add(_DemoMessage(text: response, isFromMoody: true));
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _showActivities = true);
  }

  String _getMoodyResponse(AppLocalizations l10n, String mood) {
    switch (mood.toLowerCase()) {
      case 'adventurous': return l10n.demoMoodyResponseAdventurous;
      case 'relaxed': return l10n.demoMoodyResponseRelaxed;
      case 'romantic': return l10n.demoMoodyResponseRomantic;
      case 'cultural': return l10n.demoMoodyResponseCultural;
      case 'foodie': return l10n.demoMoodyResponseFoodie;
      case 'social': return l10n.demoMoodyResponseSocial;
      default: return l10n.demoMoodyResponseDefault;
    }
  }

  List<_DemoActivity> _getActivitiesForMood(String? mood, AppLocalizations l10n) {
    switch (mood?.toLowerCase()) {
      case 'adventurous':
        return [
          _DemoActivity(emoji: '🏔️', title: l10n.demoActTitleMountainTrailHike, subtitle: l10n.demoActSubScenic32, matchPercent: 95),
          _DemoActivity(emoji: '🚴', title: l10n.demoActTitleCityBikeTour, subtitle: l10n.demoActSubActive18, matchPercent: 88),
          _DemoActivity(emoji: '🧗', title: l10n.demoActTitleIndoorClimbing, subtitle: l10n.demoActSubThrilling25, matchPercent: 82),
        ];
      case 'relaxed':
        return [
          _DemoActivity(emoji: '☕', title: l10n.demoActTitleCozyCornerCafe, subtitle: l10n.demoActSubUnwinding08, matchPercent: 96),
          _DemoActivity(emoji: '🌳', title: l10n.demoActTitleBotanicalGarden, subtitle: l10n.demoActSubPeaceful21, matchPercent: 91),
          _DemoActivity(emoji: '🛁', title: l10n.demoActTitleWellnessSpa, subtitle: l10n.demoActSubRelaxation34, matchPercent: 85),
        ];
      case 'romantic':
        return [
          _DemoActivity(emoji: '🌅', title: l10n.demoActTitleSunsetViewpoint, subtitle: l10n.demoActSubMagical15, matchPercent: 94),
          _DemoActivity(emoji: '🍷', title: l10n.demoActTitleWineAndDine, subtitle: l10n.demoActSubIntimate09, matchPercent: 90),
          _DemoActivity(emoji: '🌸', title: l10n.demoActTitleRoseGardenWalk, subtitle: l10n.demoActSubStroll23, matchPercent: 86),
        ];
      case 'cultural':
        return [
          _DemoActivity(emoji: '🏛️', title: l10n.demoActTitleHistoryMuseum, subtitle: l10n.demoActSubExhibits12, matchPercent: 93),
          _DemoActivity(emoji: '🎭', title: l10n.demoActTitleLocalTheater, subtitle: l10n.demoActSubLive18, matchPercent: 87),
          _DemoActivity(emoji: '🎨', title: l10n.demoActTitleArtGallery, subtitle: l10n.demoActSubContemporary07, matchPercent: 84),
        ];
      case 'foodie':
        return [
          _DemoActivity(emoji: '🍕', title: l10n.demoActTitleLocalFavorite, subtitle: l10n.demoActSubTopReviewed05, matchPercent: 94),
          _DemoActivity(emoji: '☕', title: l10n.demoActTitleCozyCafe, subtitle: l10n.demoActSubBrunch09, matchPercent: 88),
          _DemoActivity(emoji: '🍷', title: l10n.demoActTitleWineBar, subtitle: l10n.demoActSubSmallPlates12, matchPercent: 85),
        ];
      case 'social':
        return [
          _DemoActivity(emoji: '🎉', title: l10n.demoActTitleRooftopBar, subtitle: l10n.demoActSubVibes11, matchPercent: 92),
          _DemoActivity(emoji: '🎮', title: l10n.demoActTitleArcadeLounge, subtitle: l10n.demoActSubGames07, matchPercent: 87),
          _DemoActivity(emoji: '🎵', title: l10n.demoActTitleLiveMusicSpot, subtitle: l10n.demoActSubTonightsGig15, matchPercent: 84),
        ];
      default:
        return [
          _DemoActivity(emoji: '🌟', title: l10n.demoActTitlePopularSpot, subtitle: l10n.demoActSubHighlyRated10, matchPercent: 90),
          _DemoActivity(emoji: '🎉', title: l10n.demoActTitleFunActivity, subtitle: l10n.demoActSubGreatToday15, matchPercent: 85),
          _DemoActivity(emoji: '🍽️', title: l10n.demoActTitleLocalFavorite, subtitle: l10n.demoActSubTopReviewed08, matchPercent: 82),
        ];
    }
  }

  void _onContinue() {
    // Mark demo as completed
    ref.read(onboardingProgressProvider.notifier).markDemoCompleted();
    ref.read(currentOnboardingStepProvider.notifier).state = OnboardingStep.guestExplore;
    
    // Navigate to guest explore
    context.go('/guest-explore');
  }

  void _onSignUp() {
    // Skip to signup
    context.go('/auth/magic-link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwirlBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header with demo badge
              _buildHeader(),
              
              // Chat area
              Expanded(
                child: _buildChatArea(),
              ),
              
              // Mood options or CTA
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go('/intro'),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.grey[700],
          ),
          
          const Spacer(),
          
          // Demo mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.demoMode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Skip button
          TextButton(
            onPressed: _onSignUp,
            child: Text(
              AppLocalizations.of(context)!.introSkip,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        
        // Moody character
        Center(
          child: Column(
            children: [
              MoodyCharacter(
                size: 100,
                mood: _isTyping ? 'thinking' : 'happy',
                currentFeature: MoodyFeature.none,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.demoMoodyName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Messages (with index for Moody bubble left-border color)
        ..._messages.asMap().entries.map((e) => _buildMessage(e.value, messageIndex: e.key)),
        
        // Typing indicator
        if (_isTyping) _buildTypingIndicator(),
        
        // Activity cards
        if (_showActivities) ...[
          const SizedBox(height: 16),
          ..._getActivitiesForMood(_selectedMood, AppLocalizations.of(context)!).map((activity) => 
            _buildActivityCard(activity)
          ),
        ],
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMessage(_DemoMessage message, {int? messageIndex}) {
    HapticFeedback.lightImpact();

    // Every bubble gets a rainbow left border (different color per message index)
    final int index = messageIndex ?? 0;
    final Color leftBorderColor = _rainbowBubbleColors[index % _rainbowBubbleColors.length];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromMoody 
            ? MainAxisAlignment.start 
            : MainAxisAlignment.end,
        children: [
          if (!message.isFromMoody) const Spacer(flex: 2),
          
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 12),
              decoration: BoxDecoration(
                gradient: message.isFromMoody 
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: message.isFromMoody ? Colors.white : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isFromMoody ? 4 : 20),
                  bottomRight: Radius.circular(message.isFromMoody ? 20 : 4),
                ),
                border: Border(
                  left: BorderSide(color: leftBorderColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isFromMoody 
                        ? Colors.black.withOpacity(0.08)
                        : const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isFromMoody ? Colors.grey[800] : Colors.white,
                  height: 1.4,
                  fontWeight: message.isFromMoody ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
          ).animate()
            .fadeIn(duration: 300.ms)
            .slideX(
              begin: message.isFromMoody ? -0.1 : 0.1,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 200.ms,
            ),
          
          if (message.isFromMoody) const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
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
            color: Colors.grey[400]?.withOpacity(0.5 + (value * 0.5)),
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(_DemoActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  activity.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Match percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${activity.matchPercent}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showMoodOptions) ...[
              Text(
                AppLocalizations.of(context)!.demoTapToSelectMood,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMoodCard(_demoMoodConfig[0])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMoodCard(_demoMoodConfig[1])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMoodCard(_demoMoodConfig[2])),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildMoodCard(_demoMoodConfig[3])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMoodCard(_demoMoodConfig[4])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMoodCard(_demoMoodConfig[5])),
                ],
              ),
            ] else if (_showActivities) ...[
              // CTA buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    '${AppLocalizations.of(context)!.demoExploreMore} ✨',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _onSignUp,
                child: Text(
                  AppLocalizations.of(context)!.demoReadyToSignUp,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(isActive: false),
                  const SizedBox(width: 8),
                  _buildDot(isActive: true),
                  const SizedBox(width: 8),
                  _buildDot(isActive: false),
                ],
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
      case 'adventurous': return l10n.demoMoodAdventurous;
      case 'relaxed': return l10n.demoMoodRelaxed;
      case 'romantic': return l10n.demoMoodRomantic;
      case 'cultural': return l10n.demoMoodCultural;
      case 'foodie': return l10n.demoMoodFoodie;
      case 'social': return l10n.demoMoodSocial;
      default: return key;
    }
  }

  Widget _buildMoodCard(Map<String, dynamic> config) {
    final String key = config['key'] as String;
    final String emoji = config['emoji'] as String;
    final Color moodColor = _colorFromHex(config['colorHex'] as String);
    final l10n = AppLocalizations.of(context)!;
    final String label = _moodLabel(l10n, key);
    final bool isTapped = _tappedMoodKey == key;

    return AnimatedScale(
      scale: isTapped ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _selectMood(key),
          borderRadius: BorderRadius.circular(16),
          splashColor: moodColor.withOpacity(0.3),
          highlightColor: moodColor.withOpacity(0.15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  moodColor.withOpacity(1.0),
                  moodColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: moodColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: moodColor.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 200.ms)
      .scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 200.ms,
        curve: Curves.easeOutBack,
      );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4CAF50) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
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

class _DemoActivity {
  final String emoji;
  final String title;
  final String subtitle;
  final int matchPercent;

  _DemoActivity({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.matchPercent,
  });
}

