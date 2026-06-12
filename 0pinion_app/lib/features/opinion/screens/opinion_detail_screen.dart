import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/argument.dart';
import '../../../core/providers/opinion_provider.dart';

/// Opinion Detail screen — full opinion + debate zone
class OpinionDetailScreen extends ConsumerStatefulWidget {
  final String opinionId;

  const OpinionDetailScreen({super.key, required this.opinionId});

  @override
  ConsumerState<OpinionDetailScreen> createState() => _OpinionDetailScreenState();
}

class _OpinionDetailScreenState extends ConsumerState<OpinionDetailScreen>
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

    final opinionsAsync = ref.watch(feedOpinionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flag_outlined, color: secondaryText),
            onPressed: () => context.push('/report/opinion/${widget.opinionId}'),
          ),
        ],
      ),
      body: opinionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (opinions) {
          final opinion = opinions.firstWhere(
            (o) => o.id == widget.opinionId,
            // Fallback for demonstration if ID isn't found
            orElse: () => opinions.first,
          );

          // We'll stub arguments until we implement argument repository
          final arguments = <Argument>[];
      body: Column(
        children: [
          // Opinion content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cooking badge
                  if (opinion.isCooking)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryText,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'COOKING',
                          style: AppTypography.label(
                            color: isDark ? AppColors.black : AppColors.white,
                          ),
                        ),
                      ),
                    ),

                  // Title
                  Text(opinion.title, style: AppTypography.h2(color: primaryText)),
                  const SizedBox(height: 16),

                  // Author
                  Row(
                    children: [
                      if (!opinion.isAnonymous)
                        AvatarWidget(seed: opinion.authorId.hashCode, size: 32),
                      if (!opinion.isAnonymous) const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opinion.isAnonymous ? 'Anonymous' : '@${opinion.authorUsername}',
                            style: AppTypography.bodyMedium(color: primaryText),
                          ),
                          Text(
                            _formatTime(opinion.createdAt),
                            style: AppTypography.caption(color: secondaryText),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Zeroes
                  Wrap(
                    spacing: 8,
                    children: opinion.zeroes.map((z) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(z, style: AppTypography.label(color: secondaryText)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Content
                  Text(
                    opinion.content,
                    style: AppTypography.body(color: primaryText),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: borderColor),
                  const SizedBox(height: 16),

                  // Debate section header
                  Text('Debate', style: AppTypography.h3(color: primaryText)),
                  const SizedBox(height: 16),

                  // Debate tabs
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Support (${opinion.supportCount})'),
                      Tab(text: 'Oppose (${opinion.opposeCount})'),
                      Tab(text: 'Question (${opinion.questionCount})'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Arguments list (not inside TabBarView since we're in a ScrollView)
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final type = [
                        ArgumentType.support,
                        ArgumentType.oppose,
                        ArgumentType.question,
                      ][_tabController.index];
                      final filtered = arguments.where((a) => a.type == type).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No ${type.name} arguments yet',
                              style: AppTypography.body(color: secondaryText),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: filtered.map((arg) {
                          return _ArgumentTile(argument: arg);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: PrimaryButton(
              label: 'Join Debate',
              onPressed: () => context.push('/argument/${opinion.id}'),
            ),
          ),
        ],
      );
    },
  ),
);
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _ArgumentTile extends StatelessWidget {
  final Argument argument;

  const _ArgumentTile({required this.argument});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Row(
            children: [
              if (!argument.isAnonymous)
                AvatarWidget(seed: argument.authorId.hashCode, size: 24),
              if (!argument.isAnonymous) const SizedBox(width: 8),
              Text(
                argument.isAnonymous ? 'Anonymous' : '@${argument.authorUsername}',
                style: AppTypography.captionMedium(color: primaryText),
              ),
              const Spacer(),
              Text(
                _timeAgo(argument.createdAt),
                style: AppTypography.caption(color: secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Content
          Text(
            argument.content,
            style: AppTypography.body(color: primaryText),
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Text('Reply', style: AppTypography.captionMedium(color: secondaryText)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => context.push('/report/argument/${argument.id}'),
                child: Text('Report', style: AppTypography.caption(color: secondaryText)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
