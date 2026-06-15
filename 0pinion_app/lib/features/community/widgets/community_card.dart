import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../data/models/community.dart';

/// Card widget for displaying a community in list views
class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return GestureDetector(
      onTap: onTap,
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
            // Header: Avatar + Name + Member count
            Row(
              children: [
                AvatarWidget(seed: community.avatarSeed, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: AppTypography.bodySemiBold(color: primaryText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${community.memberCount} member${community.memberCount == 1 ? '' : 's'} • ${community.postCount} post${community.postCount == 1 ? '' : 's'}',
                        style: AppTypography.caption(color: secondaryText),
                      ),
                    ],
                  ),
                ),
                if (community.isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryText,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'JOINED',
                      style: AppTypography.label(
                        color: isDark ? AppColors.black : AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),

            // Description
            if (community.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                community.description,
                style: AppTypography.caption(color: secondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Zero tags
            if (community.zeroes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: community.zeroes.map((zero) {
                  return GestureDetector(
                    onTap: () {
                      context.push('/tag/$zero');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        zero,
                        style: AppTypography.label(color: secondaryText),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
