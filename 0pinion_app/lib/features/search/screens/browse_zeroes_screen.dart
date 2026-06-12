import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_data.dart';

/// Browse Zeroes screen — full directory of topic communities
class BrowseZeroesScreen extends StatelessWidget {
  const BrowseZeroesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Browse Zeroes', style: AppTypography.h3(color: primaryText)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: MockData.zeroes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final zero = MockData.zeroes[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        zero.name,
                        style: AppTypography.bodySemiBold(color: primaryText),
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
                              ? (isDark ? AppColors.black : AppColors.white)
                              : primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  zero.description,
                  style: AppTypography.caption(color: secondaryText),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_formatCount(zero.opinionsCount)} opinions',
                      style: AppTypography.caption(color: secondaryText),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_formatCount(zero.membersCount)} members',
                      style: AppTypography.caption(color: secondaryText),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
