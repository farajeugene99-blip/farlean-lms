import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'services/auth_provider.dart';

class FarleanApp extends StatefulWidget {
  final AuthProvider? authProvider;

  const FarleanApp({super.key, this.authProvider});

  @override
  State<FarleanApp> createState() => _FarleanAppState();
}

class _FarleanAppState extends State<FarleanApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider ?? AuthProvider();
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

