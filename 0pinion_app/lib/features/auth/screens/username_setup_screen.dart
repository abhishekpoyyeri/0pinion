import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/primary_button.dart';

/// Username setup screen — choose username, display name, see generated avatar
class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  int _avatarSeed = Random().nextInt(99999);

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
                onPressed: () => context.go('/select-zeroes'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
