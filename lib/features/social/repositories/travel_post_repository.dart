import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../domain/models/travel_post.dart';
import '../../../features/weather/application/enhanced_weather_service.dart';

final travelPostRepositoryProvider = Provider<TravelPostRepository>((ref) {
  return TravelPostRepositoryImpl();
});

abstract class TravelPostRepository {
  // Posts CRUD
  Future<List<TravelPost>> getFeedPosts({int page = 0, int limit = 20});
  Future<List<TravelPost>> getUserPosts(String userId, {int page = 0, int limit = 20});
  Future<TravelPost?> getPostById(String postId);
  Future<String> createPost(CreateTravelPostRequest request, List<String> photoFiles);
  Future<bool> updatePost(TravelPost post);
  Future<bool> deletePost(String postId);
  
  // Photo operations
  Future<String> uploadPhoto(String filePath, String postId);
  Future<List<String>> uploadMultiplePhotos(List<String> filePaths, String postId);
  Future<bool> deletePhoto(String photoUrl);
  
  // Interactions
  Future<bool> likePost(String postId);
  Future<bool> unlikePost(String postId);
  Future<bool> addReaction(String postId, String reactionType);
  Future<bool> removeReaction(String postId);
  Future<bool> incrementViewCount(String postId);
  
  // Discovery
  Future<List<TravelPost>> getTrendingPosts({int limit = 20});
  Future<List<TravelPost>> searchPosts(String query, {int page = 0, int limit = 20});
  Future<List<TravelPost>> getPostsByLocation(String location, {int limit = 20});
  Future<List<TravelPost>> getPostsByMood(String mood, {int limit = 20});
  
  // Cache management
  Future<void> warmCache();
  void clearCache();
}

class TravelPostRepositoryImpl implements TravelPostRepository {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  
  // Memory cache
  final Map<String, TravelPost> _postCache = {};
  final Map<String, List<TravelPost>> _feedCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache settings
  static const Duration _cacheTTL = Duration(minutes: 30);
  static const String _feedCacheKey = 'feed_posts';
  static const String _trendingCacheKey = 'trending_posts';
  
