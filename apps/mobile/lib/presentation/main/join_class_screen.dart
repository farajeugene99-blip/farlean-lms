import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/class_provider.dart';
import '../../services/join_class_service.dart';

class JoinClassScreen extends StatefulWidget {
  final JoinClassService? joinClassService;

  const JoinClassScreen({super.key, this.joinClassService});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late final JoinClassService _joinClassService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _joinClassService = widget.joinClassService ?? JoinClassService();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _joinClassService.joinClass(_codeController.text);

      if (!mounted) return;
      setState(() => _isLoading = false);

      await _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showResultDialog(JoinClassResult result) async {
    final l10n = AppLocalizations.of(context);
    final isActive = result.isActive;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isActive ? AppTheme.success : AppTheme.warning,
            ),
            const SizedBox(width: 8),
            Text(isActive ? l10n.joinClassSuccessTitle : l10n.joinClassPendingTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.className,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(result.message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.success : AppTheme.warning).withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.joinClassStatusPrefix(result.status.value.toUpperCase()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.success : AppTheme.warning,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (result.classId.isNotEmpty) {
                final classProvider = context.read<ClassProvider>();
                try {
                  await classProvider.loadClasses();
                  if (isActive) {
                    await classProvider.selectClass(result.classId);
                    if (mounted) {
                      context.go('${AppConstants.materiRoute}?classId=${result.classId}');
                    }
                  } else {
                    if (mounted) {
                      context.go(AppConstants.dashboardRoute);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.joinClassSyncFailed(e.toString())),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    context.go(AppConstants.dashboardRoute);
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(isActive ? l10n.joinClassOpenBtn : l10n.joinClassBackHomeBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinClassAppBarTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.joinClassHeading,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.joinClassDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.joinClassCodeLabel,
                    prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  ),
                  validator: JoinClassService.validateCodeFormat,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.joinClassSubmitBtn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
