import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../data/models/opinion.dart';

/// Opinion card for feed display
/// Shows title, preview, author, zeroes, debate counts
class OpinionCard extends StatelessWidget {
  final Opinion opinion;
  final VoidCallback? onTap;

  const OpinionCard({
    super.key,
    required this.opinion,
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
          border: Border.all(
            color: opinion.isCooking ? primaryText : borderColor,
            width: opinion.isCooking ? 1.5 : 1,
          ),
        ),
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
            Text(
              opinion.title,
              style: AppTypography.h3(color: primaryText),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Content preview
            Text(
              opinion.content,
              style: AppTypography.body(color: secondaryText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Author row
            Row(
              children: [
                if (!opinion.isAnonymous)
                  AvatarWidget(seed: opinion.authorId.hashCode, size: 24),
                if (!opinion.isAnonymous) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opinion.isAnonymous ? 'Anonymous' : '@${opinion.authorUsername}',
                    style: AppTypography.captionMedium(color: secondaryText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _timeAgo(opinion.createdAt),
                  style: AppTypography.caption(color: secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Zeroes
            if (opinion.zeroes.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: opinion.zeroes.map((zero) {
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
            if (opinion.zeroes.isNotEmpty) const SizedBox(height: 12),

            // Debate stats
            Divider(color: borderColor),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _StatChip(label: 'Support', count: opinion.supportCount, color: primaryText),
                _StatChip(label: 'Oppose', count: opinion.opposeCount, color: primaryText),
                _StatChip(label: 'Question', count: opinion.questionCount, color: primaryText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTypography.captionMedium(color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}
