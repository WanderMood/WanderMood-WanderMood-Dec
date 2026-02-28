import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/models/visited_place.dart';

class ThreeJsGlobeWidget extends StatefulWidget {
  final List<VisitedPlace>? visitedPlaces;
  final bool autoRotate;

  /// If provided, the globe animates to centre on this location on load.
  /// Falls back to the Atlantic default view when null.
  final double? initialLat;
  final double? initialLng;

  /// Called when the user taps a mood memory marker on the globe.
  final void Function(VisitedPlace place)? onMarkerTap;

  const ThreeJsGlobeWidget({
    super.key,
    this.visitedPlaces,
    this.autoRotate = false,
    this.initialLat,
    this.initialLng,
    this.onMarkerTap,
  });

  @override
  State<ThreeJsGlobeWidget> createState() => ThreeJsGlobeWidgetState();
}

class ThreeJsGlobeWidgetState extends State<ThreeJsGlobeWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  void setAutoRotate(bool enable) {
    _controller.runJavaScript('window.setAutoRotate($enable);');
  }

  void resetCamera() {
    _controller.runJavaScript('window.resetCamera();');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..addJavaScriptChannel(
        'WanderMoodChannel',
        onMessageReceived: _onGlobeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _initializeGlobe();
          },
        ),
      );
    _loadGlobe();
  }

  void _onGlobeMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      if (data['type'] == 'markerTap' && widget.onMarkerTap != null) {
        final placeJson = data['place'] as Map<String, dynamic>;
        // Reconstruct the VisitedPlace from the data the globe sent back
        final place = VisitedPlace(
          id: placeJson['id'] as String? ?? '',
          userId: '',
          placeName: placeJson['place_name'] as String? ?? '',
          city: placeJson['city'] as String?,
          country: placeJson['country'] as String?,
          lat: (placeJson['lat'] as num).toDouble(),
          lng: (placeJson['lng'] as num).toDouble(),
          mood: placeJson['mood'] as String?,
          moodEmoji: placeJson['mood_emoji'] as String?,
          energyLevel: placeJson['energy_level'] != null
              ? (placeJson['energy_level'] as num).toDouble()
              : null,
          notes: placeJson['notes'] as String?,
          visitedAt: placeJson['visited_at'] != null
              ? DateTime.tryParse(placeJson['visited_at'] as String)
              : null,
        );
        widget.onMarkerTap!(place);
      }
    } catch (_) {}
  }

  Future<void> _loadGlobe() async {
    await _controller.clearCache();
    const devUrl = 'http://localhost:8080/globe.html';
    const useDevServer =
        bool.fromEnvironment('GLOBE_DEV_SERVER', defaultValue: false);
    if (useDevServer) {
      try {
        await _controller.loadRequest(Uri.parse(devUrl));
        return;
      } catch (_) {}
    }
    await _controller.loadFlutterAsset('assets/globe/globe.html');
  }

  Future<void> _initializeGlobe() async {
    // Inject bundled Earth texture so the globe shows immediately (no CDN dependency)
    try {
      final bytes = await rootBundle.load('assets/globe/earth-day.jpg');
      final b64 = base64Encode(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      await _controller.runJavaScript(
        "window.setEarthTexture && window.setEarthTexture('data:image/jpeg;base64,$b64');",
      );
    } catch (_) {}

    // Pass full visited-place objects so the globe can colour-code and show mood data
    final places = widget.visitedPlaces;
    if (places != null && places.isNotEmpty) {
      final globeJson = jsonEncode(places.map((p) => p.toGlobeMap()).toList());
      await _controller.runJavaScript('window.addVisitedPlaces($globeJson);');
    }

    if (widget.autoRotate) {
      await _controller.runJavaScript('window.setAutoRotate(true);');
    }

    if (widget.initialLat != null && widget.initialLng != null) {
      await _controller.runJavaScript(
        'window.setInitialLocation && window.setInitialLocation(${widget.initialLat}, ${widget.initialLng});',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
