import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/recommendation_service.dart';
import '../../domain/models/travel_recommendation.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recListTitle),
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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${l10n.recErrorPrefix} $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendations,
              child: Text(l10n.recTryAgain),
            ),
          ],
        ),
      );
    }

    final recommendations = _recommendations;
    if (recommendations == null || recommendations.isEmpty) {
      return Center(
        child: Text(l10n.recNoneAvailable),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          final loc = AppLocalizations.of(context)!;
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
                    loc.recLocationLabel(recommendation.location),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    loc.recPriceLabel('\$${recommendation.price.toStringAsFixed(2)}'),
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
                        message: AppLocalizations.of(context)!.recFavoriteUpdated,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showWanderMoodToast(
                        context,
                        message: AppLocalizations.of(context)!.recFavoriteError('$e'),
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