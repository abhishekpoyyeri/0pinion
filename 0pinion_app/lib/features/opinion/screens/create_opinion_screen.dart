import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/opinion_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/live_room_repository.dart';

/// Screen to create a new opinion or a live room
class CreateOpinionScreen extends ConsumerStatefulWidget {
  const CreateOpinionScreen({super.key});

  @override
  ConsumerState<CreateOpinionScreen> createState() => _CreateOpinionScreenState();
}

class _CreateOpinionScreenState extends ConsumerState<CreateOpinionScreen> {
  // Opinion Controllers
  final _opinionTitleController = TextEditingController();
  final _opinionContentController = TextEditingController();
  bool _isAnonymous = false;
  String? _selectedZeroId;
  bool _isOpinionLoading = false;

  // Live Room Controllers
  final _roomTitleController = TextEditingController();
  final _roomTopicController = TextEditingController();
  bool _isRoomLoading = false;

  // We temporarily hardcode some zeroes since we don't have a Zero repository yet.
  // In a real app we would fetch this from Supabase `zeroes` table.
  final _mockZeroes = [
    {'id': null, 'name': 'Technology'},
    {'id': null, 'name': 'Politics'},
    {'id': null, 'name': 'Philosophy'},
  ];

  @override
  void dispose() {
    _opinionTitleController.dispose();
    _opinionContentController.dispose();
    _roomTitleController.dispose();
    _roomTopicController.dispose();
    super.dispose();
  }

  Future<void> _submitOpinion() async {
    final title = _opinionTitleController.text.trim();
    final content = _opinionContentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated.')),
      );
      return;
    }

    setState(() => _isOpinionLoading = true);
    try {
      final repo = ref.read(opinionRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      // EXPLICIT CHECK: Ensure they have a profile before proceeding!
      final hasProfile = await authRepo.hasProfile(user.id);
      if (!hasProfile) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must complete your profile first! Redirecting...')),
          );
          context.go('/username-setup');
        }
        return;
      }

      await repo.createOpinion(
        title: title,
        content: content,
        authorId: user.id,
        isAnonymous: _isAnonymous,
        zeroId: _selectedZeroId,
      );
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpinionLoading = false);
    }
  }

  Future<void> _submitLiveRoom() async {
    final title = _roomTitleController.text.trim();
    final topic = _roomTopicController.text.trim();

    if (title.isEmpty || topic.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated.')),
      );
      return;
    }

    setState(() => _isRoomLoading = true);
    try {
      final repo = ref.read(liveRoomRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      final hasProfile = await authRepo.hasProfile(user.id);
      if (!hasProfile) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must complete your profile first! Redirecting...')),
          );
          context.go('/username-setup');
        }
        return;
      }

      await repo.createRoom(
        title: title,
        topic: topic,
        hostId: user.id,
      );
      
      if (mounted) {
        context.go('/live');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRoomLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create', style: AppTypography.h3(color: primaryText)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.go('/home'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Opinion'),
              Tab(text: 'Live Room'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOpinionForm(context),
            _buildLiveRoomForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOpinionForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            TextField(
              controller: _opinionTitleController,
              style: AppTypography.h2(color: primaryText),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'What is your opinion?',
                hintStyle: AppTypography.h2(color: secondaryText),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Content Field
            TextField(
              controller: _opinionContentController,
              style: AppTypography.body(color: primaryText),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Expand on your thoughts. Why do you hold this view? Be concise.',
                hintStyle: AppTypography.body(color: secondaryText),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),

            Divider(color: borderColor),
            const SizedBox(height: 24),

            // Tag a Zero
            Text('Tag a Zero (Optional)', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mockZeroes.map((zero) {
                final isSelected = _selectedZeroId == zero['name'];
                return FilterChip(
                  label: Text(zero['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedZeroId = selected ? zero['id'] : null;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: isDark ? Colors.white24 : Colors.black12,
                  shape: StadiumBorder(side: BorderSide(color: borderColor)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Anonymity Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Post Anonymously', style: AppTypography.captionMedium(color: primaryText)),
                    const SizedBox(height: 4),
                    Text('Your identity will be hidden.', style: AppTypography.caption(color: secondaryText)),
                  ],
                ),
                Switch(
                  value: _isAnonymous,
                  onChanged: (val) => setState(() => _isAnonymous = val),
                  activeColor: isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Submit
            _isOpinionLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'Post Opinion',
                    onPressed: _submitOpinion,
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRoomForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            TextField(
              controller: _roomTitleController,
              style: AppTypography.h2(color: primaryText),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Live Room Title',
                hintStyle: AppTypography.h2(color: secondaryText),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Topic Field
            TextField(
              controller: _roomTopicController,
              style: AppTypography.body(color: primaryText),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What is the debate topic?',
                hintStyle: AppTypography.body(color: secondaryText),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 40),

            // Submit
            _isRoomLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'Create Live Room',
                    onPressed: _submitLiveRoom,
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
