import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/home/providers/home_data_provider.dart';
import 'package:wandermood/features/location/providers/location_provider.dart';
import 'package:wandermood/core/presentation/widgets/loading_indicator.dart';
import 'package:wandermood/core/presentation/widgets/error_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _showLocationDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return LocationDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDataAsync = ref.watch(homeDataNotifierProvider);
    final locationAsync = ref.watch(locationNotifierProvider);

    return homeDataAsync.when(
      data: (homeData) {
        if (homeData.isLoading) {
          return const LoadingIndicator();
        }

        if (homeData.error != null) {
          return ErrorView(
            error: homeData.error!,
            onRetry: () => ref.refresh(homeDataNotifierProvider),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => ref.read(homeDataNotifierProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('Welcome, ${homeData.userName ?? 'User'}'),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location and Weather Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => _showLocationDialog(context, ref),
                                      child: Row(
                                        children: [
                                          locationAsync.when(
                                            data: (location) => Row(
                                              children: [
                                                const Icon(Icons.location_on),
                                                const SizedBox(width: 8),
                                                Text(
                                                  location ?? 'Unknown Location',
                                                  style: Theme.of(context).textTheme.titleLarge,
                                                ),
                                                const Icon(Icons.arrow_drop_down),
                                              ],
                                            ),
                                            loading: () => Row(
                                              children: [
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Getting location...',
                                                  style: Theme.of(context).textTheme.titleLarge,
                                                ),
                                              ],
                                            ),
                                            error: (error, stack) => Row(
                                              children: [
                                                const Icon(Icons.error_outline, color: Colors.red),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Location error',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_drop_down, color: Colors.red),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${homeData.temperature?.toStringAsFixed(1)}°C',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (homeData.hourlyForecast != null)
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: homeData.hourlyForecast!.length,
                                      itemBuilder: (context, index) {
                                        final forecast = homeData.hourlyForecast![index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 16),
                                          child: Column(
                                            children: [
                                              Text(forecast.time ?? ''),
                                              const SizedBox(height: 8),
                                              Icon(
                                                _getWeatherIcon(forecast.conditions),
                                                color: _getWeatherIconColor(forecast.conditions),
                                              ),
                                              const SizedBox(height: 8),
                                              Text('${forecast.temperature?.toStringAsFixed(0) ?? forecast.maxTemperature.toStringAsFixed(0)}°C'),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        error: error.toString(),
        onRetry: () => ref.refresh(homeDataNotifierProvider),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherIconColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFFD700);
      case 'clouds':
        return Colors.grey;
      case 'rain':
      case 'drizzle':
        return Colors.blue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'snow':
        return Colors.lightBlue;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'fog':
        return Colors.grey.shade400;
      default:
        return const Color(0xFFFFD700);
    }
  }
}

class LocationDialog extends ConsumerWidget {
  const LocationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationNotifierProvider);

    return AlertDialog(
      title: const Text('Choose Location'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            locationAsync.when(
              data: (_) => Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.my_location),
                    title: const Text('Use Current Location'),
                    onTap: () {
                      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Search Location'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showLocationSearch(context, ref);
                    },
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Column(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(locationNotifierProvider.notifier).retryLocationAccess();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _showLocationSearch(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Search Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Enter city name',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop(value);
                },
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = textController.text;
                if (text.isNotEmpty) {
                  Navigator.of(context).pop(text);
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      ref.read(locationNotifierProvider.notifier).setCity(result);
    }
  }
} 