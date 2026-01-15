import 'package:flutter/material.dart';

/// Custom theme mode that extends ThemeMode to include black theme
enum CustomThemeMode {
  light,
  dark,
  black,
  system,
}

extension CustomThemeModeExtension on CustomThemeMode {
  /// Convert to Flutter's ThemeMode for MaterialApp
  ThemeMode toThemeMode() {
    switch (this) {
      case CustomThemeMode.light:
        return ThemeMode.light;
      case CustomThemeMode.dark:
      case CustomThemeMode.black:
        return ThemeMode.dark; // Both use dark as base
      case CustomThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Check if this is a black theme
  bool get isBlack => this == CustomThemeMode.black;
}

