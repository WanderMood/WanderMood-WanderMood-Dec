import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';

// Provider for mock data during development
final socialPostsProvider = Provider<List<SocialPost>>((ref) {
  // Return mock data
  return [
    SocialPost(
      id: '1',
      userId: 'user1',
      userName: 'Katarina',
      userAvatar: 'https://randomuser.me/api/portraits/women/44.jpg',
      location: 'Eindhoven',
      caption: 'Exploring Eindhoven by bike! 🚴',
      images: ['https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'],
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 24,
      comments: 5,
      activity: 'Biking',
      tags: ['cycling', 'nature', 'adventure'],
    ),
    SocialPost(
      id: '2',
      userId: 'user2',
      userName: 'Jonathan',
      userAvatar: 'https://randomuser.me/api/portraits/men/32.jpg',
      location: 'Cooking Class',
      caption: 'Pasta made from scratch 🍝✨',
      images: [
        'https://images.unsplash.com/photo-1556761223-4c4282c73f77?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1574694421127-3800bbd1079f?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
      ],
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 42,
      comments: 8,
      activity: 'Cooking',
      tags: ['cooking', 'food', 'culinary'],
    ),
    SocialPost(
      id: '3',
      userId: 'user3',
      userName: 'Emma',
      userAvatar: 'https://randomuser.me/api/portraits/women/22.jpg',
      location: 'Van Gogh Museum',
      caption: 'Spent the day immersed in art at the Van Gogh Museum. The colors and emotions in his work are truly breathtaking! ✨🎨',
      images: ['https://images.unsplash.com/photo-1590301157890-4810ed352733?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'],
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      likes: 67,
      comments: 12,
      activity: 'Museum Visit',
      tags: ['art', 'culture', 'museum'],
    ),
    SocialPost(
      id: '4',
      userId: 'user4',
      userName: 'Liam',
      userAvatar: 'https://randomuser.me/api/portraits/men/67.jpg',
      location: 'Rotterdam',
      caption: 'Architectural wonders of Rotterdam! 🏙️ The Cube Houses are out of this world!',
      images: ['https://images.unsplash.com/photo-1512237798647-84b57b3cbfe6?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'],
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      likes: 53,
      comments: 7,
      activity: 'Sightseeing',
      tags: ['architecture', 'city', 'travel'],
    ),
    SocialPost(
      id: '5',
      userId: 'user5',
      userName: 'Sophie',
      userAvatar: 'https://randomuser.me/api/portraits/women/54.jpg',
      location: 'Keukenhof Gardens',
      caption: 'The tulips are in full bloom at Keukenhof! 🌷 A perfect spring day!',
      images: ['https://images.unsplash.com/photo-1558980664-1db506751c6c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'],
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      likes: 89,
      comments: 15,
      activity: 'Nature',
      tags: ['flowers', 'garden', 'spring'],
    ),
  ];
});

// Provider for social profiles (mock data)
final socialProfilesProvider = Provider<List<SocialProfile>>((ref) {
  return [
    SocialProfile(
      id: 'user1',
      username: 'katarina_travels',
      fullName: 'Katarina',
      avatar: 'https://randomuser.me/api/portraits/women/44.jpg',
      bio: 'Adventure seeker | Photographer | Travel enthusiast',
      interests: ['hiking', 'photography', 'cycling'],
      followers: 324,
      following: 156,
      posts: 42,
    ),
    SocialProfile(
      id: 'user2',
      username: 'chef_jonathan',
      fullName: 'Jonathan',
      avatar: 'https://randomuser.me/api/portraits/men/32.jpg',
      bio: 'Passionate about food | Home chef | Sharing my culinary adventures',
      interests: ['cooking', 'food', 'restaurants'],
      followers: 587,
      following: 245,
      posts: 68,
    ),
    SocialProfile(
      id: 'user3',
      username: 'emma_arts',
      fullName: 'Emma',
      avatar: 'https://randomuser.me/api/portraits/women/22.jpg',
      bio: 'Art lover | Museum enthusiast | Finding beauty in everyday life',
      interests: ['art', 'museums', 'design'],
      followers: 412,
      following: 320,
      posts: 93,
    ),
    SocialProfile(
      id: 'user4',
      username: 'liam_architect',
      fullName: 'Liam',
      avatar: 'https://randomuser.me/api/portraits/men/67.jpg',
      bio: 'Architecture addict | Urban explorer | Photographer',
      interests: ['architecture', 'urban', 'design'],
      followers: 276,
      following: 184,
      posts: 37,
    ),
    SocialProfile(
      id: 'user5',
      username: 'sophie_nature',
      fullName: 'Sophie',
      avatar: 'https://randomuser.me/api/portraits/women/54.jpg',
      bio: 'Nature lover | Plant mom | Finding peace in green spaces',
      interests: ['nature', 'plants', 'gardening'],
      followers: 490,
      following: 213,
      posts: 56,
    ),
  ];
});

// Provider for comments on a specific post (mock data)
final postCommentsProvider = Provider.family<List<SocialComment>, String>((ref, postId) {
  // In a real app, you would fetch comments based on the postId
  return [
    SocialComment(
      id: 'comment1',
      userId: 'user2',
      userName: 'Jonathan',
      userAvatar: 'https://randomuser.me/api/portraits/men/32.jpg',
      text: 'This looks amazing! Which route did you take?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    SocialComment(
      id: 'comment2',
      userId: 'user3',
      userName: 'Emma',
      userAvatar: 'https://randomuser.me/api/portraits/women/22.jpg',
      text: 'Beautiful views! I need to try this route next weekend 😍',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    SocialComment(
      id: 'comment3',
      userId: 'user5',
      userName: 'Sophie',
      userAvatar: 'https://randomuser.me/api/portraits/women/54.jpg',
      text: 'Perfect weather for biking! Enjoy!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];
});

// Provider to get a specific social profile by ID
final profileByIdProvider = Provider.family<SocialProfile?, String>((ref, userId) {
  final profiles = ref.watch(socialProfilesProvider);
  try {
    return profiles.firstWhere((profile) => profile.id == userId);
  } catch (e) {
    return null;
  }
});

// Provider to filter posts by tag
final postsByTagProvider = Provider.family<List<SocialPost>, String>((ref, tag) {
  final allPosts = ref.watch(socialPostsProvider);
  return allPosts.where((post) => post.tags.contains(tag.toLowerCase())).toList();
});

// Provider for following feed
final followingFeedProvider = Provider<List<SocialPost>>((ref) {
  // In a real app, this would filter based on who the user follows
  return ref.watch(socialPostsProvider);
});

// Provider for discovery "For You" feed - could be based on user interests, etc.
final forYouFeedProvider = Provider<List<SocialPost>>((ref) {
  // In a real app, this would be personalized
  final allPosts = ref.watch(socialPostsProvider);
  return List.from(allPosts)..shuffle(); // Just shuffle for demo
}); 