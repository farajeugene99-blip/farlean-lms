import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_provider.dart';
import '../common/google_logo.dart';
import 'auth_error_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      final l10n = AppLocalizations.of(context);
      final isUnregisteredOrInvalid = authProvider.authErrorCode == 'user-not-found' ||
          authProvider.authErrorCode == 'invalid-credential';

      String msg;
      if (authProvider.authErrorCode == 'invalid-credential') {
        msg = 'Email belum terdaftar atau kata sandi salah.';
      } else if (authProvider.authErrorCode == 'user-not-found') {
        msg = l10n.authErrUserNotFound;
      } else {
        msg = AuthErrorLocalization.fromCode(
          l10n,
          authProvider.authErrorCode,
          fallbackMessage: authProvider.errorMessage,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
          action: isUnregisteredOrInvalid
              ? SnackBarAction(
                  label: 'Daftar di sini',
                  textColor: Colors.white,
                  onPressed: () => context.push(AppConstants.registerRoute),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _submitGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      final l10n = AppLocalizations.of(context);
      final msg = AuthErrorLocalization.fromCode(
        l10n,
        authProvider.authErrorCode,
        fallbackMessage: authProvider.errorMessage,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 32,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.authLoginTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.authLoginSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.authFieldEmail,
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.validEmailRequired;
                      if (!v.contains('@')) return l10n.validEmailFormat;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.authFieldPassword,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.validPasswordRequired;
                      if (v.length < 6) return l10n.validPasswordMin(6);
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push(AppConstants.forgotPasswordRoute),
                      child: Text(l10n.authForgotPasswordLink),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.authBtnLogin),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.authOrDivider,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: isLoading ? null : _submitGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.borderColor),
                      backgroundColor: context.surfaceColor,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.primaryColor,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const GoogleLogo(size: 20),
                              const SizedBox(width: 12),
                              Text(
                                l10n.authBtnGoogleSignIn,
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.authNoAccount),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(AppConstants.registerRoute),
                        child: Text(l10n.authBtnRegisterLink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
