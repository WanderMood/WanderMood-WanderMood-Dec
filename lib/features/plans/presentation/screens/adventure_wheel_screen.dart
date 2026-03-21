import 'dart:math' show pi, cos, sin, Random;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/plans/presentation/widgets/activity_details_card.dart';

class AdventureWheelScreen extends StatefulWidget {
  final List<Activity> activities;
  final Function(Activity) onActivitySelect;

  const AdventureWheelScreen({
    super.key,
    required this.activities,
    required this.onActivitySelect,
  });

  @override
  State<AdventureWheelScreen> createState() => _AdventureWheelScreenState();
}

class _AdventureWheelScreenState extends State<AdventureWheelScreen> with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _bounceController;
  late AnimationController _confettiController;
  int _currentIndex = 0;
  bool _isSpinning = false;
  bool _showDetails = false;
  final Random _random = Random();
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _confettiController.addListener(_updateConfetti);

    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _updateConfetti() {
    if (_confettiController.isAnimating && _confettiController.value < 0.8) {
      // Create new particles during the first 80% of the animation
      if (_random.nextDouble() < 0.1) {
        for (int i = 0; i < 5; i++) {
          _particles.add(ConfettiParticle(
            position: Offset(MediaQuery.of(context).size.width * _random.nextDouble(), 0),
            color: Color.fromARGB(
              255,
              128 + _random.nextInt(128),
              128 + _random.nextInt(128),
              128 + _random.nextInt(128),
            ),
            size: 5 + _random.nextDouble() * 10,
            velocity: Offset(
              (_random.nextDouble() - 0.5) * 3,
              3 + _random.nextDouble() * 5,
            ),
          ));
        }
      }
    }

    // Update existing particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final particle = _particles[i];
      particle.position += particle.velocity;
      particle.velocity += const Offset(0, 0.1); // Gravity
      
      // Remove particles that have fallen off the screen
      if (particle.position.dy > MediaQuery.of(context).size.height) {
        _particles.removeAt(i);
      }
    }
    
    setState(() {});
  }

  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _showDetails = false;
      _particles.clear();
    });

    // Random number of full rotations (3-5) plus partial rotation to selected activity
    final spins = 3 + (DateTime.now().millisecond % 3);
    final segments = widget.activities.length;
    final randomSegment = DateTime.now().millisecond % segments;
    
    final totalRotation = (spins * 360) + ((360 / segments) * randomSegment);
    
    _wheelController.reset();
    _wheelController.animateTo(
      totalRotation / 360,
      curve: Curves.easeOutCubic,
    ).then((_) {
      setState(() {
        _currentIndex = randomSegment;
        _isSpinning = false;
        _showDetails = true;
      });
      _confettiController.reset();
      _confettiController.forward();
    });
  }

  void _handleBookActivity() {
    final selectedActivity = widget.activities[_currentIndex];
    widget.onActivitySelect(selectedActivity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F5E9),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Custom confetti
              if (_particles.isNotEmpty)
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                  painter: ConfettiPainter(_particles),
                ),

              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Adventure Story',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Moody character
                  SizedBox(
                    height: 100,
                    child: MoodyCharacter(
                      size: 80,
                      mood: _isSpinning ? 'excited' : 'happy',
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).scale(
                      duration: 800.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      curve: Curves.easeInOut,
                    ),
                  ),

                  // Adventure wheel
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating wheel
                        RotationTransition(
                          turns: _wheelController,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Stack(
                                fit: StackFit.expand,
                                children: List.generate(
                                  widget.activities.length,
                                  (index) {
                                    final activity = widget.activities[index];
                                    final angle = (2 * pi * index) / widget.activities.length;
                                    return Transform.rotate(
                                      angle: angle,
                                      child: _buildActivitySegment(activity, index),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Center pointer
                        Transform.rotate(
                          angle: -pi / 2,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A6049),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                            ),
                          ).animate(
                            controller: _bounceController,
                          ).scale(
                            duration: 1500.ms,
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            curve: Curves.easeInOut,
                          ),
                        ),

                        // Activity details overlay
                        if (_showDetails && !_isSpinning)
                          ActivityDetailsCard(
                            activity: widget.activities[_currentIndex],
                            onBook: _handleBookActivity,
                            onClose: () => setState(() => _showDetails = false),
                            isVisible: _showDetails,
                          ),
                      ],
                    ),
                  ),

                  // Spin button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ElevatedButton(
                      onPressed: _isSpinning ? null : _spinWheel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A6049),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isSpinning ? 'Spinning...' : 'Spin The Wheel',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActivitySegment(Activity activity, int index) {
    final isCurrentActivity = index == _currentIndex;
    final totalActivities = widget.activities.length;
    
    return ClipPath(
      clipper: _WheelSegmentClipper(totalActivities, index),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentActivity
              ? const Color(0xFF81C784).withOpacity(0.9)
              : index % 2 == 0
                  ? const Color(0xFFA5D6A7).withOpacity(0.8)
                  : const Color(0xFFC8E6C9).withOpacity(0.8),
          image: DecorationImage(
            image: AssetImage(activity.imageUrl),
            fit: BoxFit.cover,
            opacity: 0.2,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.7),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: Offset(
                  cos(pi / totalActivities) * 90,
                  sin(pi / totalActivities) * 10,
                ),
                child: Transform.rotate(
                  angle: pi / 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activity.name.length > 20
                              ? '${activity.name.substring(0, 17)}...'
                              : activity.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(activity.startTime),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Custom clipper for wheel segments
class _WheelSegmentClipper extends CustomClipper<Path> {
  final int totalSegments;
  final int segmentIndex;

  _WheelSegmentClipper(this.totalSegments, this.segmentIndex);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = 2 * pi / totalSegments;
    
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(center.dx + radius * cos(0), center.dy + radius * sin(0));
    
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      segmentIndex * angle,
      angle,
      false,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

// Confetti implementation
class ConfettiParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double rotation = 0;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      paint.color = particle.color;
      
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      
      // Draw a rectangle for confetti piece
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.5,
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 