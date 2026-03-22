import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/preferences_provider.dart';
import '../../../home/presentation/widgets/moody_character.dart';

/// WanderMood — gecombineerde reisvoorkeuren (stap 3/4)
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);

/// Zelfde opslag-keys als voorheen (Supabase / preferences_provider).
const _allowedPaceKeys = <String>{
  'Right Now Vibes',
  'Same Day Planner',
  'Master Planner',
};

const _allowedTravelStyleKeys = <String>{
  'Local Experience',
  'Luxury Seeker',
  'Budget Conscious',
  'Off the Beaten Path',
  'Tourist Highlights',
};

class CombinedTravelPreferencesScreen extends ConsumerStatefulWidget {
  const CombinedTravelPreferencesScreen({super.key});

  @override
  ConsumerState<CombinedTravelPreferencesScreen> createState() =>
      _CombinedTravelPreferencesScreenState();
}

class _CombinedTravelPreferencesScreenState
    extends ConsumerState<CombinedTravelPreferencesScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedVibes = {};
  String? _selectedPace;
  final Set<String> _selectedStyles = {};
  static const int _maxStyleSelections = 3;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  static const List<({String key, String emoji, String title, String hint})>
      _socialOptions = [
    (
      key: 'Solo Adventures',
      emoji: '🧘',
      title: 'Solo-avonturen',
      hint: 'Tijd voor mezelf',
    ),
    (
      key: 'Small Groups',
      emoji: '👫',
      title: 'Kleine groepen',
      hint: 'Intieme sfeer',
    ),
    (
      key: 'Social Butterfly',
      emoji: '🦋',
      title: 'Sociale vlinder',
      hint: 'Nieuwe mensen',
    ),
    (
      key: 'Mood Dependent',
      emoji: '🎭',
      title: 'Wisselend',
      hint: 'Soms solo, soms sociaal',
    ),
  ];

  static const List<({String key, String label})> _paceOptions = [
    (key: 'Right Now Vibes', label: 'Nu direct ⚡'),
    (key: 'Same Day Planner', label: 'Vandaag 📅'),
    (key: 'Master Planner', label: 'Gepland 🗓'),
  ];

  static const List<
          ({
            String key,
            String emoji,
            String title,
            String subtitle,
            Color emojiBg,
          })>
      _travelOptions = [
    (
      key: 'Local Experience',
      emoji: '🏡',
      title: 'Lokale ervaring',
      subtitle: 'Authentiek en buiten de standaardroutes.',
      emojiBg: Color(0xFFEBF3EE),
    ),
    (
      key: 'Luxury Seeker',
      emoji: '✨',
      title: 'Luxezoeker',
      subtitle: 'Comfort en bijzondere ervaringen.',
      emojiBg: Color(0xFFFDF0E8),
    ),
    (
      key: 'Budget Conscious',
      emoji: '💰',
      title: 'Budgetbewust',
      subtitle: 'Maximaal plezier, slim uitgeven.',
      emojiBg: Color(0xFFEDF5F9),
    ),
    (
      key: 'Off the Beaten Path',
      emoji: '⭐',
      title: 'Van de gebaande paden',
      subtitle: 'Verborgen parels en lokale favorieten.',
      emojiBg: Color(0xFFF5F0E8),
    ),
    (
      key: 'Tourist Highlights',
      emoji: '🗺️',
      title: 'Toeristische hoogtepunten',
      subtitle: 'Iconische plekken die je gezien wilt hebben.',
      emojiBg: Color(0xFFEBF3EE),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromProvider());
  }

  void _hydrateFromProvider() {
    if (!mounted) return;
    final prefs = ref.read(preferencesProvider);

    final social = <String>{};
    for (final k in prefs.socialVibe) {
      if (_socialOptions.any((e) => e.key == k)) social.add(k);
    }

    String? pace = prefs.planningPace;
    if (!_allowedPaceKeys.contains(pace)) {
      if (pace == 'Weekend Prepper') {
        pace = 'Master Planner';
      } else {
        pace = null;
      }
    }

    final styles = prefs.travelStyles
        .where(_allowedTravelStyleKeys.contains)
        .toSet();

    setState(() {
      _selectedVibes
        ..clear()
        ..addAll(social);
      _selectedPace = pace;
      _selectedStyles
        ..clear()
        ..addAll(styles);
    });
  }

  bool get _canContinue =>
      _selectedVibes.isNotEmpty &&
      _selectedPace != null &&
      _selectedStyles.isNotEmpty;

  void _toggleSocialVibe(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedVibes.contains(key)) {
        _selectedVibes.remove(key);
      } else {
        _selectedVibes.add(key);
      }
    });
  }

  void _selectPace(String key) {
    HapticFeedback.selectionClick();
    setState(() => _selectedPace = key);
  }

  void _toggleStyle(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedStyles.contains(key)) {
        _selectedStyles.remove(key);
      } else if (_selectedStyles.length < _maxStyleSelections) {
        _selectedStyles.add(key);
      }
    });
  }

  void _onContinue() {
    if (!_canContinue) return;
    final n = ref.read(preferencesProvider.notifier);
    n.updateSocialVibe(_selectedVibes.toList());
    n.updatePlanningPace(_selectedPace!);
    n.updateTravelStyles(_selectedStyles.toList());
    context.go('/preferences/loading');
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/preferences/interests');
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _wmStone,
                    size: 20,
                  ),
                  tooltip: 'Terug',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _wmParchment,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _wmForest,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleTransition(
                    alignment: Alignment.center,
                    scale: _breathScale,
                    child: const MoodyCharacter(
                      size: 64,
                      mood: 'idle',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _MoodySpeechBubble()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jouw reisprofiel',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _wmCharcoal,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Sociale vibe 👥'),
                    const SizedBox(height: 6),
                    Text(
                      'Meerdere keuzes mogelijk',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _wmStone,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.98,
                      ),
                      itemCount: _socialOptions.length,
                      itemBuilder: (context, i) {
                        final o = _socialOptions[i];
                        final sel = _selectedVibes.contains(o.key);
                        return _SocialCard(
                          emoji: o.emoji,
                          title: o.title,
                          hint: o.hint,
                          selected: sel,
                          onTap: () => _toggleSocialVibe(o.key),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Planningsritme ⚡'),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _paceOptions.map((o) {
                          final sel = _selectedPace == o.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _PaceChip(
                              label: o.label,
                              selected: sel,
                              onTap: () => _selectPace(o.key),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Jouw stijl 🌟'),
                    const SizedBox(height: 8),
                    Text(
                      'Kies tot $_maxStyleSelections stijlen die bij je passen.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _wmStone,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._travelOptions.map((o) {
                      final sel = _selectedStyles.contains(o.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TravelStyleRow(
                          emoji: o.emoji,
                          title: o.title,
                          subtitle: o.subtitle,
                          emojiBg: o.emojiBg,
                          selected: sel,
                          onTap: () => _toggleStyle(o.key),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _canContinue ? _onContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _canContinue ? _wmForest : _wmParchment,
                    foregroundColor:
                        _canContinue ? Colors.white : _wmStone,
                    disabledBackgroundColor: _wmParchment,
                    disabledForegroundColor: _wmStone,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Doorgaan →',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _wmCharcoal,
      ),
    );
  }
}

class _MoodySpeechBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(
          size: const Size(10, 14),
          painter: _BubbleLeftTailPainter(),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _wmSkyTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _wmSky, width: 0.5),
              ),
              child: Text(
                'Nog een paar vragen en ik ken je helemaal! ✈️',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _wmCharcoal,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleLeftTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 3)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height - 3)
      ..close();
    canvas.drawPath(path, Paint()..color = _wmSkyTint);
    canvas.drawPath(
      path,
      Paint()
        ..color = _wmSky
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.emoji,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedScale(
          scale: selected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? _wmForestTint : _wmWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _wmForest : _wmParchment,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? _wmForest : _wmCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _wmStone,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaceChip extends StatelessWidget {
  const _PaceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: selected ? _wmForest : _wmWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? _wmForest : _wmParchment,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : _wmDusk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TravelStyleRow extends StatelessWidget {
  const _TravelStyleRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.emojiBg,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color emojiBg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? _wmForestTint : _wmWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _wmForest : _wmParchment,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emojiBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _wmDusk,
                        height: 1.35,
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
