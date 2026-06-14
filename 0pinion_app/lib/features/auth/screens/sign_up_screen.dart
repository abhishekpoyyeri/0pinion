import 'package:opinion_app/core/widgets/loading_gif_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';

/// Sign Up screen â€” Email/Password form + Google auth
class SignUpScreen extends ConsumerStatefulWidget {
  final bool isLogin;
  
  const SignUpScreen({super.key, this.isLogin = false});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late bool _isLogin; // Toggle between Login and Sign Up

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      if (_isLogin) {
        final res = await authRepo.signInWithEmail(email, password);
        if (res.session != null) {
          final hasProfile = await authRepo.hasProfile(res.session!.user.id);
          if (hasProfile) {
            if (mounted) context.go('/home');
          } else {
            if (mounted) context.go('/username-setup');
          }
        }
      } else {
        final res = await authRepo.signUpWithEmail(email, password);
        if (res.session == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please check your email to confirm your account, or disable Email Confirmations in Supabase Dashboard.')),
            );
          }
        } else {
          if (mounted) context.go('/username-setup');
        }
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorDialog(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email to reset password.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/splash'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Title
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: AppTypography.h1(color: primaryText),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Login to continue.' : 'Join the debate.',
                style: AppTypography.body(color: secondaryText),
              ),
              const SizedBox(height: 40),

              // Email field
              Text('Email', style: AppTypography.captionMedium(color: primaryText)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                ),
              ),
              const SizedBox(height: 24),

              // Password field
              Text('Password', style: AppTypography.captionMedium(color: primaryText)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: _isLogin ? 'Enter your password' : 'Create a password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: secondaryText,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              if (_isLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _resetPassword,
                    child: Text(
                      'Forgot password?',
                      style: AppTypography.captionMedium(color: primaryText).copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Sign Up button
              _isLoading
                  ? const Center(child: LoadingGifWidget())
                  : PrimaryButton(
                      label: _isLogin ? 'Log In' : 'Sign Up',
                      onPressed: _submit,
                    ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: AppTypography.caption(color: secondaryText)),
                  ),
                  Expanded(child: Divider(color: borderColor)),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign In
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sign-In not implemented yet.')),
                    );
                  },
                  icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  label: Text('Continue with Google', style: AppTypography.button()),
                ),
              ),
              const SizedBox(height: 32),

              // Login link
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLogin ? 'Don\'t have an account? ' : 'Already have an account? ',
                          style: AppTypography.caption(color: secondaryText),
                        ),
                        Text(
                          _isLogin ? 'Sign Up' : 'Login',
                          style: AppTypography.captionMedium(color: primaryText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
