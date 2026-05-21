import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/shake_transition.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
 
 
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeTransitionState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authState = ref.read(authProvider);
    if (authState.isLoading) return;

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _shakeKey.currentState?.shake();
      return;
    }

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
      _shakeKey.currentState?.shake();
      // Error is handled by the provider and displayed in the UI via authProvider.error
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final r = R(Size(constraints.maxWidth, constraints.maxHeight));

            return Stack(
              children: [
                Column(
                  children: [
                    // ── Scrollable form ───────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: r.pad.copyWith(top: 32, bottom: 32),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: ShakeTransition(
                                  key: _shakeKey,
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // App icon
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              r.isTablet ? 12 : 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.shadow,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/images/logo.png',
                                              height: r.font(60, tablet: 80),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 28),

                                        // Heading
                                        Text(
                                          'Welcome to Clivi',
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
                                          'Sign in to manage your projects',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: r.font(14, tablet: 16),
                                              ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Error banner from provider
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: authState.error != null
                                              ? Padding(
                                                  padding: const EdgeInsets.only(bottom: 16),
                                                  child: InlineErrorWidget(
                                                    message: authState.error!,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),

                                        // Email field
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          enabled: !isLoading,
                                          onChanged: (_) {
                                            if (authState.error != null) {
                                              ref
                                                  .read(authProvider.notifier)
                                                  .clearError();
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
                                          enabled: !isLoading,
                                          onFieldSubmitted: (_) => _handleLogin(),
                                          onChanged: (_) {
                                            if (authState.error != null) {
                                              ref
                                                  .read(authProvider.notifier)
                                                  .clearError();
                                            }
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            hintText: 'Enter your password',
                                            prefixIcon:
                                                const Icon(Icons.lock_outline),
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
                                            onPressed: isLoading
                                                ? null
                                                : () => context
                                                    .go('/forgot-password'),
                                            child: const Text('Forgot Password?'),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Sign In button
                                        Hero(
                                          tag: 'auth_button',
                                          child: AppButton(
                                            text: 'Sign In',
                                            onPressed: isLoading ? null : _handleLogin,
                                            isLoading: isLoading,
                                            icon: Icons.login,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // Bottom info
                                        Center(
                                          child: Text(
                                            '© ${DateTime.now().year} Clivi Management',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                                            ),
                                          ),
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
                    ),
                  ],
                ),
                
                // ── Loading Overlay ───────────────────────────────────────────
                if (isLoading)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: isLoading ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.8),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      authState.statusMessage ?? 'Authenticating...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Please do not close the app',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
