import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';


/// Live Rooms screen — browse active text-only debate rooms
class LiveRoomsScreen extends StatelessWidget {
  const LiveRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Rooms', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Real-time text discussions happening now',
              style: AppTypography.caption(color: secondaryText),
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 0,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                final room = null;
                return GestureDetector(
                  onTap: () => context.push('/live/${room.id}'),
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
                        // Live indicator + title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryText,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LIVE',
                                style: AppTypography.label(
                                  color: isDark ? AppColors.black : AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                room.title,
                                style: AppTypography.bodySemiBold(color: primaryText),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Host + participants
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              'Hosted by @${room.hostUsername}',
                              style: AppTypography.caption(color: secondaryText),
                            ),
                            const Spacer(),
                            Icon(Icons.group_outlined, size: 16, color: secondaryText),
                            const SizedBox(width: 4),
                            Text(
                              '${room.participantsCount} participants',
                              style: AppTypography.caption(color: secondaryText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}
