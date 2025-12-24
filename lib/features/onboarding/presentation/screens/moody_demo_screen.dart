import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/feature_flags_provider.dart';

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
  
  late AnimationController _fadeController;

  final List<_DemoMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Start the demo conversation
    _startDemo();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startDemo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Moody's greeting
    setState(() {
      _isTyping = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (!mounted) return;
    
    setState(() {
      _isTyping = false;
      _messages.add(_DemoMessage(
        text: "Hey there! 👋 I'm Moody, your travel buddy.",
        isFromMoody: true,
      ));
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    setState(() {
      _isTyping = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    setState(() {
      _isTyping = false;
      _messages.add(_DemoMessage(
        text: "I help you discover amazing places based on how you're feeling. What's your vibe today?",
        isFromMoody: true,
      ));
      _showMoodOptions = true;
    });
  }

  Future<void> _selectMood(String mood) async {
    if (!mounted) return;
    
    setState(() {
      _selectedMood = mood;
      _showMoodOptions = false;
      _messages.add(_DemoMessage(
        text: "I'm feeling $mood",
        isFromMoody: false,
      ));
    });
    
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (!mounted) return;
    
    setState(() {
      _isTyping = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // Get mood-specific response
    final response = _getMoodyResponse(mood);
    
    setState(() {
      _isTyping = false;
      _messages.add(_DemoMessage(
        text: response,
        isFromMoody: true,
      ));
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    setState(() {
      _showActivities = true;
    });
  }

  String _getMoodyResponse(String mood) {
    switch (mood.toLowerCase()) {
      case 'adventurous':
        return "Love that energy! 🔥 Here are some exciting spots that match your adventurous spirit...";
      case 'relaxed':
        return "Ah, a chill day! ☕ Let me find you some peaceful spots to unwind...";
      case 'romantic':
        return "How lovely! 💕 I've got some beautiful places perfect for romance...";
      case 'cultural':
        return "A curious explorer! 🎨 Check out these fascinating cultural gems...";
      default:
        return "Great choice! 🌟 Here are some perfect spots for your mood...";
    }
  }

  List<_DemoActivity> _getActivitiesForMood(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'adventurous':
        return [
          _DemoActivity(
            emoji: '🏔️',
            title: 'Mountain Trail Hike',
            subtitle: 'Scenic adventure • 3.2 km away',
            matchPercent: 95,
          ),
          _DemoActivity(
            emoji: '🚴',
            title: 'City Bike Tour',
            subtitle: 'Active exploration • 1.8 km away',
            matchPercent: 88,
          ),
          _DemoActivity(
            emoji: '🧗',
            title: 'Indoor Climbing',
            subtitle: 'Thrilling experience • 2.5 km away',
            matchPercent: 82,
          ),
        ];
      case 'relaxed':
        return [
          _DemoActivity(
            emoji: '☕',
            title: 'Cozy Corner Café',
            subtitle: 'Perfect for unwinding • 0.8 km away',
            matchPercent: 96,
          ),
          _DemoActivity(
            emoji: '🌳',
            title: 'Botanical Garden',
            subtitle: 'Peaceful escape • 2.1 km away',
            matchPercent: 91,
          ),
          _DemoActivity(
            emoji: '🛁',
            title: 'Wellness Spa',
            subtitle: 'Total relaxation • 3.4 km away',
            matchPercent: 85,
          ),
        ];
      case 'romantic':
        return [
          _DemoActivity(
            emoji: '🌅',
            title: 'Sunset Viewpoint',
            subtitle: 'Magical atmosphere • 1.5 km away',
            matchPercent: 94,
          ),
          _DemoActivity(
            emoji: '🍷',
            title: 'Wine & Dine',
            subtitle: 'Intimate setting • 0.9 km away',
            matchPercent: 90,
          ),
          _DemoActivity(
            emoji: '🌸',
            title: 'Rose Garden Walk',
            subtitle: 'Beautiful stroll • 2.3 km away',
            matchPercent: 86,
          ),
        ];
      case 'cultural':
        return [
          _DemoActivity(
            emoji: '🏛️',
            title: 'History Museum',
            subtitle: 'Fascinating exhibits • 1.2 km away',
            matchPercent: 93,
          ),
          _DemoActivity(
            emoji: '🎭',
            title: 'Local Theater',
            subtitle: 'Live performances • 1.8 km away',
            matchPercent: 87,
          ),
          _DemoActivity(
            emoji: '🎨',
            title: 'Art Gallery',
            subtitle: 'Contemporary art • 0.7 km away',
            matchPercent: 84,
          ),
        ];
      default:
        return [
          _DemoActivity(
            emoji: '🌟',
            title: 'Popular Spot',
            subtitle: 'Highly rated • 1.0 km away',
            matchPercent: 90,
          ),
          _DemoActivity(
            emoji: '🎉',
            title: 'Fun Activity',
            subtitle: 'Great for today • 1.5 km away',
            matchPercent: 85,
          ),
          _DemoActivity(
            emoji: '🍽️',
            title: 'Local Favorite',
            subtitle: 'Top reviewed • 0.8 km away',
            matchPercent: 82,
          ),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFFBF5),
            ],
          ),
        ),
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
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Demo Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
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
              'Skip',
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
        
        // Moody avatar
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌟', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Moody',
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
        
        // Messages
        ..._messages.map((msg) => _buildMessage(msg)),
        
        // Typing indicator
        if (_isTyping) _buildTypingIndicator(),
        
        // Activity cards
        if (_showActivities) ...[
          const SizedBox(height: 16),
          ..._getActivitiesForMood(_selectedMood).map((activity) => 
            _buildActivityCard(activity)
          ),
        ],
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMessage(_DemoMessage message) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromMoody 
                    ? Colors.white 
                    : Colors.orange[600],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isFromMoody ? 4 : 16),
                  bottomRight: Radius.circular(message.isFromMoody ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isFromMoody ? Colors.grey[800] : Colors.white,
                  height: 1.4,
                ),
              ),
            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showMoodOptions) ...[
              // Mood selection buttons
              Text(
                'Tap to select your mood:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildMoodButton('Adventurous', '🏃'),
                  _buildMoodButton('Relaxed', '😌'),
                  _buildMoodButton('Romantic', '💕'),
                  _buildMoodButton('Cultural', '🎨'),
                ],
              ),
            ] else if (_showActivities) ...[
              // CTA buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Explore More ✨',
                    style: TextStyle(
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
                  'Ready to sign up? Start now →',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.orange[700],
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

  Widget _buildMoodButton(String mood, String emoji) {
    return Material(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _selectMood(mood),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                mood,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.orange[600] : Colors.grey[300],
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

