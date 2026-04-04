import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/l10n/app_localizations.dart';

import '../../../../core/providers/communication_style_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../home/presentation/widgets/moody_character.dart';

/// WanderMood design tokens — onboarding communicatiestijl
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmSky = Color(0xFFA8C8DC);
const Color _wmSkyTint = Color(0xFFEDF5F9);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);
const Color _wmStone = Color(0xFF8C8780);

class CommunicationPreferenceScreen extends ConsumerStatefulWidget {
  const CommunicationPreferenceScreen({super.key});

  @override
  ConsumerState<CommunicationPreferenceScreen> createState() =>
      _CommunicationPreferenceScreenState();
}

class _CommunicationPreferenceScreenState
    extends ConsumerState<CommunicationPreferenceScreen>
    with TickerProviderStateMixin {
  String? _selectedStyle;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  static const List<Map<String, String>> _optionMeta = [
    {'key': 'friendly', 'emoji': '😊'},
    {'key': 'professional', 'emoji': '👔'},
    {'key': 'energetic', 'emoji': '⚡'},
    {'key': 'direct', 'emoji': '🎯'},
  ];

  ({String title, String hint}) _styleLabels(String key, AppLocalizations l10n) {
    switch (key) {
      case 'friendly':
        return (title: l10n.prefStyleFriendly, hint: l10n.prefStyleFriendlyDesc);
      case 'professional':
        return (title: l10n.prefStyleProfessional, hint: l10n.prefStyleProfessionalDesc);
      case 'energetic':
        return (title: l10n.prefStyleEnergetic, hint: l10n.prefStyleEnergeticDesc);
      case 'direct':
        return (title: l10n.prefStyleDirect, hint: l10n.prefStyleDirectDesc);
      default:
        return (title: key, hint: '');
    }
  }

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

  void _onSelect(String key) {
    HapticFeedback.selectionClick();
    setState(() => _selectedStyle = key);
    ref.read(communicationStyleProvider.notifier).setCommunicationStyle(key);
    ref.read(preferencesProvider.notifier).updateCommunicationStyle(key);
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  tooltip: l10n.prefBack,
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
                      widthFactor: 0.25,
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleTransition(
                    alignment: Alignment.center,
                    scale: _breathScale,
                    child: const MoodyCharacter(
                      size: 72,
                      mood: 'idle',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _SpeechBubble(text: l10n.commPrefSpeechBubble)),
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
                    l10n.commPrefChooseStyleTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _wmCharcoal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.commPrefChooseStyleSubtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _wmDusk,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.98,
                  ),
                  itemCount: _optionMeta.length,
                  itemBuilder: (context, index) {
                    final o = _optionMeta[index];
                    final key = o['key']!;
                    final labels = _styleLabels(key, l10n);
                    final selected = _selectedStyle == key;
                    return _StyleTile(
                      emoji: o['emoji']!,
                      title: labels.title,
                      hint: labels.hint,
                      selected: selected,
                      onTap: () => _onSelect(key),
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
                  onPressed: _selectedStyle != null
                      ? () => context.go('/preferences/interests')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedStyle != null
                        ? _wmForest
                        : _wmParchment,
                    foregroundColor: _selectedStyle != null
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
                    l10n.interestsContinue,
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

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(
          size: const Size(10, 14),
          painter: _BubbleTailPainter(),
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
                text,
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

class _BubbleTailPainter extends CustomPainter {
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

class _StyleTile extends StatelessWidget {
  const _StyleTile({
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
          duration: const Duration(milliseconds: 320),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? _wmForestTint : Colors.white,
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
                    fontWeight: FontWeight.w400,
                    color: _wmStone,
                    height: 1.25,
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
