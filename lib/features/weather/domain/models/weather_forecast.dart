import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_forecast.freezed.dart';
part 'weather_forecast.g.dart';

@freezed
class WeatherForecast with _$WeatherForecast {
  const factory WeatherForecast({
    required DateTime date,
    required double maxTemperature,
    required double minTemperature,
    String? time,
    double? temperature,
    required String conditions,
    required double precipitationProbability,
    @Default(0) double humidity,
    @Default(0) double precipitation,
    required DateTime sunrise,
    required DateTime sunset,
    @Default(0) double uvIndex,
    String? description,
    String? icon,
  }) = _WeatherForecast;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) =>
      _$WeatherForecastFromJson(json);
} 