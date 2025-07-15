import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_option.dart';
import '../services/mood_options_service.dart';

/// Provider for fetching mood options from the database
final moodOptionsProvider = FutureProvider<List<MoodOption>>((ref) async {
  return await MoodOptionsService.getMoodOptions();
});

/// Provider for selected mood options (for the home screen)
final selectedMoodOptionsProvider = StateProvider<Set<String>>((ref) {
  return <String>{};
});

/// Notifier for managing mood options state
class MoodOptionsNotifier extends StateNotifier<AsyncValue<List<MoodOption>>> {
  MoodOptionsNotifier() : super(const AsyncValue.loading());

  /// Load mood options from database
  Future<void> loadMoodOptions() async {
    try {
      state = const AsyncValue.loading();
      final moodOptions = await MoodOptionsService.getMoodOptions();
      state = AsyncValue.data(moodOptions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh mood options
  Future<void> refresh() async {
    await loadMoodOptions();
  }

  /// Get current mood options if available
  List<MoodOption> get currentMoodOptions {
    return state.when(
      data: (moodOptions) => moodOptions,
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

/// Provider for mood options notifier
final moodOptionsNotifierProvider = 
    StateNotifierProvider<MoodOptionsNotifier, AsyncValue<List<MoodOption>>>((ref) {
  return MoodOptionsNotifier();
});

/// Provider for a specific mood option by ID
final moodOptionProvider = FutureProvider.family<MoodOption?, String>((ref, id) async {
  return await MoodOptionsService.getMoodOption(id);
});

/// Provider for checking if mood options are available
final moodOptionsAvailableProvider = Provider<bool>((ref) {
  final moodOptionsAsync = ref.watch(moodOptionsProvider);
  return moodOptionsAsync.when(
    data: (moodOptions) => moodOptions.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for getting mood option by label
final moodOptionByLabelProvider = Provider.family<MoodOption?, String>((ref, label) {
  final moodOptionsAsync = ref.watch(moodOptionsProvider);
  return moodOptionsAsync.when(
    data: (moodOptions) {
      try {
        return moodOptions.firstWhere((mood) => mood.label == label);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
}); 