import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/core/theme/app_theme.dart';
import 'package:wandermood/core/router/router.dart';
import 'package:wandermood/core/presentation/providers/local_theme_provider.dart';
import 'package:wandermood/core/presentation/providers/language_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(localThemeProvider);
    final locale = ref.watch(localeProvider);
    if (kDebugMode) debugPrint('App: Building');
    
    return MaterialApp.router(
      title: 'WanderMood',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Use theme from provider (respects user preference)
      locale: locale, // Use locale from provider (respects user preference)
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('nl'), // Nederlands
        Locale('es'), // Español
        Locale('fr'), // Français
        Locale('de'), // Deutsch
      ],
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final decoration = AppTheme.backgroundGradientForTheme(themeMode, platformBrightness);
        if (kDebugMode) debugPrint('App: Platform brightness');
        return Container(
          decoration: decoration,
          child: child!,
        );
      },
    );
  }
} 