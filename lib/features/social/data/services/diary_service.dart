import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/social/domain/models/diary_entry.dart';
import 'package:wandermood/core/constants/supabase_constants.dart';
import 'dart:io';
import 'package:wandermood/features/social/domain/models/user_profile.dart';

class DiaryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Create a new diary entry
  Future<DiaryEntry> createDiaryEntry(CreateDiaryEntryRequest request) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create diary entries');
      }

      // Upload photos if any
      List<String> uploadedPhotoUrls = [];
      if (request.photos.isNotEmpty) {
        uploadedPhotoUrls = await _uploadPhotos(request.photos);
      }

      final response = await _supabase
          .from('diary_entries')
          .insert({
            'user_id': user.id,
            'title': request.title,
            'story': request.story,
            'mood': request.mood,
            'location': request.location,
            'tags': request.tags,
            'photos': uploadedPhotoUrls,
            'is_public': request.isPublic,
          })
          .select('''
            *,
            profiles!inner(full_name, image_url)
          ''')
          .single();

      return DiaryEntry.fromJson({
        ...response,
        'likes_count': 0,
        'comments_count': 0,
        'user_name': response['profiles']['full_name'],
        'user_avatar': response['profiles']['image_url'],
        'is_liked': false,
        'is_saved': false,
      });
    } catch (e) {
      print('Error creating diary entry: $e');
      rethrow;
    }
  }

  /// Upload photos to Supabase storage
  Future<List<String>> _uploadPhotos(List<String> photoPaths) async {
    List<String> uploadedUrls = [];
    
    for (String photoPath in photoPaths) {
      try {
        final file = File(photoPath);
        final fileName = 'diary_${DateTime.now().millisecondsSinceEpoch}_${photoPaths.indexOf(photoPath)}.jpg';
        
        await _supabase.storage
            .from('diary-photos')
            .upload(fileName, file);
        
        final url = _supabase.storage
            .from('diary-photos')
            .getPublicUrl(fileName);
        
        uploadedUrls.add(url);
      } catch (e) {
        print('Error uploading photo $photoPath: $e');
        // Continue with other photos even if one fails
      }
    }
    
    return uploadedUrls;
  }

  /// Get diary entries for the feed (public entries from all users)
  Future<List<DiaryEntry>> getDiaryFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to view diary feed');
      }
      
      final response = await _supabase
          .from('diary_entries')
          .select('''
            *,
            profiles!inner(full_name, image_url),
            diary_likes!left(user_id),
            saved_diary_entries!left(user_id)
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<DiaryEntry>((entry) {
        // Count likes and check if current user liked
        final likes = entry['diary_likes'] as List? ?? [];
        final saves = entry['saved_diary_entries'] as List? ?? [];
        
        final isLiked = likes.any((like) => like['user_id'] == user.id);
        final isSaved = saves.any((save) => save['user_id'] == user.id);

        return DiaryEntry.fromJson({
          ...entry,
          'likes_count': likes.length,
          'comments_count': 0, // Will be populated separately if needed
          'user_name': entry['profiles']['full_name'],
          'user_avatar': entry['profiles']['image_url'],
          'is_liked': isLiked,
          'is_saved': isSaved,
        });
      }).toList();
    } catch (e) {
      print('Error loading diary feed: $e');
      rethrow;
    }
  }

  /// Get diary entries from followed users (friends feed)
  Future<List<DiaryEntry>> getFriendsDiaryFeed({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to view friends diary feed');
      }

      final followedUserIds = await _getFollowedUserIds(user.id);
      
      // If no followed users, return empty list
      if (followedUserIds.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('diary_entries')
          .select('''
            *,
            profiles!inner(full_name, image_url),
            diary_likes!left(user_id),
            saved_diary_entries!left(user_id)
          ''')
          .inFilter('user_id', followedUserIds)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<DiaryEntry>((entry) {
        final likes = entry['diary_likes'] as List? ?? [];
        final saves = entry['saved_diary_entries'] as List? ?? [];
        
        final isLiked = likes.any((like) => like['user_id'] == user.id);
        final isSaved = saves.any((save) => save['user_id'] == user.id);

        return DiaryEntry.fromJson({
          ...entry,
          'likes_count': likes.length,
          'comments_count': 0,
          'user_name': entry['profiles']['full_name'],
          'user_avatar': entry['profiles']['image_url'],
          'is_liked': isLiked,
          'is_saved': isSaved,
        });
      }).toList();
    } catch (e) {
      print('Error loading friends diary feed: $e');
      rethrow;
    }
  }

  /// Get diary entries for a specific user
  Future<List<DiaryEntry>> getUserDiaryEntries(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to view diary entries');
      }

      final response = await _supabase
          .from('diary_entries')
          .select('''
            *,
            profiles!inner(full_name, image_url),
            diary_likes!left(user_id),
            saved_diary_entries!left(user_id)
          ''')
          .eq('user_id', userId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return response.map<DiaryEntry>((entry) {
        final likes = entry['diary_likes'] as List? ?? [];
        final saves = entry['saved_diary_entries'] as List? ?? [];
        
        final isLiked = likes.any((like) => like['user_id'] == user.id);
        final isSaved = saves.any((save) => save['user_id'] == user.id);

        return DiaryEntry.fromJson({
          ...entry,
          'likes_count': likes.length,
          'comments_count': 0,
          'user_name': entry['profiles']['full_name'],
          'user_avatar': entry['profiles']['image_url'],
          'is_liked': isLiked,
          'is_saved': isSaved,
        });
      }).toList();
    } catch (e) {
      print('Error loading user diary entries: $e');
      rethrow;
    }
  }

  /// Get a single diary entry by ID
  Future<DiaryEntry> getDiaryEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to view diary entries');
      }

      final response = await _supabase
          .from('diary_entries')
          .select('''
            *,
            profiles!inner(full_name, image_url),
            diary_likes!left(user_id),
            saved_diary_entries!left(user_id)
          ''')
          .eq('id', entryId)
          .eq('is_public', true)
          .single();

      final likes = response['diary_likes'] as List? ?? [];
      final saves = response['saved_diary_entries'] as List? ?? [];
      
      final isLiked = likes.any((like) => like['user_id'] == user.id);
      final isSaved = saves.any((save) => save['user_id'] == user.id);

      return DiaryEntry.fromJson({
        ...response,
        'likes_count': likes.length,
        'comments_count': 0, // Will be populated separately if needed
        'user_name': response['profiles']['full_name'],
        'user_avatar': response['profiles']['image_url'],
        'is_liked': isLiked,
        'is_saved': isSaved,
      });
    } catch (e) {
      print('Error loading diary entry: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to view profiles');
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error loading user profile: $e');
      rethrow;
    }
  }

  /// Get followed user IDs
  Future<List<String>> _getFollowedUserIds(String userId) async {
    try {
    final response = await _supabase
        .from('user_follows')
          .select('followed_user_id')
          .eq('follower_user_id', userId);

      return response.map<String>((row) => row['followed_user_id'] as String).toList();
    } catch (e) {
      print('Error loading followed users: $e');
      return [];
    }
  }

  /// Like a diary entry
  Future<void> likeDiaryEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to like entries');
      }

      await _supabase.from('diary_likes').insert({
        'user_id': user.id,
        'diary_entry_id': entryId,
      });
    } catch (e) {
      print('Error liking diary entry: $e');
      rethrow;
    }
  }

  /// Unlike a diary entry
  Future<void> unlikeDiaryEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to unlike entries');
      }

      await _supabase
          .from('diary_likes')
          .delete()
          .eq('user_id', user.id)
          .eq('diary_entry_id', entryId);
    } catch (e) {
      print('Error unliking diary entry: $e');
      rethrow;
    }
  }

  /// Save a diary entry
  Future<void> saveDiaryEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to save entries');
      }

      await _supabase.from('saved_diary_entries').insert({
        'user_id': user.id,
        'diary_entry_id': entryId,
      });
    } catch (e) {
      print('Error saving diary entry: $e');
      rethrow;
    }
  }

  /// Unsave a diary entry
  Future<void> unsaveDiaryEntry(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to unsave entries');
      }

      await _supabase
          .from('saved_diary_entries')
          .delete()
          .eq('user_id', user.id)
          .eq('diary_entry_id', entryId);
    } catch (e) {
      print('Error unsaving diary entry: $e');
      rethrow;
    }
  }

  /// Toggle like status for a diary entry
  Future<bool> toggleLike(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to like entries');
      }

      // Check if already liked
      final existingLike = await _supabase
          .from('diary_likes')
          .select()
          .eq('user_id', user.id)
          .eq('diary_entry_id', entryId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await unlikeDiaryEntry(entryId);
        return false;
      } else {
        // Like
        await likeDiaryEntry(entryId);
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Toggle save status for a diary entry
  Future<bool> toggleSave(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to save entries');
      }

      // Check if already saved
      final existingSave = await _supabase
          .from('saved_diary_entries')
          .select()
          .eq('user_id', user.id)
          .eq('diary_entry_id', entryId)
          .maybeSingle();

      if (existingSave != null) {
        // Unsave
        await unsaveDiaryEntry(entryId);
        return false;
      } else {
        // Save
        await saveDiaryEntry(entryId);
        return true;
      }
    } catch (e) {
      print('Error toggling save: $e');
      rethrow;
    }
  }

  /// Get comments for a diary entry
  Future<List<DiaryComment>> getComments(String entryId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to view comments');
      }

      final response = await _supabase
          .from('diary_comments')
          .select('''
            *,
            profiles!inner(full_name, image_url)
          ''')
          .eq('diary_entry_id', entryId)
          .order('created_at', ascending: true);

      return response.map<DiaryComment>((comment) {
        return DiaryComment.fromJson({
          ...comment,
          'user_name': comment['profiles']['full_name'],
          'user_avatar': comment['profiles']['image_url'],
        });
      }).toList();
    } catch (e) {
      print('Error loading comments: $e');
      rethrow;
    }
  }

  /// Add a comment to a diary entry
  Future<DiaryComment> addComment(String entryId, String comment) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to add comments');
      }
      
      final response = await _supabase
          .from('diary_comments')
          .insert({
            'diary_entry_id': entryId,
            'user_id': user.id,
            'comment': comment,
          })
          .select('''
            *,
            profiles!inner(full_name, image_url)
          ''')
          .single();

      return DiaryComment.fromJson({
        ...response,
        'user_name': response['profiles']['full_name'],
        'user_avatar': response['profiles']['image_url'],
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Get friends' diaries (fallback method)
  Future<List<DiaryEntry>> getFriendsDiaries() async {
    // This is a fallback that just returns the friends feed
    return await getFriendsDiaryFeed();
  }

  /// Get discover diaries (fallback method)
  Future<List<DiaryEntry>> getDiscoverDiaries() async {
    // This is a fallback that just returns the public feed
    return await getDiaryFeed();
  }
}

 