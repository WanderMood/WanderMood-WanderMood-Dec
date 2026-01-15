import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ThreeJsGlobeWidget extends StatefulWidget {
  final List<Map<String, dynamic>>? visitedPlaces;
  final bool autoRotate;
  
  const ThreeJsGlobeWidget({
    Key? key,
    this.visitedPlaces,
    this.autoRotate = false,
  }) : super(key: key);

  @override
  State<ThreeJsGlobeWidget> createState() => _ThreeJsGlobeWidgetState();
}

class _ThreeJsGlobeWidgetState extends State<ThreeJsGlobeWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _initializeGlobe();
          },
        ),
      )
      ..loadFlutterAsset('assets/globe/globe.html');
  }

  void _initializeGlobe() {
    if (widget.visitedPlaces != null && widget.visitedPlaces!.isNotEmpty) {
      final placesJson = widget.visitedPlaces!.map((place) => {
        'lat': place['lat'],
        'lng': place['lng'],
      }).toList();
      
      _controller.runJavaScript('''
        window.addVisitedPlaces($placesJson);
      ''');
    }
    
    if (widget.autoRotate) {
      _controller.runJavaScript('window.setAutoRotate(true);');
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
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
