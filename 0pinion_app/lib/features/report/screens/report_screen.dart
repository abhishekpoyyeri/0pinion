import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';

/// Report screen — flag content with reason
class ReportScreen extends StatefulWidget {
  final String contentType;
  final String contentId;

  const ReportScreen({
    super.key,
    required this.contentType,
    required this.contentId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedReason;

  final List<String> _reasons = [
    'Spam',
    'Harassment',
    'Self Promotion',
    'Misinformation',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Report', style: AppTypography.h3(color: primaryText)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reporting this ${widget.contentType}?',
                      style: AppTypography.body(color: primaryText),
                    ),
                    const SizedBox(height: 24),

                    // Reason list
                    ...(_reasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedReason = reason),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryText : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryText : borderColor,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: AppTypography.bodyMedium(
                              color: isSelected
                                  ? (isDark ? AppColors.black : AppColors.white)
                                  : primaryText,
                            ),
                          ),
                        ),
                      );
                    })),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'Submit Report',
                onPressed: _selectedReason != null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Report submitted. Thank you.',
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
      ),
    );
  }
}
