import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import '../models/community.dart';
import '../models/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(supabaseClientProvider));
});

class CommunityRepository {
  final SupabaseClient _supabase;

  CommunityRepository(this._supabase);

  /// Fetch all communities with their zero tags, ordered by member count
  Future<List<Community>> fetchCommunities() async {
    final userId = _supabase.auth.currentUser?.id;

    final res = await _supabase
        .from('communities')
        .select('*, community_zeroes(zeroes(name))')
        .order('member_count', ascending: false);

    // Check membership for current user
    Set<String> joinedIds = {};
    if (userId != null) {
      final memberships = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', userId);
      joinedIds = memberships
          .map((m) => m['community_id'] as String)
          .toSet();
    }

    return (res as List).map((json) {
      final id = json['id'] as String;
      return Community.fromJson(json, isMember: joinedIds.contains(id));
    }).toList();
  }

  /// Fetch a single community by ID
  Future<Community> fetchCommunity(String id) async {
    final userId = _supabase.auth.currentUser?.id;

    final res = await _supabase
        .from('communities')
        .select('*, community_zeroes(zeroes(name))')
        .eq('id', id)
        .single();

    bool isMember = false;
    if (userId != null) {
      final membership = await _supabase
          .from('community_members')
          .select('user_id')
          .eq('community_id', id)
          .eq('user_id', userId)
          .maybeSingle();
      isMember = membership != null;
    }

    return Community.fromJson(res, isMember: isMember);
  }

  /// Fetch posts for a community, newest first
  Future<List<CommunityPost>> fetchPosts(String communityId) async {
    final res = await _supabase
        .from('community_posts')
        .select('*, profiles(username, avatar_seed)')
        .eq('community_id', communityId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => CommunityPost.fromJson(json))
        .toList();
  }

  /// Fetch members for a community
  Future<List<Map<String, dynamic>>> fetchMembers(String communityId) async {
    final res = await _supabase
        .from('community_members')
        .select('*, profiles(username, avatar_seed, display_name)')
        .eq('community_id', communityId)
        .order('joined_at', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Create a new community with zero tags, adding the creator as admin
  Future<Community> createCommunity({
    required String name,
    required String description,
    required List<String> zeroIds,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // 1. Insert the community
    final communityRes = await _supabase
        .from('communities')
        .insert({
          'name': name,
          'description': description,
          'creator_id': userId,
        })
        .select()
        .single();

    final communityId = communityRes['id'] as String;

    // 2. Link zeroes
    if (zeroIds.isNotEmpty) {
      final links = zeroIds.map((zid) => {
        'community_id': communityId,
        'zero_id': zid,
      }).toList();
      await _supabase.from('community_zeroes').insert(links);
    }

    // 3. Add creator as admin member
    await _supabase.from('community_members').insert({
      'community_id': communityId,
      'user_id': userId,
      'role': 'admin',
    });

    return fetchCommunity(communityId);
  }

  /// Join a community
  Future<void> joinCommunity(String communityId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('community_members').insert({
      'community_id': communityId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Leave a community
  Future<void> leaveCommunity(String communityId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  /// Create a post in a community
  Future<void> createPost({
    required String communityId,
    required String content,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('community_posts').insert({
      'community_id': communityId,
      'author_id': userId,
      'content': content,
    });
  }

  /// Delete own post
  Future<void> deletePost(String postId) async {
    await _supabase.from('community_posts').delete().eq('id', postId);
  }

  /// Fetch communities filtered by a specific zero
  Future<List<Community>> fetchCommunitiesByZero(String zeroId) async {
    final userId = _supabase.auth.currentUser?.id;

    // Get community IDs linked to this zero
    final links = await _supabase
        .from('community_zeroes')
        .select('community_id')
        .eq('zero_id', zeroId);

    final communityIds = (links as List)
        .map((l) => l['community_id'] as String)
        .toList();

    if (communityIds.isEmpty) return [];

    final res = await _supabase
        .from('communities')
        .select('*, community_zeroes(zeroes(name))')
        .inFilter('id', communityIds)
        .order('member_count', ascending: false);

    Set<String> joinedIds = {};
    if (userId != null) {
      final memberships = await _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', userId);
      joinedIds = memberships
          .map((m) => m['community_id'] as String)
          .toSet();
    }

    return (res as List).map((json) {
      final id = json['id'] as String;
      return Community.fromJson(json, isMember: joinedIds.contains(id));
    }).toList();
  }

  /// Check if community name is available
  Future<bool> isNameAvailable(String name) async {
    final res = await _supabase
        .from('communities')
        .select('id')
        .ilike('name', name)
        .maybeSingle();
    return res == null;
  }
}
