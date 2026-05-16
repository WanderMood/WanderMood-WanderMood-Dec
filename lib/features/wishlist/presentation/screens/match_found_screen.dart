import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/features/wishlist/data/plan_met_vriend_service.dart';
import 'package:wandermood/features/wishlist/domain/plan_met_vriend_flow.dart';

const _wmCream = Color(0xFFF5F0E8);
const _wmForest = Color(0xFF2A6049);
const _wmMint = Color(0xFF5DCAA5);
const _wmCharcoal = Color(0xFF1A1714);
const _wmMuted = Color(0x8C1A1714);

class MatchFoundScreen extends ConsumerStatefulWidget {
  const MatchFoundScreen({super.key, required this.args});

  final PlanMetVriendMatchArgs args;

  @override
  ConsumerState<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends ConsumerState<MatchFoundScreen> {
  late final ConfettiController _confetti;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _dateLabel =>
      DateFormat('EEEE d MMMM', 'nl').format(widget.args.matchedDate);

  Future<void> _addToMyDay() async {
    setState(() => _busy = true);
    try {
      await ref.read(planMetVriendServiceProvider).saveAnchorDateToMyDay(
        sessionId: widget.args.sessionId,
        place: widget.args.place,
        date: widget.args.matchedDate,
      );
      if (!mounted) return;
      showWanderMoodToast(context, message: 'Toegevoegd aan My Day.');
      context.go('/main?tab=0', extra: <String, dynamic>{'tab': 0});
    } catch (e) {
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Opslaan mislukt. Probeer opnieuw.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.args.place.photoUrl;

    return Scaffold(
      backgroundColor: _wmCream,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: _wmCharcoal),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jullie matchen! 🎉',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _wmForest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _wmCharcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: WmPlacePhotoNetworkImage(photo, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    widget.args.place.placeName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _wmCharcoal,
                    ),
                  ),
                  Text(
                    'met ${widget.args.friend.displayName}',
                    style: GoogleFonts.poppins(fontSize: 14, color: _wmMuted),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy ? null : _addToMyDay,
                    style: FilledButton.styleFrom(
                      backgroundColor: _wmForest,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _busy ? 'Toevoegen...' : 'Toevoegen aan My Day',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [_wmForest, _wmMint, Color(0xFFE8784A)],
            ),
          ),
        ],
      ),
    );
  }
}
