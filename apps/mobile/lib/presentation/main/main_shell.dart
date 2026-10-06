import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static String? activeClassId;

  int _calculateSelectedIndex(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final String location = uri.path;
    final queryClassId = uri.queryParameters['classId'];
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
        if (activeClassId != null && activeClassId!.isNotEmpty) {
          context.go('${AppConstants.materiRoute}?classId=$activeClassId');
        } else {
          context.go(AppConstants.materiRoute);
        }
        break;
      case 2:
        context.go(AppConstants.aiRoute);
        break;
      case 3:
        context.go(AppConstants.diskusiRoute);
        break;
      case 4:
        context.go(AppConstants.profileRoute);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                label: 'Beranda',
              ),
              _buildNavItem(
                context,
                index: 1,
                selectedIndex: selectedIndex,
                icon: Icons.menu_book_rounded,
                label: 'Materi',
                isFuture: true,
              ),
              _buildNavItem(
                context,
                index: 2,
                selectedIndex: selectedIndex,
                icon: Icons.auto_awesome_rounded,
                label: 'AI Tutor',
                isFuture: true,
                isHighlight: true,
              ),
              _buildNavItem(
                context,
                index: 3,
                selectedIndex: selectedIndex,
                icon: Icons.forum_rounded,
                label: 'Diskusi',
                isFuture: true,
              ),
              _buildNavItem(
                context,
                index: 4,
                selectedIndex: selectedIndex,
                icon: Icons.person_rounded,
                label: 'Profil',
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
    bool isFuture = false,
    bool isHighlight = false,
  }) {
    final isSelected = index == selectedIndex;
    final primaryColor = isHighlight ? AppTheme.secondary : AppTheme.primary;

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? primaryColor : AppTheme.textSecondary,
                ),
                if (isFuture)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
