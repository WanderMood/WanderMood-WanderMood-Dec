import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';

/// Provider for the app's current locale based on user profile preference
/// Returns null to use system locale, or a specific Locale if user has set a preference
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._ref) : super(null) {
    _loadLocale();
    // When profile loads and the user has never chosen a language locally,
    // adopt the server preference once (multi-device). Never clobber explicit prefs.
    _ref.listen(profileProvider, (previous, next) {
      next.whenData((profile) async {
        final lang = profile?.languagePreference;
        if (lang == null) return;
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey(_localeKey)) return;
        final useSystem = prefs.getBool(_useSystemKey) ?? false;
        if (useSystem) return;
        _updateLocaleFromProfile(lang);
      });
    });
  }

  final Ref _ref;
  static const String _localeKey = 'app_locale';
  static const String _useSystemKey = 'use_system_locale';

  static const Set<String> _supported = {'en', 'nl', 'es', 'fr', 'de'};

  static String _primaryTag(String code) =>
      code.toLowerCase().split(RegExp(r'[-_]')).first;

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useSystem = prefs.getBool(_useSystemKey) ?? false;
      if (useSystem) {
        state = null;
        return;
      }

      final hasSetLanguage = prefs.containsKey(_localeKey);

      if (hasSetLanguage) {
        final raw = prefs.getString(_localeKey);
        if (raw != null && raw.isNotEmpty) {
          final tag = _primaryTag(raw);
          state = Locale(tag);
        } else {
          state = null;
        }
        return;
      }

      // First install: follow device (never force English).
      final deviceTag =
          _primaryTag(PlatformDispatcher.instance.locale.languageCode);
      if (deviceTag == 'nl') {
        await prefs.setString(_localeKey, 'nl');
        await prefs.setBool(_useSystemKey, false);
        state = const Locale('nl');
      } else if (_supported.contains(deviceTag)) {
        await prefs.setString(_localeKey, deviceTag);
        await prefs.setBool(_useSystemKey, false);
        state = Locale(deviceTag);
      } else {
        state = null;
      }
    } catch (_) {
      state = null;
    }
  }

  void _updateLocaleFromProfile(String languageCode) {
    final localeMap = {
      'en': const Locale('en'),
      'nl': const Locale('nl'),
      'es': const Locale('es'),
      'fr': const Locale('fr'),
      'de': const Locale('de'),
    };

    final tag = _primaryTag(languageCode);
    state = localeMap[tag] ?? Locale(_supported.contains(tag) ? tag : 'en');

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_localeKey, tag);
      prefs.setBool(_useSystemKey, false);
    });
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;

    final prefs = await SharedPreferences.getInstance();

    if (locale == null) {
      await prefs.setBool(_useSystemKey, true);
      await prefs.remove(_localeKey);
    } else {
      await prefs.setBool(_useSystemKey, false);
      await prefs.setString(_localeKey, locale.languageCode);

      try {
        await _ref.read(profileProvider.notifier).updateProfile(
              languagePreference: locale.languageCode,
            );
      } catch (_) {}
    }
  }
}
