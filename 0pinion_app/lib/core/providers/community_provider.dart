import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/community_repository.dart';
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
