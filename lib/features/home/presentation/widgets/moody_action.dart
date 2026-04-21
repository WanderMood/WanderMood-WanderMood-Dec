import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Stable identifier for each possible top-level action. Lets the builder
/// key `AnimatedSwitcher`s on a deterministic list rather than the label,
/// which can change per-state (e.g. Mood Match copy).
enum MoodyActionId {
  planWholeDay,
  continueDay,
  changeMood,
  replaceActivity,
  findCoffee,
  getMeActive,
  moodMatch,
}

/// Visual prominence of an action — picked once by the builder, read by both
/// the pill row and any future expanded surface.
enum MoodyActionTone {
  /// Filled forest green — one per state, always first.
  primary,

  /// Sunset accent — reserved for Mood Match when it's in the pill row.
  accent,

  /// White / tinted — everything else.
  neutral,
}

@immutable
class MoodyAction {
  const MoodyAction({
    required this.id,
    required this.emoji,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final MoodyActionId id;
  final String emoji;
  final String label;
  final MoodyActionTone tone;
  final VoidCallback onTap;
}
