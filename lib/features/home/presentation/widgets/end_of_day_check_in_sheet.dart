import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/mood/services/end_of_day_check_in_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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
  // Internal keys used for DB storage (language-neutral)
  static const _q1Keys = ['activities', 'friends', 'exploring', 'food', 'relaxing'];
  static const _q2Keys = ['amazing', 'good', 'ok', 'not_for_me'];
  static const _q3EmojiKeys = <String, String>{
    '😊': 'happy',
    '😌': 'relaxed',
    '😴': 'tired',
    '🤔': 'mixed',
  };

  List<String> _q1Labels(AppLocalizations l10n) => [
    l10n.checkInQ1Activities,
    l10n.checkInQ1Friends,
    l10n.checkInQ1Exploring,
    l10n.checkInQ1Food,
    l10n.checkInQ1Relaxing,
  ];

  List<String> _q2Labels(AppLocalizations l10n) => [
    l10n.checkInQ2Amazing,
    l10n.checkInQ2Good,
    l10n.checkInQ2Ok,
    l10n.checkInQ2NotForMe,
  ];

  Map<String, String> _q3Labels(AppLocalizations l10n) => {
    '😊': l10n.checkInQ3Happy,
    '😌': l10n.checkInQ3Relaxed,
    '😴': l10n.checkInQ3Tired,
    '🤔': l10n.checkInQ3Mixed,
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
          _error = AppLocalizations.of(context)!.checkInSaveError;
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
    final l10n = AppLocalizations.of(context)!;
    final labels = _q1Labels(l10n);
    return Column(
      children: [
        Text(
          l10n.checkInQ1Title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.checkInQ1Subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.35,
            color: _wmStone,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.checkInQ1Question,
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
            itemCount: _q1Keys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final key = _q1Keys[i];
              final label = labels[i];
              return _ChipButton(
                label: label,
                selected: _q1 == key,
                onTap: () => _advanceFromQ1(key),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _onSkip,
          child: Text(
            l10n.checkInMaybeLater,
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
    final l10n = AppLocalizations.of(context)!;
    final name = widget.spotlightActivityName.trim();
    final labels = _q2Labels(l10n);
    return Column(
      children: [
        Text(
          l10n.checkInQ2Question(name),
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
          children: List.generate(_q2Keys.length, (i) {
            final key = _q2Keys[i];
            final label = labels[i];
            return _ChipButton(
              label: label,
              selected: _q2 == key,
              onTap: () => _advanceFromQ2(key),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQ3() {
    final l10n = AppLocalizations.of(context)!;
    final localizedLabels = _q3Labels(l10n);
    return Column(
      children: [
        Text(
          l10n.checkInQ3Question,
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
          children: _q3EmojiKeys.entries.map((e) {
            final displayLabel = '${e.key} ${localizedLabels[e.key]}';
            return _ChipButton(
              label: displayLabel,
              selected: _q3Emoji == e.key,
              onTap: () => _advanceFromQ3(e.key, e.value),
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
          AppLocalizations.of(context)!.checkInDoneTitle,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _wmCharcoal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.checkInDoneSubtitle,
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
                    AppLocalizations.of(context)!.checkInClose,
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
