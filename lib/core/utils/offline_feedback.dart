import 'package:flutter/material.dart';

/// Design token `wmError`
const Color kOfflineSnackColor = Color(0xFFE05C5C);

void showOfflineSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This feature needs an internet connection'),
      backgroundColor: kOfflineSnackColor,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}
