import 'package:flutter/material.dart';
import 'package:wandermood/features/home/presentation/widgets/moody_character.dart';

/// Full animated Moody mascot scaled for inline use (cards, tips, guest UI).
class MoodyAvatarCompact extends StatelessWidget {
  final double size;
  final String mood;
  final double glowOpacityScale;

  const MoodyAvatarCompact({
    super.key,
    this.size = 32,
    this.mood = 'idle',
    this.glowOpacityScale = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    final base = (size * 3).clamp(72.0, 120.0);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: Colors.transparent,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: MoodyCharacter(
              size: base,
              mood: mood,
              glowOpacityScale: glowOpacityScale,
            ),
          ),
        ),
      ),
    );
  }
}
