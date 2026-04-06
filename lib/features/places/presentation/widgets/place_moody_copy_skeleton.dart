import 'package:flutter/material.dart';

/// Neutral placeholder while Moody / Places copy loads (avoids misleading fallback text).
class PlaceMoodyCopySkeleton extends StatelessWidget {
  const PlaceMoodyCopySkeleton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final w = MediaQuery.sizeOf(context).width;
    return Semantics(
      label: 'Loading description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(base, width: compact ? 140.0 : 200.0, height: compact ? 10.0 : 12.0),
          SizedBox(height: compact ? 10 : 14),
          _bar(base, width: w * 0.92, height: compact ? 9.0 : 10.0),
          SizedBox(height: compact ? 6 : 8),
          _bar(base, width: w * 0.78, height: compact ? 9.0 : 10.0),
          if (!compact) ...[
            SizedBox(height: 8),
            _bar(base, width: w * 0.55, height: 10.0),
          ],
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double width, required double height}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
