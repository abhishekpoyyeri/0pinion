import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/widgets/animated_refresh_widget.dart';
import '../../../core/widgets/loading_gif_widget.dart';
import '../../../data/models/community.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../data/repositories/community_invite_repository.dart';
import '../widgets/community_card.dart';

/// Main community browser with Public/Private tabs
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // rebuild to update "+" button behavior
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isPrivateTab => _tabController.index == 1;

  void _onCreatePressed() {
    if (_isPrivateTab) {
      context.push('/community/create?private=true');
    } else {
      context.push('/community/create?private=false');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final communitiesAsync = ref.watch(communitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Communities', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.mail_outline, color: primaryText),
            tooltip: 'Pending Invites',
            onPressed: () => _showInvitesSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.add, color: primaryText),
            tooltip: _isPrivateTab ? 'Create Private Community' : 'Create Public Community',
            onPressed: _onCreatePressed,
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primaryText,
            unselectedLabelColor: secondaryText,
            indicatorColor: primaryText,
            tabs: const [
              Tab(text: 'Public'),
              Tab(text: 'Private'),
            ],
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: AppTypography.body(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'Search communities...',
                  hintStyle: AppTypography.body(color: secondaryText),
                  prefixIcon: Icon(Icons.search, color: secondaryText, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Community list
          Expanded(
            child: communitiesAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: LoadingGifWidget()),
              error: (err, _) => AnimatedRefreshWidget(                onRefresh: () async {
                  ref.invalidate(communitiesProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              'Could not load communities',
                              style: AppTypography.bodySemiBold(color: primaryText),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pull down to retry',
                              style: AppTypography.caption(color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (communities) {
                final filtered = _searchQuery.isEmpty
                    ? communities
                    : communities.where((c) =>
                        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        c.zeroes.any((z) => z.toLowerCase().contains(_searchQuery.toLowerCase()))
                      ).toList();

                final publicCommunities = filtered.where((c) => !c.isPrivate).toList();
                final privateCommunities = filtered.where((c) => c.isPrivate).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Public Tab
                    _buildCommunityList(publicCommunities, context, primaryText, secondaryText),
                    // Private Tab
                    _buildCommunityList(privateCommunities, context, primaryText, secondaryText),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityList(List<Community> communitiesList, BuildContext context, Color primaryText, Color secondaryText) {
    if (communitiesList.isEmpty) {
      return AnimatedRefreshWidget(
        onRefresh: () async {
          ref.invalidate(communitiesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_outlined, size: 48, color: secondaryText),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No communities yet'
                          : 'No results for "$_searchQuery"',
                      style: AppTypography.bodySemiBold(color: primaryText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Be the first to create one!'
                          : 'Try a different search term',
                      style: AppTypography.caption(color: secondaryText),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _onCreatePressed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: primaryText,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Create Community',
                            style: AppTypography.button(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.black : AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedRefreshWidget(
      onRefresh: () async {
        ref.invalidate(communitiesProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: communitiesList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final community = communitiesList[index];
          return CommunityCard(
            community: community,
            onTap: () => context.push('/community/${community.id}'),
          );
        },
      ),
    );
  }

  void _showInvitesSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final inviteRepo = ref.read(communityInviteRepositoryProvider);
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: inviteRepo.fetchPendingInvites(),
              builder: (sheetContext, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('Error loading invites', style: AppTypography.body(color: secondaryText)),
                    ),
                  );
                }

                final invites = snapshot.data ?? [];

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Pending Invites', style: AppTypography.h3(color: primaryText)),
                        const SizedBox(height: 16),
                        if (invites.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('No pending invites', style: AppTypography.body(color: secondaryText)),
                            ),
                          )
                        else
                          Flexible(
                            child: AnimatedRefreshWidget(
                              onRefresh: () async {
                                ref.invalidate(pendingInvitesProvider);
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: invites.length,
                                separatorBuilder: (sheetContext, index) => Divider(color: borderColor),
                                itemBuilder: (sheetContext, index) {
                                  final invite = invites[index];
                                  final community = invite['communities'] as Map<String, dynamic>?;
                                  final inviter = invite['profiles'] as Map<String, dynamic>?;

                                  final communityName = community?['name'] as String? ?? 'Unknown Community';
                                  final inviterName = inviter?['username'] as String? ?? 'someone';
                                  final inviteId = invite['id'] as String;
                                  final communityId = invite['community_id'] as String;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(communityName, style: AppTypography.bodyMedium(color: primaryText)),
                                              Text('Invited by @$inviterName', style: AppTypography.caption(color: secondaryText)),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            try {
                                              final repo = ref.read(communityRepositoryProvider);
                                              await repo.acceptInvite(inviteId, communityId);
                                              ref.invalidate(communitiesProvider);
                                              ref.invalidate(pendingInvitesProvider);
                                              ref.invalidate(communityMembersProvider(communityId));
                                              setSheetState(() {}); // refresh the bottom sheet
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Joined $communityName!')),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error: $e')),
                                                );
                                              }
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: primaryText,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: Text(
                                            'Accept',
                                            style: AppTypography.button(color: isDark ? AppColors.black : AppColors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
