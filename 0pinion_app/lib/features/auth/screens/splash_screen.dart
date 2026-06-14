import 'package:opinion_app/core/widgets/loading_gif_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/repositories/auth_repository.dart';

/// Splash / Landing screen
/// Displays "0pinion" wordmark, tagline, and Get Started / Login buttons
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndProfile();
    });
  }

  Future<void> _checkAuthAndProfile() async {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final authRepo = ref.read(authRepositoryProvider);
      final hasProfile = await authRepo.hasProfile(user.id);
      if (mounted) {
        if (hasProfile) {
          context.go('/home');
        } else {
          context.go('/username-setup');
        }
      }
    }
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
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Wordmark
                  Semantics(
                    label: '0pinion',
                    child: Image.asset(
                      'assets/title.png',
                      height: 80,
                      fit: BoxFit.contain,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(
                    width: 0,
                    height: 0,
                    child: Text(
                      '0pinion',
                      style: TextStyle(
                        color: Colors.transparent,
                        fontSize: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    'Debate, Not Doomscroll.',
                    style: AppTypography.body(color: secondaryText),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 4),

                  SizedBox(
                    height: 116,
                    child: Center(
                      child: (ref.watch(authStateProvider).isLoading || !ref.watch(authStateProvider).hasValue)
                          ? const LoadingGifWidget(width: 52, height: 52)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PrimaryButton(
                                  label: 'Get Started',
                                  onPressed: () => context.go('/signup'),
                                ),
                                const SizedBox(height: 12),
                                SecondaryButton(
                                  label: 'Login',
                                  onPressed: () => context.go('/login'),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
