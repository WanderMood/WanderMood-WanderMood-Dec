import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/place.dart';
import '../services/places_service.dart';

part 'places_provider.g.dart';

@riverpod
class PlacesNotifier extends _$PlacesNotifier {
  @override
  FutureOr<List<Place>> build() async {
    return [];
  }

  Future<void> searchPlaces(String query) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(placesServiceProvider.notifier);
      final predictions = await service.searchPlaces(query);
      
      final places = await Future.wait<Place>(
        predictions.map((prediction) async {
          final details = await service.getPlaceDetails(prediction.placeId!);
          return Place(
            id: prediction.placeId!,
            name: details['name'] ?? '',
            address: details['address'] ?? '',
            rating: (details['rating'] as num?)?.toDouble() ?? 0.0,
            photos: (details['photos'] as List<String>?) ?? [],
            types: (details['types'] as List<String>?) ?? [],
            location: PlaceLocation(
              lat: details['location']['lat'] ?? 0.0,
              lng: details['location']['lng'] ?? 0.0,
            ),
          );
        }),
      );
      
      state = AsyncValue.data(places);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  String getPhotoUrl(String photoReference) {
    final service = ref.read(placesServiceProvider.notifier);
    return service.getPhotoUrl(photoReference);
  }
} 