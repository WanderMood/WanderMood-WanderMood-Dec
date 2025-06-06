class SocialPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String location;
  final String caption;
  final List<String> images;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final String activity;
  final List<String> tags;
  
  SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.location,
    required this.caption,
    required this.images,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.activity,
    this.tags = const [],
  });
  
  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      location: json['location'] as String,
      caption: json['caption'] as String,
      images: List<String>.from(json['images'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
      likes: json['likes'] as int,
      comments: json['comments'] as int,
      activity: json['activity'] as String,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'location': location,
      'caption': caption,
      'images': images,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'activity': activity,
      'tags': tags,
    };
  }
}

class SocialComment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime timestamp;
  
  SocialComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
  });
  
  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SocialProfile {
  final String id;
  final String username;
  final String fullName;
  final String avatar;
  final String bio;
  final List<String> interests;
  final int followers;
  final int following;
  final int posts;
  
  SocialProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
    required this.bio,
    required this.interests,
    required this.followers,
    required this.following,
    required this.posts,
  });
  
  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      avatar: json['avatar'] as String,
      bio: json['bio'] as String,
      interests: List<String>.from(json['interests'] as List),
      followers: json['followers'] as int,
      following: json['following'] as int,
      posts: json['posts'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
      'bio': bio,
      'interests': interests,
      'followers': followers,
      'following': following,
      'posts': posts,
    };
  }
} 