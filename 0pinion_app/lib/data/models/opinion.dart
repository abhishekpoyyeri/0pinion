import 'dart:math';

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
    required this.createdAt,
  });

  int get totalDebates => supportCount + opposeCount + questionCount;

  /// Weighted engagement: support=1, oppose=1, question=2
  int get weightedEngagement =>
      (supportCount * 1) + (opposeCount * 1) + (questionCount * 2);

  /// Time-decay cooking score.
  /// Higher = more cooking. Decays aggressively with age.
  /// Formula: weightedEngagement / (ageHours + 2)^1.5
  double get cookingScore {
    if (weightedEngagement == 0) return 0.0;
    final ageHours =
        DateTime.now().difference(createdAt).inMinutes / 60.0;
    return weightedEngagement / pow(ageHours + 2, 1.5);
  }

  /// A post is "cooking" if it has meaningful engagement (>= 3 weighted points)
  bool get isCooking => weightedEngagement >= 3 && cookingScore > 0;

  factory Opinion.fromJson(Map<String, dynamic> json) {
    return Opinion(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String? ?? 'anonymous',
      authorUsername: json['profiles']?['username'] as String? ?? 'Anonymous',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      zeroes: json['zeroes'] != null ? [json['zeroes']['name'] as String] : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      supportCount: (json['arguments'] as List?)?.where((a) => a['type'] == 'support').length ?? 0,
      opposeCount: (json['arguments'] as List?)?.where((a) => a['type'] == 'oppose').length ?? 0,
      questionCount: (json['arguments'] as List?)?.where((a) => a['type'] == 'question').length ?? 0,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
