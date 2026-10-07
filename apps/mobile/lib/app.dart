import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'services/auth_provider.dart';
import 'services/class_provider.dart';

class FarleanApp extends StatefulWidget {
  final AuthProvider? authProvider;
  final ClassProvider? classProvider;

  const FarleanApp({super.key, this.authProvider, this.classProvider});

  @override
  State<FarleanApp> createState() => _FarleanAppState();
}

class _FarleanAppState extends State<FarleanApp> {
  late final AuthProvider _authProvider;
  late final ClassProvider _classProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider ?? AuthProvider();
    _classProvider = widget.classProvider ?? ClassProvider();
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ClassProvider>.value(value: _classProvider),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        // Konfigurasi Localization termasuk delegate FlutterQuill
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id'),
          Locale('en'),
        ],
        // Konfigurasi frame DevicePreview:
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
      ),
    );
  }
}