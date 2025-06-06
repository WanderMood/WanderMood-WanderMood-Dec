import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import 'package:wandermood/core/router/router.dart';
import 'package:wandermood/core/presentation/providers/local_theme_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(localThemeProvider);
    print('🏗️ App: Building with themeMode: $themeMode');
    
    return MaterialApp.router(
      title: 'WanderMood',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // TEMP: Force dark mode for testing
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final decoration = AppTheme.backgroundGradientForTheme(themeMode, platformBrightness);
        print('🏗️ App: Platform brightness: $platformBrightness, Using decoration: ${decoration == AppTheme.darkBackgroundGradient ? "DARK" : "LIGHT"}');
        return Container(
          decoration: decoration,
          child: child!,
        );
      },
    );
  }
} 