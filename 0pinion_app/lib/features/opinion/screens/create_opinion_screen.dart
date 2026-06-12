import 'package:opinion_app/core/widgets/video_loader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/opinion_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/utils/error_handler.dart';

/// Screen to create a new opinion
class CreateOpinionScreen extends ConsumerStatefulWidget {
  const CreateOpinionScreen({super.key});

  @override
  ConsumerState<CreateOpinionScreen> createState() => _CreateOpinionScreenState();
}

class _CreateOpinionScreenState extends ConsumerState<CreateOpinionScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  String? _selectedZeroId;
  bool _isLoading = false;

  // We temporarily hardcode some zeroes since we don't have a Zero repository yet.
  // In a real app we would fetch this from Supabase `zeroes` table.
  final _mockZeroes = [
    {'id': null, 'name': 'Technology'},
    {'id': null, 'name': 'Politics'},
    {'id': null, 'name': 'Philosophy'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitOpinion() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppErrorHandler.showErrorDialog(context, 'Error: Not authenticated.');
      return;
    }

    setState(() => _isLoading = true);
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
        AppErrorHandler.showErrorDialog(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Opinion', style: AppTypography.h3(color: primaryText)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextField(
                controller: _titleController,
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
                controller: _contentController,
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
              _isLoading
                  ? const Center(child: VideoLoader())
                  : PrimaryButton(
                      label: 'Post Opinion',
                      onPressed: _submitOpinion,
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
