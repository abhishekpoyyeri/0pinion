class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final int avatarSeed;
  final int reputationScore;
  final int opinionsCount;
  final int debatesJoined;
  final List<String> joinedZeroes;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarSeed,
    this.reputationScore = 0,
    this.opinionsCount = 0,
    this.debatesJoined = 0,
    this.joinedZeroes = const [],
  });

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    int? avatarSeed,
    int? reputationScore,
    int? opinionsCount,
    int? debatesJoined,
    List<String>? joinedZeroes,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      reputationScore: reputationScore ?? this.reputationScore,
      opinionsCount: opinionsCount ?? this.opinionsCount,
      debatesJoined: debatesJoined ?? this.debatesJoined,
      joinedZeroes: joinedZeroes ?? this.joinedZeroes,
    );
  }
}
