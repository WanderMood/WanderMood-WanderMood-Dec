import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/auth_helper.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/mood/services/end_of_day_check_in_service.dart';

// WanderMood design tokens (Moody Hub / sheets)
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

const List<String> _openerFallbacks = [
  'Je bent thuis! Hoe was je dag?',
  'Vertel! Hoe was het vandaag?',
  'Hoe ging het vandaag?',
  'Moody is benieuwd — hoe was je dag?',
];

const Map<String, String> _followupFallbacks = {
  'Geweldig! 🤩': 'Tof! Wat was het mooiste moment? 🌟',
  'Best goed 😊': 'Fijn! Iets wat er echt uitsprong?',
  'Oké 😐': 'Eerlijk antwoord. Wat had beter gekund?',
  'Tegenvaller 😔': 'Jammer... Wat ging er mis?',
};

const List<String> _closingFallbacks = [
  'Goed gedaan vandaag. Slaap lekker 🌙',
  'Moody onthoudt dit voor morgen. Tot dan! ✨',
  'Dankje voor het delen. Morgen weer een mooie dag 🌟',
  'Slaap lekker. Morgen maken we er wat moois van 🌙',
];

const List<String> _exchange1Chips = [
  'Geweldig! 🤩',
  'Best goed 😊',
  'Oké 😐',
  'Tegenvaller 😔',
];

const List<String> _exchange2Chips = [
  'De activiteiten 🎯',
  'Met mensen 👥',
  'Het ontdekken 🔍',
  'Lekker gegeten 🍽',
  'Gewoon relaxen 🛋',
  'Iets onverwachts ✨',
];

/// End-of-day "Hoe was je dag?" — three short chip exchanges; Moody speaks first.
class HoeWasJeDagSheet extends StatefulWidget {
  const HoeWasJeDagSheet({
    super.key,
    required this.completedActivities,
    required this.userId,
  });

  final List<String> completedActivities;
  final String userId;

  @override
  State<HoeWasJeDagSheet> createState() => _HoeWasJeDagSheetState();
}

