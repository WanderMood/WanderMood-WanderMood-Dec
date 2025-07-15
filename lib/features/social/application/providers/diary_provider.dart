import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/social/domain/models/diary_entry.dart';
import 'package:wandermood/features/social/domain/models/user_profile.dart';
import 'package:wandermood/features/social/data/services/diary_service.dart';

// Diary service provider
final diaryServiceProvider = Provider<DiaryService>((ref) {
  return DiaryService();
});

// Diary feed provider (public entries from all users)
final diaryFeedProvider = FutureProvider.autoDispose<List<DiaryEntry>>((ref) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getDiaryFeed();
});

// Friends diary feed provider (entries from followed users)
final friendsDiaryFeedProvider = FutureProvider.autoDispose<List<DiaryEntry>>((ref) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getFriendsDiaryFeed();
});

// User diary entries provider
final userDiaryEntriesProvider = FutureProvider.family.autoDispose<List<DiaryEntry>, String?>((ref, userId) async {
  final diaryService = ref.read(diaryServiceProvider);
  if (userId == null) {
    throw Exception('User ID is required to fetch diary entries');
  }
  return await diaryService.getUserDiaryEntries(userId);
});

// Single diary entry provider
final diaryEntryProvider = FutureProvider.family.autoDispose<DiaryEntry, String>((ref, entryId) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getDiaryEntry(entryId);
});

// Diary comments provider
final diaryCommentsProvider = FutureProvider.family.autoDispose<List<DiaryComment>, String>((ref, entryId) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getComments(entryId);
});

// Create diary entry provider
final createDiaryEntryProvider = FutureProvider.family<DiaryEntry, CreateDiaryEntryRequest>((ref, request) async {
  final diaryService = ref.read(diaryServiceProvider);
  final newEntry = await diaryService.createDiaryEntry(request);
  
  // Invalidate relevant providers to refresh data
  ref.invalidate(diaryFeedProvider);
  ref.invalidate(friendsDiaryFeedProvider);
  ref.invalidate(userDiaryEntriesProvider);
  
  return newEntry;
});

// Toggle like provider
final toggleLikeProvider = FutureProvider.family<bool, String>((ref, entryId) async {
  final diaryService = ref.read(diaryServiceProvider);
  final result = await diaryService.toggleLike(entryId);
  
  // Invalidate providers to refresh like counts
  ref.invalidate(diaryFeedProvider);
  ref.invalidate(friendsDiaryFeedProvider);
  ref.invalidate(diaryEntryProvider(entryId));
  
  return result;
});

// Toggle save provider
final toggleSaveProvider = FutureProvider.family<bool, String>((ref, entryId) async {
  final diaryService = ref.read(diaryServiceProvider);
  final result = await diaryService.toggleSave(entryId);
  
  // Invalidate providers to refresh save status
  ref.invalidate(diaryFeedProvider);
  ref.invalidate(friendsDiaryFeedProvider);
  ref.invalidate(diaryEntryProvider(entryId));
  
  return result;
});

// Add comment provider
final addCommentProvider = FutureProvider.family<DiaryComment, ({String entryId, String comment})>((ref, params) async {
  final diaryService = ref.read(diaryServiceProvider);
  final newComment = await diaryService.addComment(params.entryId, params.comment);
  
  // Invalidate comments provider to refresh comments
  ref.invalidate(diaryCommentsProvider(params.entryId));
  ref.invalidate(diaryEntryProvider(params.entryId));
  
  return newComment;
});

// Fallback diary providers with demo data for when database isn't available
final friendsDiariesProvider = FutureProvider.autoDispose<List<DiaryEntry>>((ref) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getFriendsDiaries();
});

final discoverDiariesProvider = FutureProvider.autoDispose<List<DiaryEntry>>((ref) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getDiscoverDiaries();
});

// Removed currentUserProfileProvider - now using the one from profile_settings_providers.dart

// User profile provider for specific users
final userProfileProvider = FutureProvider.family.autoDispose<UserProfile?, String>((ref, userId) async {
  final diaryService = ref.read(diaryServiceProvider);
  return await diaryService.getUserProfile(userId);
}); 