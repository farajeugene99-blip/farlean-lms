import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../main/main_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final email = authProvider.firebaseUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authVerifyAppBar)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.authVerifyHeading,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.authVerifyBody(email),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final isVerified =
                            await authProvider.checkEmailVerification();
                        if (!context.mounted) return;

                        if (!isVerified) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context).authVerifyNotYet,
                              ),
                              backgroundColor: AppTheme.warning,
                            ),
                          );
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(l10n.authBtnVerifyCheck),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: (isLoading || _cooldownSeconds > 0)
                    ? null
                    : () async {
                        final sent =
                            await authProvider.resendVerificationEmail();
                        if (!context.mounted) return;

                        if (sent) {
                          _startCooldown();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context).authVerifyResent,
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } else {
                          final errorMsg = authProvider.errorMessage ??
                              'Gagal mengirim email verifikasi. Silakan coba beberapa saat lagi.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _cooldownSeconds > 0
                      ? '${l10n.authBtnResendEmail} (${_cooldownSeconds}s)'
                      : l10n.authBtnResendEmail,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  try {
                    await context.read<ClassProvider>().clear();
                  } catch (_) {}
                  MainShell.activeClassId = null;
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go(AppConstants.loginRoute);
                  }
                },
                child: Text(l10n.authBtnSwitchAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
