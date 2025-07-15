import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../domain/models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

abstract class ProfileRepository {
  Future<UserProfile?> getCurrentUserProfile();
  Future<UserProfile?> getProfileById(String userId);
  Future<bool> updateProfile(UserProfile profile);
  Future<String?> uploadAvatar(String filePath);
  Future<void> warmCache();
  void clearCache();
}

class ProfileRepositoryImpl implements ProfileRepository {
  final _supabase = Supabase.instance.client;
  
  // Memory cache
  final Map<String, UserProfile> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache TTL
  static const Duration _cacheTTL = Duration(hours: 24);
  static const String _cachePrefix = 'user_profile_';
  
  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    return await getProfileById(user.id);
  }
  
  @override
  Future<UserProfile?> getProfileById(String userId) async {
    // 1. Check memory cache first
    if (_memoryCache.containsKey(userId) && _isCacheValid(userId)) {
      return _memoryCache[userId];
    }
    
    // 2. Check local storage cache
    final cachedProfile = await _getFromLocalCache(userId);
    if (cachedProfile != null) {
      _memoryCache[userId] = cachedProfile;
      _cacheTimestamps[userId] = DateTime.now();
      return cachedProfile;
    }
    
    // 3. Fetch from Supabase
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final profile = UserProfileFromDatabase.fromDatabase(response);
      
      // Cache the result
      await _saveToLocalCache(userId, profile);
      _memoryCache[userId] = profile;
      _cacheTimestamps[userId] = DateTime.now();
      
      return profile;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }
  
  @override
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      final updateData = profile.toDatabase();
      
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', profile.id);
      
      // Update caches
      _memoryCache[profile.id] = profile;
      _cacheTimestamps[profile.id] = DateTime.now();
      await _saveToLocalCache(profile.id, profile);
      
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  @override
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final file = File(filePath);
      final fileExt = path.extension(filePath);
      final fileName = '${user.id}/avatar$fileExt';
      
      await _supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ));
      
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      // Update profile with new avatar URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);
      
      // Clear cache to force refresh
      _memoryCache.remove(user.id);
      await _removeFromLocalCache(user.id);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
  
  @override
  Future<void> warmCache() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    // Preload current user profile
    await getCurrentUserProfile();
    
    // TODO: Preload other frequently accessed data
    // - Following list
    // - Recent interactions
    // - Popular locations
  }
  
  @override
  void clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _clearAllLocalCache();
  }
  
  // ============================================================================
  // PRIVATE CACHE METHODS
  // ============================================================================
  
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }
  
  Future<UserProfile?> _getFromLocalCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + userId;
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) return null;
      
      final cacheInfo = json.decode(cachedData);
      final timestamp = DateTime.parse(cacheInfo['timestamp']);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheTTL) {
        await prefs.remove(cacheKey);
        return null;
      }
      
      return UserProfile.fromJson(cacheInfo['data']);
    } catch (e) {
      print('Error reading from local cache: $e');
      return null;
    }
  }
  
  Future<void> _saveToLocalCache(String userId, UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + userId;
      
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': profile.toJson(),
      };
      
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Error saving to local cache: $e');
    }
  }
  
  Future<void> _removeFromLocalCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + userId;
      await prefs.remove(cacheKey);
    } catch (e) {
      print('Error removing from local cache: $e');
    }
  }
  
  Future<void> _clearAllLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing local cache: $e');
    }
  }
} 