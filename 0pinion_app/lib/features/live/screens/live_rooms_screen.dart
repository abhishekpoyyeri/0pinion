import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Placeholder screen for a new feature coming to the Live tab
class LiveRoomsScreen extends StatelessWidget {
  const LiveRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text('Coming Soon', style: AppTypography.h2(color: primaryText)),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Icon(
                  Icons.rocket_launch_outlined,
                  size: 40,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something new is brewing',
                style: AppTypography.h3(color: primaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'A new feature is on its way.\nStay tuned for updates!',
                style: AppTypography.body(color: secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'COMING SOON',
                  style: AppTypography.captionMedium(color: secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
