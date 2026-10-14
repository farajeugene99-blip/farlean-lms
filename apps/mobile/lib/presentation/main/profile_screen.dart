import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/app_user.dart';
import '../../repositories/attempt_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/class_provider.dart';
import '../auth/auth_error_localization.dart';
import 'main_shell.dart';

class ProfileScreen extends StatefulWidget {
  final UserRepository? userRepository;
  final AttemptRepository? attemptRepository;

  const ProfileScreen({
    super.key,
    this.userRepository,
    this.attemptRepository,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepository;
  late final AttemptRepository _attemptRepository;
  String? _nimNip;
  bool _isLoadingIdentity = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? UserRepository();
    _attemptRepository = widget.attemptRepository ?? AttemptRepository();
    _loadPrivateIdentity();
  }

  Future<void> _loadPrivateIdentity() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;

    setState(() => _isLoadingIdentity = true);
    try {
      final identity = await _userRepository.getPrivateIdentity(uid);
      if (mounted) {
        setState(() {
          _nimNip = identity;
          _isLoadingIdentity = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingIdentity = false);
    }
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final l10n = AppLocalizations.of(context);
    final outerMessenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileEditNameTitle),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.authFieldName),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.validNameRequired;
                if (v.trim().length > 100) return l10n.profileNameMaxLength(100);
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authProvider = context.read<AuthProvider>();
              final uid = authProvider.firebaseUser?.uid;
              if (uid == null) return;

              try {
                await _userRepository.updateName(uid, controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  outerMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.profileNameUpdateFail(e.toString())),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    ).whenComplete(() {
      controller.dispose();
    });

    if (updated == true && mounted) {
      outerMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.profileNameUpdated),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showEditNimDialog(String label) async {
    final l10n = AppLocalizations.of(context);
    final outerMessenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: _nimNip ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileIdentityTitle(label)),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileIdentityPrivacyNote,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: label,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.profileIdentityRequired(label);
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authProvider = context.read<AuthProvider>();
              final uid = authProvider.firebaseUser?.uid;
              if (uid == null) return;

              try {
                await _userRepository.setPrivateIdentity(uid, controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  outerMessenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.profileIdentitySaveFail(label, e.toString())),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    ).whenComplete(() {
      controller.dispose();
    });

    if (updated == true && mounted) {
      setState(() => _nimNip = controller.text.trim());
      outerMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.profileIdentitySaved(label)),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final outerMessenger = ScaffoldMessenger.of(context);
    final pwUpdatedText = AppLocalizations.of(context).profilePwUpdated;
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ChangePasswordDialog(
        userEmail: context.read<AuthProvider>().firebaseUser?.email,
        onSave: ({required currentPassword, required newPassword}) {
          return context.read<AuthProvider>().changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
              );
        },
        onResetPassword: (email) {
          return context.read<AuthProvider>().sendPasswordReset(email);
        },
      ),
    );

    if (updated == true && mounted) {
      outerMessenger.showSnackBar(
        SnackBar(
          content: Text(pwUpdatedText),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showCacheManagementDialog() async {
    final classProvider = context.read<ClassProvider>();
    final selectedClass = classProvider.selectedClass;
    final selectedClassId = classProvider.selectedClassId;
    final l10n = AppLocalizations.of(context);
    final outerMessenger = ScaffoldMessenger.of(context);
    final resetSuccessText = l10n.profileResetClassDone;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cacheBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
            final cacheCount = PaintingBinding.instance.imageCache.currentSize;
            final kbFormatted = NumberFormat.decimalPatternDigits(
              locale: l10n.localeName,
              decimalDigits: 1,
            ).format(cacheBytes / 1024);
            final cacheText = cacheBytes == 0
                ? l10n.profileCacheEmpty
                : l10n.profileCacheStats(cacheCount, kbFormatted);

            final activeClassText = selectedClass != null
                ? '${selectedClass.name} (${selectedClass.code})'
                : (selectedClassId != null && selectedClassId.isNotEmpty
                    ? 'ID: $selectedClassId'
                    : l10n.profileClassNoneSelected);

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.storage_rounded, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.profileCacheTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileCacheDesc,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      // Bagian 1: Cache Gambar RAM
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image_outlined, size: 16, color: AppTheme.secondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.profileCacheImageSection,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cacheText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.profileCacheImageNote,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: cacheBytes == 0
                                  ? null
                                  : () {
                                      PaintingBinding.instance.imageCache.clear();
                                      PaintingBinding.instance.imageCache.clearLiveImages();
                                      setDialogState(() {});
                                      outerMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.profileCacheCleared),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cleaning_services_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.profileCacheClearBtn,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bagian 2: Pilihan Kelas Aktif
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.class_outlined, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.profileClassSavedSection,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activeClassText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.profileClassResetNote,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                              onPressed: (selectedClassId == null || selectedClassId.isEmpty)
                                  ? null
                                  : () async {
                                      // Guard Kuis Aktif: Periksa attempt aktif terlebih dahulu
                                      final authProvider = context.read<AuthProvider>();
                                      final uid = authProvider.firebaseUser?.uid;
                                      if (uid != null && uid.isNotEmpty) {
                                        try {
                                          final hasActive = await _attemptRepository.hasActiveOngoingAttempt(userId: uid);
                                          if (hasActive) {
                                            if (dialogCtx.mounted) {
                                              await showDialog<void>(
                                                context: dialogCtx,
                                                builder: (c) => AlertDialog(
                                                  title: Row(
                                                    children: [
                                                      const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                                                      const SizedBox(width: 8),
                                                      Text(l10n.profileActiveQuizTitle),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    l10n.profileResetClassQuizBlocked,
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.profileBtnGotIt)),
                                                  ],
                                                ),
                                              );
                                            }
                                            return;
                                          }
                                        } catch (_) {
                                          // Jika pemeriksaan gagal / offline, blokir reset kelas demi keselamatan pengerjaan kuis
                                          if (dialogCtx.mounted) {
                                            await showDialog<void>(
                                              context: dialogCtx,
                                              builder: (c) => AlertDialog(
                                                title: Row(
                                                  children: [
                                                    const Icon(Icons.wifi_off_rounded, color: AppTheme.warning),
                                                    const SizedBox(width: 8),
                                                    Text(l10n.profileOfflineTitle),
                                                  ],
                                                ),
                                                content: Text(
                                                  l10n.profileResetClassOfflineBlocked,
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.profileBtnGotIt)),
                                                ],
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      // Konfirmasi reset kelas aktif
                                      if (!dialogCtx.mounted) return;
                                      final confirm = await showDialog<bool>(
                                        context: dialogCtx,
                                        builder: (c) => AlertDialog(
                                          title: Text(l10n.profileResetClassConfirmTitle),
                                          content: Text(l10n.profileResetClassConfirmBody),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.btnCancel)),
                                            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.profileBtnReset)),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                                        await classProvider.selectClass(null);
                                        MainShell.activeClassId = null;
                                        outerMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(resetSuccessText),
                                            backgroundColor: AppTheme.success,
                                          ),
                                        );
                                        if (mounted) {
                                          try {
                                            context.go(AppConstants.dashboardRoute);
                                          } catch (_) {}
                                        }
                                      }
                                    },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.restart_alt_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.profileResetClassBtn,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(l10n.btnClose),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSignOut() async {
    if (_isLoggingOut) return;

    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    String? quizWarning;

    if (uid != null && uid.isNotEmpty) {
      try {
        final hasActive = await _attemptRepository.hasActiveOngoingAttempt(userId: uid);
        if (hasActive) {
          quizWarning = l10n.profileLogoutQuizWarning;
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          // Aturan rules menolak pemeriksaan, jangan tampilkan peringatan offline palsu
        } else {
          quizWarning = l10n.profileLogoutOfflineWarning;
        }
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDialogLoggingOut = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return PopScope(
              canPop: !isDialogLoggingOut,
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      quizWarning != null ? Icons.warning_amber_rounded : Icons.logout_rounded,
                      color: quizWarning != null ? AppTheme.warning : AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.profileLogoutConfirmTitle),
                  ],
                ),
                content: Column(
                  mainAxisSize: vitalityColumn(quizWarning, l10n),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quizWarning != null) ...[
                      Text(
                        quizWarning,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      l10n.profileLogoutConfirmBody,
                      style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoggingOut
                        ? null
                        : () {
                            if (dialogContext.mounted) Navigator.pop(dialogContext, false);
                          },
                    child: Text(l10n.btnCancel),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    onPressed: isDialogLoggingOut
                        ? null
                        : () {
                            setDialogState(() => isDialogLoggingOut = true);
                            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                          },
                    child: isDialogLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.btnLogout),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      try {
        await context.read<ClassProvider>().clear();
      } catch (_) {}
      MainShell.activeClassId = null;
      await authProvider.signOut();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.profileLogoutFailed(e.toString())),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  static MainAxisSize vitalityColumn(String? quizWarning, AppLocalizations l10n) {
    return MainAxisSize.min;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    final appUser = authProvider.appUser;

    final displayName = appUser?.name ?? firebaseUser?.displayName ?? l10n.profileDefaultName;
    final email = firebaseUser?.email ?? appUser?.email ?? '-';
    final accountType = appUser?.accountType.value ?? 'UMUM';
    final role = appUser?.role.value ?? 'USER';
    final isVerified = firebaseUser?.emailVerified ?? false;

    final String? identityLabel;
    if (appUser == null) {
      identityLabel = null;
    } else if (appUser.accountType == AccountType.mahasiswa) {
      identityLabel = 'NIM';
    } else if (appUser.accountType == AccountType.dosen) {
      identityLabel = 'NIP';
    } else {
      identityLabel = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.btnLogout,
            onPressed: _isLoggingOut ? null : _confirmAndSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary.withAlpha(30),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: l10n.profileEditNameTooltip,
                        onPressed: () => _showEditNameDialog(displayName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(l10n.profileBadgeType(accountType), AppTheme.primary),
                      _buildBadge(l10n.profileBadgeRole(role), AppTheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                if (identityLabel != null) ...[
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(l10n.profileIdentityTitle(identityLabel)),
                    subtitle: Text(
                      _isLoadingIdentity
                          ? l10n.labelLoading
                          : (_nimNip != null && _nimNip!.isNotEmpty
                              ? _nimNip!
                              : l10n.profileIdentityNotSet),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditNimDialog(identityLabel!),
                    ),
                  ),
                  const Divider(height: 1),
                ],
                if (authProvider.hasPasswordProvider) ...[
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: Text(l10n.profileSecurityTitle),
                    subtitle: Text(l10n.profileSecuritySubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: Text(l10n.profileCacheTitle),
                  subtitle: Text(l10n.profileCacheSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: _showCacheManagementDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: Text(l10n.profileEmailVerificationTitle),
                  subtitle: Text(isVerified ? l10n.profileEmailVerified : l10n.profileEmailPending),
                  trailing: Icon(
                    isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: isVerified ? AppTheme.success : AppTheme.warning,
                    size: 20,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    authProvider.isRoleOutOfSync ? Icons.sync_problem_rounded : Icons.sync_rounded,
                    color: authProvider.isRoleOutOfSync ? AppTheme.warning : null,
                  ),
                  title: Text(l10n.profileSyncTitle),
                  subtitle: Text(
                    authProvider.isRoleOutOfSync
                        ? l10n.profileSyncOutOfSync(
                            appUser?.claimsRole?.value ?? 'USER',
                            appUser?.role.value ?? 'USER',
                          )
                        : l10n.profileSyncUpToDate,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: l10n.profileRefreshSessionTooltip,
                    onPressed: () async {
                      await authProvider.refreshSession();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.profileSessionRefreshed),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoggingOut ? null : _confirmAndSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.logout_rounded, size: 20),
            label: Text(
              _isLoggingOut ? l10n.profileLoggingOut : l10n.profileLogoutBtn,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function({required String currentPassword, required String newPassword}) onSave;
  final Future<void> Function(String email) onResetPassword;
  final String? userEmail;

  const _ChangePasswordDialog({
    required this.onSave,
    required this.onResetPassword,
    this.userEmail,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const int _newPasswordMinLength = 8;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _serverError;

  @override
  void dispose() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(l10n.profileChangePasswordTitle),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileChangePasswordNote(_newPasswordMinLength),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (_serverError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _serverError!,
                              style: const TextStyle(fontSize: 12, color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: l10n.profileCurrentPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.profileCurrentPasswordRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: l10n.profileNewPasswordLabel(_newPasswordMinLength),
                      prefixIcon: const Icon(Icons.password_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.profileNewPasswordRequired;
                      if (v.length < _newPasswordMinLength) {
                        return l10n.profileNewPasswordMinError(_newPasswordMinLength);
                      }
                      if (v == _currentPasswordController.text) {
                        return l10n.profileNewPasswordSameAsCurrent;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: l10n.profileConfirmNewPasswordLabel,
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l10n.profileConfirmPasswordRequired;
                      if (v != _newPasswordController.text) return l10n.validPasswordMismatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                final email = widget.userEmail!;
                                await widget.onResetPassword(email);
                                if (context.mounted) Navigator.pop(context, false);
                              },
                        child: Text(l10n.profileForgotCurrentPasswordLink, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() {
                      _isSubmitting = true;
                      _serverError = null;
                    });

                    try {
                      await widget.onSave(
                        currentPassword: _currentPasswordController.text,
                        newPassword: _newPasswordController.text,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                          if (e is FirebaseAuthException) {
                            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                              _serverError = l10n.profileCurrentPasswordWrong;
                            } else {
                              _serverError = AuthErrorLocalization.fromCode(
                                l10n,
                                e.code,
                                fallbackMessage: AuthService.translateError(e),
                              );
                            }
                          } else {
                            _serverError = l10n.profilePasswordUpdateFail(e.toString());
                          }
                        });
                      }
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.profileSavePasswordBtn),
          ),
        ],
      ),
    );
  }
}
