import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/travel_post.dart';
import '../repositories/travel_post_repository.dart';

// ============================================================================
// TRAVEL POST STATE PROVIDERS
// ============================================================================

/// Feed posts provider with pagination
final feedPostsProvider = StateNotifierProvider<FeedPostsNotifier, AsyncValue<List<TravelPost>>>((ref) {
  return FeedPostsNotifier(ref.read(travelPostRepositoryProvider));
});

/// User posts provider
final userPostsProvider = StateNotifierProvider.family<UserPostsNotifier, AsyncValue<List<TravelPost>>, String>(
  (ref, userId) {
    return UserPostsNotifier(ref.read(travelPostRepositoryProvider), userId);
  },
);

/// Single post provider
final postProvider = StateNotifierProvider.family<PostNotifier, AsyncValue<TravelPost?>, String>(
  (ref, postId) {
    return PostNotifier(ref.read(travelPostRepositoryProvider), postId);
  },
);

/// Trending posts provider
final trendingPostsProvider = StateNotifierProvider<TrendingPostsNotifier, AsyncValue<List<TravelPost>>>((ref) {
  return TrendingPostsNotifier(ref.read(travelPostRepositoryProvider));
});

/// Post creation provider
final postCreationProvider = StateNotifierProvider<PostCreationNotifier, AsyncValue<String?>>((ref) {
  return PostCreationNotifier(ref.read(travelPostRepositoryProvider));
});

/// Search posts provider
final searchPostsProvider = StateNotifierProvider<SearchPostsNotifier, AsyncValue<List<TravelPost>>>((ref) {
  return SearchPostsNotifier(ref.read(travelPostRepositoryProvider));
});

// ============================================================================
// STATE NOTIFIERS
// ============================================================================

class FeedPostsNotifier extends StateNotifier<AsyncValue<List<TravelPost>>> {
  final TravelPostRepository _repository;
  int _currentPage = 0;
  bool _hasMore = true;
  
  FeedPostsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFeedPosts();
  }
  
  Future<void> loadFeedPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    } else if (!_hasMore) {
      return; // No more data to load
    }
    
    try {
      final posts = await _repository.getFeedPosts(page: _currentPage);
      
      if (posts.isEmpty || posts.length < 20) {
        _hasMore = false;
      }
      
      if (_currentPage == 0 || refresh) {
        state = AsyncValue.data(posts);
      } else {
        final currentPosts = state.valueOrNull ?? [];
        state = AsyncValue.data([...currentPosts, ...posts]);
      }
      
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await loadFeedPosts();
    }
  }
  
  Future<void> refresh() async {
    await loadFeedPosts(refresh: true);
  }
}

class UserPostsNotifier extends StateNotifier<AsyncValue<List<TravelPost>>> {
  final TravelPostRepository _repository;
  final String _userId;
  int _currentPage = 0;
  bool _hasMore = true;
  
  UserPostsNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadUserPosts();
  }
  
  Future<void> loadUserPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    } else if (!_hasMore) {
      return;
    }
    
    try {
      final posts = await _repository.getUserPosts(_userId, page: _currentPage);
      
      if (posts.isEmpty || posts.length < 20) {
        _hasMore = false;
      }
      
      if (_currentPage == 0 || refresh) {
        state = AsyncValue.data(posts);
      } else {
        final currentPosts = state.valueOrNull ?? [];
        state = AsyncValue.data([...currentPosts, ...posts]);
      }
      
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await loadUserPosts();
    }
  }
  
  Future<void> refresh() async {
    await loadUserPosts(refresh: true);
  }
}

class PostNotifier extends StateNotifier<AsyncValue<TravelPost?>> {
  final TravelPostRepository _repository;
  final String _postId;
  
  PostNotifier(this._repository, this._postId) : super(const AsyncValue.loading()) {
    loadPost();
  }
  
