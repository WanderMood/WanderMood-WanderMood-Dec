import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../mood/domain/models/mood.dart';
import '../../../weather/domain/models/weather_data.dart';

part 'recommendation.freezed.dart';
part 'recommendation.g.dart';

class MoodConverter implements JsonConverter<Mood?, Map<String, dynamic>?> {
  const MoodConverter();

  @override
  Mood? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Mood.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(Mood? mood) {
    return mood?.toJson();
  }
}

class WeatherDataConverter implements JsonConverter<WeatherData?, Map<String, dynamic>?> {
  const WeatherDataConverter();

  @override
  WeatherData? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return WeatherData.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(WeatherData? weather) {
    return weather?.toJson();
  }
}

@freezed
class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String id,
    required String title,
    required String description,
    required String category,
    required double confidence,
    required List<String> tags,
    required DateTime createdAt,
    @MoodConverter() required Mood? currentMood,
    @WeatherDataConverter() required WeatherData? currentWeather,
    @Default(false) bool isCompleted,
  }) = _Recommendation;

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);
} 