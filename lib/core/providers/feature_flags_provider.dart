import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for controlling app behavior
/// 
/// Usage:
/// ```dart
/// final useNewOnboarding = ref.watch(useNewOnboardingFlowProvider);
/// if (useNewOnboarding) {
///   // Show new flow
/// } else {
///   // Show old flow
/// }
/// ```

// ============================================================================
// FEATURE FLAGS
// ============================================================================

/// Controls whether to use the new onboarding flow
/// - true: Splash → Intro → Demo → Guest Explore → Magic Link → Main
/// - false: Splash → Onboarding → Signup → Email Verification → Preferences → Main
/// 
/// Set to `true` to enable new flow, `false` to use old flow
final useNewOnboardingFlowProvider = StateProvider<bool>((ref) {
  // Start with new flow ENABLED for development
  // Change to `false` to instantly rollback to old flow
  return true;
});

/// Controls whether magic link auth is available
/// - true: Show magic link option (email only, no password)
/// - false: Use traditional email/password signup
final useMagicLinkAuthProvider = StateProvider<bool>((ref) {
  return true;
});

/// Controls whether guest exploration is allowed before signup
/// - true: Allow limited exploration without authentication
/// - false: Require authentication before any exploration
final allowGuestExploreProvider = StateProvider<bool>((ref) {
  return true;
});

// ============================================================================
// FEATURE FLAG PERSISTENCE (for A/B testing and remote config)
// ============================================================================

/// Provider for managing persisted feature flags
class FeatureFlagsNotifier extends StateNotifier<Map<String, bool>> {
  FeatureFlagsNotifier() : super({}) {
    _loadFlags();
  }
  
  static const String _storageKey = 'feature_flags';
  
  Future<void> _loadFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final flagsJson = prefs.getString(_storageKey);
      
      if (flagsJson != null) {
        // Parse saved flags
        // For now, we use defaults
      }
      
      // Set default flags
      state = {
        'new_onboarding': true,
        'magic_link_auth': true,
        'guest_explore': true,
      };
    } catch (e) {
      // Use defaults on error
      state = {
        'new_onboarding': true,
        'magic_link_auth': true,
        'guest_explore': true,
      };
    }
  }
  
  /// Toggle a specific flag
  void toggleFlag(String flagName) {
    if (state.containsKey(flagName)) {
      state = {
        ...state,
        flagName: !state[flagName]!,
      };
      _saveFlags();
    }
  }
  
  /// Set a specific flag value
  void setFlag(String flagName, bool value) {
    state = {
      ...state,
      flagName: value,
    };
    _saveFlags();
  }
  
  /// Get a flag value with fallback
  bool getFlag(String flagName, {bool defaultValue = false}) {
    return state[flagName] ?? defaultValue;
  }
  
  /// Save flags to persistent storage
  Future<void> _saveFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save as JSON string if needed for remote config
      // For now, we just persist the current state
    } catch (e) {
      // Ignore save errors
    }
  }
  
  /// Reset all flags to defaults
  void resetToDefaults() {
    state = {
      'new_onboarding': true,
      'magic_link_auth': true,
      'guest_explore': true,
    };
    _saveFlags();
  }
}

/// Provider for the feature flags notifier
final featureFlagsProvider = StateNotifierProvider<FeatureFlagsNotifier, Map<String, bool>>((ref) {
  return FeatureFlagsNotifier();
});

// ============================================================================
// ONBOARDING STATE TRACKING
// ============================================================================

/// Tracks guest exploration session state
class GuestSessionState {
  final int placesViewed;
  final int moodyInteractions;
  final DateTime? sessionStart;
  final bool hasSeenSignupPrompt;
  
  const GuestSessionState({
    this.placesViewed = 0,
    this.moodyInteractions = 0,
    this.sessionStart,
    this.hasSeenSignupPrompt = false,
  });
  
  GuestSessionState copyWith({
    int? placesViewed,
    int? moodyInteractions,
    DateTime? sessionStart,
    bool? hasSeenSignupPrompt,
  }) {
    return GuestSessionState(
      placesViewed: placesViewed ?? this.placesViewed,
      moodyInteractions: moodyInteractions ?? this.moodyInteractions,
      sessionStart: sessionStart ?? this.sessionStart,
      hasSeenSignupPrompt: hasSeenSignupPrompt ?? this.hasSeenSignupPrompt,
    );
  }
  