  Future<void> loadPost() async {
    try {
      final post = await _repository.getPostById(_postId);
      state = AsyncValue.data(post);
      
      // Track view count (fire and forget)
      if (post != null) {
        _repository.incrementViewCount(_postId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> likePost() async {
    final currentPost = state.valueOrNull;
    if (currentPost == null) return;
    
    try {
      await _repository.likePost(_postId);
      // Refresh post to get updated like count
      await loadPost();
    } catch (e) {
      // Handle error
      print('Error liking post: $e');
    }
  }
  
  Future<void> unlikePost() async {
    final currentPost = state.valueOrNull;
    if (currentPost == null) return;
    
    try {
      await _repository.unlikePost(_postId);
      // Refresh post to get updated like count
      await loadPost();
    } catch (e) {
      print('Error unliking post: $e');
    }
  }
  
  Future<void> addReaction(String reactionType) async {
    try {
      await _repository.addReaction(_postId, reactionType);
      await loadPost();
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }
  
  Future<void> removeReaction() async {
    try {
      await _repository.removeReaction(_postId);
      await loadPost();
    } catch (e) {
      print('Error removing reaction: $e');
    }
  }
}

class TrendingPostsNotifier extends StateNotifier<AsyncValue<List<TravelPost>>> {
  final TravelPostRepository _repository;
  
  TrendingPostsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTrendingPosts();
  }
  
  Future<void> loadTrendingPosts() async {
    try {
      final posts = await _repository.getTrendingPosts();
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await loadTrendingPosts();
  }
}

class PostCreationNotifier extends StateNotifier<AsyncValue<String?>> {
  final TravelPostRepository _repository;
  
  PostCreationNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<void> createPost(CreateTravelPostRequest request, List<String> photoFiles) async {
    state = const AsyncValue.loading();
    
    try {
      final postId = await _repository.createPost(request, photoFiles);
      state = AsyncValue.data(postId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  void reset() {
    state = const AsyncValue.data(null);
  }
}

class SearchPostsNotifier extends StateNotifier<AsyncValue<List<TravelPost>>> {
  final TravelPostRepository _repository;
  String _currentQuery = '';
  int _currentPage = 0;
  bool _hasMore = true;
  
  SearchPostsNotifier(this._repository) : super(const AsyncValue.data([]));
  
  Future<void> searchPosts(String query, {bool newSearch = true}) async {
    if (newSearch) {
      _currentQuery = query;
      _currentPage = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    } else if (!_hasMore || query != _currentQuery) {
      return;
    }
    
    try {
      final posts = await _repository.searchPosts(query, page: _currentPage);
      
      if (posts.isEmpty || posts.length < 20) {
        _hasMore = false;
      }
      
      if (_currentPage == 0 || newSearch) {
        state = AsyncValue.data(posts);
      } else {
        final currentPosts = state.valueOrNull ?? [];
        state = AsyncValue.data([...currentPosts, ...posts]);
      }
      
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading && _currentQuery.isNotEmpty) {
      await searchPosts(_currentQuery, newSearch: false);
    }
  }
  
  void clearSearch() {
    _currentQuery = '';
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.data([]);
  }
}

// ============================================================================
// COMPUTED PROVIDERS
// ============================================================================

/// Posts by location
final postsByLocationProvider = FutureProvider.family<List<TravelPost>, String>((ref, location) async {
  final repository = ref.read(travelPostRepositoryProvider);
  return await repository.getPostsByLocation(location);
});

/// Posts by mood
final postsByMoodProvider = FutureProvider.family<List<TravelPost>, String>((ref, mood) async {
  final repository = ref.read(travelPostRepositoryProvider);
  return await repository.getPostsByMood(mood);
});

/// Post loading state
final isPostLoadingProvider = Provider<bool>((ref) {
  final feedState = ref.watch(feedPostsProvider);
  final trendingState = ref.watch(trendingPostsProvider);
  final creationState = ref.watch(postCreationProvider);
  
  return feedState.isLoading || trendingState.isLoading || creationState.isLoading;
});

// ============================================================================
// ACTIONS PROVIDER
// ============================================================================

final postActionsProvider = Provider<PostActions>((ref) {
  return PostActions(ref);
});

class PostActions {
  final Ref ref;
  
  PostActions(this.ref);
  
  /// Create a new travel post
  Future<String?> createPost({
    String? title,
    required String story,
    required String mood,
    String? location,
    LocationDetails? locationDetails,
    List<String> tags = const [],
    List<String> activities = const [],
    List<String> travelCompanions = const [],
    double? budgetSpent,
    String currencyCode = 'EUR',
    int? rating,
    String? travelTips,
    String? bestTimeToVisit,
    String privacyLevel = 'public',
    List<ItineraryItem> itinerary = const [],
    List<TravelExpense> expenses = const [],
    List<String> photoFiles = const [],
  }) async {
    final request = CreateTravelPostRequest(
      title: title,
      story: story,
      mood: mood,
      location: location,
      locationDetails: locationDetails,
      tags: tags,
      activities: activities,
      travelCompanions: travelCompanions,
      budgetSpent: budgetSpent,
      currencyCode: currencyCode,
      rating: rating,
      travelTips: travelTips,
      bestTimeToVisit: bestTimeToVisit,
      privacyLevel: privacyLevel,
      itinerary: itinerary,
      expenses: expenses,
    );
    
    final notifier = ref.read(postCreationProvider.notifier);
    await notifier.createPost(request, photoFiles);
    
    final result = ref.read(postCreationProvider);
    return result.valueOrNull;
  }
  
  /// Refresh feed posts
  Future<void> refreshFeed() async {
    ref.read(feedPostsProvider.notifier).refresh();
  }
  
  /// Refresh trending posts
  Future<void> refreshTrending() async {
    ref.read(trendingPostsProvider.notifier).refresh();
  }
  
  /// Search for posts
  Future<void> searchPosts(String query) async {
    ref.read(searchPostsProvider.notifier).searchPosts(query);
  }
  
  /// Clear search results
  void clearSearch() {
    ref.read(searchPostsProvider.notifier).clearSearch();
  }
  
  /// Get posts by location
  Future<List<TravelPost>> getPostsByLocation(String location) async {
    final result = await ref.read(postsByLocationProvider(location).future);
    return result;
  }
  
  /// Get posts by mood
  Future<List<TravelPost>> getPostsByMood(String mood) async {
    final result = await ref.read(postsByMoodProvider(mood).future);
    return result;
  }
} 