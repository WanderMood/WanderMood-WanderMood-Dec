class AIChatMessage {
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  AIChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
} 