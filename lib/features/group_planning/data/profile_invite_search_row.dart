/// Public profile row for in-app Mood Match username search.
class ProfileInviteSearchRow {
  const ProfileInviteSearchRow({
    required this.id,
    this.username,
    this.fullName,
    this.imageUrl,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? imageUrl;

  String get displayLabel {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return '@$u';
    final f = fullName?.trim();
    if (f != null && f.isNotEmpty) return f;
    return 'Traveler';
  }
}
