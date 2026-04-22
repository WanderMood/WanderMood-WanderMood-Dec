import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/utils/canonical_communication_style.dart'
    show canonicalCommunicationStyleKey, profileCommunicationStyleChipLabel;
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/constants/inclusion_preference_options.dart';
import 'package:wandermood/features/profile/presentation/widgets/inclusion_dietary_preference_field.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/domain/enums/moody_feature.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final supabase = Supabase.instance.client;

  String? _communicationStyle;
  List<String> _travelInterests = [];
  List<String> _socialVibe = [];
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
          _communicationStyle = profileCommunicationStyleChipLabel(
            response?['communication_style'] as String?,
          );
          _travelInterests =
              List<String>.from((response?['travel_interests'] as List?) ?? const []);
          _socialVibe =
              List<String>.from((response?['social_vibe'] as List?) ?? const []);
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
        'communication_style': _communicationStyle == null
            ? null
            : canonicalCommunicationStyleKey(_communicationStyle),
        'travel_interests': _travelInterests,
        'social_vibe': _socialVibe,
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
                  color: const Color(0xFFF5F0E8),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 12,
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
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8E2D8)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 44,
                                height: 44,
                                child: MoodyCharacter(
                                  size: 44,
                                  mood: 'happy',
                                  currentFeature: MoodyFeature.none,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.prefSectionInterestsSub,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF4A4640),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: '${l10n.prefSectionCommunicationStyle} 💬',
                          child: _buildSingleOptions(
                            l10n: l10n,
                            options: _communicationOptions,
                            selected: _communicationStyle,
                            labelFor: _communicationLabel,
                            onSelected: (v) => _setSingle('communicationStyle', v),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSectionCard(
                          title: '${l10n.prefSectionInterests} ✨',
                          child: _buildChipOptions(
                            l10n: l10n,
                            options: _interestOptions,
                            selected: _travelInterests,
                            labelFor: _interestLabel,
                            onTap: (v) => _toggleValue(_travelInterests, v),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSectionCard(
                          title: '${l10n.prefSectionSocialVibe} 🫶',
                          child: _buildChipOptions(
                            l10n: l10n,
                            options: _socialOptions,
                            selected: _socialVibe,
                            labelFor: _socialLabel,
                            onTap: (v) => _toggleValue(_socialVibe, v),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSectionCard(
                          title: '${l10n.prefSectionDietaryInclusion} 🌿',
                          subtitle: l10n.prefDietaryInclusionSubtitle,
                          child: InclusionDietaryPreferenceField(
                            selected: _dietaryInclusionKeys,
                            onToggleKey: _toggleDietaryInclusionKey,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _hasChanges ? _savePreferences : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2A6049),
            disabledBackgroundColor: const Color(0xFFE8E2D8),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF8C8780),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.prefSave,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E2D8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C18),
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF8C8780),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
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
