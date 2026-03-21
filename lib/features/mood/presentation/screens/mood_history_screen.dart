import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/mood/presentation/widgets/mood_history_widget.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// WanderMood v2 — cream canvas, white app bar, parchment hairline (no swirl).
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmDusk = Color(0xFF4A4640);

class MoodHistoryScreen extends ConsumerWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _wmCream,
      appBar: AppBar(
        backgroundColor: _wmWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _wmParchment),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _wmDusk, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.profileMoodJourneyTitle,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _wmCharcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: const MoodHistoryWidget(),
    );
  }
}