class _HoeWasJeDagSheetState extends State<HoeWasJeDagSheet>
    with TickerProviderStateMixin {
  int _exchange = 1;
  String? _exchange1Answer;
  String? _exchange2Answer;
  String _moodyMessage = '';
  String _closingMessage = '';
  bool _messageLoading = true;
  bool _saving = false;
  String? _saveError;

  String? _chipSelecting1;
  String? _chipSelecting2;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final AnimationController _closingPulseController;
  late final Animation<double> _closingPulseScale;

  final TextEditingController _optionalReflectionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _closingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _closingPulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _closingPulseController, curve: Curves.easeOut),
    );

    _loadOpener();
  }

  @override
  void dispose() {
    _optionalReflectionController.dispose();
    _breathController.dispose();
    _closingPulseController.dispose();
    super.dispose();
  }

  TextStyle get _wmCardTitle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _wmCharcoal,
        height: 1.35,
      );

  TextStyle get _wmCaption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: _wmStone,
      );

  Future<String?> _invokeMoody(Map<String, dynamic> body) async {
    try {
      await AuthHelper.ensureValidSession();
      final response = await Supabase.instance.client.functions.invoke(
        'moody',
        body: body,
      );

      if (response.status != 200) return null;
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final m = raw['message'] as String?;
        if (m != null && m.trim().isNotEmpty) return m.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadOpener() async {
    setState(() {
      _messageLoading = true;
      _moodyMessage = '';
    });

    String? text;
    try {
      text = await _invokeMoody({
        'action': 'end_of_day_opener',
        'user_id': widget.userId,
        'completed_activities': widget.completedActivities,
        'time_of_day': 'evening',
      }).timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
    } catch (_) {
      text = null;
    }

    if (!mounted) return;
    setState(() {
      _moodyMessage = text ??
          _openerFallbacks[math.Random().nextInt(_openerFallbacks.length)];
      _messageLoading = false;
    });
  }

  Future<void> _loadFollowup() async {
    final first = _exchange1Answer;
    if (first == null) return;

    setState(() {
      _messageLoading = true;
      _moodyMessage = '';
    });

    String? text;
    try {
      text = await _invokeMoody({
        'action': 'end_of_day_followup',
        'user_id': widget.userId,
        'first_answer': first,
        'completed_activities': widget.completedActivities,
      }).timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
    } catch (_) {
      text = null;
    }

    if (!mounted) return;
    setState(() {
      _moodyMessage =
          text ?? _followupFallbacks[first] ?? 'Vertel eens meer! ✨';
      _messageLoading = false;
    });
  }

  Future<void> _loadClosing() async {
    final first = _exchange1Answer;
    final second = _exchange2Answer;
    if (first == null || second == null) return;

    setState(() {
      _messageLoading = true;
      _moodyMessage = '';
    });

    String? text;
    try {
      text = await _invokeMoody({
        'action': 'end_of_day_close',
        'user_id': widget.userId,
        'first_answer': first,
        'second_answer': second,
        'completed_activities': widget.completedActivities,
      }).timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
    } catch (_) {
      text = null;
    }

    if (!mounted) return;
    final closing = text ??
        _closingFallbacks[math.Random().nextInt(_closingFallbacks.length)];
    setState(() {
      _closingMessage = closing;
      _moodyMessage = closing;
      _messageLoading = false;
    });
    await _closingPulseController.forward(from: 0);
  }

  String _mapAnswerToMood(String answer) {
    if (answer.contains('🤩')) return 'amazing';
    if (answer.contains('😊')) return 'good';
    if (answer.contains('😐')) return 'okay';
    if (answer.contains('😔')) return 'low';
    return 'okay';
  }

  Future<void> _saveAndDismiss() async {
    final e1 = _exchange1Answer;
    final e2 = _exchange2Answer;
    if (e1 == null || e2 == null) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final date = EndOfDayCheckInService.todayDateString();
    try {
      await EndOfDayCheckInService.submit(
        client: Supabase.instance.client,
        userId: widget.userId,
        mood: _mapAnswerToMood(e1),
        completedActivityNames: widget.completedActivities,
        reactions: [e1, e2],
        dateYyyyMmDd: date,
        dayRating: e1,
        highlight: e2,
        closingMessage: _closingMessage,
        reflectionText: _optionalReflectionController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = _saveErrorMessageForUser(e);
        });
      }
    }
  }

  String _saveErrorMessageForUser(Object e) {
    const fallback = 'Opslaan lukte niet. Probeer het nog eens.';
    if (!kDebugMode) return fallback;
    if (e is PostgrestException) {
      final msg = e.message.trim();
      if (msg.isEmpty) return '$fallback\n(debug: code ${e.code})';
      return '$fallback\n\nDebug: $msg';
    }
    return '$fallback\n\nDebug: $e';
  }

  Future<void> _onExchange1Chip(String answer) async {
    if (_exchange != 1 || _chipSelecting1 != null) return;
    setState(() => _chipSelecting1 = answer);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _exchange1Answer = answer;
      _exchange = 2;
      _chipSelecting1 = null;
    });
    await _loadFollowup();
  }

  Future<void> _onExchange2Chip(String answer) async {
    if (_exchange != 2 || _chipSelecting2 != null) return;
    setState(() => _chipSelecting2 = answer);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _exchange2Answer = answer;
      _exchange = 3;
      _chipSelecting2 = null;
    });
    _breathController.stop();
    await _loadClosing();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _wmWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _wmParchment,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressDots(),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_exchange),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMoody(),
                    const SizedBox(height: 20),
                    _buildMessageBlock(),
                    const SizedBox(height: 28),
                    if (_exchange == 1) _buildExchange1Chips(),
                    if (_exchange == 2) _buildExchange2Chips(),
                    if (_exchange == 3 && !_messageLoading)
                      _buildExchange3Cta(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < _exchange;
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

  Widget _buildMoody() {
    if (_exchange == 3) {
      return AnimatedBuilder(
        animation: _closingPulseScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _closingPulseScale.value,
            child: child,
          );
        },
        child: const MoodyCharacter(size: 90, mood: 'happy'),
      );
    }

    return AnimatedBuilder(
      animation: _breathScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _breathScale.value,
          child: child,
        );
      },
      child: const MoodyCharacter(size: 90, mood: 'idle'),
    );
  }

  Widget _buildMessageBlock() {
    if (_messageLoading) {
      return SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _wmForest.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Text(
        _moodyMessage,
        textAlign: TextAlign.center,
        style: _wmCardTitle,
      ),
    );
  }

  Widget _buildExchange1Chips() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_exchange1Chips.length, (i) {
            final chip = _exchange1Chips[i];
            final selecting = _chipSelecting1 == chip;
            final hidden =
                _chipSelecting1 != null && _chipSelecting1 != chip;

            Widget child = _buildChip(
              label: chip,
              selected: selecting,
              onTap: () => _onExchange1Chip(chip),
            );

            if (selecting) {
              child = TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.05),
                duration: const Duration(milliseconds: 150),
                builder: (context, scale, c) =>
                    Transform.scale(scale: scale, child: c),
                child: child,
              );
            }

            child = AnimatedOpacity(
              opacity: hidden ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: child,
            );

            return child
                .animate()
                .fadeIn(duration: 200.ms, delay: (i * 60).ms);
          }),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Misschien later',
            style: _wmCaption,
          ),
        ),
      ],
    );
  }

  Widget _buildExchange2Chips() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_exchange2Chips.length, (i) {
        final chip = _exchange2Chips[i];
        final selecting = _chipSelecting2 == chip;
        final hidden = _chipSelecting2 != null && _chipSelecting2 != chip;

        Widget child = _buildChip(
          label: chip,
          selected: selecting,
          onTap: () => _onExchange2Chip(chip),
        );

        if (selecting) {
          child = TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.05),
            duration: const Duration(milliseconds: 150),
            builder: (context, scale, c) =>
                Transform.scale(scale: scale, child: c),
            child: child,
          );
        }

        child = AnimatedOpacity(
          opacity: hidden ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: child,
        );

        return child.animate().fadeIn(duration: 200.ms, delay: (i * 60).ms);
      }),
    );
  }

  Widget _buildExchange3Cta() {
    return Column(
      children: [
        Text(
          'Nog iets wat je wilt kwijt? Alles mag — of laat leeg en ga lekker slapen. ✨',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: _wmCharcoal.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _optionalReflectionController,
          maxLines: 4,
          maxLength: 500,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: _wmCharcoal,
            height: 1.35,
          ),
          decoration: InputDecoration(
            hintText: 'Typ hier… (optioneel)',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: _wmStone,
            ),
            filled: true,
            fillColor: _wmCream,
            counterStyle: GoogleFonts.poppins(fontSize: 11, color: _wmStone),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _wmParchment, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _wmParchment, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _wmForest, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_saveError != null) ...[
          Text(
            _saveError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _wmForest,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: _saving ? null : _saveAndDismiss,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Welterusten Moody 🌙',
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

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _wmForestTint : _wmCream,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _wmForest : _wmParchment,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? _wmForest : _wmCharcoal,
            ),
          ),
        ),
      ),
    );
  }
}
