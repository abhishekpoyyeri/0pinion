import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/opinion_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';

/// Profile screen — avatar, reputation, stats, opinions/arguments/zeroes tabs
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
                      // We don't have the user's avatar_seed or display_name loaded into currentUserProvider easily
                      // because currentUserProvider only returns GoTrue User object.
                      // For now, we'll just show the email as a fallback.
                      AvatarWidget(seed: user.id.hashCode, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        user.email ?? 'Unknown User',
                        style: AppTypography.h3(color: primaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@user_${user.id.substring(0, 4)}',
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
                          'Reputation: 0',
                          style: AppTypography.bodySemiBold(color: primaryText),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(value: '0', label: 'Opinions'),
                          Container(width: 1, height: 32, color: borderColor),
                          _StatItem(value: '0', label: 'Debates'),
                          Container(width: 1, height: 32, color: borderColor),
                          _StatItem(value: '0', label: 'Zeroes'),
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
          return Center(child: Text('No opinions yet', style: AppTypography.body(color: secondaryText)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: userOpinions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final op = userOpinions[index];
            return Container(
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
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading opinions', style: AppTypography.body(color: secondaryText))),
    );
  }

  Widget _buildArgumentsTab(Color primaryText, Color secondaryText, Color borderColor) {
    return Center(
      child: Text(
        'Your arguments will appear here',
        style: AppTypography.body(color: secondaryText),
      ),
    );
  }

  Widget _buildZeroesTab(Color primaryText, Color secondaryText, Color borderColor) {
    return Center(
      child: Text(
        'Your joined zeroes will appear here',
        style: AppTypography.body(color: secondaryText),
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
