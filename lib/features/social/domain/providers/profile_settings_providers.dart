import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/social/data/services/profile_settings_service.dart';
import 'package:wandermood/features/social/domain/models/user_profile.dart';
import 'package:wandermood/features/social/domain/models/wander_badge.dart';
import 'package:wandermood/features/social/domain/models/saved_folder.dart';
import 'package:wandermood/features/social/domain/models/travel_mood_preferences.dart';

// Service provider
final profileSettingsServiceProvider = Provider<ProfileSettingsService>((ref) {
  return ProfileSettingsService();
});

// User badges provider
final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final service = ref.read(profileSettingsServiceProvider);
  return service.getUserBadges();
});

// All available badges provider
final allBadgesProvider = FutureProvider<List<WanderBadge>>((ref) async {
  final service = ref.read(profileSettingsServiceProvider);
  return service.getAllBadges();
});

// Saved folders provider
final savedFoldersProvider = StateNotifierProvider<SavedFoldersNotifier, AsyncValue<List<SavedFolder>>>((ref) {
  return SavedFoldersNotifier(ref.read(profileSettingsServiceProvider));
});

class SavedFoldersNotifier extends StateNotifier<AsyncValue<List<SavedFolder>>> {
  final ProfileSettingsService _service;

  SavedFoldersNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await _service.getSavedFolders();
      state = AsyncValue.data(folders);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createFolder({
    required String name,
    String? description,
    String color = '#6366f1',
    String icon = '📁',
  }) async {
    try {
      await _service.createFolder(
        name: name,
        description: description,
        color: color,
        icon: icon,
      );
      await _loadFolders(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateFolder(SavedFolder folder) async {
    try {
      await _service.updateFolder(folder);
      await _loadFolders(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      await _service.deleteFolder(folderId);
      await _loadFolders(); // Refresh the list
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void refresh() => _loadFolders();
}

// Travel mood preferences provider
final travelMoodPreferencesProvider = StateNotifierProvider<TravelMoodPreferencesNotifier, AsyncValue<TravelMoodPreferences?>>((ref) {
  return TravelMoodPreferencesNotifier(ref.read(profileSettingsServiceProvider));
});

class TravelMoodPreferencesNotifier extends StateNotifier<AsyncValue<TravelMoodPreferences?>> {
  final ProfileSettingsService _service;

  TravelMoodPreferencesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _service.getTravelMoodPreferences();
      state = AsyncValue.data(preferences);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updatePreferences(TravelMoodPreferences preferences) async {
    try {
      await _service.updateTravelMoodPreferences(preferences);
      state = AsyncValue.data(preferences);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void refresh() => _loadPreferences();
}

// Current user profile provider - loads from database, not demo data
final currentUserProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final service = ref.read(profileSettingsServiceProvider);
  return await service.getCurrentUserProfile();
});

// Profile settings actions provider
final profileSettingsActionsProvider = Provider<ProfileSettingsActions>((ref) {
  return ProfileSettingsActions(ref.read(profileSettingsServiceProvider));
});

class ProfileSettingsActions {
  final ProfileSettingsService _service;

  ProfileSettingsActions(this._service);

  Future<void> updateProfileInfo({
    String? travelBio,
    String? currentlyExploring,
    List<String>? travelVibes,
    String? fullName,
    String? imageUrl,
  }) async {
    await _service.updateProfileInfo(
      travelBio: travelBio,
      currentlyExploring: currentlyExploring,
      travelVibes: travelVibes,
      fullName: fullName,
      imageUrl: imageUrl,
    );
  }

  Future<void> updatePrivacySettings({
    String? profileVisibility,
    String? storyVisibility,
    bool? locationSharing,
    bool? activityStatus,
    bool? allowMessages,
    bool? showFollowers,
  }) async {
    await _service.updatePrivacySettings(
      profileVisibility: profileVisibility,
      storyVisibility: storyVisibility,
      locationSharing: locationSharing,
      activityStatus: activityStatus,
      allowMessages: allowMessages,
      showFollowers: showFollowers,
    );
  }

  Future<void> updateGeneralSettings({
    String? themePreference,
    String? languagePreference,
    Map<String, bool>? notificationPreferences,
  }) async {
    await _service.updateGeneralSettings(
      themePreference: themePreference,
      languagePreference: languagePreference,
      notificationPreferences: notificationPreferences,
    );
  }

  Future<String?> uploadProfilePhoto(String filePath) async {
    return await _service.uploadProfilePhoto(filePath);
  }

  Future<void> checkAndAwardBadges() async {
    await _service.checkAndAwardBadges();
  }

  Future<void> updateTravelDna() async {
    await _service.updateTravelDna();
  }

  Future<void> updateMoodOfMonth() async {
    await _service.updateMoodOfMonth();
  }
} 