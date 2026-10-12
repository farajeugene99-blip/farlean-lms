import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/classroom.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../common/loading_indicator.dart';
import 'dashboard_profile_error_localization.dart';
import 'main_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MeetingRepository _meetingRepository;

  @override
  void initState() {
    super.initState();
    _meetingRepository = MeetingRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadClasses();
    });
  }

  Future<void> _showCreateClassDialog() async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dashboardCreateClassTitle),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.dashboardClassNameLabel,
                      hintText: l10n.dashboardClassNameHint,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return l10n.dashboardClassNameMinLength;
                      }
                      if (v.trim().length > 100) {
                        return l10n.dashboardClassNameMaxLength;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.dashboardClassDescLabel,
                      hintText: l10n.dashboardClassDescHint,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.dashboardClassCodeLabel,
                      hintText: l10n.dashboardClassCodeHint,
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final clean = v.trim().toUpperCase();
                        if (clean.length < 6 || clean.length > 12) {
                          return l10n.dashboardClassCodeLength;
                        }
                        if (!RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) {
                          return l10n.dashboardClassCodeAlphanumeric;
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
              try {
                final classProvider = context.read<ClassProvider>();
                await classProvider.createClass(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  customCode: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.dashboardCreateClassBtn),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      descController.dispose();
      codeController.dispose();
    });

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dashboardClassCreatedSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();

    // 1. Jika profil sedang dimuat, tampilkan loading indikator
    if (authProvider.profileStatus == ProfileStatus.loading) {
      return Scaffold(
        body: LoadingIndicator(message: l10n.dashboardLoadingProfile),
      );
    }

    // 2. Jika profil gagal dimuat, tampilkan pesan error eksplisit tanpa merender role palsu
    if (authProvider.profileStatus == ProfileStatus.error) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.appName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 56,
                  color: AppTheme.error.withAlpha(180),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.dashboardProfileErrorTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  DashboardProfileErrorLocalization.message(authProvider, l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await context.read<ClassProvider>().clear();
                        } catch (_) {}
                        MainShell.activeClassId = null;
                        await authProvider.signOut();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(110, 44),
                      ),
                      child: Text(l10n.btnLogout),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => authProvider.retryLoadSession(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(130, 44),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.labelRetry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final classProvider = context.watch<ClassProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          if (isStaff)
            IconButton(
              icon: const Icon(Icons.add_business_rounded),
              tooltip: l10n.dashboardCreateClassTitle,
              onPressed: _showCreateClassDialog,
            ),
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: l10n.meetingJoinClassBtn,
            onPressed: () => context.push(AppConstants.joinClassRoute),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: classProvider.isLoading && classProvider.allClasses.isEmpty
          ? LoadingIndicator(message: l10n.dashboardLoadingClasses)
          : RefreshIndicator(
              onRefresh: () => classProvider.loadClasses(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Banner Card
                  _buildWelcomeCard(context, classProvider),
                  if (authProvider.isRoleOutOfSync) ...[
                    const SizedBox(height: 12),
                    _buildSyncWarningBanner(context, authProvider),
                  ],
                  const SizedBox(height: 20),

                  // Section: Kelas yang Dikelola (Dosen / Pengajar)
                  if (isStaff) ...[
                    Text(
                      l10n.dashboardManagedClassesSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (classProvider.ownedClasses.isEmpty)
                      _buildEmptyOwnedCard(context)
                    else
                      ...classProvider.ownedClasses.map((c) => _buildClassCard(context, c, isOwner: true)),
                    const SizedBox(height: 24),
                  ],

                  // Section: Kelas yang Diikuti (Mahasiswa / Anggota)
                  Row(
                    children: [
                      Text(
                        l10n.dashboardJoinedClassesSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (classProvider.joinedClasses.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => context.push(AppConstants.joinClassRoute),
                          icon: const Icon(Icons.add_link_rounded, size: 16),
                          label: Text(l10n.dashboardJoinCodeBtn, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (classProvider.joinedClasses.isEmpty)
                    _buildEmptyJoinedCard(context)
                  else
                    ...classProvider.joinedClasses.map((c) => _buildClassCard(context, c, isOwner: false)),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, ClassProvider classProvider) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.dashboardWelcomeBadge,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.dashboardWelcomeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboardWelcomeBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncWarningBanner(BuildContext context, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context);
    final appUser = authProvider.appUser!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: AppTheme.warning, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardRoleOutOfSyncTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.warning),
                ),
                Text(
                  l10n.dashboardRoleOutOfSyncBody(
                    appUser.claimsRole?.value ?? "USER",
                    appUser.role.value,
                  ),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => authProvider.refreshSession(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 32),
            ),
            child: Text(l10n.dashboardRefreshRoleBtn, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, Classroom classroom, {required bool isOwner}) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOwner ? Icons.workspace_premium_rounded : Icons.school_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (classroom.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          classroom.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(classroom.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (classroom.code.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: classroom.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.dashboardCodeCopied(classroom.code)), duration: const Duration(seconds: 1)),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key_rounded, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            classroom.code,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                FutureBuilder<int>(
                  future: _meetingRepository.getMeetingCount(classroom.id, isStaff: isOwner),
                  builder: (context, snapshot) {
                    final count = snapshot.data;
                    if (count == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.dashboardMeetingCount(count),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final classProvider = context.read<ClassProvider>();
                    classProvider.selectClass(classroom.id);
                    context.push('/classes/${classroom.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(110, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(isOwner ? l10n.dashboardManageClassBtn : l10n.dashboardOpenClassBtn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOwnedCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.add_business_outlined, size: 40, color: AppTheme.textSecondary.withAlpha(128)),
            const SizedBox(height: 8),
            Text(l10n.dashboardEmptyOwnedTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l10n.dashboardEmptyOwnedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showCreateClassDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.dashboardCreateFirstClassBtn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyJoinedCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.group_add_outlined, size: 40, color: AppTheme.textSecondary.withAlpha(128)),
            const SizedBox(height: 8),
            Text(l10n.dashboardEmptyJoinedTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l10n.dashboardEmptyJoinedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push(AppConstants.joinClassRoute),
              icon: const Icon(Icons.key_rounded, size: 16),
              label: Text(l10n.meetingJoinClassBtn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isArchived = status.toLowerCase() == 'archived';
    final isPublished = status.toLowerCase() == 'published' || status.toLowerCase() == 'active';
    final color = isPublished
        ? AppTheme.success
        : (isArchived ? AppTheme.textSecondary : AppTheme.warning);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
