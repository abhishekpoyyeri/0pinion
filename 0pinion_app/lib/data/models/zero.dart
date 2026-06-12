class Zero {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final int opinionsCount;
  final int membersCount;
  final bool isJoined;

  const Zero({
    required this.id,
    required this.name,
    required this.displayName,
    this.description = '',
    this.opinionsCount = 0,
    this.membersCount = 0,
    this.isJoined = false,
  });

  Zero copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    int? opinionsCount,
    int? membersCount,
    bool? isJoined,
  }) {
    return Zero(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      opinionsCount: opinionsCount ?? this.opinionsCount,
      membersCount: membersCount ?? this.membersCount,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
