import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
 
 
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Returns a user-friendly message and whether it is a credential error.
  ({String message, bool isCredential}) _parseError(dynamic e) {
    final raw =
        '${e.toString()} ${ExceptionHandler.getMessage(e)}'.toLowerCase();

    if (raw.contains('socket') ||
        raw.contains('network') ||
        raw.contains('internet') ||
        raw.contains('connection') ||
        raw.contains('timeout')) {
      return (
        message: 'No internet. Check your connection and try again.',
        isCredential: false,
      );
    }

    if (raw.contains('invalid_credentials') ||
        raw.contains('credential') ||
        raw.contains('invalid login') ||
        raw.contains('incorrect password') ||
        raw.contains('user not found') ||
        raw.contains('no account registered') ||
        raw.contains('invalid email')) {
      return (message: 'Incorrect email or password.', isCredential: true);
    }

    return (message: 'Login failed. Please try again.', isCredential: false);
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _passwordError = null;
    });

    // Yield to the event loop so Flutter renders the loading state
    // before the network call starts. Without this, a fast-completing
    // Future can cause both setState(true) and setState(false) to land
    // in the same frame, making the loading bar never appear.
    await Future.delayed(Duration.zero);

    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      final role = ref.read(authProvider).role;
      switch (role) {
        case UserRole.superAdmin:
          context.go('/super-admin/dashboard');
        case UserRole.admin:
          context.go('/admin/dashboard');
        case UserRole.siteManager:
          context.go('/site-manager/dashboard');
        case null:
          break;
      }
    } catch (e) {
      if (!mounted) return;
      final (:message, :isCredential) = _parseError(e);
      setState(() {
        if (isCredential) {
          _passwordError = message;
        } else {
          _errorMessage = message;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // resizeToAvoidBottomInset keeps the form above the keyboard
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final r = R(Size(constraints.maxWidth, constraints.maxHeight));

            return Column(
              children: [
                // ── Loading bar ───────────────────────────────────────────────
                // First child of the Column so it is always painted above the
                // scroll view.  It cannot scroll away and no overlay can cover it.
                if (_isLoading)
                  LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),

                // ── Scrollable form ───────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      // Keeps the form vertically centred on tall screens.
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: r.pad.copyWith(top: 32, bottom: 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // App icon
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        r.isTablet ? 20 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.construction,
                                        size: r.font(40, tablet: 48),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Heading
                                  Text(
                                    'Welcome Back',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontSize: r.font(28, tablet: 34),
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to your account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: r.font(14, tablet: 16),
                                        ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Network / generic error banner
                                  if (_errorMessage != null) ...[
                                    InlineErrorWidget(
                                      message: _errorMessage!,
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    enabled: !_isLoading,
                                    onChanged: (_) {
                                      if (_errorMessage != null) {
                                        setState(() => _errorMessage = null);
                                      }
                                    },
                                    onFieldSubmitted: (_) =>
                                        _passwordFocusNode.requestFocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'you@example.com',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    enabled: !_isLoading,
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
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      errorText: _passwordError,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(
                                          () => _isPasswordVisible =
                                              !_isPasswordVisible,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Forgot password link
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () =>
                                              context.go('/forgot-password'),
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Sign In button
                                  AppButton(
                                    text: _isLoading
                                        ? 'Signing in…'
                                        : 'Sign In',
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                    isLoading: _isLoading,
                                    icon: _isLoading ? null : Icons.login,
                                  ),
                                  const SizedBox(height: 12),

                                  // Progress bar — shown below the button
                                  // where the user's eyes are after tapping.
                                  AnimatedCrossFade(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    crossFadeState: _isLoading
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    firstChild: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            minHeight: 6,
                                            backgroundColor: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Signing in, please wait…',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    secondChild: const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
