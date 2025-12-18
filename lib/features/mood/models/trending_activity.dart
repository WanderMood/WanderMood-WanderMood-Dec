import 'package:freezed_annotation/freezed_annotation.dart';

part 'trending_activity.freezed.dart';
part 'trending_activity.g.dart';

@freezed
class TrendingActivity with _$TrendingActivity {
  const factory TrendingActivity({
    required String id,
    required String title,
    @Default('') String description,
    @Default('') String imageUrl,
    @Default('') String location,
    @Default('') String moodTag,
    @Default(0) int likes,
    // UI fields expected by screens
    @Default('⭐') String emoji,
    @Default('popular') String trend, // hot | rising | popular | new
    @Default('') String subtitle,
    @Default(0) int peopleCount,
    @Default(85.0) double popularityScore,
    @Default('activity') String category, // dining | culture | outdoor | sightseeing | activity
  }) = _TrendingActivity;

  factory TrendingActivity.fromJson(Map<String, dynamic> json) => _$TrendingActivityFromJson(json);
}


