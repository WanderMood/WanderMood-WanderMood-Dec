import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/recommendation.dart';
import '../../application/ai_recommendation_service.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class RecommendationDetailPage extends ConsumerWidget {
  final Recommendation recommendation;

  const RecommendationDetailPage({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recDetailTitle),
        actions: [
          if (!recommendation.isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {
                ref
                    .read(aIRecommendationServiceProvider.notifier)
                    .markAsCompleted(recommendation.id);
                Navigator.pop(context);
              },
              tooltip: l10n.recDetailMarkCompleteTooltip,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  recommendation.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: recommendation.isCompleted ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  recommendation.isCompleted
                      ? l10n.recDetailStatusCompleted
                      : l10n.recDetailStatusNotCompleted,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.recDetailSectionDescription,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.recDetailSectionCategory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(recommendation.category),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.recDetailSectionTags,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendation.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.recDetailSectionConfidence,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: recommendation.confidence,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            Text(
              '${(recommendation.confidence * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (recommendation.currentMood != null) ...[
              Text(
                l10n.recDetailSectionMood,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.mood),
                title: Text(recommendation.currentMood!.label),
                subtitle: Text(
                  l10n.recDetailMoodRegisteredOn(
                    _formatDateTime(recommendation.currentMood!.timestamp),
                  ),
                ),
              ),
            ],
            if (recommendation.currentWeather != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.recDetailSectionWeather,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: Text(recommendation.currentWeather!.conditions),
                subtitle: Text(
                  l10n.recDetailWeatherSubtitle(
                    '${recommendation.currentWeather!.temperature}',
                    '${recommendation.currentWeather!.humidity}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}-${dateTime.month}-${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 