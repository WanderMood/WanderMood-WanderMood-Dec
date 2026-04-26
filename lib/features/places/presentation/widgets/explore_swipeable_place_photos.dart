import 'package:flutter/material.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/utils/place_card_photo_index.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Horizontal swipe + dots for Explore [PlaceCard] / [PlaceGridCard] when
/// [photos] has more than one URL.
class ExploreSwipeablePlacePhotos extends StatefulWidget {
  const ExploreSwipeablePlacePhotos({
    super.key,
    required this.place,
    required this.photos,
    required this.photoSeed,
    required this.height,
    this.dotBottomPadding = 8,
    this.activeDotColor = const Color(0xFF2A6049),
    this.inactiveDotColor = const Color(0xFFFFFFFF),
  });

  final Place place;
  final List<String> photos;
  final int photoSeed;
  final double height;
  final double dotBottomPadding;
  final Color activeDotColor;
  final Color inactiveDotColor;

  @override
  State<ExploreSwipeablePlacePhotos> createState() =>
      _ExploreSwipeablePlacePhotosState();
}

class _ExploreSwipeablePlacePhotosState extends State<ExploreSwipeablePlacePhotos> {
  PageController? _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final n = widget.photos.length;
    if (n > 1) {
      _page = placeCardPhotoIndex(
        widget.place.id,
        n,
        refreshSeed: widget.photoSeed,
      ).clamp(0, n - 1);
      _pageController = PageController(initialPage: _page);
    }
  }

  @override
  void didUpdateWidget(covariant ExploreSwipeablePlacePhotos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoSeed == widget.photoSeed &&
        oldWidget.photos.length == widget.photos.length &&
        _sameUrls(oldWidget.photos, widget.photos)) {
      return;
    }
    final n = widget.photos.length;
    if (n <= 1) {
      _pageController?.dispose();
      _pageController = null;
      setState(() {});
      return;
    }
    if (_pageController == null) {
      _page = placeCardPhotoIndex(
        widget.place.id,
        n,
        refreshSeed: widget.photoSeed,
      ).clamp(0, n - 1);
      _pageController = PageController(initialPage: _page);
    } else {
      _page = placeCardPhotoIndex(
        widget.place.id,
        n,
        refreshSeed: widget.photoSeed,
      ).clamp(0, n - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController?.hasClients == true) {
          _pageController!.jumpToPage(_page);
        }
      });
    }
    setState(() {});
  }

  static bool _sameUrls(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Widget _photoPage(int index) {
    final p = widget.photos[index];
    if (widget.place.isAsset) {
      return Image.asset(
        p,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _greyPlaceholder(),
      );
    }
    return WmPlacePhotoNetworkImage(
      p,
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _greyPlaceholder(),
      progressIndicatorBuilder: (context, url, progress) => Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            value: progress.progress,
            color: const Color(0xFF2A6049),
          ),
        ),
      ),
    );
  }

  Widget _greyPlaceholder() => Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final n = photos.length;
    if (n == 0) {
      return SizedBox(height: widget.height, width: double.infinity);
    }
    if (n == 1) {
      return _photoPage(0);
    }

    final c = _pageController;
    if (c == null) {
      return SizedBox(height: widget.height, width: double.infinity);
    }

    final dotSize = n > 8 ? 4.0 : 5.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: c,
          itemCount: n,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => _photoPage(i),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.dotBottomPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(n, (i) {
              final on = i == _page;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on
                        ? widget.activeDotColor
                        : widget.inactiveDotColor.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
