import 'dart:async';
import 'package:flutter/material.dart';

Timer? _wandermoodToastTimer;
OverlayEntry? _wandermoodToastEntry;

/// Removes the current WanderMood toast overlay (if any).
void dismissWanderMoodToast() {
  _wandermoodToastTimer?.cancel();
  _wandermoodToastTimer = null;
  final e = _wandermoodToastEntry;
  _wandermoodToastEntry = null;
  if (e != null) {
    try {
      e.remove();
    } catch (_) {
      // Already removed
    }
  }
}

/// Custom overlay toast (QA: prefer over [SnackBar]).
///
/// Supports legacy call sites: [backgroundColor], [leading].
/// Optional [actionLabel] + [onAction] show a tappable action (e.g. "View").
void showWanderMoodToast(
  BuildContext context, {
  required String message,
  bool isError = false,
  /// Non-error heads-up — uses wmSunset when [backgroundColor] is null.
  bool isWarning = false,
  /// When set, overrides the default forest / sunset / error fill.
  Color? backgroundColor,
  /// Optional icon or progress indicator before the message.
  Widget? leading,
  Duration duration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  dismissWanderMoodToast();

  final overlay = Overlay.of(context);

  Color bg;
  if (backgroundColor != null) {
    bg = backgroundColor;
  } else if (isError) {
    bg = const Color(0xFFB3261E);
  } else if (isWarning) {
    bg = const Color(0xFFE8784A); // wmSunset
  } else {
    bg = const Color(0xFF2A6049); // wmForest
  }

  final labelStr = actionLabel;
  final actionCb = onAction;
  final hasAction = labelStr != null &&
      labelStr.isNotEmpty &&
      actionCb != null;
  final lead = leading;
  final interactive = hasAction;

  late final OverlayEntry entry;
  var dismissed = false;

  void dismiss() {
    if (dismissed) return;
    dismissed = true;
    _wandermoodToastTimer?.cancel();
    _wandermoodToastTimer = null;
    if (_wandermoodToastEntry == entry) {
      _wandermoodToastEntry = null;
    }
    try {
      entry.remove();
    } catch (_) {}
  }

  final textStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  Widget content;
  if (hasAction) {
    final onTap = actionCb;
    final label = labelStr;
    content = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (lead != null) ...[
              lead,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: textStyle,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                onTap();
                dismiss();
              },
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } else if (lead != null) {
    content = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            lead,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: textStyle,
      ),
    );
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(ctx).padding.bottom + 24,
      child: interactive
          ? Material(
              color: Colors.transparent,
              child: AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 150),
                child: content,
              ),
            )
          : IgnorePointer(
              child: Material(
                color: Colors.transparent,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 150),
                  child: content,
                ),
              ),
            ),
    ),
  );

  _wandermoodToastEntry = entry;
  overlay.insert(entry);
  _wandermoodToastTimer = Timer(duration, dismiss);
}
