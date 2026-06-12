import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/argument.dart';

/// Write Argument screen — compose a support/oppose/question argument
class WriteArgumentScreen extends StatefulWidget {
  final String opinionId;

  const WriteArgumentScreen({super.key, required this.opinionId});

  @override
  State<WriteArgumentScreen> createState() => _WriteArgumentScreenState();
}

class _WriteArgumentScreenState extends State<WriteArgumentScreen> {
  final _controller = TextEditingController();
  ArgumentType _selectedType = ArgumentType.support;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Write Argument', style: AppTypography.h3(color: primaryText)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Argument type selector
                  Text('Your position', style: AppTypography.captionMedium(color: primaryText)),
                  const SizedBox(height: 12),
                  Row(
                    children: ArgumentType.values.map((type) {
                      final isSelected = _selectedType == type;
                      final label = type.name[0].toUpperCase() + type.name.substring(1);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: type != ArgumentType.question ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryText : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryText : borderColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: AppTypography.captionMedium(
                                  color: isSelected
                                      ? (isDark ? AppColors.black : AppColors.white)
                                      : primaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Argument text
                  Text('Your argument', style: AppTypography.captionMedium(color: primaryText)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    maxLines: 8,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'Present your argument...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: PrimaryButton(
              label: 'Submit Argument',
              onPressed: _controller.text.trim().isNotEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Argument submitted',
                            style: AppTypography.caption(),
                          ),
                          backgroundColor: primaryText,
                        ),
                      );
                      context.pop();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
