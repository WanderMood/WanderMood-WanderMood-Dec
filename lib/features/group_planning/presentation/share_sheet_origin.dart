import 'package:flutter/material.dart';

/// iOS (especially iPad) requires a non-zero [Rect] for the share popover anchor.
Rect sharePositionOriginForContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    if (rect.width >= 1 && rect.height >= 1) {
      return rect;
    }
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 48,
    height: 48,
  );
}
