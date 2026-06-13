import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/video_refresh_indicator.dart';
import '../../../core/widgets/video_loader.dart';
import '../../../core/providers/community_provider.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../data/models/community_post.dart';

/// Community detail page with Posts, Members, and About tabs
class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleMembership(bool isMember) async {
    final repo = ref.read(communityRepositoryProvider);
    try {
      if (isMember) {
        await repo.leaveCommunity(widget.communityId);
      } else {
        await repo.joinCommunity(widget.communityId);
      }
      ref.invalidate(communityDetailProvider(widget.communityId));
      ref.invalidate(communityMembersProvider(widget.communityId));
      ref.invalidate(communitiesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final communityAsync = ref.watch(communityDetailProvider(widget.communityId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => context.pop(),
        ),
        title: communityAsync.when(
          data: (c) => Text(c.name, style: AppTypography.h2(color: primaryText)),
          loading: () => Text('Loading...', style: AppTypography.h2(color: primaryText)),
          error: (error, stackTrace) => Text('Community', style: AppTypography.h2(color: primaryText)),
        ),
      ),
      body: communityAsync.when(
        loading: () => const Center(child: VideoLoader()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: secondaryText),
              const SizedBox(height: 16),
              Text('Failed to load community', style: AppTypography.bodySemiBold(color: primaryText)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => ref.invalidate(communityDetailProvider(widget.communityId)),
                child: Text('Tap to retry', style: AppTypography.caption(color: secondaryText)),
              ),
            ],
          ),
        ),
        data: (community) => Column(
          children: [
            // Community header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      AvatarWidget(seed: community.avatarSeed, size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(community.name, style: AppTypography.h3(color: primaryText)),
                            const SizedBox(height: 4),
                            Text(
                              '${community.memberCount} members • ${community.postCount} posts',
                              style: AppTypography.caption(color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (community.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        community.description,
                        style: AppTypography.body(color: secondaryText),
                      ),
                    ),
                  ],
                  if (community.zeroes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: community.zeroes.map((zero) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(zero, style: AppTypography.label(color: secondaryText)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Join/Leave button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => _toggleMembership(community.isMember),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: community.isMember ? Colors.transparent : primaryText,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryText,
                            width: community.isMember ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          community.isMember ? 'Leave Community' : 'Join Community',
                          textAlign: TextAlign.center,
                          style: AppTypography.button(
                            color: community.isMember
                                ? primaryText
                                : (isDark ? AppColors.black : AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Members'),
                Tab(text: 'About'),
              ],
            ),
            Divider(height: 1, color: borderColor),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PostsTab(
                    communityId: widget.communityId,
                    isMember: community.isMember,
                  ),
                  _MembersTab(communityId: widget.communityId),
                  _AboutTab(community: community),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: communityAsync.value?.isMember == true
          ? FloatingActionButton(
              onPressed: () async {
                await context.push('/community/${widget.communityId}/post');
                ref.invalidate(communityPostsProvider(widget.communityId));
                ref.invalidate(communityDetailProvider(widget.communityId));
              },
              backgroundColor: primaryText,
              child: Icon(
                Icons.edit_outlined,
                color: isDark ? AppColors.black : AppColors.white,
              ),
            )
          : null,
    );
  }
}

/// Posts tab — shows community posts with pull-to-refresh
class _PostsTab extends ConsumerWidget {
  final String communityId;
  final bool isMember;

  const _PostsTab({required this.communityId, required this.isMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;


    final postsAsync = ref.watch(communityPostsProvider(communityId));

    return postsAsync.when(
      loading: () => const Center(child: VideoLoader()),
      error: (err, _) => Center(
        child: Text('Error loading posts', style: AppTypography.body(color: secondaryText)),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 48, color: secondaryText),
                const SizedBox(height: 16),
                Text('No posts yet', style: AppTypography.bodySemiBold(color: primaryText)),
                const SizedBox(height: 8),
                Text(
                  isMember ? 'Be the first to post!' : 'Join to start the conversation',
                  style: AppTypography.caption(color: secondaryText),
                ),
              ],
            ),
          );
        }

        return VideoRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityPostsProvider(communityId));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            key: PageStorageKey<String>('community_posts_$communityId'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 1),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _PostCard(post: post);
            },
          ),
        );
      },
    );
  }
}

/// Individual post card
class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              AvatarWidget(seed: post.authorAvatarSeed, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '@${post.authorUsername}',
                  style: AppTypography.captionMedium(color: primaryText),
                ),
              ),
              Text(
                _timeAgo(post.createdAt),
                style: AppTypography.caption(color: secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content
          Text(
            post.content,
            style: AppTypography.body(color: primaryText),
          ),
        ],
      ),
    );
  }
}

/// Members tab
class _MembersTab extends ConsumerWidget {
  final String communityId;

  const _MembersTab({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final membersAsync = ref.watch(communityMembersProvider(communityId));

    return membersAsync.when(
      loading: () => const Center(child: VideoLoader()),
      error: (err, _) => Center(
        child: Text('Error loading members', style: AppTypography.body(color: secondaryText)),
      ),
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Text('No members yet', style: AppTypography.body(color: secondaryText)),
          );
        }

        return ListView.separated(
          key: PageStorageKey<String>('community_members_$communityId'),
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
          itemBuilder: (context, index) {
            final member = members[index];
            final profile = member['profiles'] as Map<String, dynamic>?;
            final username = profile?['username'] as String? ?? 'unknown';
            final displayName = profile?['display_name'] as String? ?? username;
            final avatarSeed = profile?['avatar_seed'] as int? ?? 0;
            final role = member['role'] as String? ?? 'member';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  AvatarWidget(seed: avatarSeed, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: AppTypography.bodyMedium(color: primaryText)),
                        Text('@$username', style: AppTypography.caption(color: secondaryText)),
                      ],
                    ),
                  ),
                  if (role != 'member')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: role == 'admin' ? primaryText : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryText),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: AppTypography.label(
                          color: role == 'admin'
                              ? (isDark ? AppColors.black : AppColors.white)
                              : primaryText,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// About tab
class _AboutTab extends StatelessWidget {
  final dynamic community;

  const _AboutTab({required this.community});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: AppTypography.h3(color: primaryText)),
          const SizedBox(height: 12),
          Text(
            community.description.isNotEmpty ? community.description : 'No description provided.',
            style: AppTypography.body(color: secondaryText),
          ),
          const SizedBox(height: 24),
          Divider(color: borderColor),
          const SizedBox(height: 16),
          _infoRow('Members', '${community.memberCount}', primaryText, secondaryText),
          const SizedBox(height: 12),
          _infoRow('Posts', '${community.postCount}', primaryText, secondaryText),
          const SizedBox(height: 12),
          _infoRow(
            'Created',
            '${community.createdAt.day}/${community.createdAt.month}/${community.createdAt.year}',
            primaryText,
            secondaryText,
          ),
          if (community.zeroes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            Text('Tagged Zeroes', style: AppTypography.bodySemiBold(color: primaryText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (community.zeroes as List<String>).map((zero) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(zero, style: AppTypography.captionMedium(color: primaryText)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color primaryText, Color secondaryText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(color: secondaryText)),
        Text(value, style: AppTypography.bodySemiBold(color: primaryText)),
      ],
    );
  }
}
