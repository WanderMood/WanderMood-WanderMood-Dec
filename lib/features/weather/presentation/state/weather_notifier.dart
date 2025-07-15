import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/weather_service.dart';
import '../../domain/models/weather_location.dart';
import '../../domain/models/weather.dart';
import 'weather_state.dart';

part 'weather_notifier.g.dart';

@riverpod
class WeatherNotifier extends _$WeatherNotifier {
  late final WeatherService _weatherService;
  StreamSubscription<Weather>? _weatherSubscription;

  @override
  WeatherState build() {
    _weatherService = ref.watch(weatherServiceProvider);
    return const WeatherState.initial();
  }

  Future<void> getCurrentWeather(WeatherLocation location) async {
    state = const WeatherState.loading();

    try {
      final weather = await _weatherService.getCurrentWeather(location);
      state = WeatherState.loaded(
        currentWeather: weather,
        location: location,
      );
    } catch (e) {
      state = WeatherState.error(e.toString());
    }
  }

  Future<void> getHistoricalWeather(
    WeatherLocation location,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final historicalData = await _weatherService.getHistoricalWeather(
        location,
        start,
        end,
      );

      if (state is _Loaded) {
        state = WeatherState.loaded(
          currentWeather: (state as _Loaded).currentWeather,
          location: location,
          historicalWeather: historicalData,
        );
      }
    } catch (e) {
      // Keep current weather but show error for historical
      if (state is _Loaded) {
        state = WeatherState.loaded(
          currentWeather: (state as _Loaded).currentWeather,
          location: location,
        );
      }
    }
  }

  void startWeatherUpdates(WeatherLocation location) {
    _weatherSubscription?.cancel();
    _weatherSubscription = _weatherService
        .watchWeatherUpdates(location)
        .listen((weather) {
      if (state is _Loaded) {
        state = WeatherState.loaded(
          currentWeather: weather,
          location: location,
          historicalWeather: (state as _Loaded).historicalWeather,
        );
      } else {
        state = WeatherState.loaded(
          currentWeather: weather,
            location: location,
        );
  }
    });
  }

  @override
  void dispose() {
    _weatherSubscription?.cancel();
    super.dispose();
  }
} 