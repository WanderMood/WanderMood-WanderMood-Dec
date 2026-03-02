/// Combined profile + preferences for the current user profile screen.
/// Single source of truth so the UI doesn't fetch from two tables.
class CurrentUserProfile {
  const CurrentUserProfile({
    required this.userId,
    this.fullName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.ageGroup,
    this.homeBase,
    this.selectedMoods = const [],
    this.budgetLevel,
    this.socialVibe,
    this.dietaryRestrictions = const [],
    this.activityPace,
    this.timeAvailable,
    this.interests,
  });

  final String userId;
  final String? fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? ageGroup;
  final String? homeBase;
  final List<String> selectedMoods;
  final String? budgetLevel;
  final String? socialVibe;
  final List<String> dietaryRestrictions;
  final String? activityPace;
  final String? timeAvailable;
  final dynamic interests;

  bool get isLocalMode => homeBase == null || homeBase == 'Local Explorer';

  CurrentUserProfile copyWith({
    String? userId,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? ageGroup,
    String? homeBase,
    List<String>? selectedMoods,
    String? budgetLevel,
    String? socialVibe,
    List<String>? dietaryRestrictions,
    String? activityPace,
    String? timeAvailable,
    dynamic interests,
  }) {
    return CurrentUserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ageGroup: ageGroup ?? this.ageGroup,
      homeBase: homeBase ?? this.homeBase,
      selectedMoods: selectedMoods ?? this.selectedMoods,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      socialVibe: socialVibe ?? this.socialVibe,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      activityPace: activityPace ?? this.activityPace,
      timeAvailable: timeAvailable ?? this.timeAvailable,
      interests: interests ?? this.interests,
    );
  }
}
