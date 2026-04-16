import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';

/// Sections in [guestDemo*MoodyAbout] ARB strings: `\n---\n` between blocks.
/// Each block: first line = title (emoji + label), following lines = body.
class GuestDemoAboutSection {
  const GuestDemoAboutSection(this.title, this.body);
  final String title;
  final String body;

  bool get isMoodySection {
    final t = title.toLowerCase();
    return t.contains('moody');
  }
}

const String guestDemoAboutSectionDelimiter = '\n---\n';

List<GuestDemoAboutSection> parseGuestDemoAboutSections(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return [];

  final parts = trimmed.split(guestDemoAboutSectionDelimiter);
  final out = <GuestDemoAboutSection>[];
  for (final p in parts) {
    final lines = p.trim().split('\n');
    if (lines.isEmpty) continue;
    final title = lines.first.trim();
    final body = lines.skip(1).join('\n').trim();
    if (body.isEmpty) {
      out.add(GuestDemoAboutSection('📍 About', title));
    } else {
      out.add(GuestDemoAboutSection(title, body));
    }
  }
  return out;
}

/// Readable About copy for guest demo: titled sections, spacing, Moody avatar on her block.
class GuestDemoAboutSectionsView extends StatelessWidget {
  const GuestDemoAboutSectionsView({
    super.key,
    required this.source,
    this.compact = false,
    /// When [compact] is true, max lines for the first section body (default 5).
    this.compactBodyMaxLines = 5,
    /// Optional smaller type for tight cards (e.g. Explore grid).
    this.compactTitleFontSize,
    this.compactBodyFontSize,
  });

  final String source;
  final bool compact;
  final int compactBodyMaxLines;
  final double? compactTitleFontSize;
  final double? compactBodyFontSize;

  static const Color _forest = Color(0xFF2A6049);
  static const Color _charcoal = Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    final sections = parseGuestDemoAboutSections(source);
    if (sections.isEmpty) {
      return Text(
        source,
        style: GoogleFonts.poppins(
          fontSize: compact ? 13 : 14,
          color: _charcoal,
          height: 1.5,
        ),
      );
    }

    if (compact) {
      return _buildCompact(sections, compactBodyMaxLines);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          _buildSection(context, sections[i]),
        ],
      ],
    );
  }

  /// Day-plan cards: first section only (e.g. "What kind of place is this?").
  /// Further sections appear on the activity detail screen.
  Widget _buildCompact(
    List<GuestDemoAboutSection> sections,
    int bodyMaxLines,
  ) {
    final first = sections.first;
    final titleFs = compactTitleFontSize ?? 13;
    final bodyFs = compactBodyFontSize ?? 13;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.title,
          style: GoogleFonts.poppins(
            fontSize: titleFs,
            fontWeight: FontWeight.w700,
            color: _forest,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          first.body,
          style: GoogleFonts.poppins(
            fontSize: bodyFs,
            color: _charcoal,
            height: 1.45,
          ),
          maxLines: bodyMaxLines.clamp(1, 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, GuestDemoAboutSection s) {
    final titleStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _forest,
      height: 1.35,
    );
    final bodyStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _charcoal,
      height: 1.55,
    );
    final moodyBodyStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      color: _forest.withValues(alpha: 0.92),
      height: 1.5,
    );

    if (s.isMoodySection) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC5D9CE).withValues(alpha: 0.7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MoodyCharacter(size: 40, mood: 'happy'),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.body, style: moodyBodyStyle),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.title, style: titleStyle),
        const SizedBox(height: 8),
        Text(s.body, style: bodyStyle),
      ],
    );
  }
}
