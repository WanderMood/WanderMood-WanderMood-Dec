import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import '../../application/mood_service.dart';
import '../../domain/models/mood_data.dart';

class MoodStatsCard extends ConsumerWidget {
  const MoodStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final moodServiceAsync = ref.watch(moodServiceProvider);

    return moodServiceAsync.when(
      data: (moods) {
        final analytics = MoodAnalytics(
          averageMood: moods.isEmpty ? 0.0 : moods.map((m) => m.moodScore).reduce((a, b) => a + b) / moods.length,
          totalEntries: moods.length,
          moodTypes: _calculateMoodTypes(moods),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moodStatsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      l10n.moodStatsAverageLabel,
                      analytics.averageMood.toStringAsFixed(1),
                      Icons.sentiment_satisfied,
                    ),
                    _buildStatItem(
                      l10n.moodStatsTotalEntriesLabel,
                      analytics.totalEntries.toString(),
                      Icons.history,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.moodStatsTypesLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: analytics.moodTypes.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('${l10n.recErrorPrefix} $error'),
      ),
    );
  }

  Map<String, int> _calculateMoodTypes(List<MoodData> moods) {
    final moodTypes = <String, int>{};
    for (final mood in moods) {
      moodTypes[mood.moodType] = (moodTypes[mood.moodType] ?? 0) + 1;
    }
    return moodTypes;
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 