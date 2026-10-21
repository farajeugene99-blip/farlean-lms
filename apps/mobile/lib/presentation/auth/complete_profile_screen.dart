import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/app_user.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserRepository? userRepository;

  const CompleteProfileScreen({super.key, this.userRepository});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  late final UserRepository _userRepository;

  bool _termsAccepted = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? UserRepository();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.firebaseUser;
    final appUser = authProvider.appUser;

    _nameController.text = appUser?.name ?? user?.displayName ?? '';

    if (user != null) {
      try {
        final existingNim = await _userRepository.getPrivateIdentity(user.uid);
        if (existingNim != null && existingNim.isNotEmpty) {
          _nimController.text = existingNim;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.completeProfileTermsRequired),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completeProfile(
      name: _nameController.text.trim(),
      nimNip: _nimController.text.trim().isNotEmpty ? _nimController.text.trim() : null,
    );

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.error,
        ),
      );
    } else if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.completeProfileSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    final appUser = authProvider.appUser;
    final isLoading = authProvider.isLoading || _isLoadingInitial;

    final accountType = appUser?.accountType ?? AccountType.umum;
    final isStudentOrTeacher = accountType == AccountType.mahasiswa || accountType == AccountType.dosen;
    final identityLabel = accountType == AccountType.dosen ? 'NIP' : 'NIM';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.completeProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.authBtnSwitchAccount,
            onPressed: isLoading ? null : () => authProvider.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingInitial
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Title
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.manage_accounts_rounded,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.completeProfileTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.completeProfileSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondaryColor),
                      ),
                      const SizedBox(height: 24),

                      // Email Terverifikasi (Read-Only)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: AppTheme.success, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.completeProfileEmailLabel,
                                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                                  ),
                                  Text(
                                    firebaseUser?.email ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Badge Klasifikasi Akun
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined, color: AppTheme.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.completeProfileAccountType,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primary),
                                  ),
                                  Text(
                                    l10n.profileBadgeType(accountType.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Field Nama Lengkap
                      TextFormField(
                        controller: _nameController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: l10n.completeProfileNameLabel,
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.completeProfileNameRequired;
                          }
                          if (v.trim().length > 100) {
                            return l10n.profileNameMaxLength(100);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field NIM / NIP kondisional
                      if (isStudentOrTeacher) ...[
                        TextFormField(
                          controller: _nimController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: identityLabel == 'NIP'
                                ? 'NIP (Nomor Induk Pegawai)'
                                : 'NIM (Nomor Induk Mahasiswa)',
                            hintText: l10n.completeProfileIdentityHint(identityLabel),
                            prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                            helperText: l10n.profileIdentityPrivacyNote,
                            helperMaxLines: 2,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.completeProfileIdentityRequired(identityLabel);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Checkbox Syarat & Ketentuan
                      Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _termsAccepted,
                          onChanged: isLoading ? null : (val) => setState(() => _termsAccepted = val ?? false),
                          title: Text(
                            l10n.completeProfileTermsCheckbox,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan & Lanjutkan
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.completeProfileSubmitBtn,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Tombol Ganti Akun / Keluar (UX Safety Net)
                      Center(
                        child: TextButton.icon(
                          onPressed: isLoading ? null : () => authProvider.signOut(),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(l10n.authBtnSwitchAccount),
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
