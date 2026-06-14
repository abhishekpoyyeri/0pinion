class Community {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final int avatarSeed;
  final int memberCount;
  final int postCount;
  final List<String> zeroes;
  final bool isPrivate;
  final bool isMember;
  final DateTime createdAt;

  const Community({
    required this.id,
    required this.name,
    this.description = '',
    required this.creatorId,
    this.avatarSeed = 0,
    this.memberCount = 1,
    this.postCount = 0,
    this.zeroes = const [],
    this.isPrivate = false,
    this.isMember = false,
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json, {bool isMember = false}) {
    // Parse zeroes from the joined community_zeroes â†’ zeroes relation
    List<String> zeroNames = [];
    if (json['community_zeroes'] != null) {
      final czList = json['community_zeroes'] as List;
      for (final cz in czList) {
        if (cz['zeroes'] != null && cz['zeroes']['name'] != null) {
          zeroNames.add(cz['zeroes']['name'] as String);
        }
      }
    }

    final rawMemberCount = json['member_count'] as int? ?? 1;
    final displayMemberCount = rawMemberCount > 1 ? rawMemberCount - 1 : 0;

    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      creatorId: json['creator_id'] as String,
      avatarSeed: json['avatar_seed'] as int? ?? 0,
      memberCount: displayMemberCount,
      postCount: json['post_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      zeroes: zeroNames,
      isMember: isMember,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    int? avatarSeed,
    int? memberCount,
    int? postCount,
    bool? isPrivate,
    List<String>? zeroes,
    bool? isMember,
    DateTime? createdAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      isPrivate: isPrivate ?? this.isPrivate,
      zeroes: zeroes ?? this.zeroes,
      isMember: isMember ?? this.isMember,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
