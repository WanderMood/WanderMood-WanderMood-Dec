import 'lib/core/services/google_places_service.dart';

void main() {
  // Create a mock place that represents Yogaschool Rotterdam
  final yogaPlace = GooglePlace(
    placeId: 'test_yoga_id',
    name: 'Yogaschool Rotterdam',
    types: ['gym', 'health', 'point_of_interest', 'establishment'],
    rating: 5.0,
    userRatingsTotal: 50,
    vicinity: 'Rotterdam',
    latitude: 51.9225,
    longitude: 4.47917,
    priceLevel: null,
    photoReferences: [],
  );
  
  // Create a mock place that represents Bodyland Men's BodyCare
  final bodyCarePlace = GooglePlace(
    placeId: 'test_bodycare_id',
    name: 'Bodyland Men\'s BodyCare',
    types: ['beauty_salon', 'health', 'point_of_interest', 'establishment'],
    rating: 4.9,
    userRatingsTotal: 100,
    vicinity: 'Rotterdam',
    latitude: 51.9225,
    longitude: 4.47917,
    priceLevel: null,
    photoReferences: [],
  );
  
  print('🧪 Testing filtering logic...');
  print('');
  
  // Test the filtering from GooglePlacesService
  final yogaResult = GooglePlacesService.testTouristFiltering(yogaPlace);
  print('🔍 Yogaschool Rotterdam - GooglePlacesService filtering: ${yogaResult ? "✅ APPROVED" : "🚫 FILTERED OUT"}');
  
  final bodyCareResult = GooglePlacesService.testTouristFiltering(bodyCarePlace);
  print('🔍 Bodyland Men\'s BodyCare - GooglePlacesService filtering: ${bodyCareResult ? "✅ APPROVED" : "🚫 FILTERED OUT"}');
} 