  @override
  Future<List<TravelPost>> getFeedPosts({int page = 0, int limit = 20}) async {
    final cacheKey = '${_feedCacheKey}_${page}_$limit';
    
    // Check cache first
    if (_isCacheValid(cacheKey) && _feedCache.containsKey(cacheKey)) {
      return _feedCache[cacheKey]!;
    }
    
    try {
      final response = await _supabase
          .from('diary_entries')
          .select('''
            *, 
            profiles:user_id(username, full_name, avatar_url),
            diary_likes(count),
            post_reactions(count),
            diary_comments(count)
          ''')
          .eq('privacy_level', 'public')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);
      
      final posts = response.map<TravelPost>((data) {
        return TravelPostFromDatabase.fromDatabase(data);
      }).toList();
      
      // Cache the results
      _feedCache[cacheKey] = posts;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Also cache individual posts
      for (final post in posts) {
        _postCache[post.id] = post;
        _cacheTimestamps[post.id] = DateTime.now();
      }
      
      return posts;
    } catch (e) {
      print('Error fetching feed posts: $e');
      return [];
    }
  }
  
  @override
  Future<List<TravelPost>> getUserPosts(String userId, {int page = 0, int limit = 20}) async {
    final cacheKey = 'user_posts_${userId}_${page}_$limit';
    
    if (_isCacheValid(cacheKey) && _feedCache.containsKey(cacheKey)) {
      return _feedCache[cacheKey]!;
    }
    
    try {
      final response = await _supabase
          .from('diary_entries')
          .select('''
            *, 
            profiles:user_id(username, full_name, avatar_url),
            diary_likes(count),
            post_reactions(count),
            diary_comments(count)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);
      
      final posts = response.map<TravelPost>((data) {
        return TravelPostFromDatabase.fromDatabase(data);
      }).toList();
      
      _feedCache[cacheKey] = posts;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return posts;
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }
  
  @override
  Future<TravelPost?> getPostById(String postId) async {
    // Check cache first
    if (_isCacheValid(postId) && _postCache.containsKey(postId)) {
      return _postCache[postId];
    }
    
    try {
      final response = await _supabase
          .rpc('get_post_with_full_stats', params: {'post_id': postId});
      
      if (response.isEmpty) return null;
      
      final post = TravelPostFromDatabase.fromDatabase(response.first);
      
      // Cache the result
      _postCache[postId] = post;
      _cacheTimestamps[postId] = DateTime.now();
      
      return post;
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }
  
  @override
  Future<String> createPost(CreateTravelPostRequest request, List<String> photoFiles) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final postId = _uuid.v4();
      
      // Upload photos first
      List<String> photoUrls = [];
      if (photoFiles.isNotEmpty) {
        photoUrls = await uploadMultiplePhotos(photoFiles, postId);
      }
      
      // Fetch weather data if location details are available
      Map<String, dynamic>? weatherData;
      if (request.locationDetails?.latitude != null && 
          request.locationDetails?.longitude != null) {
        try {
          print('Fetching weather data for location: ${request.locationDetails?.name}');
          
          // Create an instance of the enhanced weather service
          final weatherService = EnhancedWeatherService();
          
          final weatherMap = await weatherService.getWeatherForTravelPost(
            request.locationDetails!.latitude!,
            request.locationDetails!.longitude!,
          );
          
          // Convert to WeatherData format expected by TravelPost
          weatherData = {
            'temperature': weatherMap['temperature'],
            'condition': weatherMap['condition'],
            'description': weatherMap['description'],
            'humidity': weatherMap['humidity'],
            'windSpeed': weatherMap['windSpeed'],
            'icon': weatherMap['icon'],
            'timestamp': weatherMap['timestamp'],
          };
          
          print('Weather data fetched successfully: ${weatherMap['temperature']}°C, ${weatherMap['condition']}');
        } catch (e) {
          print('Failed to fetch weather data: $e');
          // Continue without weather data - don't fail the post creation
          weatherData = null;
        }
      }
      
      // Create post data
      final postData = {
        'id': postId,
        'user_id': user.id,
        'title': request.title,
        'story': request.story,
        'mood': request.mood,
        'location': request.location,
        'location_details': request.locationDetails?.toJson(),
        'weather_data': weatherData, // Include the fetched weather data
        'tags': request.tags,
        'photos': photoUrls,
        'activities': request.activities,
        'travel_companions': request.travelCompanions,
        'budget_spent': request.budgetSpent,
        'currency_code': request.currencyCode,
        'rating': request.rating,
        'travel_tips': request.travelTips,
        'best_time_to_visit': request.bestTimeToVisit,
        'privacy_level': request.privacyLevel,
        'featured_photo_url': photoUrls.isNotEmpty ? photoUrls.first : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('diary_entries').insert(postData);
      
      // Add itinerary items if any
      if (request.itinerary.isNotEmpty) {
        final itineraryData = request.itinerary.map((item) => {
          'id': _uuid.v4(),
          'diary_entry_id': postId,
          'title': item.title,
          'description': item.description,
          'location': item.location,
          'start_time': item.startTime?.toIso8601String(),
          'end_time': item.endTime?.toIso8601String(),
          'cost': item.cost,
          'category': item.category,
          'rating': item.rating,
          'photos': item.photos,
          'tips': item.tips,
          'booking_url': item.bookingUrl,
          'order_index': item.orderIndex,
        }).toList();
        
        await _supabase.from('itinerary_items').insert(itineraryData);
      }
      
      // Add expenses if any
      if (request.expenses.isNotEmpty) {
        final expensesData = request.expenses.map((expense) => {
          'id': _uuid.v4(),
          'diary_entry_id': postId,
          'category': expense.category,
          'description': expense.description,
          'amount': expense.amount,
          'currency_code': expense.currencyCode,
          'date': expense.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'location': expense.location,
          'receipt_url': expense.receiptUrl,
        }).toList();
        
        await _supabase.from('travel_expenses').insert(expensesData);
      }
      
      // Clear cache to force refresh
      _clearFeedCache();
      
      return postId;
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }
  
  @override
  Future<bool> updatePost(TravelPost post) async {
    try {
      final updateData = post.toDatabase();
      
      await _supabase
          .from('diary_entries')
          .update(updateData)
          .eq('id', post.id);
      
      // Update cache
      _postCache[post.id] = post;
      _cacheTimestamps[post.id] = DateTime.now();
      _clearFeedCache();
      
      return true;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deletePost(String postId) async {
    try {
      // Delete from database (CASCADE will handle related data)
      await _supabase
          .from('diary_entries')
          .delete()
          .eq('id', postId);
      
      // Remove from cache
      _postCache.remove(postId);
      _cacheTimestamps.remove(postId);
      _clearFeedCache();
      
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }
  
  @override
  Future<String> uploadPhoto(String filePath, String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final file = File(filePath);
      final fileExt = path.extension(filePath);
      final fileName = '${user.id}/$postId/${_uuid.v4()}$fileExt';
      
      await _supabase.storage
          .from('travel-photos')
          .upload(fileName, file, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));
      
      final publicUrl = _supabase.storage
          .from('travel-photos')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }
  
  @override
  Future<List<String>> uploadMultiplePhotos(List<String> filePaths, String postId) async {
    final urls = <String>[];
    
    for (final filePath in filePaths) {
      try {
        final url = await uploadPhoto(filePath, postId);
        urls.add(url);
      } catch (e) {
        print('Failed to upload photo $filePath: $e');
        // Continue with other photos
      }
    }
    
    return urls;
  }
  
  @override
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      
      await _supabase.storage
          .from('travel-photos')
          .remove([fileName]);
      
      return true;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }
  
  @override
  Future<bool> likePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      await _supabase.from('diary_likes').insert({
        'id': _uuid.v4(),
        'user_id': user.id,
        'diary_entry_id': postId,
      });
      
      // Invalidate cache
      _postCache.remove(postId);
      
      return true;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }
  
  @override
  Future<bool> unlikePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      await _supabase.from('diary_likes')
          .delete()
          .eq('user_id', user.id)
          .eq('diary_entry_id', postId);
      
      // Invalidate cache
      _postCache.remove(postId);
      
      return true;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }
  
  @override
  Future<bool> addReaction(String postId, String reactionType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      await _supabase.from('post_reactions').upsert({
        'user_id': user.id,
        'diary_entry_id': postId,
        'reaction_type': reactionType,
      });
      
      // Invalidate cache
      _postCache.remove(postId);
      
      return true;
    } catch (e) {
      print('Error adding reaction: $e');
      return false;
    }
  }
  
  @override
  Future<bool> removeReaction(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      await _supabase.from('post_reactions')
          .delete()
          .eq('user_id', user.id)
          .eq('diary_entry_id', postId);
      
      // Invalidate cache
      _postCache.remove(postId);
      
      return true;
    } catch (e) {
      print('Error removing reaction: $e');
      return false;
    }
  }
  
  @override
  Future<bool> incrementViewCount(String postId) async {
    try {
      await _supabase.rpc('increment_post_view_count', params: {
        'post_id': postId,
      });
      
      return true;
    } catch (e) {
      print('Error incrementing view count: $e');
      return false;
    }
  }
  
  @override
  Future<List<TravelPost>> getTrendingPosts({int limit = 20}) async {
    if (_isCacheValid(_trendingCacheKey) && _feedCache.containsKey(_trendingCacheKey)) {
      return _feedCache[_trendingCacheKey]!;
    }
    
    try {
      final response = await _supabase.rpc('get_trending_posts', params: {
        'days_back': 7,
        'limit_count': limit,
      });
      
      final postIds = response.map<String>((item) => item['post_id'] as String).toList();
      
      // Fetch full post data
      final posts = <TravelPost>[];
      for (final postId in postIds) {
        final post = await getPostById(postId);
        if (post != null) posts.add(post);
      }
      
      _feedCache[_trendingCacheKey] = posts;
      _cacheTimestamps[_trendingCacheKey] = DateTime.now();
      
      return posts;
    } catch (e) {
      print('Error fetching trending posts: $e');
      return [];
    }
  }
  
  @override
  Future<List<TravelPost>> searchPosts(String query, {int page = 0, int limit = 20}) async {
    try {
      final response = await _supabase
          .from('diary_entries')
          .select('*')
          .or('title.ilike.%$query%,story.ilike.%$query%,location.ilike.%$query%')
          .eq('privacy_level', 'public')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);
      
      return response.map<TravelPost>((data) {
        return TravelPostFromDatabase.fromDatabase(data);
      }).toList();
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }
  
  @override
  Future<List<TravelPost>> getPostsByLocation(String location, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('diary_entries')
          .select('*')
          .ilike('location', '%$location%')
          .eq('privacy_level', 'public')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return response.map<TravelPost>((data) {
        return TravelPostFromDatabase.fromDatabase(data);
      }).toList();
    } catch (e) {
      print('Error fetching posts by location: $e');
      return [];
    }
  }
  
  @override
  Future<List<TravelPost>> getPostsByMood(String mood, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('diary_entries')
          .select('*')
          .eq('mood', mood)
          .eq('privacy_level', 'public')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return response.map<TravelPost>((data) {
        return TravelPostFromDatabase.fromDatabase(data);
      }).toList();
    } catch (e) {
      print('Error fetching posts by mood: $e');
      return [];
    }
  }
  
  @override
  Future<void> warmCache() async {
    try {
      // Preload trending posts and recent feed
      await getTrendingPosts();
      await getFeedPosts(limit: 10);
    } catch (e) {
      print('Cache warming failed: $e');
    }
  }
  
  @override
  void clearCache() {
    _postCache.clear();
    _feedCache.clear();
    _cacheTimestamps.clear();
  }
  
  // Private helper methods
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }
  
  void _clearFeedCache() {
    // Remove all feed-related cache entries
    final keysToRemove = _feedCache.keys.where((key) => 
        key.startsWith(_feedCacheKey) || 
        key.startsWith('user_posts_') ||
        key == _trendingCacheKey
    ).toList();
    
    for (final key in keysToRemove) {
      _feedCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
} 