import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../data/mock/mock_data.dart';

/// Profile screen — avatar, reputation, stats, opinions/arguments/zeroes tabs
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
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
    final user = MockData.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: primaryText),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AvatarWidget(seed: user.avatarSeed, size: 80),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: AppTypography.h3(color: primaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
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
                    'Reputation: ${user.reputationScore}',
                    style: AppTypography.bodySemiBold(color: primaryText),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(value: '${user.opinionsCount}', label: 'Opinions'),
                    Container(width: 1, height: 32, color: borderColor),
                    _StatItem(value: '${user.debatesJoined}', label: 'Debates'),
                    Container(width: 1, height: 32, color: borderColor),
                    _StatItem(value: '${user.joinedZeroes.length}', label: 'Zeroes'),
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
                _buildOpinionsTab(primaryText, secondaryText, borderColor),
                _buildArgumentsTab(primaryText, secondaryText, borderColor),
                _buildZeroesTab(primaryText, secondaryText, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionsTab(Color primaryText, Color secondaryText, Color borderColor) {
    final userOpinions = MockData.opinions
        .where((o) => o.authorId == MockData.currentUser.id)
        .toList();

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
    final joinedZeroes = MockData.zeroes.where((z) => z.isJoined).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: joinedZeroes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final zero = joinedZeroes[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zero.name, style: AppTypography.bodyMedium(color: primaryText)),
                    const SizedBox(height: 4),
                    Text(
                      '${zero.opinionsCount} opinions',
                      style: AppTypography.caption(color: secondaryText),
                    ),
                  ],
                ),
              ),
              Text('Joined', style: AppTypography.captionMedium(color: secondaryText)),
            ],
          ),
        );
      },
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
