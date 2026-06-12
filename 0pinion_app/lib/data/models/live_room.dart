class LiveRoom {
  final String id;
  final String title;
  final String hostId;
  final String hostUsername;
  final int participantsCount;
  final bool isActive;
  final DateTime createdAt;

  const LiveRoom({
    required this.id,
    required this.title,
    required this.hostId,
    required this.hostUsername,
    this.participantsCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  LiveRoom copyWith({
    String? id,
    String? title,
    String? hostId,
    String? hostUsername,
    int? participantsCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      hostId: hostId ?? this.hostId,
      hostUsername: hostUsername ?? this.hostUsername,
      participantsCount: participantsCount ?? this.participantsCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.timestamp,
  });
}
