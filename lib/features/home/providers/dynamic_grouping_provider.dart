import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../application/dynamic_grouping_service.dart';
import '../application/context_manager.dart';
import '../../places/models/place.dart';
import '../../places/providers/explore_places_provider.dart';
import '../../../core/domain/providers/location_notifier_provider.dart';
import 'smart_context_provider.dart';

/// Dynamic grouping result model
class DynamicGroupingResult {
  final Map<String, List<Place>> groups;
  final List<String> recommendations;
  final int totalPlaces;
  final SmartContext context;
  final bool isLoading;
  final String? error;

  const DynamicGroupingResult({
    required this.groups,
    required this.recommendations,
    required this.totalPlaces,
    required this.context,
    this.isLoading = false,
    this.error,
  });

  DynamicGroupingResult copyWith({
    Map<String, List<Place>>? groups,
    List<String>? recommendations,
    int? totalPlaces,
    SmartContext? context,
    bool? isLoading,
    String? error,
  }) {
    return DynamicGroupingResult(
      groups: groups ?? this.groups,
      recommendations: recommendations ?? this.recommendations,
      totalPlaces: totalPlaces ?? this.totalPlaces,
      context: context ?? this.context,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Loading state constructor
  factory DynamicGroupingResult.loading(SmartContext context) {
    return DynamicGroupingResult(
      groups: {},
      recommendations: [],
      totalPlaces: 0,
      context: context,
      isLoading: true,
    );
  }

  /// Error state constructor
  factory DynamicGroupingResult.error(String error, SmartContext context) {
    return DynamicGroupingResult(
      groups: {},
      recommendations: [],
      totalPlaces: 0,
      context: context,
      error: error,
    );
  }
}

/// Provider for dynamic grouping service
class DynamicGroupingNotifier extends StateNotifier<DynamicGroupingResult?> {
  DynamicGroupingNotifier() : super(null);

  /// Group places dynamically based on context
  Future<void> groupPlaces({
    required List<Place> places,
    required SmartContext context,
    String? userId,
  }) async {
    try {
      // Set loading state
      state = DynamicGroupingResult.loading(context);

      // Get grouped data from service
      final result = await DynamicGroupingService.groupPlacesByContext(
        places: places,
        context: context,
        userId: userId,
      );

      // Update state with results
      state = DynamicGroupingResult(
        groups: result['groups'] as Map<String, List<Place>>,
        recommendations: result['recommendations'] as List<String>,
        totalPlaces: result['totalPlaces'] as int,
        context: result['context'] as SmartContext,
      );
    } catch (e) {
      state = DynamicGroupingResult.error(
        'Failed to group places: ${e.toString()}',
        context,
      );
    }
  }

  /// Clear grouping results
  void clearResults() {
    state = null;
  }

  /// Update user preference when place is interacted with
  Future<void> updateUserInteraction({
    required String userId,
    String? visitedPlaceId,
    String? savedPlaceId,
  }) async {
    try {
      await DynamicGroupingService.updateUserPreferences(
        userId: userId,
        visitedPlaceId: visitedPlaceId,
        savedPlaceId: savedPlaceId,
      );
    } catch (e) {
      print('Error updating user interaction: $e');
    }
  }
}

/// Provider for dynamic grouping
final dynamicGroupingProvider = StateNotifierProvider<DynamicGroupingNotifier, DynamicGroupingResult?>(
  (ref) => DynamicGroupingNotifier(),
);

/// Provider for current user ID (from Supabase auth)
final currentUserIdProvider = Provider<String?>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.currentUser?.id;
});

/// Provider that automatically groups places when context or places change
final autoGroupingProvider = Provider<AsyncValue<DynamicGroupingResult?>>((ref) {
  final smartContext = ref.watch(smartContextProvider);
  final places = ref.watch(filteredPlacesProvider);
  final userId = ref.watch(currentUserIdProvider);
  final groupingNotifier = ref.watch(dynamicGroupingProvider.notifier);
  
  // Smart context is available directly (not wrapped in AsyncValue)
  if (places.isNotEmpty) {
    // Trigger grouping when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      groupingNotifier.groupPlaces(
        places: places,
        context: smartContext,
        userId: userId,
      );
    });
  }
  return AsyncValue.data(ref.watch(dynamicGroupingProvider));
});

/// Provider for filtered places from explore screen - using keepAlive to prevent rebuilds
final filteredPlacesProvider = Provider<List<Place>>((ref) {
  // Keep this provider alive to prevent constant rebuilds
  ref.keepAlive();
  
  final locationState = ref.watch(locationNotifierProvider);
  final city = locationState.value ?? 'Rotterdam';
  
  // Use Edge Function data instead of old Google Places API
  final placesAsync = ref.read(moodyExploreAutoProvider);
  
  return placesAsync.when(
    data: (places) => places,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Enhanced smart context provider with grouping integration
final smartContextWithGroupingProvider = Provider<SmartContextWithGrouping?>((ref) {
  final smartContext = ref.watch(smartContextProvider);
  final groupingResult = ref.watch(dynamicGroupingProvider);
  
  // Smart context is available directly
  if (groupingResult != null) {
    return SmartContextWithGrouping(
      context: smartContext,
      grouping: groupingResult,
    );
  }
  return null;
});

/// Combined smart context and grouping model
class SmartContextWithGrouping {
  final SmartContext context;
  final DynamicGroupingResult grouping;

  const SmartContextWithGrouping({
    required this.context,
    required this.grouping,
  });

  /// Get primary group for display
  String? get primaryGroupName {
    if (grouping.groups.isEmpty) return null;
    
    // Return the group with most places
    String? bestGroup;
    int maxPlaces = 0;
    
    for (final entry in grouping.groups.entries) {
      if (entry.value.length > maxPlaces) {
        maxPlaces = entry.value.length;
        bestGroup = entry.key;
      }
    }
    
    return bestGroup;
  }

  /// Get primary group places
  List<Place> get primaryGroupPlaces {
    final groupName = primaryGroupName;
    return groupName != null ? grouping.groups[groupName] ?? [] : [];
  }

  /// Get total grouped places count
  int get totalGroupedPlaces {
    return grouping.groups.values.fold(0, (sum, places) => sum + places.length);
  }

  /// Check if grouping is active
  bool get isGroupingActive {
    return grouping.groups.isNotEmpty && !grouping.isLoading;
  }
} 