import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/class_provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static String? activeClassId;

  int _calculateSelectedIndex(BuildContext context) {
    String location = '';
    String? queryClassId;
    try {
      final uri = GoRouterState.of(context).uri;
      location = uri.path;
      queryClassId = uri.queryParameters['classId'];
    } catch (_) {}

    if (queryClassId != null && queryClassId.trim().isNotEmpty && queryClassId.trim() != 'default_class') {
      activeClassId = queryClassId.trim();
    }
    if (location.startsWith(AppConstants.dashboardRoute)) return 0;
    if (location.startsWith(AppConstants.materiRoute)) return 1;
    if (location.startsWith(AppConstants.aiRoute)) return 2;
    if (location.startsWith(AppConstants.diskusiRoute)) return 3;
    if (location.startsWith(AppConstants.profileRoute)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppConstants.dashboardRoute);
        break;
      case 1:
        // Smart Tab: jika user punya 1 kelas atau ada kelas yang terpilih, buka langsung
        final classProvider = context.read<ClassProvider>();
        final targetClassId = classProvider.selectedClassId ??
            (classProvider.hasSingleClass ? classProvider.singleClassId : null) ??
            activeClassId;

        if (targetClassId != null && targetClassId.isNotEmpty && targetClassId != 'default_class') {
          context.go('${AppConstants.materiRoute}?classId=$targetClassId');
        } else {
          // Arahkan ke Beranda agar pengguna memilih kelas terlebih dahulu
          final l10n = AppLocalizations.of(context);
          context.go(AppConstants.dashboardRoute);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.navSelectClassFirst),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
      case 2:
        context.go(AppConstants.aiRoute);
        break;
      case 3:
        // Smart Tab: jika user punya 1 kelas atau ada kelas yang terpilih, teruskan classId
        final classProvider = context.read<ClassProvider>();
        final targetClassId = classProvider.selectedClassId ??
            (classProvider.hasSingleClass ? classProvider.singleClassId : null) ??
            activeClassId;

        if (targetClassId != null && targetClassId.isNotEmpty && targetClassId != 'default_class') {
          context.go('${AppConstants.diskusiRoute}?classId=$targetClassId');
        } else {
          context.go(AppConstants.diskusiRoute);
        }
        break;
      case 4:
        context.go(AppConstants.profileRoute);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                selectedIndex: selectedIndex,
                icon: Icons.grid_view_rounded,
                label: l10n.navHome,
              ),
              _buildNavItem(
                context,
                index: 1,
                selectedIndex: selectedIndex,
                icon: Icons.menu_book_rounded,
                label: l10n.navMaterials,
              ),
              _buildNavItem(
                context,
                index: 2,
                selectedIndex: selectedIndex,
                icon: Icons.auto_awesome_rounded,
                label: l10n.navAiTutor,
                isHighlight: true,
              ),
              _buildNavItem(
                context,
                index: 3,
                selectedIndex: selectedIndex,
                icon: Icons.forum_rounded,
                label: l10n.navDiscussion,
              ),
              _buildNavItem(
                context,
                index: 4,
                selectedIndex: selectedIndex,
                icon: Icons.person_rounded,
                label: l10n.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
    bool isHighlight = false,
  }) {
    final isSelected = index == selectedIndex;
    final primaryColor = isHighlight ? AppTheme.secondary : AppTheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? primaryColor : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
