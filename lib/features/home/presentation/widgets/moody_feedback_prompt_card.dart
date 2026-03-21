import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_chat_sheet.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// "How's it going?" + Share feedback — same on My Day and Moody Hub (v2 tokens).
class MoodyFeedbackPromptCard extends ConsumerWidget {
  const MoodyFeedbackPromptCard({super.key});

  static const Color _wmDusk = Color(0xFF4A4640);
  static const Color _wmForest = Color(0xFF2A6049);
  static const Color _wmSky = Color(0xFFA8C8DC);
  static const Color _wmSkyTint = Color(0xFFEDF5F9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

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
          const MoodyCharacter(size: 48, mood: 'happy'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moodyFeedbackPromptBody,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _wmDusk,
                    height: 1.5,
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
  }
}
