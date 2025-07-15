class UserProfile {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? imageUrl;
  final String? bio;
  final String? location;
  final int totalDiaries;
  final int totalFollowers;
  final int totalFollowing;
  final DateTime joinedAt;
  final String travelStyle;
  final Map<String, int> moodBreakdown;
  
  // New WanderFeed fields
  final String? travelBio;
  final String? currentlyExploring;
  final List<String> travelVibes;
  final Map<String, dynamic> privacySettings;
  final Map<String, int> travelDna;
  final Map<String, dynamic> moodOfMonth;

  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.imageUrl,
    this.bio,
    this.location,
    required this.totalDiaries,
    required this.totalFollowers,
    required this.totalFollowing,
    required this.joinedAt,
    this.travelStyle = 'adventurous',
    this.moodBreakdown = const {},
    this.travelBio,
    this.currentlyExploring,
    this.travelVibes = const [],
    this.privacySettings = const {},
    this.travelDna = const {},
    this.moodOfMonth = const {},
  });

  // Computed properties for backward compatibility
  String? get avatarUrl => imageUrl;
  DateTime get createdAt => joinedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['full_name'] as String? ?? json['email'] as String? ?? 'User',
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String? ?? json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      totalDiaries: json['total_diaries'] as int? ?? 0,
      totalFollowers: json['total_followers'] as int? ?? 0,
      totalFollowing: json['total_following'] as int? ?? 0,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      travelStyle: json['travel_style'] as String? ?? 'adventurous',
      moodBreakdown: json['mood_breakdown'] != null
          ? Map<String, int>.from(json['mood_breakdown'])
          : {},
      // New WanderFeed fields
      travelBio: json['travel_bio'] as String?,
      currentlyExploring: json['currently_exploring'] as String?,
      travelVibes: json['travel_vibes'] != null
          ? List<String>.from(json['travel_vibes'] as List)
          : [],
      privacySettings: json['privacy_settings'] != null
          ? Map<String, dynamic>.from(json['privacy_settings'])
          : {},
      travelDna: json['travel_dna'] != null
          ? Map<String, int>.from(json['travel_dna'])
          : {},
      moodOfMonth: json['mood_of_month'] != null
          ? Map<String, dynamic>.from(json['mood_of_month'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'image_url': imageUrl,
      'bio': bio,
      'location': location,
      'total_diaries': totalDiaries,
      'total_followers': totalFollowers,
      'total_following': totalFollowing,
      'joined_at': joinedAt.toIso8601String(),
      'travel_style': travelStyle,
      'mood_breakdown': moodBreakdown,
      // New WanderFeed fields
      'travel_bio': travelBio,
      'currently_exploring': currentlyExploring,
      'travel_vibes': travelVibes,
      'privacy_settings': privacySettings,
      'travel_dna': travelDna,
      'mood_of_month': moodOfMonth,
    };
  }

  // Helper methods for WanderFeed features
  String get displayTravelBio => travelBio ?? bio ?? 'Ready to explore the world! ✈️';
  
  String get displayCurrentlyExploring => currentlyExploring ?? 'Somewhere amazing';
  
  List<String> get displayTravelVibes => travelVibes.isEmpty 
      ? ['Adventurous', 'Cultural', 'Peaceful'] 
      : travelVibes;

  Map<String, int> get displayTravelDna => travelDna.isEmpty
      ? {'adventure': 75, 'culture': 60, 'relaxation': 85}
      : travelDna;

  Map<String, dynamic> get displayMoodOfMonth => moodOfMonth.isEmpty
      ? {
          'mood': 'Peaceful',
          'month': 'December',
          'description': 'Mostly Peaceful this December'
        }
      : moodOfMonth;

  bool get isProfilePublic => privacySettings['profile_visibility'] != 'private';
  bool get areStoriesPublic => privacySettings['story_visibility'] != 'private';
  bool get isLocationSharingEnabled => privacySettings['location_sharing'] == true;

  UserProfile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? imageUrl,
    String? bio,
    String? location,
    int? totalDiaries,
    int? totalFollowers,
    int? totalFollowing,
    DateTime? joinedAt,
    String? travelStyle,
    Map<String, int>? moodBreakdown,
    String? travelBio,
    String? currentlyExploring,
    List<String>? travelVibes,
    Map<String, dynamic>? privacySettings,
    Map<String, int>? travelDna,
    Map<String, dynamic>? moodOfMonth,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      totalDiaries: totalDiaries ?? this.totalDiaries,
      totalFollowers: totalFollowers ?? this.totalFollowers,
      totalFollowing: totalFollowing ?? this.totalFollowing,
      joinedAt: joinedAt ?? this.joinedAt,
      travelStyle: travelStyle ?? this.travelStyle,
      moodBreakdown: moodBreakdown ?? this.moodBreakdown,
      travelBio: travelBio ?? this.travelBio,
      currentlyExploring: currentlyExploring ?? this.currentlyExploring,
      travelVibes: travelVibes ?? this.travelVibes,
      privacySettings: privacySettings ?? this.privacySettings,
      travelDna: travelDna ?? this.travelDna,
      moodOfMonth: moodOfMonth ?? this.moodOfMonth,
    );
  }
} 