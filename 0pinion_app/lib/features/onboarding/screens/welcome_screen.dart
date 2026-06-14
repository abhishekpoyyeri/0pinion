import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';

/// Welcome screen â€” "You're in." confirmation
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Checkmark
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryText,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 40,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  "You're in.",
                  style: AppTypography.h1(color: primaryText),
                ),
              ),
              const SizedBox(height: 12),

              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  'Start exploring opinions, join debates,\nand discover what others think.',
                  style: AppTypography.body(color: secondaryText),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 4),

              PrimaryButton(
                label: 'Enter 0pinion',
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
