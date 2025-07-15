import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/mood/application/mood_service.dart';
import 'package:wandermood/features/mood/domain/models/mood.dart';
import 'package:wandermood/features/mood/domain/models/mood_data.dart';

class MoodHistoryWidget extends ConsumerWidget {
  const MoodHistoryWidget({
    super.key,
    this.daysToShow = 7,
  });

  final int daysToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authStateProvider);
    
    return userAsyncValue.when(
      data: (user) {
    if (user == null) {
      return const Center(
        child: Text('Je moet ingelogd zijn om je stemmingsgeschiedenis te zien'),
      );
    }
    
    final moodsAsyncValue = ref.watch(userMoodsProvider(user.id));
        return _buildMoodHistory(moodsAsyncValue);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Fout bij ophalen gebruiker: $error'),
      ),
    );
  }
  
  Widget _buildMoodHistory(AsyncValue<List<MoodData>> moodsAsyncValue) {
    
    return moodsAsyncValue.when(
      data: (moods) {
        if (moods.isEmpty) {
          return const Center(
            child: Text('Nog geen stemmingen geregistreerd'),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: moods.length,
          itemBuilder: (context, index) {
            final mood = moods[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getMoodEmoji(mood.moodType),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mood.moodType,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(mood.timestamp),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (mood.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        mood.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (mood.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: mood.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text(
          'Fout bij het laden van stemmingen: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  String _getMoodEmoji(String moodType) {
    switch (moodType.toLowerCase()) {
      case 'blij':
        return '😊';
      case 'energiek':
        return '⚡';
      case 'rustig':
        return '😌';
      case 'verdrietig':
        return '😢';
      case 'boos':
        return '😠';
      default:
        return '😐';
    }
  }
} 