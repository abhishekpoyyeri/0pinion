import 'package:opinion_app/core/widgets/video_refresh_indicator.dart';
import 'package:opinion_app/core/widgets/video_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/live_room_repository.dart';

/// Live Rooms screen — browse active text-only debate rooms
class LiveRoomsScreen extends ConsumerWidget {
  const LiveRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final roomsAsync = ref.watch(liveRoomsProvider);

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
            child: roomsAsync.when(
              loading: () => const Center(child: VideoLoader()),
              error: (err, _) => VideoRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(liveRoomsProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
                              const SizedBox(height: 16),
                              Text(
                                'Connection lost or session expired',
                                style: AppTypography.bodySemiBold(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh and reconnect',
                                style: AppTypography.caption(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: secondaryText),
                        const SizedBox(height: 16),
                        Text(
                          'No live rooms yet',
                          style: AppTypography.bodySemiBold(color: primaryText),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create one from the + tab!',
                          style: AppTypography.caption(color: secondaryText),
                        ),
                      ],
                    ),
                  );
                }

                return VideoRefreshIndicator(
                  onRefresh: () async {
                    // ignore: unused_result
                    ref.refresh(liveRoomsProvider);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: rooms.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final roomId = room['id'] as String;
                      final title = room['title'] as String? ?? 'Untitled';
                      final topic = room['topic'] as String? ?? '';
                      final participantCount = room['participant_count'] as int? ?? 1;

                      // Extract host username from joined profile
                      final profileData = room['profiles'];
                      final hostUsername = profileData != null && profileData is Map
                          ? (profileData['username'] as String? ?? 'unknown')
                          : 'unknown';

                      return GestureDetector(
                        onTap: () => context.push('/live/$roomId'),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryText,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'LIVE',
                                      style: AppTypography.label(
                                        color: isDark
                                            ? AppColors.black
                                            : AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: AppTypography.bodySemiBold(
                                          color: primaryText),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (topic.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  topic,
                                  style: AppTypography.caption(color: secondaryText),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Host + participants
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 16, color: secondaryText),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Hosted by @$hostUsername',
                                      style: AppTypography.caption(
                                          color: secondaryText),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.group_outlined,
                                      size: 16, color: secondaryText),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$participantCount participants',
                                    style: AppTypography.caption(
                                        color: secondaryText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
