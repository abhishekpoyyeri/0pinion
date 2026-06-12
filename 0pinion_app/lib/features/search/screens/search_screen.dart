import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/opinion_card.dart';
import '../../../data/models/opinion.dart';

/// Search screen — search bar + Opinions/Zeroes/Users tabs
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search opinions, zeroes, users...',
                prefixIcon: Icon(Icons.search, color: secondaryText),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: secondaryText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Opinions'),
              Tab(text: 'Zeroes'),
              Tab(text: 'Users'),
            ],
          ),
          Divider(height: 1, color: borderColor),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Opinions tab
                _buildOpinionsTab(primaryText, secondaryText),
                // Zeroes tab
                _buildZeroesTab(primaryText, secondaryText, borderColor, surfaceColor),
                // Users tab (placeholder)
                _buildUsersTab(secondaryText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionsTab(Color primaryText, Color secondaryText) {
    final List<Opinion> filtered = [];

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 200,
              child: Center(child: Text('No opinions found', style: AppTypography.body(color: secondaryText))),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return OpinionCard(
            opinion: filtered[index],
            onTap: () => context.push('/opinion/${filtered[index].id}'),
          );
        },
      ),
    );
  }

  Widget _buildZeroesTab(Color primaryText, Color secondaryText, Color borderColor, Color surfaceColor) {
    final List<dynamic> filtered = [];

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 200,
              child: Center(child: Text('No zeroes found', style: AppTypography.body(color: secondaryText))),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
        final zero = filtered[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zero.name, style: AppTypography.bodySemiBold(color: primaryText)),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCount(zero.opinionsCount)} opinions',
                      style: AppTypography.caption(color: secondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: zero.isJoined ? primaryText : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryText),
                ),
                child: Text(
                  zero.isJoined ? 'Joined' : 'Join',
                  style: AppTypography.captionMedium(
                    color: zero.isJoined
                        ? (Theme.of(context).brightness == Brightness.dark ? AppColors.black : AppColors.white)
                        : primaryText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  Widget _buildUsersTab(Color secondaryText) {
    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_outlined, size: 48, color: secondaryText),
                const SizedBox(height: 16),
                Text(
                  'Search for users',
                  style: AppTypography.body(color: secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
