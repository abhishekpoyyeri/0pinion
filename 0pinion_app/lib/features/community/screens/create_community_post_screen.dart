import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/widgets/video_loader.dart';
import '../../../data/repositories/community_repository.dart';

/// Screen to create a new post inside a community
class CreateCommunityPostScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CreateCommunityPostScreen({super.key, required this.communityId});

  @override
  ConsumerState<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState
    extends ConsumerState<CreateCommunityPostScreen> {
  final _contentController = TextEditingController();
  bool _isPosting = false;

  static const int _maxLength = 1000;

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.createPost(
        communityId: widget.communityId,
        content: content,
      );

      ref.invalidate(communityPostsProvider(widget.communityId));
      ref.invalidate(communityDetailProvider(widget.communityId));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final contentLength = _contentController.text.length;
    final canPost =
        contentLength > 0 && contentLength <= _maxLength && !_isPosting;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text('New Post', style: AppTypography.h2(color: primaryText)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: canPost ? _submitPost : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: canPost
                      ? primaryText
                      : (isDark
                          ? AppColors.darkDisabled
                          : AppColors.lightDisabled),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isPosting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: const VideoLoader(width: 16, height: 16),
                      )
                    : Text(
                        'Post',
                        style: AppTypography.button(
                          color: canPost
                              ? (isDark ? AppColors.black : AppColors.white)
                              : secondaryText,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _contentController,
                  onChanged: (_) => setState(() {}),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTypography.body(color: primaryText),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts with the community...',
                    hintStyle: AppTypography.body(color: secondaryText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$contentLength / $_maxLength',
                style: AppTypography.caption(
                  color: contentLength > _maxLength
                      ? Theme.of(context).colorScheme.error
                      : secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
