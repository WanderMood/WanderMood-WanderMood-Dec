import 'package:flutter/material.dart';

/// WanderMood v2 — wmCharcoal floating snack (QA: consistent toast style).
const Color kWmCharcoalToast = Color(0xFF1E1C18);

void showMoodyToast(BuildContext context, String message) {
  final bottomClearance =
      16.0 + MediaQuery.of(context).padding.bottom + 72.0;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomClearance),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kWmCharcoalToast,
        elevation: 8,
        duration: const Duration(seconds: 3),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
}
