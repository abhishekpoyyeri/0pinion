class CommunityInvite {
  final String id;
  final String communityId;
  final String inviterId;
  final String inviteeId;
  final String status;
  final DateTime createdAt;

  const CommunityInvite({
    required this.id,
    required this.communityId,
    required this.inviterId,
    required this.inviteeId,
    this.status = 'pending',
    required this.createdAt,
  });

  factory CommunityInvite.fromJson(Map<String, dynamic> json) {
    return CommunityInvite(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
