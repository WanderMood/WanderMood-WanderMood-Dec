// lib/features/profile/presentation/widgets/travel_mode_toggle.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/places/providers/moody_explore_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'dart:ui';

class TravelModeToggle extends ConsumerStatefulWidget {
  final bool isLocal; // true = Local Mode, false = Traveling
  final Function(bool) onModeChanged;

  const TravelModeToggle({
    Key? key,
    required this.isLocal,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  ConsumerState<TravelModeToggle> createState() => _TravelModeToggleState();
}

class _TravelModeToggleState extends ConsumerState<TravelModeToggle> {
  void _handleToggleTap(bool newMode) {
    if (newMode == widget.isLocal) return;

    // Show confirmation dialog first
    _showConfirmationDialog(newMode);
  }

  void _showConfirmationDialog(bool newMode) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _ConfirmationOverlay(
        isLocal: newMode,
        onConfirm: () {
          Navigator.pop(context); // Close confirmation dialog
          // Show success animation
          _showSuccessAnimation(newMode);
          // Update mode after animation
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              widget.onModeChanged(newMode);
              // Invalidate recommendations provider to refresh places
              ref.invalidate(moodyExploreAutoProvider);
            }
          });
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSuccessAnimation(bool isLocal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _SuccessAnimationOverlay(isLocal: isLocal),
    );

    // Auto-hide after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showExplanationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TravelModeExplanationModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Toggle buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    // Local Mode Button
                    Expanded(
                      child: _ToggleButton(
                        icon: Icons.home,
                        label: l10n.profileModeLocal,
                        isActive: widget.isLocal,
                        activeGradient: const [Color(0xFF5BB32A), Color(0xFF4CAF50)], // Match splash screen color
                        onTap: () => _handleToggleTap(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Travel Mode Button
                    Expanded(
                      child: _ToggleButton(
                        icon: Icons.map,
                        label: l10n.profileModeTravel,
                        isActive: !widget.isLocal,
                        activeGradient: const [Color(0xFFF97316), Color(0xFFEC4899)],
                        onTap: () => _handleToggleTap(false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Info button
        GestureDetector(
          onTap: _showExplanationModal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ℹ️ ${l10n.profileModeWhatDoesThisDo}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Toggle Button Widget
class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final List<Color> activeGradient;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(colors: activeGradient)
              : null,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeGradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Confirmation Overlay (shown before mode change)
class _ConfirmationOverlay extends StatefulWidget {
  final bool isLocal;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmationOverlay({
    required this.isLocal,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_ConfirmationOverlay> createState() => _ConfirmationOverlayState();
}

class _ConfirmationOverlayState extends State<_ConfirmationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modeData = _getModeData(context, widget.isLocal);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: modeData.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: modeData.gradient[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location Pin Icon at top
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: modeData.gradient[0],
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title with airplane icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isLocal ? Icons.home : Icons.flight,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isLocal ? l10n.profileModeLocalTitle : l10n.profileModeTravelTitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    modeData.description,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Features (3 items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: modeData.features.take(3).map((feature) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              feature.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature.text,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Switch Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: modeData.gradient[0],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check,
                                color: modeData.gradient[0],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isLocal
                                    ? l10n.profileModeSwitchToLocal
                                    : l10n.profileModeSwitchToTravel,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n.profileModeCancel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Footer text
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    l10n.profileModeChangeAnytime,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ModeData _getModeData(BuildContext context, bool isLocal) {
    final l10n = AppLocalizations.of(context)!;
    if (isLocal) {
      return _ModeData(
        icon: Icons.home,
        title: l10n.profileModeLocalTitle,
        description: l10n.profileModeLocalDescription,
        gradient: [const Color(0xFF10B981), Color(0xFF059669)],
        features: [
          _Feature(Icons.coffee, l10n.profileModeLocalFeature1),
          _Feature(Icons.auto_awesome, l10n.profileModeLocalFeature2),
          _Feature(Icons.check, l10n.profileModeLocalFeature3),
        ],
      );
    } else {
      return _ModeData(
        icon: Icons.map,
        title: l10n.profileModeTravelTitle,
        description: l10n.profileModeTravelDescription,
        gradient: [const Color(0xFFF97316), Color(0xFFEC4899)],
        features: [
          _Feature(Icons.account_balance, l10n.profileModeTravelFeature1),
          _Feature(Icons.explore, l10n.profileModeTravelFeature2),
          _Feature(Icons.check, l10n.profileModeTravelFeature3),
        ],
      );
    }
  }
}

// Success Animation Overlay (shown after confirmation)
class _SuccessAnimationOverlay extends StatefulWidget {
  final bool isLocal;

  const _SuccessAnimationOverlay({required this.isLocal});

  @override
  State<_SuccessAnimationOverlay> createState() => _SuccessAnimationOverlayState();
}

class _SuccessAnimationOverlayState extends State<_SuccessAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modeData = _getModeData(context, widget.isLocal);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: modeData.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: modeData.gradient[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success checkmark
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.profileModeUpdated,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.profileModeUpdating,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ModeData _getModeData(BuildContext context, bool isLocal) {
    final l10n = AppLocalizations.of(context)!;
    if (isLocal) {
      return _ModeData(
        icon: Icons.home,
        title: l10n.profileModeLocalTitle,
        description: l10n.profileModeLocalDescription,
        gradient: [const Color(0xFF10B981), Color(0xFF059669)],
        features: [
          _Feature(Icons.coffee, l10n.profileModeLocalFeature1),
          _Feature(Icons.auto_awesome, l10n.profileModeLocalFeature2),
          _Feature(Icons.check, l10n.profileModeLocalFeature3),
        ],
      );
    } else {
      return _ModeData(
        icon: Icons.map,
        title: l10n.profileModeTravelTitle,
        description: l10n.profileModeTravelDescription,
        gradient: [const Color(0xFFF97316), Color(0xFFEC4899)],
        features: [
          _Feature(Icons.account_balance, l10n.profileModeTravelFeature1),
          _Feature(Icons.explore, l10n.profileModeTravelFeature2),
          _Feature(Icons.check, l10n.profileModeTravelFeature3),
        ],
      );
    }
  }
}

// Old Mode Overlay (kept for reference, but replaced by confirmation + success)
class _ModeOverlay extends StatefulWidget {
  final bool isLocal;

  const _ModeOverlay({required this.isLocal});

  @override
  State<_ModeOverlay> createState() => _ModeOverlayState();
}

class _ModeOverlayState extends State<_ModeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeData = _getModeData(context, widget.isLocal);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: modeData.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: modeData.gradient[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Icon(
                        modeData.icon,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  modeData.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  modeData.description,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Features
                ...modeData.features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            feature.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature.text,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),

                // Success checkmark
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 24,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ModeData _getModeData(BuildContext context, bool isLocal) {
    final l10n = AppLocalizations.of(context)!;
    if (isLocal) {
      return _ModeData(
        icon: Icons.home,
        title: l10n.profileModeLocalTitle,
        description: l10n.profileModeLocalDescription,
        gradient: [const Color(0xFF10B981), Color(0xFF059669)],
        features: [
          _Feature(Icons.coffee, l10n.profileModeLocalFeature1),
          _Feature(Icons.auto_awesome, l10n.profileModeLocalFeature2),
          _Feature(Icons.check, l10n.profileModeLocalFeature3),
        ],
      );
    } else {
      return _ModeData(
        icon: Icons.map,
        title: l10n.profileModeTravelTitle,
        description: l10n.profileModeTravelDescription,
        gradient: [const Color(0xFFF97316), Color(0xFFEC4899)],
        features: [
          _Feature(Icons.account_balance, l10n.profileModeTravelFeature1),
          _Feature(Icons.explore, l10n.profileModeTravelFeature2),
          _Feature(Icons.check, l10n.profileModeTravelFeature3),
        ],
      );
    }
  }
}

// Explanation Modal (bottom sheet)
class TravelModeExplanationModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.profileModeTravelModesExplained,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Local Mode
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green[50]!,
                          Colors.teal[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.green[200]!, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.home, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.profileModeLocalTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.profileModeLocalExplainer,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.check, Colors.green[600]!, l10n.profileModeLocalGem1),
                        _buildFeatureItem(Icons.check, Colors.green[600]!, l10n.profileModeLocalGem2),
                        _buildFeatureItem(Icons.check, Colors.green[600]!, l10n.profileModeLocalGem3),
                        _buildFeatureItem(Icons.check, Colors.green[600]!, l10n.profileModeLocalGem4),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.profileModeLocalExample,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Travel Mode
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange[50]!,
                          Colors.pink[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orange[200]!, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.map, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.profileModeTravelTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.profileModeTravelExplainer,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.check, Colors.orange[600]!, l10n.profileModeTravelSpot1),
                        _buildFeatureItem(Icons.check, Colors.orange[600]!, l10n.profileModeTravelSpot2),
                        _buildFeatureItem(Icons.check, Colors.orange[600]!, l10n.profileModeTravelSpot3),
                        _buildFeatureItem(Icons.check, Colors.orange[600]!, l10n.profileModeTravelSpot4),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.profileModeTravelExample,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pro Tip
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!, width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue[500],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💡 ${l10n.profileModeProTip}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.profileModeSwitchAnytime,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[500],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  l10n.profileModeGotIt,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data models
class _ModeData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final List<_Feature> features;

  _ModeData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.features,
  });
}

class _Feature {
  final IconData icon;
  final String text;

  _Feature(this.icon, this.text);
}
