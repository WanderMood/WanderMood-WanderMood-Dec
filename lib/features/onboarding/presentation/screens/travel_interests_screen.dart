import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/preferences_provider.dart';
import '../../../home/presentation/widgets/moody_character.dart';

/// WanderMood design tokens — interesses onboarding
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);

/// UI + opslag-key (keys sluiten aan bij [UserPreferencesService] waar mogelijk).
const List<({String storageKey, String emoji, String label})> _interestOptions = [
  (storageKey: 'Food & Dining', emoji: '🍽', label: 'Eten & drinken'),
  (storageKey: 'Arts & Culture', emoji: '🎨', label: 'Kunst & cultuur'),
  (storageKey: 'Shopping & Markets', emoji: '🛍', label: 'Winkelen & markten'),
  (storageKey: 'Sports', emoji: '⚽', label: 'Sport & activiteiten'),
  (storageKey: 'Nature & Outdoors', emoji: '🌿', label: 'Natuur & parken'),
  (storageKey: 'Nightlife', emoji: '🎭', label: 'Uitgaan & nightlife'),
  (storageKey: 'Coffee & Cafés', emoji: '☕', label: 'Koffie & cafés'),
  (storageKey: 'Photography & Spots', emoji: '📸', label: 'Fotografie & spots'),
];

class TravelInterestsScreen extends ConsumerStatefulWidget {
  const TravelInterestsScreen({super.key});

  @override
  ConsumerState<TravelInterestsScreen> createState() =>
      _TravelInterestsScreenState();
}

class _TravelInterestsScreenState extends ConsumerState<TravelInterestsScreen>
    with TickerProviderStateMixin {
  final Set<String> _selectedInterests = {};

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

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
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  void _toggleInterest(String storageKey) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedInterests.contains(storageKey)) {
        _selectedInterests.remove(storageKey);
      } else {
        _selectedInterests.add(storageKey);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(preferencesProvider.notifier)
            .updateTravelInterests(_selectedInterests.toList());
      }
    });
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/preferences/communication');
    }
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
                      widthFactor: 0.5,
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _wmSkyTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _wmSky, width: 0.5),
                            ),
                            child: Text(
                              'Wat vind jij leuk? Ik zoek het voor je uit! 🔍',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: _wmCharcoal,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(10, 14),
                          painter: _BubbleRightTailPainter(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScaleTransition(
                    alignment: Alignment.center,
                    scale: _breathScale,
                    child: const MoodyCharacter(
                      size: 64,
                      mood: 'idle',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wat zijn jouw interesses?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _wmCharcoal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kies alles wat je aanspreekt.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _wmDusk,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Meerdere keuzes mogelijk',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _wmStone,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Twee kolommen (twee "verticale rijen" kaarten) × vier horizontale rijen = 8 tegels.
                    const gap = 12.0;
                    const crossAxisCount = 2;
                    const cellHeight = 104.0;
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _interestOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: gap,
                        mainAxisSpacing: gap,
                        mainAxisExtent: cellHeight,
                      ),
                      itemBuilder: (context, index) {
                        final o = _interestOptions[index];
                        final selected =
                            _selectedInterests.contains(o.storageKey);
                        return _InterestChip(
                          emoji: o.emoji,
                          label: o.label,
                          selected: selected,
                          onTap: () => _toggleInterest(o.storageKey),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedInterests.isNotEmpty
                      ? () => context.go('/preferences/travel-preferences')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedInterests.isNotEmpty
                        ? _wmForest
                        : _wmParchment,
                    foregroundColor: _selectedInterests.isNotEmpty
                        ? Colors.white
                        : _wmStone,
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
}

class _BubbleRightTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 3)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height - 3)
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

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: selected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _wmForestTint : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _wmForest : _wmParchment,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected ? _wmForest : _wmDusk,
                        height: 1.2,
                      ),
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
}
