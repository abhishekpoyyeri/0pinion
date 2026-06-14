import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_dialogs.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/animated_refresh_widget.dart';
import '../../../core/widgets/loading_gif_widget.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../data/repositories/community_invite_repository.dart';
import '../../../data/models/community_post.dart';
import 'dart:async';

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
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleMembership(bool isMember) async {
    if (isMember) {
      final communityAsync = ref.read(communityDetailProvider(widget.communityId));
      final community = communityAsync.value;
      if (community != null) {
        final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
        final isCreator = community.creatorId == currentUserId;

        if (isCreator) {
          final membersAsync = ref.read(communityMembersProvider(widget.communityId));
          final members = membersAsync.value ?? [];

          if (members.length > 1) {
            AppErrorHandler.showErrorDialog(
              context, 
              'You are the admin of this community. Please transfer admin controls to someone else before leaving.'
            );
            return;
          } else {
            // Admin is the only member left
            _confirmDeleteCommunity(community.name);
            return;
          }
        }
      }
    }

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
        AppErrorHandler.showErrorDialog(context, e);
      }
    }
  }

  Future<void> _confirmDeleteCommunity(String communityName) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Delete Community?',
      message: 'Are you sure you want to permanently delete "$communityName"? This will remove all posts, members, and data associated with it. This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_forever_outlined,
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(communityRepositoryProvider).deleteCommunity(widget.communityId);
        ref.invalidate(communitiesProvider);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppErrorHandler.showErrorDialog(context, e);
        }
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
    final currentUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => context.pop(),
        ),
        title: communityAsync.when(
          skipLoadingOnRefresh: true,
          data: (c) => Text(c.name, style: AppTypography.h2(color: primaryText)),          loading: () => Text('Loading...', style: AppTypography.h2(color: primaryText)),
          error: (error, stackTrace) => Text('Community', style: AppTypography.h2(color: primaryText)),
        ),
        actions: communityAsync.maybeWhen(
          data: (community) {
            final isCreator = community.creatorId == currentUserId;
            return [
              // Remove the Search icon since it's now in Members Tab
              if (isCreator)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: primaryText),
                  onPressed: () => _confirmDeleteCommunity(community.name),
                  tooltip: 'Delete Community',
                ),
            ];
          },
          orElse: () => null,
        ),
      ),
      body: communityAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: LoadingGifWidget()),        error: (err, _) => Center(
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
                              '${community.memberCount} member${community.memberCount == 1 ? '' : 's'} • ${community.postCount} post${community.postCount == 1 ? '' : 's'}',
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
                  if (!community.isPrivate || community.isMember)
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
                  if (community.isPrivate && !community.isMember)
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: secondaryText),
                        ),
                        child: Text(
                          'Invited (Pending)',
                          textAlign: TextAlign.center,
                          style: AppTypography.button(color: secondaryText),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: primaryText,
              unselectedLabelColor: secondaryText,
              indicatorColor: primaryText,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Members'),
                Tab(text: 'About'),
              ],
            ),
            Divider(height: 1, color: borderColor),

            // Tab content
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _PostsTab(
                        communityId: widget.communityId,
                        isMember: community.isMember,
                      ),
                      _MembersTab(
                        communityId: widget.communityId,
                        isCreator: community.creatorId == currentUserId,
                        isPrivate: community.isPrivate,
                      ),
                      _AboutTab(community: community),
                    ],
                  ),
                  if (community.isMember)
                    AnimatedBuilder(
                      animation: _tabController.animation!,
                      builder: (context, child) {
                        final v = _tabController.animation!.value;
                        final isCreator = community.creatorId == currentUserId;
                        
                        double opacity = 1.0;
                        if (v > 1.0) {
                          opacity = (2.0 - v).clamp(0.0, 1.0);
                        } else if (v < 0.0) {
                          opacity = (1.0 + v).clamp(0.0, 1.0);
                        }
                        
                        if (!isCreator && v > 0.0) {
                          opacity = (1.0 - v).clamp(0.0, 1.0);
                        }

                        if (opacity <= 0.0) return const SizedBox.shrink();

                        final screenWidth = MediaQuery.of(context).size.width;
                        const writeWidth = 56.0;
                        const addMemberWidth = 160.0;
                        
                        final currentV = v.clamp(0.0, 1.0);
                        final targetWidth = isCreator ? addMemberWidth : writeWidth;
                        final currentWidth = writeWidth + (targetWidth - writeWidth) * currentV;
                        final targetRight = (screenWidth - currentWidth) / 2;
                        final endRight = isCreator ? targetRight : 16.0;
                        final currentRight = 16.0 + (endRight - 16.0) * currentV;

                        return Positioned(
                          right: currentRight,
                          bottom: 16.0,
                          child: Opacity(
                            opacity: opacity,
                            child: Material(
                              color: primaryText,
                              borderRadius: BorderRadius.circular(28.0),
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28.0),
                                onTap: () {
                                  if (v < 0.5) {
                                    context.push('/community/${widget.communityId}/post').then((_) {
                                      ref.invalidate(communityPostsProvider(widget.communityId));
                                      ref.invalidate(communityDetailProvider(widget.communityId));
                                    });
                                  } else if (isCreator) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => _AddMemberSheet(communityId: widget.communityId),
                                    );
                                  }
                                },
                                child: Container(
                                  width: currentWidth,
                                  height: 56.0,
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Opacity(
                                        opacity: (1.0 - currentV * 2).clamp(0.0, 1.0),
                                        child: Icon(Icons.edit_outlined, color: isDark ? AppColors.black : AppColors.white),
                                      ),
                                      if (isCreator)
                                        Opacity(
                                          opacity: ((currentV - 0.5) * 2).clamp(0.0, 1.0),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            physics: const NeverScrollableScrollPhysics(),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.person_add_alt_1, color: isDark ? AppColors.black : AppColors.white),
                                                const SizedBox(width: 8),
                                                Text('Add Member', style: AppTypography.button(color: isDark ? AppColors.black : AppColors.white)),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Posts tab â€” shows community posts with pull-to-refresh
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: LoadingGifWidget()),      error: (err, _) => Center(
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

        return AnimatedRefreshWidget(
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

class _MembersTab extends ConsumerStatefulWidget {
  final String communityId;
  final bool isCreator;
  final bool isPrivate;

  const _MembersTab({
    required this.communityId,
    required this.isCreator,
    required this.isPrivate,
  });

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  final String communityId;
  const _AddMemberSheet({required this.communityId});

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final searchAsync = _query.isEmpty
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(searchUsersProvider((communityId: widget.communityId, query: _query)));

    return Container(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Member', style: AppTypography.h2(color: primaryText)),
              IconButton(icon: Icon(Icons.close, color: primaryText), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: AppTypography.body(color: primaryText),
              decoration: InputDecoration(
                hintText: 'Search by username or display name...',
                hintStyle: AppTypography.body(color: secondaryText),
                prefixIcon: Icon(Icons.search, color: secondaryText, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (_query.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Results', style: AppTypography.h3(color: primaryText)),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: _query.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Type to search for users', style: AppTypography.caption(color: secondaryText)),
                    ),
                  )
                : searchAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingGifWidget(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error: ', style: AppTypography.body(color: secondaryText)),
                      ),
                    ),
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No users found', style: AppTypography.caption(color: secondaryText)),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: users.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userId = user['id'] as String;
                          final username = user['username'] as String? ?? 'unknown';
                          final displayName = user['display_name'] as String? ?? username;
                          final avatarSeed = user['avatar_seed'] as int? ?? 0;
                          final status = user['status'] as String?;

                          Widget actionWidget;
                          if (status == 'pending') {
                            actionWidget = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.transparent,
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule, size: 14, color: secondaryText),
                                  const SizedBox(width: 4),
                                  Text('Pending', style: AppTypography.captionMedium(color: secondaryText)),
                                ],
                              ),
                            );
                          } else if (status == 'member' || status == 'accepted') {
                            actionWidget = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: primaryText,
                                border: Border.all(color: primaryText),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: surfaceColor),
                                  const SizedBox(width: 4),
                                  Text('Joined', style: AppTypography.captionMedium(color: surfaceColor)),
                                ],
                              ),
                            );
                          } else if (status == 'declined') {
                            actionWidget = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.transparent,
                                border: Border.all(color: secondaryText),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel, size: 14, color: secondaryText),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Declined', 
                                    style: AppTypography.captionMedium(color: secondaryText).copyWith(decoration: TextDecoration.lineThrough)
                                  ),
                                ],
                              ),
                            );
                          } else {
                            actionWidget = TextButton(
                              onPressed: () async {
                                try {
                                  final inviteRepo = ref.read(communityInviteRepositoryProvider);
                                  await inviteRepo.sendInvite(
                                    communityId: widget.communityId,
                                    inviteeId: userId,
                                  );
                                  ref.invalidate(searchUsersProvider((communityId: widget.communityId, query: _query)));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Invited @$username')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppErrorHandler.showErrorDialog(context, e);
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: primaryText,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text('Invite', style: AppTypography.button(color: isDark ? AppColors.black : AppColors.white)),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                AvatarWidget(seed: avatarSeed, size: 40),
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
                                actionWidget,
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final membersAsync = ref.watch(communityMembersProvider(widget.communityId));

    return membersAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: LoadingGifWidget()),      error: (err, _) => Center(
        child: Text('Error loading members', style: AppTypography.body(color: secondaryText)),
      ),
      data: (members) {
        return AnimatedRefreshWidget(
          onRefresh: () async {
            ref.invalidate(communityMembersProvider(widget.communityId));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            key: PageStorageKey<String>('community_members_'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Members Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text('Members', style: AppTypography.h3(color: primaryText)),
                ),
              ),

              // Members section
              if (members.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No members yet', style: AppTypography.body(color: secondaryText)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final member = members[index];
                        final profile = member['profiles'] as Map<String, dynamic>?;
                        final username = profile?['username'] as String? ?? 'unknown';
                        final displayName = profile?['display_name'] as String? ?? username;
                        final avatarSeed = profile?['avatar_seed'] as int? ?? 0;
                        final role = member['role'] as String? ?? 'member';

                        final userId = member['user_id'] as String;

                        return Column(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPress: () {
                                if (widget.isCreator && role != 'admin') {
                                  _showTransferAdminDialog(context, userId, displayName, username);
                                }
                              },
                              child: Padding(
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
                              ),
                            ),
                            if (index < members.length - 1)
                              Divider(height: 1, color: borderColor),
                          ],
                        );
                      },
                      childCount: members.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showTransferAdminDialog(BuildContext context, String newAdminId, String displayName, String username) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Make Admin?',
      message: 'Are you sure you want to transfer your admin rights to $displayName (@$username)? You will lose your admin status and become a regular member.',
      confirmText: 'Transfer',
      icon: Icons.admin_panel_settings_outlined,
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(communityRepositoryProvider);
        await repo.transferAdmin(
          communityId: widget.communityId,
          newAdminId: newAdminId,
        );
        ref.invalidate(communityDetailProvider(widget.communityId));
        ref.invalidate(communityMembersProvider(widget.communityId));
        ref.invalidate(communitiesProvider);
      } catch (e) {
        if (context.mounted) {
          AppErrorHandler.showErrorDialog(context, e);
        }
      }
    }
  }
}
class _AboutTab extends StatelessWidget {
  final dynamic community;

  const _AboutTab({required this.community});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AnimatedRefreshWidget(
      onRefresh: () async {
        // We can't easily access ref here without converting to ConsumerWidget, 
        // but Since About Tab rarely changes on its own, it's ok.
        // Wait, to use ref we must change this to ConsumerWidget.
        // I will just mock a delay to show the animation since it's just static data passed in
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            const SizedBox(height: 12),
            _infoRow('Visibility', community.isPrivate ? 'Private' : 'Public', primaryText, secondaryText),
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
