import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/zero_provider.dart';
import '../../../core/providers/opinion_provider.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/widgets/opinion_card.dart';
import '../../community/widgets/community_card.dart';

class TagScreen extends ConsumerStatefulWidget {
  final String tagName;

  const TagScreen({
    super.key,
    required this.tagName,
  });

  @override
  ConsumerState<TagScreen> createState() => _TagScreenState();
}

class _TagScreenState extends ConsumerState<TagScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final zeroAsync = ref.watch(zeroByNameProvider(widget.tagName));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.tagName,
          style: AppTypography.h3(color: primaryText),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryText,
          labelColor: primaryText,
          unselectedLabelColor: secondaryText,
          tabs: const [
            Tab(text: 'Opinions'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: zeroAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: primaryText),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: AppTypography.body(color: secondaryText)),
        ),
        data: (zeroData) {
          if (zeroData == null) {
            return Center(
              child: Text('Tag not found.', style: AppTypography.body(color: secondaryText)),
            );
          }

          final zeroId = zeroData['id'] as String;

          return TabBarView(
            controller: _tabController,
            children: [
              _OpinionsTab(zeroId: zeroId),
              _CommunitiesTab(zeroId: zeroId),
            ],
          );
        },
      ),
    );
  }
}

class _OpinionsTab extends ConsumerWidget {
  final String zeroId;

  const _OpinionsTab({required this.zeroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final opinionsAsync = ref.watch(opinionsByZeroProvider(zeroId));

    return opinionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: AppTypography.body(color: secondaryText)),
      ),
      data: (opinions) {
        if (opinions.isEmpty) {
          return Center(
            child: Text('No opinions found for this tag.', style: AppTypography.body(color: secondaryText)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: opinions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final opinion = opinions[index];
            return OpinionCard(
              opinion: opinion,
              onTap: () => context.push('/opinion/${opinion.id}'),
            );
          },
        );
      },
    );
  }
}

class _CommunitiesTab extends ConsumerWidget {
  final String zeroId;

  const _CommunitiesTab({required this.zeroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    final communitiesAsync = ref.watch(communitiesByZeroProvider(zeroId));

    return communitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: AppTypography.body(color: secondaryText)),
      ),
      data: (communities) {
        if (communities.isEmpty) {
          return Center(
            child: Text('No communities found for this tag.', style: AppTypography.body(color: secondaryText)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final community = communities[index];
            return CommunityCard(
              community: community,
              onTap: () => context.push('/community/${community.id}'),
            );
          },
        );
      },
    );
  }
}
