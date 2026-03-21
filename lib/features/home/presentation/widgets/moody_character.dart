import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';

class MoodyCharacter extends StatefulWidget {
  final double size;
  final String mood;
  final VoidCallback? onTap;
  final MoodyFeature currentFeature;
  final double mouthScaleFactor;

  /// Multiplier for outer glow / halo shadows (1.0 = default). Use below 1 on busy backdrops.
  final double glowOpacityScale;

  const MoodyCharacter({
    super.key,
    this.size = 120,
    this.mood = 'idle',
    this.onTap,
    this.currentFeature = MoodyFeature.none,
    this.mouthScaleFactor = 1.0,
    this.glowOpacityScale = 1.0,
  });

  @override
  State<MoodyCharacter> createState() => _MoodyCharacterState();
}

class _MoodyCharacterState extends State<MoodyCharacter> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _blinkController;
  late final AnimationController _moodController;
  late final AnimationController _touchController;
  late final AnimationController _rotateController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _blinkAnimation;
  late final Animation<double> _smileAnimation;
  late final Animation<double> _touchAnimation;
  late final Animation<double> _rotateAnimation;
  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleAnimation;
  Timer? _blinkTimer;
  bool _isDisposed = false;
  bool _isHovered = false;
  String _currentTimeOfDay = 'day';
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  String _currentMessage = '';
  bool _showBubble = false;
  
  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _updateTimeOfDay();
    _initializeAnimations();
    _initializeFeatureMessage();
  }

  void _initializeAnimations() {
    if (_isDisposed) return;
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _moodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _touchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Initialize animations
    _floatAnimation = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));

    _smileAnimation = Tween<double>(
      begin: 0.85,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _moodController,
      curve: Curves.easeInOut,
    ));

    _touchAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _touchController,
      curve: Curves.easeOutCubic,
    ));

    _rotateAnimation = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bubbleAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutBack,
    );

    // Start repeating animations after initialization
    if (!_isDisposed) {
      _floatController.repeat(reverse: true);
      _rotateController.repeat(reverse: true);
      if (widget.mood != 'sleeping') {
        _startBlinking();
      } else {
        _blinkController.value = 1.0;
      }
    }
  }

  void _initializeFeatureMessage() {
    if (widget.currentFeature != MoodyFeature.none) {
      _showFeatureMessage(widget.currentFeature);
    }
  }

  String _getFeatureMessage(MoodyFeature feature) {
    switch (feature) {
      case MoodyFeature.navigation:
        return "Hi! I'll help you explore new places! 🗺️";
      case MoodyFeature.weather:
        return "Let me check the weather for your adventures! ⛅";
      case MoodyFeature.moodTracking:
        return "How are you feeling today? Let's track your mood! 😊";
      case MoodyFeature.activities:
        return "I've got some fun activities planned for you! 🎯";
      case MoodyFeature.settings:
        return "Want to customize your experience? Let me help! ⚙️";
      case MoodyFeature.none:
        return "";
      case MoodyFeature.planGeneration:
        return "I'm generating a plan for you! 🎯";
    }
  }

  void _showFeatureMessage(MoodyFeature feature) {
    setState(() {
      _currentMessage = _getFeatureMessage(feature);
      _showBubble = true;
    });
    _bubbleController.forward();
  }

  @override
  void didUpdateWidget(MoodyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFeature != oldWidget.currentFeature) {
      if (widget.currentFeature == MoodyFeature.none) {
        _hideBubble();
      } else {
        _showFeatureMessage(widget.currentFeature);
      }
    }
    if (oldWidget.mood != widget.mood) {
      if (widget.mood == 'sleeping') {
        _blinkTimer?.cancel();
        // Controller at 1.0 drives blink tween to "shut" = scale 0 for open-eye
        // widgets; sleeping uses CustomPaint eyes, so this only affects reuse.
        _blinkController.value = 1.0;
      } else if (oldWidget.mood == 'sleeping') {
        // Was at 1.0 → normal eyes would be scaled to 0 (invisible). Reset open.
        _blinkController.value = 0.0;
        _startBlinking();
      }
    }
  }

  void _hideBubble() {
    _bubbleController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showBubble = false;
        });
      }
    });
  }

  void _updateTimeOfDay() {
    final hour = MoodyClock.now().hour;
    setState(() {
      if (hour >= 5 && hour < 12) {
        _currentTimeOfDay = 'morning';
      } else if (hour >= 12 && hour < 17) {
        _currentTimeOfDay = 'day';
      } else if (hour >= 17 && hour < 21) {
        _currentTimeOfDay = 'evening';
      } else {
        _currentTimeOfDay = 'night';
      }
    });
  }

  void _startBlinking() {
    if (_isDisposed) return;
    
    // Cancel any existing timer
    _blinkTimer?.cancel();
    
    // Random blink interval between 2-4 seconds
    final interval = 2000 + math.Random().nextInt(2000);
    _blinkTimer = Timer(Duration(milliseconds: interval), () async {
      if (_isDisposed) return;
      
      try {
        if (!_isDisposed && mounted) {
          await _blinkController.forward();
        }
        if (!_isDisposed && mounted) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (!_isDisposed && mounted) {
          await _blinkController.reverse();
        }
        if (!_isDisposed && mounted) {
          _startBlinking();
        }
      } catch (e) {
        // Handle or log any animation errors
        if (!_isDisposed && mounted) {
          debugPrint('Animation error: $e');
        }
      }
    });
  }

  void _handleInteraction() {
    if (_isDisposed) return;
    widget.onTap?.call();
    
    _moodController.forward().then((_) {
      if (!_isDisposed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && mounted) {
            _moodController.reverse();
          }
        });
      }
    });
  }

  void _updatePanPosition(DragUpdateDetails details) {
    setState(() {
      _tiltX = math.max(-5, math.min(5, details.delta.dx * 0.5));
      _tiltY = math.max(-5, math.min(5, details.delta.dy * 0.5));
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _blinkTimer?.cancel();
    
    // Dispose controllers only if they're initialized
    if (_floatController.isAnimating) _floatController.stop();
    if (_blinkController.isAnimating) _blinkController.stop();
    if (_moodController.isAnimating) _moodController.stop();
    if (_touchController.isAnimating) _touchController.stop();
    if (_rotateController.isAnimating) _rotateController.stop();
    if (_bubbleController.isAnimating) _bubbleController.stop();
    
    _floatController.dispose();
    _blinkController.dispose();
    _moodController.dispose();
    _touchController.dispose();
    _rotateController.dispose();
    _bubbleController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => _touchController.forward(),
            onTapUp: (_) => _touchController.reverse(),
            onTapCancel: () => _touchController.reverse(),
            onTap: _handleInteraction,
            onPanUpdate: _updatePanPosition,
            onPanEnd: (_) => _resetTilt(),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _floatAnimation,
                _touchAnimation,
                _rotateAnimation,
              ]),
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_tiltY * math.pi / 180)
                    ..rotateY((_tiltX + _rotateAnimation.value) * math.pi / 180)
                    ..scale(_touchAnimation.value),
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(-0.2 + (_tiltX / 20), -0.2 + (_tiltY / 20)),
                          radius: 0.9,
                          colors: [
                            _currentTimeOfDay == 'night' 
                                ? const Color(0xFFB0CCFF)
                                : const Color(0xFFCCE5FF),
                            const Color(0xFFB5D6FF),
                            const Color(0xFF90C2FF),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF90C2FF).withValues(
                                alpha: (0.2 * widget.glowOpacityScale).clamp(0.0, 1.0)),
                            blurRadius: 30,
                            spreadRadius: 10,
                            offset: Offset(_tiltX, _tiltY + 6),
                          ),
                          BoxShadow(
                            color: const Color(0xFF90C2FF).withValues(
                                alpha: (0.4 * widget.glowOpacityScale).clamp(0.0, 1.0)),
                            blurRadius: 20,
                            spreadRadius: 4,
                            offset: Offset(_tiltX * 0.5, _tiltY * 0.5 + 6),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(
                                alpha: (0.6 * widget.glowOpacityScale).clamp(0.0, 1.0)),
                            blurRadius: 15,
                            spreadRadius: -2,
                            offset: Offset(-4 + (_tiltX * 0.2), -4 + (_tiltY * 0.2)),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(
                                alpha: (0.3 * widget.glowOpacityScale).clamp(0.0, 1.0)),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: Offset(_tiltX * -0.1, _tiltY * -0.1),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.mood == 'sleeping')
                                  SizedBox(
                                    width: widget.size * 0.58,
                                    height: widget.size * 0.24,
                                    child: CustomPaint(
                                      painter: _MoodySleepingEyesPainter(
                                        faceSize: widget.size,
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildEye(left: true),
                                      _buildEye(left: false),
                                    ],
                                  ),
                                SizedBox(height: widget.size * 0.15),
                                SizedBox(
                                  width: widget.size * 0.5,
                                  height: widget.size * 0.2,
                                  child: CustomPaint(
                                    painter: SmilePainter(
                                      mouthScaleFactor: widget.mouthScaleFactor,
                                      isBlinking: _blinkAnimation.value == 1.0,
                                      mood: widget.mood,
                                      timeOfDay: _currentTimeOfDay,
                                      tiltX: _tiltX,
                                      tiltY: _tiltY,
                                      smileProgress: _smileAnimation.value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.mood == 'sleeping') ...[
                            Positioned(
                              top: widget.size * 0.06,
                              left: widget.size * 0.1,
                              child: Text(
                                'z',
                                style: TextStyle(
                                  fontSize: widget.size * 0.13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7EB0E8),
                                  height: 1,
                                ),
                              ),
                            ),
                            Positioned(
                              top: widget.size * 0.02,
                              right: widget.size * 0.08,
                              child: Text(
                                'Z',
                                style: TextStyle(
                                  fontSize: widget.size * 0.17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6FA0D8),
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                          if (_isHovered)
                            Container(
                              width: widget.size,
                              height: widget.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: Alignment(_tiltX / 10, _tiltY / 10),
                                  radius: 1.2,
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        if (_showBubble)
          Positioned(
            top: -60,
            left: widget.size * 0.5,
            child: FadeTransition(
              opacity: _bubbleAnimation,
              child: ScaleTransition(
                scale: _bubbleAnimation,
                child: SpeechBubble(
                  message: _currentMessage,
                  size: widget.size,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEye({required bool left}) {
    return Transform.scale(
      scale: _blinkAnimation.value,
      child: Container(
        width: widget.size * 0.25,
        height: widget.size * 0.32,
        margin: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.elliptical(
              widget.size * 0.25,
              widget.size * 0.32,
            ),
          ),
          border: Border.all(
            color: Color(0xFF90C2FF),
            width: widget.size * 0.025,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: widget.size * 0.14,
                height: widget.size * 0.14,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: widget.size * 0.04,
              left: widget.size * 0.04,
              child: Container(
                width: widget.size * 0.08,
                height: widget.size * 0.08,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
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

/// Closed eyelids (arcs) for [MoodyCharacter] `mood: sleeping`.
class _MoodySleepingEyesPainter extends CustomPainter {
  const _MoodySleepingEyesPainter({required this.faceSize});

  final double faceSize;

  @override
  void paint(Canvas canvas, Size size) {
    final r = faceSize * 0.47;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final line = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, faceSize * 0.016)
      ..strokeCap = StrokeCap.round;

    final eyeY = cy - r * 0.08;
    final eyeSpread = r * 0.2;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - eyeSpread, eyeY),
        width: r * 0.26,
        height: r * 0.12,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      line,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + eyeSpread, eyeY),
        width: r * 0.26,
        height: r * 0.12,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodySleepingEyesPainter oldDelegate) =>
      oldDelegate.faceSize != faceSize;
}

class SmilePainter extends CustomPainter {
  final double smileProgress;
  final double mouthScaleFactor;
  final bool isBlinking;
  final String mood;
  final String timeOfDay;
  final double tiltX;
  final double tiltY;

  SmilePainter({
    required this.smileProgress,
    required this.mouthScaleFactor,
    required this.isBlinking,
    required this.mood,
    required this.timeOfDay,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw mouth
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    final mouthWidth = radius * 0.8; // Wider mouth
    final mouthY = center.dy - radius * 0.1; // Slightly higher position
    
    // Calculate mouth opening based on mouthScaleFactor
    final openAmount = (mouthScaleFactor - 1.0) * radius * 0.5;
    
    // Create mouth shape
    if (openAmount > 0) {
      // Open mouth state
      final mouthFillPaint = Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.fill;
      
      final mouthInteriorPath = Path();
      
      // Upper lip with U shape
      mouthInteriorPath.moveTo(center.dx - mouthWidth / 2, mouthY);
      mouthInteriorPath.quadraticBezierTo(
        center.dx,
        mouthY - openAmount * 0.3, // Less upward movement
        center.dx + mouthWidth / 2,
        mouthY,
      );
      
      // Lower lip with deeper U shape
      mouthInteriorPath.quadraticBezierTo(
        center.dx,
        mouthY + openAmount * 2.0, // More downward curve
        center.dx - mouthWidth / 2,
        mouthY,
      );
      
      // Fill mouth interior
      canvas.drawPath(mouthInteriorPath, mouthFillPaint);
      
      // Draw mouth outline
      canvas.drawPath(mouthInteriorPath, mouthPaint);
    } else {
      // Closed mouth state - U-shaped smile
      mouthPath.moveTo(center.dx - mouthWidth / 2, mouthY);
      mouthPath.quadraticBezierTo(
        center.dx,
        mouthY + radius * 0.3, // Deeper curve for U shape
        center.dx + mouthWidth / 2,
        mouthY,
      );
      canvas.drawPath(mouthPath, mouthPaint);
    }
  }

  @override
  bool shouldRepaint(SmilePainter oldDelegate) {
    return oldDelegate.smileProgress != smileProgress ||
        oldDelegate.mouthScaleFactor != mouthScaleFactor ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.mood != mood ||
        oldDelegate.timeOfDay != timeOfDay ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY;
  }
}

class SpeechBubble extends StatelessWidget {
  final String message;
  final double size;

  const SpeechBubble({
    super.key,
    required this.message,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: size * 2,
              minWidth: size,
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Triangle pointer
          Positioned(
            bottom: -12,
            left: size * 0.4,
            child: CustomPaint(
              size: Size(20, 12),
              painter: TrianglePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 