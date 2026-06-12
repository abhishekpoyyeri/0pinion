class Opinion {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorUsername;
  final bool isAnonymous;
  final List<String> zeroes;
  final int supportCount;
  final int opposeCount;
  final int questionCount;
  final bool isCooking;
  final DateTime createdAt;

  const Opinion({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorUsername,
    this.isAnonymous = false,
    this.zeroes = const [],
    this.supportCount = 0,
    this.opposeCount = 0,
    this.questionCount = 0,
    this.isCooking = false,
    required this.createdAt,
  });

  int get totalDebates => supportCount + opposeCount + questionCount;

  factory Opinion.fromJson(Map<String, dynamic> json) {
    return Opinion(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String? ?? 'anonymous',
      authorUsername: json['profiles']?['username'] as String? ?? 'Anonymous',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      zeroes: json['zeroes'] != null ? [json['zeroes']['name'] as String] : [],
      isCooking: json['is_cooking'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      // We'll calculate counts if they come from a joined query, or default to 0
      supportCount: 0,
      opposeCount: 0,
      questionCount: 0,
    );
  }

  Opinion copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorUsername,
    bool? isAnonymous,
    List<String>? zeroes,
    int? supportCount,
    int? opposeCount,
    int? questionCount,
    bool? isCooking,
    DateTime? createdAt,
  }) {
    return Opinion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      zeroes: zeroes ?? this.zeroes,
      supportCount: supportCount ?? this.supportCount,
      opposeCount: opposeCount ?? this.opposeCount,
      questionCount: questionCount ?? this.questionCount,
      isCooking: isCooking ?? this.isCooking,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
