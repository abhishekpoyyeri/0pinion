import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/community_invite_repository.dart';
import '../../core/providers/supabase_provider.dart';
import '../../data/models/community.dart';
import '../../data/models/community_post.dart';

/// All communities, ordered by member count
final communitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchCommunities();
});

/// Single community detail
final communityDetailProvider =
    FutureProvider.family<Community, String>((ref, id) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchCommunity(id);
});

/// Posts for a community
final communityPostsProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchPosts(communityId);
});

/// Members for a community
final communityMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchMembers(communityId);
});

/// Communities filtered by a zero tag
final communitiesByZeroProvider =
    FutureProvider.family<List<Community>, String>((ref, zeroId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchCommunitiesByZero(zeroId);
});

/// Search users for invite — keyed by (communityId, query)
final searchUsersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({String communityId, String query})>(
        (ref, params) async {
  if (params.query.trim().isEmpty) return [];

  final inviteRepo = ref.watch(communityInviteRepositoryProvider);
  final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

  final excludeIds = <String>[];
  if (currentUserId != null) excludeIds.add(currentUserId);

  return inviteRepo.searchUsers(
    query: params.query,
    communityId: params.communityId,
    excludeUserIds: excludeIds,
  );
});

/// Pending invites for current user
final pendingInvitesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final inviteRepo = ref.watch(communityInviteRepositoryProvider);
  return inviteRepo.fetchPendingInvites();
});
