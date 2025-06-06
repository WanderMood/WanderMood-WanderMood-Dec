import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';
part 'place.g.dart';

@freezed
class Place with _$Place {
  const factory Place({
    required String id,
    required String name,
    required String address,
    @Default(0.0) double rating,
    @Default([]) List<String> photos,
    @Default([]) List<String> types,
    required PlaceLocation location,
    String? description,
    String? emoji,
    String? tag,
    @Default(false) bool isAsset,
    @Default([]) List<String> activities,
    DateTime? dateAdded,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}

@freezed
class PlaceLocation with _$PlaceLocation {
  const factory PlaceLocation({
    required double lat,
    required double lng,
  }) = _PlaceLocation;

  factory PlaceLocation.fromJson(Map<String, dynamic> json) => 
      _$PlaceLocationFromJson(json);
} 