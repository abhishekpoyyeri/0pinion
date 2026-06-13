import 'package:opinion_app/core/widgets/video_refresh_indicator.dart';
import 'package:opinion_app/core/widgets/video_loader.dart';
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
            _buildTab(opinionsAsync, (opinions) => opinions),
            _buildTab(opinionsAsync, (opinions) => opinions.where((o) => o.isCooking).toList()),
            _buildLiveRoomsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AsyncValue opinionsAsync, List Function(List) filter) {
    return opinionsAsync.when(
      data: (opinions) => _buildFeed(filter(opinions as List)),
      loading: () => const Center(child: VideoLoader()),
      error: (err, stack) => VideoRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedOpinionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
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

  Widget _buildFeed(List opinions) {
    if (opinions.isEmpty) {
      return VideoRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedOpinionsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
      loading: () => const Center(child: VideoLoader()),
      error: (err, _) => Center(
        child: Text('Error loading rooms: $err',
            style: AppTypography.caption(color: secondaryText)),
      ),
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(liveRoomsProvider);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomId = room['id'] as String;
              final title = room['title'] as String? ?? 'Untitled';
              final topic = room['topic'] as String? ?? '';
              final status = room['status'] as String? ?? 'active';
              final conclusion = room['conclusion'] as String?;
              final durationMinutes = room['duration_minutes'] as int? ?? 10;
              final createdAt = DateTime.tryParse(room['created_at'] as String? ?? '');
              final isClosed = status == 'closed';

              final profileData = room['profiles'];
              final hostUsername = profileData != null && profileData is Map
                  ? (profileData['username'] as String? ?? 'unknown')
                  : 'unknown';

              // Calculate remaining time
              String timeInfo = '';
              if (!isClosed && createdAt != null) {
                final endTime = createdAt.add(Duration(minutes: durationMinutes));
                final remaining = endTime.difference(DateTime.now());
                if (remaining.isNegative) {
                  timeInfo = 'Expired';
                } else {
                  final mins = remaining.inMinutes;
                  timeInfo = '${mins}m left';
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
                                color: isClosed ? Colors.redAccent : Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isClosed ? 'CLOSED' : 'LIVE',
                                style: AppTypography.label(
                                  color: Colors.white,
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

                        // Host
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
