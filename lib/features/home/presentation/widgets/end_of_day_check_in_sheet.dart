import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/mood/services/end_of_day_check_in_service.dart';

const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

/// End-of-day reflection sheet (Moody Hub). Caller supplies [spotlightActivityName] for Q2.
class EndOfDayCheckInSheet extends StatefulWidget {
  const EndOfDayCheckInSheet({
    super.key,
    required this.spotlightActivityName,
    required this.completedActivityNames,
    required this.onDismiss,
  });

  final String spotlightActivityName;
  final List<String> completedActivityNames;
  final VoidCallback onDismiss;

  @override
  State<EndOfDayCheckInSheet> createState() => _EndOfDayCheckInSheetState();
}

class _EndOfDayCheckInSheetState extends State<EndOfDayCheckInSheet>
    with TickerProviderStateMixin {
  static const _q1Options = [
    'De activiteiten 🎯',
    'Met vrienden 👥',
    'Ontdekken 🔍',
    'Eten & drinken 🍽',
    'Relaxen 🛋',
  ];

  static const _q2Options = [
    'Geweldig! 🤩',
    'Goed 👍',
    'Prima',
    'Niet voor mij',
  ];

  static const _q3Options = <String, String>{
    '😊': 'Blij',
    '😌': 'Ontspannen',
    '😴': 'Moe',
    '🤔': 'Gemengd',
  };

  int _step = 0;
  String? _q1;
  String? _q2;
  String? _q3Emoji;
  String? _q3Key;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _submitAndClose() async {
    if (_q1 == null || _q2 == null || _q3Key == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      widget.onDismiss();
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final date = EndOfDayCheckInService.todayDateString();
    try {
      await EndOfDayCheckInService.submit(
        client: Supabase.instance.client,
        userId: user.id,
        mood: _q3Key!,
        completedActivityNames: widget.completedActivityNames,
        reactions: [_q1!, _q2!, _q3Key!],
        dateYyyyMmDd: date,
        dayRating: _q2!,
        highlight: _q1!,
        endMoodLabel: _q3Key!,
      );
      if (mounted) widget.onDismiss();
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Opslaan lukte niet. Probeer het nog eens.';
        });
      }
    }
  }

  void _onSkip() => widget.onDismiss();

  void _advanceFromQ1(String value) {
    setState(() {
      _q1 = value;
      _step = 1;
    });
  }

  void _advanceFromQ2(String value) {
    setState(() {
      _q2 = value;
      _step = 2;
    });
  }

  void _advanceFromQ3(String emoji, String key) {
    setState(() {
      _q3Emoji = emoji;
      _q3Key = key;
      _step = 3;
    });
    _breathController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _wmCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _wmParchment,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _progressDots(),
            const SizedBox(height: 16),
            if (_step < 3) ...[
              AnimatedBuilder(
                animation: _breathScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathScale.value,
                    child: child,
                  );
                },
                child: const MoodyCharacter(
                  size: 80,
                  mood: 'idle',
                  mouthScaleFactor: 1.0,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const MoodyCharacter(
                size: 80,
                mood: 'happy',
                mouthScaleFactor: 1.0,
              ),
              const SizedBox(height: 16),
            ],
            if (_step == 0) _buildQ1(),
            if (_step == 1) _buildQ2(),
            if (_step == 2) _buildQ3(),
            if (_step == 3) _buildDone(),
          ],
        ),
      ),
    );
  }

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i <= _step.clamp(0, 2);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? _wmForest : _wmParchment,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQ1() {
    return Column(
      children: [
        Text(
          'Hoe was je dag?',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Moody wil je beter leren kennen 🌙',
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.35,
            color: _wmStone,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Wat was het beste moment van vandaag?',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _q1Options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final label = _q1Options[i];
              return _ChipButton(
                label: label,
                selected: _q1 == label,
                onTap: () => _advanceFromQ1(label),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _onSkip,
          child: Text(
            'Misschien later',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _wmStone,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQ2() {
    final name = widget.spotlightActivityName.trim();
    return Column(
      children: [
        Text(
          'Was $name de moeite waard?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _q2Options
              .map(
                (label) => _ChipButton(
                  label: label,
                  selected: _q2 == label,
                  onTap: () => _advanceFromQ2(label),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQ3() {
    return Column(
      children: [
        Text(
          'Hoe voel je je nu?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _q3Options.entries.map((e) {
            final label = '${e.key} ${e.value}';
            return _ChipButton(
              label: label,
              selected: _q3Emoji == e.key,
              onTap: () => _advanceFromQ3(e.key, e.value.toLowerCase()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        Text(
          'Dankje! Tot morgen 🌟',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Moody onthoudt dit voor de volgende keer',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: _wmStone,
          ),
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _wmForest,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: _submitting ? null : _submitAndClose,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Sluiten',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
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
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _wmForestTint : _wmCream,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _wmForest : _wmParchment,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? _wmForest : _wmCharcoal,
            ),
          ),
        ),
      ),
    );
  }
}
