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
