part of 'explore_screen.dart';

/// Google Map body, markers, quick filters, and small geo helpers used only here.
extension _ExploreScreenMapView on _ExploreScreenState {
  Widget _buildMapView(List<Place> places, Position? userLocation) {
    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.exploreNoPlacesOnMap,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    LatLng initialPosition;
    if (userLocation != null) {
      final isSanFrancisco = (userLocation.latitude - 37.785834).abs() < 0.1 &&
          (userLocation.longitude + 122.406417).abs() < 0.1;
      if (!isSanFrancisco) {
        initialPosition = LatLng(userLocation.latitude, userLocation.longitude);
      } else {
        final currentCity =
            ref.read(locationNotifierProvider).value ?? 'Rotterdam';
        final cityCoords = _getCityCoordinates(currentCity);
        initialPosition = LatLng(cityCoords['lat']!, cityCoords['lng']!);
      }
    } else {
      final currentCity =
          ref.read(locationNotifierProvider).value ?? 'Rotterdam';
      final cityCoords = _getCityCoordinates(currentCity);
      initialPosition = LatLng(cityCoords['lat']!, cityCoords['lng']!);
    }

    final Set<Marker> markers = {};
    final currentCity = ref.read(locationNotifierProvider).value ?? 'Rotterdam';

    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      final markerId = MarkerId(place.id);

      BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
      if (_quickFilterRating45 && place.rating >= 4.5) {
        markerIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (_quickFilterDistance1km) {
        final distance =
            _calculatePlaceDistance(place, userLocation, currentCity);
        if (distance != null && distance <= 1.0) {
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }
      }

      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(place.location.lat, place.location.lng),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.rating > 0
                ? '⭐ ${place.rating.toStringAsFixed(1)}'
                : null,
          ),
          icon: markerIcon,
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            if (!mounted) {
              return;
            }
            HapticFeedback.lightImpact();
            final city =
                ref.read(locationNotifierProvider).valueOrNull?.trim() ??
                    'Rotterdam';
            final userLocation = ref.read(userLocationProvider).valueOrNull;
            await showExplorePlaceQuickPeekSheet(
              context: context,
              place: place,
              photoSelectionSeed: _explorePlacePhotoRefreshSeed,
              userLocation: userLocation,
              cityName: city,
              onViewFullPlace: () => _openPlaceDetailFromExplore(place),
              onAddToMyDay: () {
                unawaited(_showAddToMyDaySheet(place));
              },
              onPlanWithFriend: () {
                openPlanWithFriend(
                  context,
                  PlanWithFriendArgs.fromPlace(
                    place,
                    onAddToMyDay: () => unawaited(_showAddToMyDaySheet(place)),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GoogleMap(
                key: const ValueKey<String>('explore_google_map'),
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 13,
                ),
                markers: markers,
                mapType: MapType.normal,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                minMaxZoomPreference: const MinMaxZoomPreference(9, 20),
                padding: EdgeInsets.zero,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted || _mapController != controller) return;
                    try {
                      await controller.moveCamera(
                        CameraUpdate.newLatLngZoom(initialPosition, 13),
                      );
                    } catch (_) {}
                  });
                },
                myLocationEnabled: userLocation != null &&
                    (userLocation.latitude - 37.785834).abs() > 0.1,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.exploreQuickFilters,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    _buildQuickFilterChip(
                      '1km',
                      isActive: _quickFilterDistance1km,
                      onTap: () {
                        // ignore: invalid_use_of_protected_member — extension on State.
                        setState(() {
                          _quickFilterDistance1km = !_quickFilterDistance1km;
                          _exploreVisiblePlaceCount = _kExplorePageSize;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickFilterChip(
                      '4.5+',
                      isActive: _quickFilterRating45,
                      onTap: () {
                        // ignore: invalid_use_of_protected_member — extension on State.
                        setState(() {
                          _quickFilterRating45 = !_quickFilterRating45;
                          _exploreVisiblePlaceCount = _kExplorePageSize;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getCityCoordinates(String cityName) {
    final cityCoords = {
      'Rotterdam': {'lat': 51.9244, 'lng': 4.4777},
      'Amsterdam': {'lat': 52.3676, 'lng': 4.9041},
      'The Hague': {'lat': 52.0705, 'lng': 4.3007},
      'Utrecht': {'lat': 52.0907, 'lng': 5.1214},
      'Eindhoven': {'lat': 51.4416, 'lng': 5.4697},
      'Groningen': {'lat': 53.2194, 'lng': 6.5665},
      'Delft': {'lat': 52.0067, 'lng': 4.3556},
      'Beneden-Leeuwen': {'lat': 51.8892, 'lng': 5.5142},
    };
    return cityCoords[cityName] ?? cityCoords['Rotterdam']!;
  }

  double? _calculatePlaceDistance(
      Place place, Position? userLocation, String cityName) {
    Position? referencePoint;

    if (userLocation != null) {
      final isSanFrancisco = (userLocation.latitude - 37.785834).abs() < 0.1 &&
          (userLocation.longitude + 122.406417).abs() < 0.1;
      if (!isSanFrancisco) {
        referencePoint = userLocation;
      }
    }

    if (referencePoint == null) {
      final cityCoords = _getCityCoordinates(cityName);
      referencePoint = Position(
        latitude: cityCoords['lat']!,
        longitude: cityCoords['lng']!,
        timestamp: MoodyClock.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return DistanceService.calculateDistance(
      referencePoint.latitude,
      referencePoint.longitude,
      place.location.lat,
      place.location.lng,
    );
  }

  Widget _buildQuickFilterChip(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF5EE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF2A6049) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF2A6049) : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}
