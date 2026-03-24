import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final supabase = Supabase.instance.client;
  
  // Preferences state
  String? _ageGroup;
  String? _budgetLevel;
  String? _socialVibe;
  String? _activityPace;
  String? _timeAvailable;
  List<String> _interests = [];
  
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await supabase
          .from('user_preferences')
          .select('age_group, budget_level, social_vibe, activity_pace, time_available, interests')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          // Load age_group - ensure it's a string and matches expected format
          final ageGroupData = response?['age_group'];
          _ageGroup = ageGroupData is String 
              ? ageGroupData.trim()  // Trim whitespace
              : (ageGroupData?.toString().trim());
          _budgetLevel = response?['budget_level'] as String?;
          // Handle social_vibe: can be JSONB array or string
          final socialVibeData = response?['social_vibe'];
          if (socialVibeData is List && socialVibeData.isNotEmpty) {
            _socialVibe = socialVibeData.first.toString();
          } else if (socialVibeData is String) {
            _socialVibe = socialVibeData;
          }
          _activityPace = response?['activity_pace'] as String?;
          _timeAvailable = response?['time_available'] as String?;
          _interests = (response?['interests'] as List<dynamic>?)?.cast<String>() ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final updateData = <String, dynamic>{
        'age_group': _ageGroup,
        'budget_level': _budgetLevel,
        'activity_pace': _activityPace,
        'time_available': _timeAvailable,
        'interests': _interests,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Handle social_vibe - store as string (database is JSONB but we'll store as string)
      updateData['social_vibe'] = _socialVibe;

      await supabase
          .from('user_preferences')
          .upsert({'user_id': userId, ...updateData}, onConflict: 'user_id');

      // Invalidate preferences provider to refresh
      ref.invalidate(preferencesProvider);

      if (mounted) {
        setState(() => _hasChanges = false);
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.prefSavedSuccess,
          duration: const Duration(seconds: 1),
        );
        
        // Navigate back to profile after a short delay to show success message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      if (mounted) {
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.prefSaveError,
          isError: true,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      _hasChanges = true;
      switch (key) {
        case 'ageGroup':
          _ageGroup = value?.toString().trim();  // Ensure it's a clean string
          break;
        case 'budgetLevel':
          _budgetLevel = value as String?;
          break;
        case 'socialVibe':
          _socialVibe = value as String?;
          break;
        case 'activityPace':
          _activityPace = value as String?;
          break;
        case 'timeAvailable':
          _timeAvailable = value as String?;
          break;
      }
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      _hasChanges = true;
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else {
        _interests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always show the gradient background, even while loading
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF7ED), // orange-50
              Color(0xFFFDF2F8), // pink-50
              Color(0xFFFAF5FF), // purple-50
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header - White background, sticky at top
                  Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: 16,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF374151)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.prefScreenTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        decoration: _hasChanges
                            ? BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF97316), // orange-500
                                    Color(0xFFEC4899), // pink-500
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                        child: TextButton(
                          onPressed: _hasChanges ? _savePreferences : null,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.prefSave,
                            style: GoogleFonts.poppins(
                              color: _hasChanges
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Border bottom
            Container(
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Age Group Section
              _buildSectionHeader(
                icon: Icons.calendar_today,
                title: AppLocalizations.of(context)!.prefSectionAgeGroup,
                subtitle: AppLocalizations.of(context)!.prefSectionAgeGroupSub,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              ..._buildAgeGroupOptions(),
              const SizedBox(height: 32),

              // Budget Comfort Section
              _buildSectionHeader(
                icon: Icons.attach_money,
                title: AppLocalizations.of(context)!.prefSectionBudget,
                subtitle: AppLocalizations.of(context)!.prefSectionBudgetSub,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildBudgetOptions(),
              const SizedBox(height: 32),

              // Social Vibe Section
              _buildSectionHeader(
                icon: Icons.people,
                title: AppLocalizations.of(context)!.prefSectionSocialVibe,
                subtitle: AppLocalizations.of(context)!.prefSectionSocialVibeSub,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              ..._buildSocialVibeOptions(),
              const SizedBox(height: 32),

              // Activity Pace Section
              _buildSectionHeader(
                icon: Icons.flash_on,
                title: AppLocalizations.of(context)!.prefSectionActivityPace,
                subtitle: AppLocalizations.of(context)!.prefSectionActivityPaceSub,
                color: Colors.purple,
              ),
              const SizedBox(height: 16),
              _buildActivityPaceOptions(),
              const SizedBox(height: 32),

              // Time Available Section
              _buildSectionHeader(
                icon: Icons.access_time,
                title: AppLocalizations.of(context)!.prefSectionTimeAvailable,
                subtitle: AppLocalizations.of(context)!.prefSectionTimeAvailableSub,
                color: Colors.pink,
              ),
              const SizedBox(height: 16),
              ..._buildTimeAvailableOptions(),
              const SizedBox(height: 32),

              // Interests Section
              _buildSectionHeader(
                icon: Icons.favorite,
                title: AppLocalizations.of(context)!.prefSectionInterests,
                subtitle: AppLocalizations.of(context)!.prefSectionInterestsSub,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              _buildInterestsGrid(),
              const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937), // gray-800
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280), // gray-500
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAgeGroupOptions() {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'value': '18-24', 'label': l10n.prefAge1824Label, 'emoji': '🎓', 'desc': l10n.prefAge1824Desc},
      {'value': '25-34', 'label': l10n.prefAge2534Label, 'emoji': '🌟', 'desc': l10n.prefAge2534Desc},
      {'value': '35-44', 'label': l10n.prefAge3544Label, 'emoji': '🎯', 'desc': l10n.prefAge3544Desc},
      {'value': '45-54', 'label': l10n.prefAge4554Label, 'emoji': '🍷', 'desc': l10n.prefAge4554Desc},
      {'value': '55+', 'label': l10n.prefAge55Label, 'emoji': '🌺', 'desc': l10n.prefAge55Desc},
    ];

    return options.map((option) {
      final isSelected = _ageGroup == option['value'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSelectableCard(
          isSelected: isSelected,
          borderColor: Colors.orange,
          onTap: () => _updatePreference('ageGroup', option['value']),
          child: Row(
            children: [
              Text(
                option['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['label'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      option['desc'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBudgetOptions() {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'value': '\$', 'label': l10n.prefBudgetLabel, 'emoji': '💰', 'desc': l10n.prefBudgetDesc, 'color': Colors.green},
      {'value': '\$\$', 'label': l10n.prefModerateLabel, 'emoji': '💳', 'desc': l10n.prefModerateDesc, 'color': Colors.blue},
      {'value': '\$\$\$', 'label': l10n.prefUpscaleLabel, 'emoji': '💎', 'desc': l10n.prefUpscaleDesc, 'color': Colors.purple},
      {'value': '\$\$\$\$', 'label': l10n.prefLuxuryLabel, 'emoji': '👑', 'desc': l10n.prefLuxuryDesc, 'color': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _budgetLevel == option['value'];
        return _buildSelectableCard(
          isSelected: isSelected,
          borderColor: option['color'] as Color,
          onTap: () => _updatePreference('budgetLevel', option['value']),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getBudgetGradientColors(option['color'] as Color),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    option['emoji'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                option['label'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                option['desc'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: option['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSocialVibeOptions() {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'value': 'solo', 'label': l10n.prefSoloLabel, 'emoji': '🧘', 'desc': l10n.prefSoloDesc},
      {'value': 'small-group', 'label': l10n.prefSmallGroupLabel, 'emoji': '👥', 'desc': l10n.prefSmallGroupDesc},
      {'value': 'mix', 'label': l10n.prefMixLabel, 'emoji': '🎭', 'desc': l10n.prefMixDesc},
      {'value': 'social', 'label': l10n.prefSocialSceneLabel, 'emoji': '🎉', 'desc': l10n.prefSocialSceneDesc},
    ];

    return options.map((option) {
      final isSelected = _socialVibe == option['value'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSelectableCard(
          isSelected: isSelected,
          borderColor: Colors.blue,
          onTap: () => _updatePreference('socialVibe', option['value']),
          child: Row(
            children: [
              Text(
                option['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['label'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      option['desc'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildActivityPaceOptions() {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'value': 'slow', 'label': l10n.prefSlowChillLabel, 'emoji': '🐢', 'desc': l10n.prefSlowChillDesc},
      {'value': 'moderate', 'label': l10n.prefModerateActivityLabel, 'emoji': '🚶', 'desc': l10n.prefModerateActivityDesc},
      {'value': 'active', 'label': l10n.prefActiveLabel, 'emoji': '🏃', 'desc': l10n.prefActiveDesc},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _activityPace == option['value'];
        return _buildSelectableCard(
          isSelected: isSelected,
          borderColor: Colors.purple,
          onTap: () => _updatePreference('activityPace', option['value']),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                option['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                option['label'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                option['desc'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimeAvailableOptions() {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      {'value': 'quick', 'label': l10n.prefQuickVisitLabel, 'time': '< 1 hour', 'emoji': '⚡'},
      {'value': 'half-day', 'label': l10n.prefHalfDayLabel, 'time': '2-4 hours', 'emoji': '🌤️'},
      {'value': 'full-day', 'label': l10n.prefFullDayLabel, 'time': '4+ hours', 'emoji': '☀️'},
    ];

    return options.map((option) {
      final isSelected = _timeAvailable == option['value'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSelectableCard(
          isSelected: isSelected,
          borderColor: Colors.pink,
          onTap: () => _updatePreference('timeAvailable', option['value']),
          child: Row(
            children: [
              Text(
                option['emoji'] as String,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['label'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      option['time'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildInterestsGrid() {
    final l10n = AppLocalizations.of(context)!;
    final interests = [
      {'value': 'food', 'label': l10n.prefInterestFood, 'emoji': '🍽️'},
      {'value': 'culture', 'label': l10n.prefInterestCulture, 'emoji': '🎨'},
      {'value': 'nature', 'label': l10n.prefInterestNature, 'emoji': '🌲'},
      {'value': 'shopping', 'label': l10n.prefInterestShopping, 'emoji': '🛍️'},
      {'value': 'nightlife', 'label': l10n.prefInterestNightlife, 'emoji': '🌃'},
      {'value': 'wellness', 'label': l10n.prefInterestWellness, 'emoji': '💆'},
      {'value': 'adventure', 'label': l10n.prefInterestAdventure, 'emoji': '🏔️'},
      {'value': 'history', 'label': l10n.prefInterestHistory, 'emoji': '🏛️'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: interests.length,
      itemBuilder: (context, index) {
        final interest = interests[index];
        final isSelected = _interests.contains(interest['value']);
        return _buildSelectableCard(
          isSelected: isSelected,
          borderColor: Colors.red,
          onTap: () => _toggleInterest(interest['value']!),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                interest['emoji']!,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                interest['label']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectableCard({
    required bool isSelected,
    required Color borderColor,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? borderColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? borderColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  List<Color> _getBudgetGradientColors(Color baseColor) {
    if (baseColor == Colors.green) {
      return [const Color(0xFF4ADE80), const Color(0xFF10B981)]; // green-400 to emerald-500
    } else if (baseColor == Colors.blue) {
      return [const Color(0xFF60A5FA), const Color(0xFF06B6D4)]; // blue-400 to cyan-500
    } else if (baseColor == Colors.purple) {
      return [const Color(0xFFA78BFA), const Color(0xFFEC4899)]; // purple-400 to pink-500
    } else {
      return [const Color(0xFFFACC15), const Color(0xFFF97316)]; // yellow-400 to orange-500
    }
  }
}
