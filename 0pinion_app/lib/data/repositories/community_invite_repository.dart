import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';

final communityInviteRepositoryProvider = Provider<CommunityInviteRepository>((ref) {
  return CommunityInviteRepository(ref.watch(supabaseClientProvider));
});

class CommunityInviteRepository {
  final SupabaseClient _supabase;

  CommunityInviteRepository(this._supabase);

  /// Send an invite to a user
  Future<void> sendInvite({required String communityId, required String inviteeId}) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('community_invites').insert({
      'community_id': communityId,
      'inviter_id': userId,
      'invitee_id': inviteeId,
      'status': 'pending',
    });
  }

  /// Accept an invite
  Future<void> acceptInvite(String inviteId, String communityId) async {
    final userId = _supabase.auth.currentUser!.id;
    // Update invite status
    await _supabase.from('community_invites').update({'status': 'accepted'}).eq('id', inviteId);
    // Add member
    await _supabase.from('community_members').insert({
      'community_id': communityId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Fetch pending invites for current user
  Future<List<Map<String, dynamic>>> fetchPendingInvites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _supabase
        .from('community_invites')
        .select('*, communities(*), profiles!community_invites_inviter_id_fkey(username, display_name)')
        .eq('invitee_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Search users by username or display_name, excluding certain user IDs, and attach their invite status
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required String communityId,
    required List<String> excludeUserIds,
  }) async {
    if (query.trim().isEmpty) return [];

    final cleanQuery = query.trim().replaceAll('@', '');

    final res = await _supabase
        .from('profiles')
        .select('id, username, display_name, avatar_seed')
        .or('username.ilike.%$cleanQuery%,display_name.ilike.%$cleanQuery%')
        .limit(20);

    final results = List<Map<String, dynamic>>.from(res);

    // Exclude specified user IDs client-side
    if (excludeUserIds.isNotEmpty) {
      results.removeWhere((user) => excludeUserIds.contains(user['id'] as String));
    }

    if (results.isEmpty) return results;

    final profileIds = results.map((u) => u['id'] as String).toList();

    // Fetch member status
    final membersRes = await _supabase
        .from('community_members')
        .select('user_id')
        .eq('community_id', communityId)
        .inFilter('user_id', profileIds);
    final memberIds = (membersRes as List).map((m) => m['user_id'] as String).toSet();

    // Fetch invite status
    final invitesRes = await _supabase
        .from('community_invites')
        .select('invitee_id, status')
        .eq('community_id', communityId)
        .inFilter('invitee_id', profileIds);
    
    final inviteStatusMap = <String, String>{};
    for (var invite in invitesRes as List) {
      // Latest status wins if there are multiple, but there's a unique constraint anyway
      inviteStatusMap[invite['invitee_id'] as String] = invite['status'] as String;
    }

    for (var user in results) {
      final uid = user['id'] as String;
      if (memberIds.contains(uid)) {
        user['status'] = 'member';
      } else if (inviteStatusMap.containsKey(uid)) {
        user['status'] = inviteStatusMap[uid]; // pending, accepted, declined
      } else {
        user['status'] = null; // No invite
      }
    }

    return results;
  }

  /// Get IDs of existing members of a community
  Future<Set<String>> getCommunityMemberIds(String communityId) async {
    final res = await _supabase
        .from('community_members')
        .select('user_id')
        .eq('community_id', communityId);
    return (res as List).map((m) => m['user_id'] as String).toSet();
  }

  /// Get IDs of users with pending invites for a community
  Future<Set<String>> getPendingInviteeIds(String communityId) async {
    final res = await _supabase
        .from('community_invites')
        .select('invitee_id')
        .eq('community_id', communityId)
        .eq('status', 'pending');
    return (res as List).map((m) => m['invitee_id'] as String).toSet();
  }
}
