import 'package:opinion_app/core/widgets/loading_gif_widget.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/auth_repository.dart';

/// Username setup screen â€” choose username, display name, see generated avatar
class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  int _avatarSeed = Random().nextInt(99999);
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _regenerateAvatar() {
    setState(() {
      _avatarSeed = Random().nextInt(99999);
    });
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (username.isEmpty || displayName.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppErrorHandler.showErrorDialog(context, 'Error: Not authenticated.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.createProfile(
        userId: user.id,
        username: username,
        displayName: displayName,
        avatarSeed: _avatarSeed,
      );
      ref.invalidate(userProfileDetailsProvider);
      ref.invalidate(profileStatsProvider);
      if (mounted) context.go('/select-zeroes');
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/signup'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Set Up Profile',
                style: AppTypography.h1(color: primaryText),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your identity.',
                style: AppTypography.body(color: secondaryText),
              ),
              const SizedBox(height: 40),

              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _regenerateAvatar,
                  child: Column(
                    children: [
                      AvatarWidget(seed: _avatarSeed, size: 96),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 16, color: secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to regenerate',
                            style: AppTypography.caption(color: secondaryText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Username
              Text('Username', style: AppTypography.captionMedium(color: primaryText)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Choose a username',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 24),

              // Display name
              Text('Display Name', style: AppTypography.captionMedium(color: primaryText)),
              const SizedBox(height: 8),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  hintText: 'Your display name',
                ),
              ),
              const SizedBox(height: 40),

              PrimaryButton(
                label: 'Continue',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
