import 'package:opinion_app/core/widgets/video_refresh_indicator.dart';
import 'package:opinion_app/core/widgets/video_loader.dart';
import 'package:opinion_app/core/widgets/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/opinion_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/opinion_provider.dart';
import '../../../data/repositories/live_room_repository.dart';

/// Home screen — For You / Cooking / Latest tabs with opinion feed
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final opinionsAsync = ref.watch(feedOpinionsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140.0,
              collapsedHeight: 64.0,
              pinned: true,
              floating: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'For You'),
                        Tab(text: 'Cooking'),
                        Tab(text: 'Live'),
                      ],
                    ),
                    Divider(height: 1, color: borderColor),
                  ],
                ),
              ),
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double top = constraints.biggest.height;
                  final double statusBarHeight = MediaQuery.of(context).padding.top;
                  
                  // The collapsed height is toolbar + bottom + statusbar
                  final double minHeight = statusBarHeight + 64.0 + 48.0;
                  // The expanded height is expandedHeight + statusbar
                  final double maxHeight = statusBarHeight + 140.0;
                  
                  double expandRatio = (top - minHeight) / (maxHeight - minHeight);
                  expandRatio = expandRatio.clamp(0.0, 1.0);

                  return Container(
                    padding: EdgeInsets.only(
                      top: statusBarHeight,
                      bottom: 48.0 + 8.0, // Space for TabBar + a little bottom padding
                      left: 24.0 * (1.0 - expandRatio), // Safe left padding when collapsed
                    ),
                    child: Align(
                      alignment: Alignment.lerp(
                        Alignment.bottomLeft,
                        Alignment.bottomCenter,
                        expandRatio,
                      )!,
                      child: Image.asset(
                        'assets/title.png',
                        height: 28.0, // Reduced to prevent the zoomed-in look
                        fit: BoxFit.contain,
                        color: primaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            KeepAliveWrapper(child: _buildTab(opinionsAsync, (opinions) => opinions, 'for_you')),
            KeepAliveWrapper(child: _buildCookingTab()),
            KeepAliveWrapper(child: _buildLiveRoomsTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AsyncValue opinionsAsync, List Function(List) filter, String tabKey) {
    return opinionsAsync.when(
      skipLoadingOnRefresh: true,
      data: (opinions) => _buildFeed(filter(opinions as List), tabKey),
      loading: () => const Center(child: VideoLoader()),
      error: (err, stack) => VideoRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedOpinionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          key: PageStorageKey<String>('${tabKey}_error'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Connection lost or session expired',
                        style: AppTypography.bodySemiBold(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull down to refresh and reconnect',
                        style: AppTypography.caption(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingTab() {
    final cookingAsync = ref.watch(cookingOpinionsProvider);
    return cookingAsync.when(
      data: (opinions) => _buildFeed(opinions, 'cooking'),
      loading: () => const Center(child: VideoLoader()),
      error: (err, stack) => VideoRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedOpinionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          key: const PageStorageKey<String>('cooking_error'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  'Could not load cooking opinions',
                  style: AppTypography.body(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(List opinions, String tabKey) {
    if (opinions.isEmpty) {
      return VideoRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedOpinionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          key: PageStorageKey<String>('${tabKey}_empty'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No opinions yet',
                      style: AppTypography.body(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
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
        ref.invalidate(feedOpinionsProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.separated(
        key: PageStorageKey<String>('${tabKey}_data'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: opinions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final opinion = opinions[index];
          return OpinionCard(
            opinion: opinion,
            onTap: () => context.push('/opinion/${opinion.id}'),
          );
        },
      ),
    );
  }

  Widget _buildLiveRoomsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final roomsAsync = ref.watch(liveRoomsProvider);

    return roomsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: VideoLoader()),
      error: (err, _) => VideoRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveRoomsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          key: const PageStorageKey<String>('live_rooms_error'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text('Error loading rooms: $err',
                    style: AppTypography.caption(color: secondaryText)),
              ),
            ),
          ],
        ),
      ),
      data: (rooms) {
        if (rooms.isEmpty) {
          return VideoRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(liveRoomsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              key: const PageStorageKey<String>('live_rooms_empty'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: secondaryText),
                        const SizedBox(height: 16),
                        Text('No live rooms yet',
                            style: AppTypography.bodySemiBold(color: primaryText)),
                        const SizedBox(height: 8),
                        Text('Create one from the + tab!',
                            style: AppTypography.caption(color: secondaryText)),
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
            ref.invalidate(liveRoomsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            key: const PageStorageKey<String>('live_rooms_data'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomId = room['id'] as String;
              final title = room['title'] as String? ?? 'Untitled';
              final topic = room['topic'] as String? ?? '';
              final participantCount = room['participant_count'] as int? ?? 1;

              final profileData = room['profiles'];
              final hostUsername = profileData != null && profileData is Map
                  ? (profileData['username'] as String? ?? 'unknown')
                  : 'unknown';

              final status = room['status'] as String? ?? 'active';
              final isClosed = status == 'closed';
              final conclusion = room['conclusion'] as String?;
              
              String timeInfo = '';
              if (!isClosed) {
                final createdAtStr = room['created_at'] as String?;
                final durationMins = room['duration_minutes'] as int? ?? 10;
                if (createdAtStr != null) {
                  final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
                  final expiresAt = createdAt.add(Duration(minutes: durationMins));
                  final remaining = expiresAt.difference(DateTime.now());
                  if (remaining.isNegative) {
                    timeInfo = '0m left';
                  } else {
                    final mins = remaining.inMinutes;
                    timeInfo = '${mins}m left';
                  }
                }
              }

              return GestureDetector(
                onTap: () => context.push('/live/$roomId'),
                child: Opacity(
                  opacity: isClosed ? 0.6 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isClosed ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Text(
                                isClosed ? 'CLOSED' : 'LIVE',
                                style: AppTypography.label(
                                  color: isClosed ? AppColors.white : AppColors.black,
                                ),
                              ),
                            ),
                            if (!isClosed && timeInfo.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  timeInfo,
                                  style: AppTypography.label(color: secondaryText),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.bodySemiBold(
                                    color: primaryText),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        // Show conclusion for closed rooms, topic for active
                        if (isClosed && conclusion != null && conclusion.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.gavel, size: 14, color: secondaryText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  conclusion,
                                  style: AppTypography.caption(color: secondaryText),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else if (topic.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            topic,
                            style: AppTypography.caption(color: secondaryText),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Host and participants
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 16, color: secondaryText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Hosted by @$hostUsername',
                                style: AppTypography.caption(
                                    color: secondaryText),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.group_outlined,
                                size: 16, color: secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              '$participantCount participants',
                              style: AppTypography.caption(
                                  color: secondaryText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
