import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String? _communicationStyle;
  String? _planningPace;
  List<String> _travelInterests = [];
  List<String> _socialVibe = [];
  List<String> _travelStyles = [];
  List<String> _favoriteMoods = [];
  List<String> _selectedMoods = [];

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
          .select('''
            communication_style,
            travel_interests,
            social_vibe,
            travel_styles,
            favorite_moods,
            planning_pace,
            selected_moods
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
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
        'updated_at': DateTime.now().toIso8601String(),
      };

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

  @override
  Widget build(BuildContext context) {
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
                            'Bewerk voorkeuren',
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
                            AppLocalizations.of(context)!.prefSave,
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
                        _buildSectionTitle('Communicatiestijl'),
                        const SizedBox(height: 10),
                        _buildSingleOptions(
                          options: const ['Friendly', 'Playful', 'Calm', 'Practical'],
                          selected: _communicationStyle,
                          onSelected: (v) => _setSingle('communicationStyle', v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle('Interesses'),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          options: const ['Food', 'Culture', 'Nature', 'Nightlife', 'Shopping', 'Wellness'],
                          selected: _travelInterests,
                          onTap: (v) => _toggleValue(_travelInterests, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle('Sociale vibe'),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          options: const ['Solo', 'Small-group', 'Mix', 'Social'],
                          selected: _socialVibe,
                          onTap: (v) => _toggleValue(_socialVibe, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle('Reisstijlen'),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          options: const ['Relaxed', 'Adventurous', 'Cultural', 'City-break'],
                          selected: _travelStyles,
                          onTap: (v) => _toggleValue(_travelStyles, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle('Favoriete moods'),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          options: const ['Happy', 'Adventurous', 'Calm', 'Romantic', 'Energetic'],
                          selected: _favoriteMoods,
                          onTap: (v) => _toggleValue(_favoriteMoods, v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle('Planningstempo'),
                        const SizedBox(height: 10),
                        _buildSingleOptions(
                          options: const ['Same Day Planner', 'Week Ahead Planner', 'Spontaneous'],
                          selected: _planningPace,
                          onSelected: (v) => _setSingle('planningPace', v),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle('Geselecteerde moods'),
                        const SizedBox(height: 10),
                        _buildChipOptions(
                          options: const ['Happy', 'Relaxed', 'Cultural', 'Romantic', 'Energetic', 'Creative'],
                          selected: _selectedMoods,
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
    required List<String> options,
    required String? selected,
    required void Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (o) => ChoiceChip(
              label: Text(o),
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
    required List<String> options,
    required List<String> selected,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (o) => FilterChip(
              label: Text(o),
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
