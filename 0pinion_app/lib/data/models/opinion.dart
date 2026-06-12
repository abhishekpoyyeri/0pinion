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
