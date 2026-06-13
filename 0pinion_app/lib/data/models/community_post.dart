class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String authorUsername;
  final int authorAvatarSeed;
  final String content;
  final int likesCount;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarSeed = 0,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: json['profiles']?['username'] as String? ?? 'unknown',
      authorAvatarSeed: json['profiles']?['avatar_seed'] as int? ?? 0,
      content: json['content'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
