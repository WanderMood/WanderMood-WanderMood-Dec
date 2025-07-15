import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/weather.dart';
import '../../domain/models/weather_location.dart';

part 'weather_state.freezed.dart';

@freezed
class WeatherState with _$WeatherState {
  const factory WeatherState.initial() = _Initial;
  
  const factory WeatherState.loading() = _Loading;
  
  const factory WeatherState.loaded({
    required Weather currentWeather,
    required WeatherLocation location,
    List<Weather>? historicalWeather,
  }) = _Loaded;
  
  const factory WeatherState.error(String message) = _Error;
} 