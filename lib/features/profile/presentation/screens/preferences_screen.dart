import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/constants/inclusion_preference_options.dart';
import 'package:wandermood/features/profile/presentation/widgets/inclusion_dietary_preference_field.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final supabase = Supabase.instance.client;

  String? _communicationStyle;
  String? _planningPace;
  List<String> _travelInterests = [];
  List<String> _socialVibe = [];
  List<String> _travelStyles = [];
  List<String> _favoriteMoods = [];
  List<String> _selectedMoods = [];
  final Set<String> _dietaryInclusionKeys = {};

  bool _isLoading = true;
  bool _hasChanges = false;

  static const _communicationOptions = ['Friendly', 'Playful', 'Calm', 'Practical'];
  static const _interestOptions = [
    'Food',
    'Culture',
    'Nature',
    'Nightlife',
    'Shopping',
    'Wellness',
  ];
  static const _socialOptions = ['Solo', 'Small-group', 'Mix', 'Social'];
  static const _travelStyleOptions = [
    'Relaxed',
    'Adventurous',
    'Cultural',
    'City-break',
  ];
  static const _favoriteMoodOptions = [
    'Happy',
    'Adventurous',
    'Calm',
    'Romantic',
    'Energetic',
  ];
  static const _planningOptions = [
    'Same Day Planner',
    'Week Ahead Planner',
    'Spontaneous',
  ];
  static const _selectedMoodOptions = [
    'Happy',
    'Relaxed',
    'Cultural',
    'Romantic',
    'Energetic',
    'Creative',
  ];

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
          .select('''
            communication_style,
            travel_interests,
            social_vibe,
            travel_styles,
            favorite_moods,
            planning_pace,
            selected_moods,
            dietary_restrictions
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        final drRaw = response?['dietary_restrictions'] as List?;
        final dr = normalizeInclusionPreferenceKeys(
          (drRaw ?? const []).map((e) => e.toString()),
        );
        setState(() {
          _communicationStyle = response?['communication_style'] as String?;
          _travelInterests =
              List<String>.from((response?['travel_interests'] as List?) ?? const []);
          _socialVibe =
              List<String>.from((response?['social_vibe'] as List?) ?? const []);
          _travelStyles =
              List<String>.from((response?['travel_styles'] as List?) ?? const []);
          _favoriteMoods =
              List<String>.from((response?['favorite_moods'] as List?) ?? const []);
          _planningPace = response?['planning_pace'] as String?;
          _selectedMoods =
              List<String>.from((response?['selected_moods'] as List?) ?? const []);
          _dietaryInclusionKeys
            ..clear()
            ..addAll(dr);
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
        'communication_style': _communicationStyle,
        'travel_interests': _travelInterests,
        'social_vibe': _socialVibe,
        'travel_styles': _travelStyles,
        'favorite_moods': _favoriteMoods,
        'planning_pace': _planningPace,
        'selected_moods': _selectedMoods,
        'dietary_restrictions':
            normalizeInclusionPreferenceKeys(_dietaryInclusionKeys),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('user_preferences')
          .upsert({'user_id': userId, ...updateData}, onConflict: 'user_id');

      ref.invalidate(preferencesProvider);

      if (mounted) {
        setState(() => _hasChanges = false);
        showWanderMoodToast(
          context,
          message: AppLocalizations.of(context)!.prefSavedSuccess,
          duration: const Duration(seconds: 1),
        );

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

  void _toggleValue(List<String> list, String value) {
    setState(() {
      _hasChanges = true;
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  void _toggleDietaryInclusionKey(String key) {
    setState(() {
      _hasChanges = true;
      if (_dietaryInclusionKeys.contains(key)) {
        _dietaryInclusionKeys.remove(key);
      } else {
        _dietaryInclusionKeys.add(key);
      }
    });
  }

  void _setSingle(String key, String? value) {
    setState(() {
      _hasChanges = true;
      if (key == 'communicationStyle') {
        _communicationStyle = value;
      } else if (key == 'planningPace') {
        _planningPace = value;
      }
    });
  }

  String _communicationLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Friendly':
        return l10n.prefCommFriendly;
      case 'Playful':
        return l10n.prefCommPlayful;
      case 'Calm':
        return l10n.prefCommCalm;
      case 'Practical':
        return l10n.prefCommPractical;
      default:
        return stored;
    }
  }

  String _interestLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Food':
        return l10n.prefIntFood;
      case 'Culture':
        return l10n.prefIntCulture;
      case 'Nature':
        return l10n.prefIntNature;
      case 'Nightlife':
        return l10n.prefIntNightlife;
      case 'Shopping':
        return l10n.prefIntShopping;
      case 'Wellness':
        return l10n.prefIntWellness;
      default:
        return stored;
    }
  }

  String _socialLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Solo':
        return l10n.prefSocSolo;
      case 'Small-group':
        return l10n.prefSocSmallGroup;
      case 'Mix':
        return l10n.prefSocMix;
      case 'Social':
        return l10n.prefSocSocial;
      default:
        return stored;
    }
  }

  String _travelStyleLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Relaxed':
        return l10n.prefTravelRelaxed;
      case 'Adventurous':
        return l10n.prefTravelAdventurous;
      case 'Cultural':
        return l10n.prefTravelCultural;
      case 'City-break':
        return l10n.prefTravelCityBreak;
      default:
        return stored;
    }
  }

  String _favoriteMoodLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Happy':
        return l10n.prefFavHappy;
      case 'Adventurous':
        return l10n.prefFavAdventurous;
      case 'Calm':
        return l10n.prefFavCalm;
      case 'Romantic':
        return l10n.prefFavRomantic;
      case 'Energetic':
        return l10n.prefFavEnergetic;
      default:
        return stored;
    }
  }

  String _planningLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Same Day Planner':
        return l10n.prefPlanSameDay;
      case 'Week Ahead Planner':
        return l10n.prefPlanWeekAhead;
      case 'Spontaneous':
        return l10n.prefPlanSpontaneous;
      default:
        return stored;
    }
  }

  String _selectedMoodLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Happy':
        return l10n.prefSelHappy;
      case 'Relaxed':
        return l10n.prefSelRelaxed;
      case 'Cultural':
        return l10n.prefSelCultural;
      case 'Romantic':
        return l10n.prefSelRomantic;
      case 'Energetic':
        return l10n.prefSelEnergetic;
      case 'Creative':
        return l10n.prefSelCreative;
      default:
        return stored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2A6049)))
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 10,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF4A4640)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            l10n.preferencesScreenTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1C18),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _hasChanges ? _savePreferences : null,
                          child: Text(
                            l10n.prefSave,
                            style: GoogleFonts.poppins(
                              color: _hasChanges
                                  ? const Color(0xFF2A6049)
                                  : const Color(0xFF8C8780),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFE8E2D8)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(l10n.prefSectionCommunicationStyle),
                        const SizedBox(height: 10),
                        _buildSingleOptions(
                          l10n: l10n,
                          options: _communicationOptions,
                          selected: _communicationStyle,
                          labelFor: _communicationLabel,
                          onSelected: (v) => _setSingle('communicationStyle', v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionInterests),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          l10n: l10n,
                          options: _interestOptions,
                          selected: _travelInterests,
                          labelFor: _interestLabel,
                          onTap: (v) => _toggleValue(_travelInterests, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionSocialVibe),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          l10n: l10n,
                          options: _socialOptions,
                          selected: _socialVibe,
                          labelFor: _socialLabel,
                          onTap: (v) => _toggleValue(_socialVibe, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionTravelStyles),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          l10n: l10n,
                          options: _travelStyleOptions,
                          selected: _travelStyles,
                          labelFor: _travelStyleLabel,
                          onTap: (v) => _toggleValue(_travelStyles, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionDietaryInclusion),
                        const SizedBox(height: 8),
                        Text(
                          l10n.prefDietaryInclusionSubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF8C8780),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InclusionDietaryPreferenceField(
                          selected: _dietaryInclusionKeys,
                          onToggleKey: _toggleDietaryInclusionKey,
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionFavoriteMoods),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          l10n: l10n,
                          options: _favoriteMoodOptions,
                          selected: _favoriteMoods,
                          labelFor: _favoriteMoodLabel,
                          onTap: (v) => _toggleValue(_favoriteMoods, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionPlanningPace),
                        const SizedBox(height: 10),
                        _buildSingleOptions(
                          l10n: l10n,
                          options: _planningOptions,
                          selected: _planningPace,
                          labelFor: _planningLabel,
                          onSelected: (v) => _setSingle('planningPace', v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(l10n.prefSectionSelectedMoods),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          l10n: l10n,
                          options: _selectedMoodOptions,
                          selected: _selectedMoods,
                          labelFor: _selectedMoodLabel,
                          onTap: (v) => _toggleValue(_selectedMoods, v),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E1C18),
      ),
    );
  }

  Widget _buildSingleOptions({
    required AppLocalizations l10n,
    required List<String> options,
    required String? selected,
    required String Function(AppLocalizations l10n, String stored) labelFor,
    required void Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (o) => ChoiceChip(
              label: Text(labelFor(l10n, o)),
              selected: selected == o,
              selectedColor: const Color(0xFF2A6049),
              labelStyle: GoogleFonts.poppins(
                color: selected == o ? Colors.white : const Color(0xFF1E1C18),
                fontSize: 12,
              ),
              side: const BorderSide(color: Color(0xFFE8E2D8)),
              onSelected: (_) => onSelected(o),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChipOptions({
    required AppLocalizations l10n,
    required List<String> options,
    required List<String> selected,
    required String Function(AppLocalizations l10n, String stored) labelFor,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (o) => FilterChip(
              label: Text(labelFor(l10n, o)),
              selected: selected.contains(o),
              selectedColor: const Color(0xFFEBF3EE),
              checkmarkColor: const Color(0xFF2A6049),
              labelStyle: GoogleFonts.poppins(
                color: selected.contains(o)
                    ? const Color(0xFF2A6049)
                    : const Color(0xFF1E1C18),
                fontSize: 12,
              ),
              side: const BorderSide(color: Color(0xFFE8E2D8)),
              onSelected: (_) => onTap(o),
            ),
          )
          .toList(),
    );
  }
}
