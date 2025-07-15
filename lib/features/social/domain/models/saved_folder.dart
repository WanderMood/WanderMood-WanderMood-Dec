class SavedFolder {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemCount; // Number of saved entries in this folder

  const SavedFolder({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount = 0,
  });

  factory SavedFolder.fromJson(Map<String, dynamic> json) {
    return SavedFolder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      icon: json['icon'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SavedFolder copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
  }) {
    return SavedFolder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }
} 