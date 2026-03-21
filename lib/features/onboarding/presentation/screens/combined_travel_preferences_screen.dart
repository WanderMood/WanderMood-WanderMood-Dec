import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/communication_style_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class CombinedTravelPreferencesScreen extends ConsumerStatefulWidget {
  const CombinedTravelPreferencesScreen({super.key});

  @override
  ConsumerState<CombinedTravelPreferencesScreen> createState() => _CombinedTravelPreferencesScreenState();
}

class _CombinedTravelPreferencesScreenState extends ConsumerState<CombinedTravelPreferencesScreen> 
    with TickerProviderStateMixin {
  late final AnimationController _moodyController;
  late final AnimationController _messageController;
  
  // Social Vibe state
  final Set<String> _selectedVibes = {};
  
  // Planning Pace state
  String? _selectedPace;
  
  // Travel Style state
  final Set<String> _selectedStyles = {};
  static const int maxStyleSelections = 3;

  List<Map<String, dynamic>> _socialVibes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'key': 'Solo Adventures', 'name': l10n.prefSocialSolo, 'emoji': '🧘‍♀️', 'description': l10n.prefSocialSoloDesc, 'color': const Color(0xFFFFB74D)},
      {'key': 'Small Groups', 'name': l10n.prefSocialSmallGroups, 'emoji': '👥', 'description': l10n.prefSocialSmallGroupsDesc, 'color': const Color(0xFF66BB6A)},
      {'key': 'Social Butterfly', 'name': l10n.prefSocialButterfly, 'emoji': '🦋', 'description': l10n.prefSocialButterflyDesc, 'color': const Color(0xFF42A5F5)},
      {'key': 'Mood Dependent', 'name': l10n.prefSocialMoodDependent, 'emoji': '🎭', 'description': l10n.prefSocialMoodDependentDesc, 'color': const Color(0xFFAB47BC)},
    ];
  }

  List<Map<String, dynamic>> _planningPaces(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'key': 'Right Now Vibes', 'name': l10n.prefPaceRightNow, 'emoji': '⚡', 'description': l10n.prefPaceRightNowDesc, 'color': const Color(0xFFFFB74D)},
      {'key': 'Same Day Planner', 'name': l10n.prefPaceSameDay, 'emoji': '🌅', 'description': l10n.prefPaceSameDayDesc, 'color': const Color(0xFF66BB6A)},
      {'key': 'Weekend Prepper', 'name': l10n.prefPaceWeekend, 'emoji': '📅', 'description': l10n.prefPaceWeekendDesc, 'color': const Color(0xFF8D6E63)},
      {'key': 'Master Planner', 'name': l10n.prefPaceMaster, 'emoji': '📋', 'description': l10n.prefPaceMasterDesc, 'color': const Color(0xFF78909C)},
    ];
  }

  List<Map<String, dynamic>> _travelStyles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'key': 'Spontaneous', 'name': l10n.prefTravelStyleSpontaneous, 'emoji': '🎯', 'description': l10n.prefTravelStyleSpontaneousDesc, 'color': const Color(0xFFFFB74D)},
      {'key': 'Planned', 'name': l10n.prefTravelStylePlanned, 'emoji': '📅', 'description': l10n.prefTravelStylePlannedDesc, 'color': const Color(0xFF64B5F6)},
      {'key': 'Local Experience', 'name': l10n.prefTravelStyleLocal, 'emoji': '🏡', 'description': l10n.prefTravelStyleLocalDesc, 'color': const Color(0xFF7CB342)},
      {'key': 'Luxury Seeker', 'name': l10n.prefTravelStyleLuxury, 'emoji': '✨', 'description': l10n.prefTravelStyleLuxuryDesc, 'color': const Color(0xFFEC407A)},
      {'key': 'Budget Conscious', 'name': l10n.prefTravelStyleBudget, 'emoji': '💰', 'description': l10n.prefTravelStyleBudgetDesc, 'color': const Color(0xFF66BB6A)},
      {'key': 'Tourist Highlights', 'name': l10n.prefTravelStyleTouristHighlights, 'emoji': '🗺️', 'description': l10n.prefTravelStyleTouristHighlightsDesc, 'color': const Color(0xFFEC407A)},
      {'key': 'Off the Beaten Path', 'name': l10n.prefTravelStyleOffBeatenPath, 'emoji': '⭐', 'description': l10n.prefTravelStyleOffBeatenPathDesc, 'color': const Color(0xFF9575CD)},
    ];
  }

  String _travelTitle(AppLocalizations l10n, String styleKey) {
    switch (styleKey) {
      case 'energetic': return l10n.prefTravelTitleEnergetic;
      case 'professional': return l10n.prefTravelTitleProfessional;
      case 'direct': return l10n.prefTravelTitleDirect;
      default: return l10n.prefTravelTitleFriendly;
    }
  }

  String _travelSubtitle(AppLocalizations l10n, String styleKey) {
    switch (styleKey) {
      case 'energetic': return l10n.prefTravelSubtitleEnergetic;
      case 'professional': return l10n.prefTravelSubtitleProfessional;
      case 'direct': return l10n.prefTravelSubtitleDirect;
      default: return l10n.prefTravelSubtitleFriendly;
    }
  }

  @override
  void initState() {
    super.initState();
    _moodyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _moodyController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _messageController.forward();
  }

  void _toggleSocialVibe(String vibe) {
    setState(() {
      if (_selectedVibes.contains(vibe)) {
        _selectedVibes.remove(vibe);
      } else {
        _selectedVibes.add(vibe);
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateSocialVibe(_selectedVibes.toList());
      }
    });
  }

  void _selectPlanningPace(String pace) {
    setState(() {
      _selectedPace = pace;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updatePlanningPace(pace);
      }
    });
  }

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else if (_selectedStyles.length < maxStyleSelections) {
        _selectedStyles.add(style);
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesProvider.notifier).updateTravelStyles(_selectedStyles.toList());
      }
    });
  }

  bool get _canContinue {
    return _selectedVibes.isNotEmpty && _selectedPace != null && _selectedStyles.isNotEmpty;
  }

  @override
  void dispose() {
    _moodyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildSocialVibeCard(Map<String, dynamic> vibe) {
    final String key = vibe['key'] as String;
    final bool isSelected = _selectedVibes.contains(key);
    final color = vibe['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleSocialVibe(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      vibe['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vibe['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        vibe['description'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanningPaceCard(Map<String, dynamic> pace) {
    final String key = pace['key'] as String;
    final bool isSelected = _selectedPace == key;
    final color = pace['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectPlanningPace(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      pace['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pace['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        pace['description'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard(Map<String, dynamic> style) {
    final String key = style['key'] as String;
    final bool isSelected = _selectedStyles.contains(key);
    final color = style['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleStyle(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                  ? color.withOpacity(0.12)
                  : const Color(0xFFE8E8E8).withOpacity(0.4),
                blurRadius: isSelected ? 8 : 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      style['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        style['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        style['description'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: color,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwirlBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Progress indicator (4 of 4)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(4, (index) => Container(
                      width: 35,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: index < 4 
                          ? const Color(0xFF2A6049)
                          : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                  ],
                ),
              ),

              // Back button
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () => context.go('/preferences/interests'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF2A6049),
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Title
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(_messageController),
                      child: FadeTransition(
                        opacity: _messageController,
                        child: Center(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final communicationState = ref.watch(communicationStyleProvider);
                              final styleKey = communicationState.style.toString().split('.').last;
                              final l10n = AppLocalizations.of(context)!;
                              final title = _travelTitle(l10n, styleKey);
                              return Text(
                                title,
                                style: GoogleFonts.museoModerno(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2A6049),
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.2),
                        end: Offset.zero,
                      ).animate(_messageController),
                      child: FadeTransition(
                        opacity: _messageController,
                        child: Center(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final communicationState = ref.watch(communicationStyleProvider);
                              final styleKey = communicationState.style.toString().split('.').last;
                              final l10n = AppLocalizations.of(context)!;
                              final subtitle = _travelSubtitle(l10n, styleKey);
                              return Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1: Social Vibe
                            Text(
                              AppLocalizations.of(context)!.prefSectionSocialVibe,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._socialVibes(context).map((vibe) => _buildSocialVibeCard(vibe)),
                            
                            const SizedBox(height: 32),
                            
                            // Section 2: Planning Pace
                            Text(
                              AppLocalizations.of(context)!.prefSectionPlanningPace,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._planningPaces(context).map((pace) => _buildPlanningPaceCard(pace)),
                            
                            const SizedBox(height: 32),
                            
                            // Section 3: Travel Style
                            Text(
                              AppLocalizations.of(context)!.prefSectionTravelStyle,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.prefSelectUpToStyles(maxStyleSelections),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._travelStyles(context).map((style) => _buildStyleCard(style)),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Continue button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canContinue
                            ? () => context.go('/preferences/loading')
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canContinue
                              ? const Color(0xFF2A6049)
                              : Colors.grey.withOpacity(0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.continueButton,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
  }
}
