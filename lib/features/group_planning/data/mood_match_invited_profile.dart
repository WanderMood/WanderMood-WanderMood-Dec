/// Minimal profile info for someone the current user invited to a Mood Match
/// session. Stored locally by the inviter so the lobby can show who we're
/// waiting on before they've actually joined.
class MoodMatchInvitedProfile {
  const MoodMatchInvitedProfile({
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

  String get firstName {
    final f = fullName?.trim();
    if (f != null && f.isNotEmpty) {
      final first = f.split(RegExp(r'\s+')).firstOrNull;
      if (first != null && first.isNotEmpty) return first;
    }
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return 'Traveler';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  factory MoodMatchInvitedProfile.fromJson(Map<String, dynamic> json) {
    return MoodMatchInvitedProfile(
      id: (json['id'] ?? '').toString(),
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
