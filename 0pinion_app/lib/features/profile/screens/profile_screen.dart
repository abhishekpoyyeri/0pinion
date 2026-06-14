import 'package:opinion_app/core/widgets/animated_refresh_widget.dart';
import 'package:opinion_app/core/widgets/loading_gif_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/opinion_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';

/// Profile screen â€” avatar, reputation, stats, opinions/arguments/zeroes tabs
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileDetailsProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final profile = profileAsync.value;
    final stats = statsAsync.value ?? {'opinions': 0, 'arguments': 0, 'zeroes': 0, 'reputation': 0};

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: primaryText),
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.signOut();
              if (context.mounted) context.go('/splash');
            },
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text('Not logged in', style: AppTypography.body(color: primaryText)))
          : Column(
              children: [
                // Profile header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AvatarWidget(
                        seed: profile?['avatar_seed'] as int? ?? user.id.hashCode,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (profileAsync.isLoading && profile == null)
                            ? 'Loading...'
                            : profile?['display_name'] as String? ?? user.email ?? 'Unknown User',
                        style: AppTypography.h3(color: primaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (profileAsync.isLoading && profile == null)
                            ? '@...'
                            : profile?['username'] != null 
                                ? '@${profile!['username']}' 
                                : '@user_${user.id.substring(0, 4)}',
                        style: AppTypography.body(color: secondaryText),
                      ),
                      const SizedBox(height: 20),

                      // Reputation
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          'Reputation: ${stats['reputation'] ?? 0}',
                          style: AppTypography.bodySemiBold(color: primaryText),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(value: '${stats['opinions'] ?? 0}', label: 'Opinions'),
                          Container(width: 1, height: 32, color: borderColor),
                          _StatItem(value: '${stats['arguments'] ?? 0}', label: 'Debates'),
                          Container(width: 1, height: 32, color: borderColor),
                          _StatItem(value: '${stats['zeroes'] ?? 0}', label: 'Zeroes'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Opinions'),
                    Tab(text: 'Arguments'),
                    Tab(text: 'Zeroes'),
                  ],
                ),
                Divider(height: 1, color: borderColor),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOpinionsTab(primaryText, secondaryText, borderColor, user.id),
                      _buildArgumentsTab(primaryText, secondaryText, borderColor),
                      _buildZeroesTab(primaryText, secondaryText, borderColor),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOpinionsTab(Color primaryText, Color secondaryText, Color borderColor, String userId) {
    final opinionsAsync = ref.watch(feedOpinionsProvider);
    
    return opinionsAsync.when(
      data: (opinions) {
        final userOpinions = opinions.where((o) => o.authorId == userId).toList();
        if (userOpinions.isEmpty) {
          return AnimatedRefreshWidget(
            onRefresh: () async {
              ref.invalidate(feedOpinionsProvider);
              ref.invalidate(profileStatsProvider);
              ref.invalidate(userProfileDetailsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 200,
                  child: Center(child: Text('No opinions yet', style: AppTypography.body(color: secondaryText))),
                )
              ],
            ),
          );
        }
        return AnimatedRefreshWidget(
          onRefresh: () async {
            ref.invalidate(feedOpinionsProvider);
            ref.invalidate(profileStatsProvider);
            ref.invalidate(userProfileDetailsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: userOpinions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final op = userOpinions[index];
              return InkWell(
                onTap: () => context.push('/opinion/${op.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(op.title, style: AppTypography.bodyMedium(color: primaryText)),
                      const SizedBox(height: 8),
                      Text(
                        '${op.totalDebates} debates',
                        style: AppTypography.caption(color: secondaryText),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingGifWidget()),
      error: (e, _) => AnimatedRefreshWidget(
        onRefresh: () async {
          ref.invalidate(feedOpinionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_outlined, size: 32, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Connection lost', style: AppTypography.bodyMedium(color: primaryText)),
                    Text('Pull to refresh', style: AppTypography.caption(color: secondaryText)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArgumentsTab(Color primaryText, Color secondaryText, Color borderColor) {
    final argumentsAsync = ref.watch(userArgumentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return argumentsAsync.when(
      data: (arguments) {
        if (arguments.isEmpty) {
          return AnimatedRefreshWidget(
            onRefresh: () async {
              ref.invalidate(userArgumentsProvider);
              ref.invalidate(profileStatsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Your arguments will appear here',
                      style: AppTypography.body(color: secondaryText),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AnimatedRefreshWidget(
          onRefresh: () async {
            ref.invalidate(userArgumentsProvider);
            ref.invalidate(profileStatsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: arguments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final arg = arguments[index];
              final type = arg['type'] as String? ?? 'question';
              final content = arg['content'] as String? ?? '';
              final opinionId = arg['opinion_id'] as String? ?? '';
              final opinionTitle = arg['opinions']?['title'] as String? ?? 'Opinion';

              final isSupport = type == 'support';
              final isOppose = type == 'oppose';
              final badgeBg = isSupport ? primaryText : Colors.transparent;
              final badgeTextColor = isSupport 
                  ? (isDark ? AppColors.black : AppColors.white)
                  : primaryText;
              final badgeBorder = isSupport 
                  ? Border.all(color: primaryText)
                  : (isOppose 
                      ? Border.all(color: primaryText, width: 1.5)
                      : Border.all(color: borderColor));

              return InkWell(
                onTap: () {
                  if (opinionId.isNotEmpty) {
                    context.push('/opinion/$opinionId');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                              border: badgeBorder,
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: AppTypography.label(color: badgeTextColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'on "$opinionTitle"',
                              style: AppTypography.caption(color: secondaryText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: AppTypography.bodyMedium(color: primaryText),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingGifWidget()),
      error: (e, _) => AnimatedRefreshWidget(
        onRefresh: () async {
          ref.invalidate(userArgumentsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_outlined, size: 32, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Connection lost', style: AppTypography.bodyMedium(color: primaryText)),
                    Text('Pull to refresh', style: AppTypography.caption(color: secondaryText)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroesTab(Color primaryText, Color secondaryText, Color borderColor) {
    final zeroesAsync = ref.watch(userZeroesProvider);

    return zeroesAsync.when(
      data: (zeroes) {
        if (zeroes.isEmpty) {
          return AnimatedRefreshWidget(
            onRefresh: () async {
              ref.invalidate(userZeroesProvider);
              ref.invalidate(profileStatsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Your zeroes will appear here',
                      style: AppTypography.body(color: secondaryText),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AnimatedRefreshWidget(
          onRefresh: () async {
            ref.invalidate(userZeroesProvider);
            ref.invalidate(profileStatsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: zeroes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final zero = zeroes[index];
              final name = zero['name'] as String? ?? '';
              final description = zero['description'] as String? ?? '';
              final opinionsCount = zero['opinions_count'] as int? ?? 0;

              return InkWell(
                onTap: () {
                  context.push('/zeroes');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: AppTypography.bodySemiBold(color: primaryText),
                          ),
                          Text(
                            '$opinionsCount opinions',
                            style: AppTypography.caption(color: secondaryText),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: AppTypography.caption(color: secondaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingGifWidget()),
      error: (e, _) => AnimatedRefreshWidget(
        onRefresh: () async {
          ref.invalidate(userZeroesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_outlined, size: 32, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Connection lost', style: AppTypography.bodyMedium(color: primaryText)),
                    Text('Pull to refresh', style: AppTypography.caption(color: secondaryText)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h3(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}
