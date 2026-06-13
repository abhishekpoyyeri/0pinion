import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/widgets/video_refresh_indicator.dart';
import '../../../core/widgets/video_loader.dart';
import '../widgets/community_card.dart';

/// Main community browser — replaces the "Coming Soon" placeholder
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  String _searchQuery = '';

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
            icon: Icon(Icons.add, color: primaryText),
            onPressed: () => context.push('/community/create'),
          ),
        ],
      ),
      body: Column(
        children: [
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
              loading: () => const Center(child: VideoLoader()),
              error: (err, _) => VideoRefreshIndicator(
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
                // Filter by search query
                final filtered = _searchQuery.isEmpty
                    ? communities
                    : communities.where((c) =>
                        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        c.zeroes.any((z) => z.toLowerCase().contains(_searchQuery.toLowerCase()))
                      ).toList();

                if (filtered.isEmpty) {
                  return VideoRefreshIndicator(
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
                                    onTap: () => context.push('/community/create'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: primaryText,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Create Community',
                                        style: AppTypography.button(
                                          color: isDark ? AppColors.black : AppColors.white,
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

                return VideoRefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communitiesProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final community = filtered[index];
                      return CommunityCard(
                        community: community,
                        onTap: () => context.push('/community/${community.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
