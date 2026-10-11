import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'routing/app_router.dart';
import 'services/auth_provider.dart';
import 'services/class_provider.dart';
import 'services/locale_provider.dart';

class FarleanApp extends StatefulWidget {
  final AuthProvider? authProvider;
  final ClassProvider? classProvider;
  final LocaleProvider? localeProvider;

  const FarleanApp({
    super.key,
    this.authProvider,
    this.classProvider,
    this.localeProvider,
  });

  @override
  State<FarleanApp> createState() => _FarleanAppState();
}

class _FarleanAppState extends State<FarleanApp> {
  late final AuthProvider _authProvider;
  late final ClassProvider _classProvider;
  late final LocaleProvider _localeProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider ?? AuthProvider();
    _classProvider = widget.classProvider ?? ClassProvider();
    _localeProvider = widget.localeProvider ?? LocaleProvider();
    _localeProvider.load(); // non-blocking; selama fase 2A selalu id
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ClassProvider>.value(value: _classProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: _localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _router,
          // Locale dari provider (dikunci ke 'id' selama fase migrasi 2A).
          // DevicePreview.locale tetap bisa override saat development.
          locale: DevicePreview.locale(context) ?? localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: DevicePreview.appBuilder,
        ),
      ),
    );
  }
}
