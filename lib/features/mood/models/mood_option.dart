import 'package:flutter/material.dart';

class MoodOption {
  final String id;
  final String label;
  final String emoji;
  final String colorHex;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MoodOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.colorHex,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create MoodOption from database JSON
  factory MoodOption.fromJson(Map<String, dynamic> json) {
    return MoodOption(
      id: json['id'] as String,
      label: json['label'] as String,
      emoji: json['emoji'] as String,
      colorHex: json['color_hex'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to database JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'emoji': emoji,
      'color_hex': colorHex,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get color from hex string
  Color get color {
    String hex = colorHex;
    // Remove # if present
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    
    // Add alpha if not present
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    
    return Color(int.parse(hex, radix: 16));
  }

  /// Create a copy with updated fields
  MoodOption copyWith({
    String? id,
    String? label,
    String? emoji,
    String? colorHex,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodOption(
      id: id ?? this.id,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 