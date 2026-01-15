import 'package:flutter/material.dart';

/// Extension on ThemeData to provide easy access to all colors
/// This is the SINGLE SOURCE OF TRUTH for all colors in the app
extension ThemeColors on ThemeData {
  // Background Colors
  Color get surfaceColor => cardTheme.color ?? colorScheme.surface;
  Color get backgroundColor => scaffoldBackgroundColor;
  Color get appBarColor => appBarTheme.backgroundColor ?? scaffoldBackgroundColor;
  
  // Text Colors
  Color get textPrimary => textTheme.bodyLarge?.color ?? colorScheme.onSurface;
  Color get textSecondary => textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);
  Color get textTertiary => textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.5);
  Color get textTitle => textTheme.titleLarge?.color ?? colorScheme.onSurface;
  
  // Border & Divider Colors
  Color get borderColor => dividerColor.withOpacity(brightness == Brightness.dark ? 0.3 : 0.5);
  Color get dividerColorLight => dividerColor.withOpacity(0.3);
  Color get dividerColorMedium => dividerColor.withOpacity(0.5);
  
  // Shadow Colors
  Color get shadowColorLight => shadowColor.withOpacity(0.05);
  Color get shadowColorMedium => shadowColor.withOpacity(0.1);
  Color get shadowColorHeavy => shadowColor.withOpacity(0.2);
  
  // Icon Colors
  Color get iconColor => iconTheme.color ?? colorScheme.onSurface;
  Color get iconColorSecondary => iconTheme.color?.withOpacity(0.6) ?? colorScheme.onSurface.withOpacity(0.6);
  
  // Common UI Colors (theme-aware)
  Color get whiteColor => brightness == Brightness.dark 
      ? colorScheme.onSurface 
      : Colors.white;
  
  Color get blackColor => brightness == Brightness.dark 
      ? Colors.white 
      : Colors.black;
  
  // Grey shades (theme-aware)
  Color get grey100 => brightness == Brightness.dark 
      ? colorScheme.surface.withOpacity(0.1) 
      : Colors.grey[100]!;
  
  Color get grey200 => brightness == Brightness.dark 
      ? dividerColor.withOpacity(0.3) 
      : Colors.grey[200]!;
  
  Color get grey300 => brightness == Brightness.dark 
      ? dividerColor.withOpacity(0.5) 
      : Colors.grey[300]!;
  
  Color get grey400 => brightness == Brightness.dark 
      ? colorScheme.onSurface.withOpacity(0.4) 
      : Colors.grey[400]!;
  
  Color get grey500 => brightness == Brightness.dark 
      ? colorScheme.onSurface.withOpacity(0.5) 
      : Colors.grey[500]!;
  
  Color get grey600 => brightness == Brightness.dark 
      ? colorScheme.onSurface.withOpacity(0.6) 
      : Colors.grey[600]!;
  
  Color get grey700 => brightness == Brightness.dark 
      ? colorScheme.onSurface.withOpacity(0.7) 
      : Colors.grey[700]!;
  
  Color get grey800 => brightness == Brightness.dark 
      ? colorScheme.onSurface.withOpacity(0.8) 
      : Colors.grey[800]!;
  
  // Status Colors (use theme's error/success, but provide fallbacks)
  Color get successColor => colorScheme.primary; // Green in light, adjust for dark
  Color get errorColor => colorScheme.error;
  Color get warningColor => colorScheme.tertiary;
  
  // Helper to check if dark mode
  bool get isDark => brightness == Brightness.dark;
}

