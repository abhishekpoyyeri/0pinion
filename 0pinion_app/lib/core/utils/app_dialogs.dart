import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppDialogs {
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    String cancelText = 'Cancel',
    IconData icon = Icons.info_outline,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
        final secondaryText = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
        final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

        return Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: primaryText),
                const SizedBox(height: 16),
                Text(title, style: AppTypography.h2(color: primaryText), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTypography.body(color: secondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(cancelText, style: AppTypography.button(color: primaryText)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryText,
                          foregroundColor: surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(confirmText, style: AppTypography.button(color: isDark ? AppColors.black : AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
