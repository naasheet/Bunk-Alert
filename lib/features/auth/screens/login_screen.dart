import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/repositories/auth_repository.dart';
import 'package:bunk_alert/features/auth/widgets/auth_error_banner.dart';
import 'package:bunk_alert/features/auth/widgets/auth_text_field.dart';
import 'package:bunk_alert/features/auth/screens/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _authRepository.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await _authRepository.signInWithGoogle();
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: CircleAvatar(
                    radius: AppSpacing.xxl,
                    backgroundColor: palette.surfaceElevated,
                    child: Icon(
                      Icons.school_outlined,
                      size: 36,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLarge(palette),
                ),
                const SizedBox(height: AppSpacing.base),
                if (_errorMessage != null) ...[
                  AuthErrorBanner(message: _errorMessage!),
                  const SizedBox(height: AppSpacing.base),
                ],
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  onSubmitted: (_) => _signInWithEmail(),
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  height: AppSpacing.xxxl,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'or',
                    style: AppTextStyles.caption(palette),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  height: AppSpacing.xxxl,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _GoogleLogoIcon(color: palette.textPrimary),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/google_logo.png',
      height: 20,
      width: 20,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          'G',
          style: AppTextStyles.labelLarge(
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.dark
                : AppColors.light,
          ).copyWith(color: color),
        );
      },
    );
  }
}
