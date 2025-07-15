import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_entry.freezed.dart';
part 'diary_entry.g.dart';

@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    required String userId,
    String? title,
    required String story,
    required String mood,
    String? location,
    @JsonKey(name: 'location_coordinates') String? locationCoordinates,
    @Default([]) List<String> tags,
    @Default([]) List<String> photos,
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'likes_count') @Default(0) int likesCount,
    @JsonKey(name: 'comments_count') @Default(0) int commentsCount,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'is_liked') @Default(false) bool isLiked,
    @JsonKey(name: 'is_saved') @Default(false) bool isSaved,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => _$DiaryEntryFromJson(json);
}

@freezed
class CreateDiaryEntryRequest with _$CreateDiaryEntryRequest {
  const factory CreateDiaryEntryRequest({
    String? title,
    required String story,
    required String mood,
    String? location,
    @Default([]) List<String> tags,
    @Default([]) List<String> photos,
    @Default(true) bool isPublic,
  }) = _CreateDiaryEntryRequest;

  factory CreateDiaryEntryRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateDiaryEntryRequestFromJson(json);
}

@freezed 
class DiaryComment with _$DiaryComment {
  const factory DiaryComment({
    required String id,
    required String userId,
    @JsonKey(name: 'diary_entry_id') required String diaryEntryId,
    required String comment,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
  }) = _DiaryComment;

  factory DiaryComment.fromJson(Map<String, dynamic> json) => _$DiaryCommentFromJson(json);
} 