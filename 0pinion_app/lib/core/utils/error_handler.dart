import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppErrorHandler {
  static void showErrorDialog(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred. Please try again.';

    if (error is AuthException) {
      message = _parseAuthException(error);
    } else if (error is PostgrestException) {
      message = _parsePostgrestException(error);
    } else if (error != null) {
      // Basic cleanup for generic exception strings
      String errStr = error.toString();
      if (errStr.startsWith('Exception: ')) {
        errStr = errStr.replaceFirst('Exception: ', '');
      }
      message = errStr;
    }

    showDialog(
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
                Icon(Icons.error_outline, size: 48, color: primaryText),
                const SizedBox(height: 16),
                Text('Oops!', style: AppTypography.h2(color: primaryText)),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTypography.body(color: secondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryText,
                      foregroundColor: surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: AppTypography.button()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _parseAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'The email or password you entered is incorrect.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists. Please log in instead.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    return e.message;
  }

  static String _parsePostgrestException(PostgrestException e) {
    final msg = e.message.toLowerCase();
    final detail = (e.details ?? '').toString().toLowerCase();
    
    if (msg.contains('unique constraint') || msg.contains('duplicate key')) {
      // Specific constraint messages
      if (msg.contains('communities_name_key') || detail.contains('communities_name_key')) {
        return 'A community with this name already exists. Please choose a different name.';
      }
      if (msg.contains('profiles_username_key') || detail.contains('profiles_username_key')) {
        return 'This username is already taken. Please choose another.';
      }
      return 'This value is already taken. Please try another one.';
    }
    if (msg.contains('violates foreign key constraint')) {
      return 'This action references data that no longer exists. Please refresh and try again.';
    }
    if (msg.contains('permission denied') || msg.contains('new row violates row-level security')) {
      return 'You don\'t have permission to perform this action.';
    }
    return e.message;
  }
}
