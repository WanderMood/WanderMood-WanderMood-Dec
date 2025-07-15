import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/mood_input_card.dart';
import '../widgets/mood_history_chart.dart';
import '../widgets/mood_stats_card.dart';
import '../../application/mood_service.dart';
import '../../domain/models/mood_data.dart';

class MoodPage extends ConsumerStatefulWidget {
  const MoodPage({super.key});

  @override
  ConsumerState<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends ConsumerState<MoodPage> {
  bool _isChartExpanded = false;

  @override
  Widget build(BuildContext context) {
    final moodAsync = ref.watch(moodServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWideScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            MoodInputCard(
                              onMoodSaved: (mood) async {
                                await ref.read(moodServiceProvider.notifier).saveMoodData(mood);
                              },
                            ),
                            const SizedBox(height: 16),
                            const MoodStatsCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            moodAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stackTrace) => Center(
                                child: Text('Fout bij het laden van mood data: $error'),
                              ),
                              data: (moodHistory) => _buildMoodHistorySection(moodHistory),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      MoodInputCard(
                        onMoodSaved: (mood) async {
                          await ref.read(moodServiceProvider.notifier).saveMoodData(mood);
                        },
                      ),
                      const SizedBox(height: 16),
                      const MoodStatsCard(),
                      const SizedBox(height: 16),
                      moodAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stackTrace) => Center(
                          child: Text('Fout bij het laden van mood data: $error'),
                        ),
                        data: (moodHistory) => _buildMoodHistorySection(moodHistory),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodHistorySection(List<MoodData> moodHistory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mood Geschiedenis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isChartExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isChartExpanded = !_isChartExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isChartExpanded ? 400 : 200,
              child: MoodHistoryChart(
                moodHistory: moodHistory,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 