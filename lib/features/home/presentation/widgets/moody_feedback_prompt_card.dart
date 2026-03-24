import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/features/home/presentation/widgets/hoe_was_je_dag_sheet.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_chat_sheet.dart';
import 'package:wandermood/features/mood/services/end_of_day_check_in_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// "How's it going?" + Share feedback — same on My Day and Moody Hub (v2 tokens).
class MoodyFeedbackPromptCard extends ConsumerWidget {
  const MoodyFeedbackPromptCard({super.key});

  static const Color _wmDusk = Color(0xFF4A4640);
  static const Color _wmForest = Color(0xFF2A6049);
  static const Color _wmSky = Color(0xFFA8C8DC);
  static const Color _wmSkyTint = Color(0xFFEDF5F9);

  Future<bool> _shouldShowEndOfDayCard() async {
    final now = MoodyClock.now();
    if (now.hour < 20) return false;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return false;

    final names = await EndOfDayCheckInService.fetchDoneActivityNamesToday(client);
    if (names.isEmpty) return false;

    final alreadyDone = await EndOfDayCheckInService.hasCompletedEndOfDayToday(client);
    if (alreadyDone) return false;

    return true;
  }

  Future<void> _onPromptBodyTap(BuildContext context, WidgetRef ref) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    if (MoodyClock.now().hour < 20) {
      if (context.mounted) showMoodyChatSheet(context, ref);
      return;
    }

    final names =
        await EndOfDayCheckInService.fetchDoneActivityNamesToday(client);
    if (!context.mounted) return;
    if (names.isEmpty) {
      showMoodyChatSheet(context, ref);
      return;
    }

    final alreadyDone =
        await EndOfDayCheckInService.hasCompletedEndOfDayToday(client);
    if (!context.mounted) return;
    if (alreadyDone) {
      showMoodyChatSheet(context, ref);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      useSafeArea: true,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: HoeWasJeDagSheet(
            completedActivities: names,
            userId: user.id,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: _shouldShowEndOfDayCard(),
      builder: (context, snapshot) {
        final shouldShow = snapshot.data ?? false;
        if (!shouldShow) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _wmSkyTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _wmSky, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _onPromptBodyTap(context, ref),
                child: const MoodyCharacter(size: 48, mood: 'happy'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _onPromptBodyTap(context, ref),
                      child: Text(
                        l10n.moodyFeedbackPromptBody,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _wmDusk,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => showMoodyChatSheet(context, ref),
                      child: Row(
                        children: [
                          Text(
                            l10n.moodyFeedbackShareAction,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _wmForest,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 18, color: _wmForest),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
