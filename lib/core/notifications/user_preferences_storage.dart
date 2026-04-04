import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandermood/core/domain/models/user_preferences.dart';

/// Key used by [UserPreferencesNotifier] and notification code — keep in sync.
const String userPreferencesSharedPrefsKey = 'user_preferences';

/// Reads [UserPreferences] from the same JSON blob the settings notifier uses.
UserPreferences userPreferencesFromSharedPrefs(SharedPreferences prefs) {
  final raw = prefs.getString(userPreferencesSharedPrefsKey);
  if (raw == null || raw.isEmpty) return const UserPreferences();
  try {
    return UserPreferences.fromJson(raw);
  } catch (_) {
    return const UserPreferences();
  }
}
