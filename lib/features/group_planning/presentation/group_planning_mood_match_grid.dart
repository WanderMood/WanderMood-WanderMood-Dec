import 'package:flutter/material.dart';
import 'package:wandermood/core/localization/localized_mood_labels.dart';
import 'package:wandermood/features/home/presentation/widgets/mood_hub_style_mood_tile.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// Mood tags and palette aligned with [MoodHomeScreen] fallback moods.
const kMoodMatchMoodTags = <String>[
  'happy',
  'adventurous',
  'relaxed',
  'energetic',
  'romantic',
  'social',
  'cultural',
  'curious',
  'cozy',
  'excited',
  'foody',
  'surprise',
];

const kMoodMatchMoodHex = <String, String>{
  'happy': '#FCDF7E',
  'adventurous': '#F79F9C',
  'relaxed': '#72DED5',
  'energetic': '#84C8F0',
  'romantic': '#F4A9D3',
  'social': '#ECCBA3',
  'cultural': '#BFA8E0',
  'curious': '#EFB887',
  'cozy': '#D2A08B',
  'excited': '#A3E0A3',
  'foody': '#FFD3A3',
  'surprise': '#C0D3E0',
};

const kMoodMatchMoodEmoji = <String, String>{
  'happy': '😊',
  'adventurous': '🚀',
  'relaxed': '😌',
  'energetic': '⚡',
  'romantic': '💕',
  'social': '👥',
  'cultural': '🎭',
  'curious': '🔍',
  'cozy': '☕',
  'excited': '🤩',
  'foody': '🍽️',
  'surprise': '😲',
};

Color _hex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

/// Mood Match uses the Moody Hub tiles in a slightly denser layout.
class GroupPlanningMoodMatchGrid extends StatelessWidget {
  const GroupPlanningMoodMatchGrid({
    super.key,
    required this.selectedTag,
    required this.onSelect,
    this.enabled = true,
  });

  final String? selectedTag;
  final ValueChanged<String> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kMoodMatchMoodTags.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, i) {
        final tag = kMoodMatchMoodTags[i];
        final sel = selectedTag == tag;
        final emoji = kMoodMatchMoodEmoji[tag] ?? '✨';
        final color = _hex(kMoodMatchMoodHex[tag] ?? '#EBF3EE');
        final hubLabel = localizedMoodDisplayLabel(l10n, tag);
        return MoodHubStyleMoodTile(
          emoji: emoji,
          pastelBase: color,
          title: hubLabel,
          isSelected: sel,
          dimmed: selectedTag != null && !sel,
          emojiSize: 28,
          titleSize: 10.5,
          tileRadius: 18,
          onTap: enabled ? () => onSelect(tag) : null,
        );
      },
    );
  }
}
