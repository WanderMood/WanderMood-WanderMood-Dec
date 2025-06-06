import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wandermood/features/location/providers/location_provider.dart';
import 'package:wandermood/features/weather/application/weather_service.dart';
import 'package:wandermood/features/auth/domain/providers/auth_provider.dart';
import 'package:wandermood/features/auth/application/user_preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/location/services/location_service.dart';
import 'package:wandermood/features/weather/domain/models/weather_location.dart';

part 'home_data_provider.g.dart';

class HomeData {
  final String? userName;
  final String? currentCity;
  final double? temperature;
  final List<WeatherForecast>? hourlyForecast;
  final bool isLoading;
  final String? error;

  const HomeData({
    this.userName,
    this.currentCity,
    this.temperature,
    this.hourlyForecast,
    this.isLoading = true,
    this.error,
  });

  HomeData copyWith({
    String? userName,
    String? currentCity,
    double? temperature,
    List<WeatherForecast>? hourlyForecast,
    bool? isLoading,
    String? error,
  }) {
    return HomeData(
      userName: userName ?? this.userName,
      currentCity: currentCity ?? this.currentCity,
      temperature: temperature ?? this.temperature,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@riverpod
class HomeDataNotifier extends _$HomeDataNotifier {
  Timer? _refreshTimer;

  @override
  Future<HomeData> build() async {
    // Start periodic refresh
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) => refresh());

    // Watch required providers
    final locationState = ref.watch(locationNotifierProvider);
    final userState = ref.watch(authStateProvider);
    final preferences = ref.watch(userPreferencesServiceProvider);

    return locationState.when(
      data: (city) async {
        try {
          // Get weather data
          final weatherService = ref.read(weatherServiceProvider.notifier);
          
          // Get coordinates for the city
          final locationService = LocationService();
          final coordinates = await LocationService.getCoordinatesForCity(city ?? 'Unknown');
          
          final location = Location(
            id: city?.toLowerCase() ?? 'unknown',
            name: city ?? 'Unknown',
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          );
          
          final weather = await weatherService.getCurrentWeather(location);

          // Get hourly forecast with the same coordinates
          final forecast = await weatherService.getWeatherForecast(location);

          // Get user name from Supabase metadata
          String? userName;
          if (userState != null) {
            final metadata = await Supabase.instance.client
                .from('profiles')
                .select('name')
                .eq('id', userState.id)
                .single();
            userName = metadata['name'] as String?;
          }

          return HomeData(
            userName: userName ?? preferences.value?.name ?? 'User',
            currentCity: city,
            temperature: weather.temperature,
            hourlyForecast: forecast,
            isLoading: false,
          );
        } catch (e) {
          return HomeData(
            error: e.toString(),
            isLoading: false,
          );
        }
      },
      loading: () => const HomeData(),
      error: (error, _) => HomeData(
        error: error.toString(),
        isLoading: false,
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
} 