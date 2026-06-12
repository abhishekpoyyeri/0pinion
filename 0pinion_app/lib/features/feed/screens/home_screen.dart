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
                        height: 36.0, // A bit smaller so it fits elegantly in the 64px collapsed toolbar
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
        body: opinionsAsync.when(
          data: (opinions) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildFeed(opinions),
                _buildFeed(opinions.where((o) => o.isCooking).toList()),
                _buildFeed(opinions.toList()), 
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildFeed(List opinions) {
    if (opinions.isEmpty) {
      return RefreshIndicator(
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

    return RefreshIndicator(
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
}
