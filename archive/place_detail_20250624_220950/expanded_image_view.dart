import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandedImageView extends StatefulWidget {
  final String imageAsset;
  final String tag;
  final List<String> allPhotos;
  final int initialIndex;

  const ExpandedImageView({
    required this.imageAsset,
    required this.tag,
    required this.allPhotos,
    required this.initialIndex,
    Key? key,
  }) : super(key: key);

  @override
  State<ExpandedImageView> createState() => _ExpandedImageViewState();
}

class _ExpandedImageViewState extends State<ExpandedImageView> {
  late PageController _pageController;
  late int _currentIndex;
  late double _scale;
  late double _previousScale;
  Offset? _previousOffset;
  Offset _offset = Offset.zero;
  late bool _isZoomed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _scale = 1.0;
    _previousScale = 1.0;
    _isZoomed = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _isZoomed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          onPressed: () {
            // Reset zoom before popping to ensure proper hero animation
            _resetZoom();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
            onPressed: _resetZoom,
          ),
        ],
        title: Text(
          '${_currentIndex + 1}/${widget.allPhotos.length}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          // Single tap to show/hide app bar
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          );
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.allPhotos.length,
          onPageChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentIndex = index;
              // Reset zoom when changing pages
              _resetZoom();
            });
          },
          itemBuilder: (context, index) {
            final currentPhoto = widget.allPhotos[index];
            
            // Only use Hero animation for the initial image
            final isInitialImage = index == widget.initialIndex && _scale == 1.0 && _offset == Offset.zero;
            
            final imageWidget = InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              onInteractionStart: (details) {
                _previousScale = _scale;
                _previousOffset = details.focalPoint;
              },
              onInteractionUpdate: (details) {
                if (details.scale != 1.0) {
                  setState(() {
                    _scale = (_previousScale * details.scale).clamp(0.8, 4.0);
                    _isZoomed = _scale > 1.1;
                    
                    if (_previousOffset != null) {
                      final delta = details.focalPoint - _previousOffset!;
                      _offset += delta / _scale;
                      _previousOffset = details.focalPoint;
                    }
                  });
                }
              },
              onInteractionEnd: (details) {
                _previousOffset = null;
              },
              child: Transform.scale(
                scale: _scale,
                child: Transform.translate(
                  offset: _offset,
                  child: Image.asset(
                    currentPhoto,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            );

            return isInitialImage
                ? Hero(tag: widget.tag, child: imageWidget)
                : imageWidget;
          },
        ),
      ),
    );
  }
} 