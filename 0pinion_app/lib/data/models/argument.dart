enum ArgumentType { support, oppose, question }

class Argument {
  final String id;
  final String opinionId;
  final String authorId;
  final String authorUsername;
  final ArgumentType type;
  final String content;
  final bool isAnonymous;
  final DateTime createdAt;
  final List<Argument> replies;

  const Argument({
    required this.id,
    required this.opinionId,
    required this.authorId,
    required this.authorUsername,
    required this.type,
    required this.content,
    this.isAnonymous = false,
    required this.createdAt,
    this.replies = const [],
  });

  factory Argument.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final username = profile != null ? profile['username'] as String : 'Unknown';

    ArgumentType parseType(String type) {
      switch (type) {
        case 'support': return ArgumentType.support;
        case 'oppose': return ArgumentType.oppose;
        case 'question': return ArgumentType.question;
        default: return ArgumentType.question;
      }
    }

    return Argument(
      id: json['id'] as String,
      opinionId: json['opinion_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: username,
      type: parseType(json['type'] as String),
      content: json['content'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Argument copyWith({
    String? id,
    String? opinionId,
    String? authorId,
    String? authorUsername,
    ArgumentType? type,
    String? content,
    bool? isAnonymous,
    DateTime? createdAt,
    List<Argument>? replies,
  }) {
    return Argument(
      id: id ?? this.id,
      opinionId: opinionId ?? this.opinionId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      type: type ?? this.type,
      content: content ?? this.content,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }
}
