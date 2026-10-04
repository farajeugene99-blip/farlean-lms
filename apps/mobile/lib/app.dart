import 'package:flutter/material.dart';
import 'core/config/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class FarleanApp extends StatelessWidget {
  const FarleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
