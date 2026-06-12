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
      appBar: AppBar(
        toolbarHeight: 80,
        title: Image.asset(
          'assets/title.png',
          height: 64,
          fit: BoxFit.contain,
          color: primaryText,
        ),
        centerTitle: true,
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
      ),
      body: opinionsAsync.when(
        data: (opinions) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildFeed(opinions),
              _buildFeed(opinions.where((o) => o.isCooking).toList()),
              // Just reversing the stream array for 'Latest' isn't perfect, but works for now.
              // In a real app we would have a separate query, but 'created_at' desc is already Latest.
              _buildFeed(opinions.toList()), 
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
