import 'package:flutter/material.dart';

/// Swipeable place photos with dot indicators (list + grid cards).
class PlacePhotoCarousel extends StatefulWidget {
  final int photoCount;
  final Widget Function(int index) photoBuilder;
  final double height;

  const PlacePhotoCarousel({
    super.key,
    required this.photoCount,
    required this.photoBuilder,
    this.height = 200,
  });

  @override
  State<PlacePhotoCarousel> createState() => _PlacePhotoCarouselState();
}

class _PlacePhotoCarouselState extends State<PlacePhotoCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.photoCount,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) => widget.photoBuilder(index),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photoCount,
                (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
