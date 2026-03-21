import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/recommendation_service.dart';
import '../../domain/models/travel_recommendation.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  List<TravelRecommendation>? _recommendations;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recommendations = await ref
          .read(recommendationServiceProvider.notifier)
          .getRecommendations();
      
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendations,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final recommendations = _recommendations;
    if (recommendations == null || recommendations.isEmpty) {
      return const Center(
        child: Text('No recommendations available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ListTile(
              title: Text(recommendation.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recommendation.description),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${recommendation.location}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Price: \$${recommendation.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () async {
                  try {
                    await ref
                        .read(recommendationServiceProvider.notifier)
                        .toggleFavorite(recommendation.id);
                    if (mounted) {
                      showWanderMoodToast(
                        context,
                        message: 'Favorite updated successfully',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showWanderMoodToast(
                        context,
                        message: 'Error updating favorite: $e',
                        isError: true,
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 