// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Farlean LMS';

  @override
  String get navHome => 'Home';

  @override
  String get navClass => 'Classes';

  @override
  String get navProfile => 'Profile';

  @override
  String get btnSave => 'Save';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnConfirm => 'Confirm';

  @override
  String get btnClose => 'Close';

  @override
  String get btnLogout => 'Logout';

  @override
  String get btnChangePassword => 'Change Password';

  @override
  String get labelLoading => 'Loading...';

  @override
  String get labelError => 'An error occurred';

  @override
  String get labelRetry => 'Retry';

  @override
  String labelVersion(int version) {
    return 'Version $version';
  }

  @override
  String get labelLastSaved => 'Last saved';

  @override
  String get labelWib => 'WIB';
}
