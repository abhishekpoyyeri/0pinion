import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/zero_chip.dart';
import '../../../data/mock/mock_data.dart';

/// Create Opinion screen — title, content, zeroes, anonymous toggle
class CreateOpinionScreen extends StatefulWidget {
  const CreateOpinionScreen({super.key});

  @override
  State<CreateOpinionScreen> createState() => _CreateOpinionScreenState();
}

class _CreateOpinionScreenState extends State<CreateOpinionScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final Set<String> _selectedZeroes = {};
  bool _isAnonymous = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _selectedZeroes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Opinion', style: AppTypography.h3(color: primaryText)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text('Title', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              maxLength: 150,
              decoration: const InputDecoration(
                hintText: 'State your opinion...',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Text('Content', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              onChanged: (_) => setState(() {}),
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Explain your reasoning...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Select Zeroes
            Text('Zeroes', style: AppTypography.captionMedium(color: primaryText)),
            const SizedBox(height: 4),
            Text(
              'Tag relevant communities',
              style: AppTypography.caption(color: secondaryText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MockData.zeroes.take(6).map((zero) {
                final isSelected = _selectedZeroes.contains(zero.name);
                return ZeroChip(
                  name: zero.name,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedZeroes.remove(zero.name);
                      } else {
                        _selectedZeroes.add(zero.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Anonymous toggle
            Container(
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
                        Text(
                          'Post Anonymously',
                          style: AppTypography.bodyMedium(color: primaryText),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your identity will be hidden',
                          style: AppTypography.caption(color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    activeTrackColor: primaryText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Post button
            PrimaryButton(
              label: 'Post Opinion',
              onPressed: _canPost
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opinion posted', style: AppTypography.caption()),
                          backgroundColor: primaryText,
                        ),
                      );
                      context.go('/home');
                    }
                  : null,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