  /// Check if we should show a signup prompt based on engagement
  bool get shouldShowSignupPrompt {
    if (hasSeenSignupPrompt) return false;
    
    // Show prompt after:
    // - 3+ Moody interactions, OR
    // - 5+ places viewed, OR
    // - 2+ minutes of exploration
    if (moodyInteractions >= 3) return true;
    if (placesViewed >= 5) return true;
    
    if (sessionStart != null) {
      final duration = DateTime.now().difference(sessionStart!);
      if (duration.inMinutes >= 2) return true;
    }
    
    return false;
  }
}

/// Notifier for guest session state
class GuestSessionNotifier extends StateNotifier<GuestSessionState> {
  GuestSessionNotifier() : super(const GuestSessionState());
  
  /// Start a new guest session
  void startSession() {
    state = GuestSessionState(
      sessionStart: DateTime.now(),
    );
  }
  
  /// Track when user views a place
  void trackPlaceView() {
    state = state.copyWith(
      placesViewed: state.placesViewed + 1,
    );
  }
  
  /// Track when user interacts with Moody
  void trackMoodyInteraction() {
    state = state.copyWith(
      moodyInteractions: state.moodyInteractions + 1,
    );
  }
  
  /// Mark that signup prompt was shown
  void markSignupPromptShown() {
    state = state.copyWith(
      hasSeenSignupPrompt: true,
    );
  }
  
  /// Reset session (when user signs up or leaves)
  void resetSession() {
    state = const GuestSessionState();
  }
}

/// Provider for guest session state
final guestSessionProvider = StateNotifierProvider<GuestSessionNotifier, GuestSessionState>((ref) {
  return GuestSessionNotifier();
});

// ============================================================================
// NEW ONBOARDING FLOW STATE
// ============================================================================

/// Tracks progress through the new onboarding flow
enum OnboardingStep {
  splash,
  intro,
  demo,
  guestExplore,
  signup,
  complete,
}

/// Provider for tracking current onboarding step
final currentOnboardingStepProvider = StateProvider<OnboardingStep>((ref) {
  return OnboardingStep.splash;
});

/// Helper to check if user has completed specific onboarding steps
class OnboardingProgress {
  final bool hasSeenIntro;
  final bool hasCompletedDemo;
  final bool hasExploredAsGuest;
  final bool hasSignedUp;
  
  const OnboardingProgress({
    this.hasSeenIntro = false,
    this.hasCompletedDemo = false,
    this.hasExploredAsGuest = false,
    this.hasSignedUp = false,
  });
  
  OnboardingProgress copyWith({
    bool? hasSeenIntro,
    bool? hasCompletedDemo,
    bool? hasExploredAsGuest,
    bool? hasSignedUp,
  }) {
    return OnboardingProgress(
      hasSeenIntro: hasSeenIntro ?? this.hasSeenIntro,
      hasCompletedDemo: hasCompletedDemo ?? this.hasCompletedDemo,
      hasExploredAsGuest: hasExploredAsGuest ?? this.hasExploredAsGuest,
      hasSignedUp: hasSignedUp ?? this.hasSignedUp,
    );
  }
}

/// Notifier for onboarding progress
class OnboardingProgressNotifier extends StateNotifier<OnboardingProgress> {
  OnboardingProgressNotifier() : super(const OnboardingProgress());
  
  void markIntroSeen() {
    state = state.copyWith(hasSeenIntro: true);
  }
  
  void markDemoCompleted() {
    state = state.copyWith(hasCompletedDemo: true);
  }
  
  void markGuestExploreCompleted() {
    state = state.copyWith(hasExploredAsGuest: true);
  }
  
  void markSignedUp() {
    state = state.copyWith(hasSignedUp: true);
  }
  
  void reset() {
    state = const OnboardingProgress();
  }
}

/// Provider for onboarding progress
final onboardingProgressProvider = StateNotifierProvider<OnboardingProgressNotifier, OnboardingProgress>((ref) {
  return OnboardingProgressNotifier();
});

