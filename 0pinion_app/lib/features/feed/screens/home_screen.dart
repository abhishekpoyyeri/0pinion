import 'package:opinion_app/core/widgets/video_refresh_indicator.dart';
import 'package:opinion_app/core/widgets/video_loader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/opinion_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/opinion_provider.dart';


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
                        Tab(text: 'Latest'),
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
            _buildTab(opinionsAsync, (opinions) => opinions, 'for_you'),
            _buildTab(opinionsAsync, (opinions) => opinions.where((o) => o.isCooking).toList(), 'cooking'),
            _buildTab(opinionsAsync, (opinions) => opinions.toList(), 'latest'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(AsyncValue opinionsAsync, List Function(List) filter, String tabKey) {
    return opinionsAsync.when(
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

}
