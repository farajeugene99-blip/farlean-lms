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
import 'services/theme_provider.dart';

class FarleanApp extends StatefulWidget {
  final AuthProvider? authProvider;
  final ClassProvider? classProvider;
  final LocaleProvider? localeProvider;
  final ThemeProvider? themeProvider;

  const FarleanApp({
    super.key,
    this.authProvider,
    this.classProvider,
    this.localeProvider,
    this.themeProvider,
  });

  @override
  State<FarleanApp> createState() => _FarleanAppState();
}

class _FarleanAppState extends State<FarleanApp> {
  late final AuthProvider _authProvider;
  late final ClassProvider _classProvider;
  late final LocaleProvider _localeProvider;
  late final ThemeProvider _themeProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider ?? AuthProvider();
    _classProvider = widget.classProvider ?? ClassProvider();
    _localeProvider = widget.localeProvider ?? LocaleProvider();
    _themeProvider = widget.themeProvider ?? ThemeProvider();
    _localeProvider.load();
    _themeProvider.load();
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ClassProvider>.value(value: _classProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: _localeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
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
