import 'package:flutter/material.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';

/// Compact Moody used in place of a gear for “App settings” entry points.
class MoodySettingsGlyph extends StatelessWidget {
  const MoodySettingsGlyph({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: MoodyCharacter(
        size: size,
        mood: 'thinking',
        glowOpacityScale: 0.5,
      ),
    );
  }
}
