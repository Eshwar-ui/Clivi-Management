import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive_scaffold.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../providers/auth_provider.dart';

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordError;

  String _mapLoginError(dynamic e) {
    final message = ExceptionHandler.getMessage(e);
    final normalized = '${e.toString()} $message'.toLowerCase();

    if (normalized.contains('socket') ||
        normalized.contains('network') ||
        normalized.contains('internet') ||
        normalized.contains('connection') ||
        normalized.contains('timeout')) {
      return 'Unable to connect. Please check your internet and try again.';
    }

    if (normalized.contains('incorrect password') ||
        normalized.contains('invalid login') ||
        normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials') ||
        normalized.contains('credential') ||
        normalized.contains('no account registered') ||
        normalized.contains('user not found') ||
        normalized.contains('invalid email')) {
      return 'Incorrect password';
    }

    return 'Login failed. Please try again.';
  }

  bool _isCredentialError(dynamic e) {
    final message = ExceptionHandler.getMessage(e);
    final normalized = '${e.toString()} $message'.toLowerCase();
    return normalized.contains('incorrect password') ||
        normalized.contains('invalid login') ||
        normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials') ||
        normalized.contains('credential') ||
        normalized.contains('no account registered') ||
        normalized.contains('user not found') ||
        normalized.contains('invalid email');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final startedAt = DateTime.now();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _passwordError = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.role != null) {
        switch (authState.role!) {
          case UserRole.superAdmin:
            context.go('/super-admin/dashboard');
            break;
          case UserRole.admin:
            context.go('/admin/dashboard');
            break;
          case UserRole.siteManager:
            context.go('/site-manager/dashboard');
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        final errorText = _mapLoginError(e);
        final isCredential = _isCredentialError(e);

        setState(() {
          if (isCredential) {
            _passwordError = 'Incorrect password';
          } else {
            _errorMessage = errorText;
          }
        });

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isCredential ? Icons.error_outline : Icons.wifi_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
      }
    } finally {
      if (mounted) {
        final elapsed = DateTime.now().difference(startedAt);
        const minLoadingDuration = Duration(milliseconds: 2000);
        if (elapsed < minLoadingDuration) {
          await Future.delayed(minLoadingDuration - elapsed);
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      builder: (context, r) {
        return Stack(
          children: [
            // Top progress bar while loading
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),

            // Main form — no nested ScrollView; ResponsiveScaffold handles it
            Padding(
              padding: r.pad.copyWith(top: 24, bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(r.isTablet ? 20 : 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.construction,
                            size: r.font(40, tablet: 48),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: r.font(30, tablet: 34),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: r.font(14, tablet: 16),
                              ),
                        ),
                        const SizedBox(height: 28),
                        if (_errorMessage != null) ...[
                          InlineErrorWidget(message: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          onFieldSubmitted: (_) =>
                              _passwordFocusNode.requestFocus(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: _isLoading ? 'Signing in...' : 'Sign In',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                          icon: _isLoading ? null : Icons.login,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Full-screen loading overlay
            IgnorePointer(
              ignoring: !_isLoading,
              child: AnimatedOpacity(
                opacity: _isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.16),
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Signing in...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
