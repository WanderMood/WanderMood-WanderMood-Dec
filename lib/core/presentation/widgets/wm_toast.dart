import 'package:flutter/material.dart';
import 'package:wandermood/core/utils/moody_toast.dart';

/// Hides the current [SnackBar] if [context] is available.
void dismissWanderMoodToast([BuildContext? context]) {
  if (context != null) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }
}

/// Floating charcoal snackbar — matches [showMoodyToast] styling; supports optional action and leading.
void showWanderMoodToast(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isWarning = false,
  Color? backgroundColor,
  Widget? leading,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  // [isError] / [isWarning] kept for backward-compatible call sites (same snack styling).
  if (isError || isWarning) {
    // no-op
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final bg = backgroundColor ?? kWmCharcoalToast;
  final hasAction = actionLabel != null &&
      actionLabel.isNotEmpty &&
      onAction != null;

  final mq = MediaQuery.of(context);
  final bottomClearance =
      16.0 + mq.padding.bottom + 72.0;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      closeIconColor: Colors.white70,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomClearance),
      padding: EdgeInsets.symmetric(
        horizontal: hasAction || leading != null ? 16 : 20,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bg,
      elevation: 8,
      duration: duration,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action: hasAction
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    ),
  );
}
