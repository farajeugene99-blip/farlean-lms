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

  @override
  String get authLoginTitle => 'Sign in to Farlean LMS';

  @override
  String get authLoginSubtitle => 'Learning and Classroom Management Platform';

  @override
  String get authFieldEmail => 'Campus / Personal Email';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authForgotPasswordLink => 'Forgot Password?';

  @override
  String get authBtnLogin => 'Sign In';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authBtnRegisterLink => 'Register Now';

  @override
  String get authAppBarRegister => 'Create New Account';

  @override
  String get authRegisterTitle => 'Register for Farlean LMS';

  @override
  String get authRegisterSubtitle =>
      'Use your campus email to automatically get the STUDENT / LECTURER type.';

  @override
  String get authFieldName => 'Full Name';

  @override
  String get authFieldEmailPlain => 'Email';

  @override
  String authFieldPasswordMin(int min) {
    return 'Password (min. $min characters)';
  }

  @override
  String get authFieldPasswordConfirm => 'Confirm Password';

  @override
  String get authBtnRegisterSubmit => 'Register';

  @override
  String get authForgotAppBar => 'Forgot Password';

  @override
  String get authForgotHeading => 'Reset Password';

  @override
  String get authForgotBody =>
      'Enter your registered email address to receive a password recovery link.';

  @override
  String get authFieldEmailAddress => 'Email Address';

  @override
  String get authBtnSendReset => 'Send Recovery Link';

  @override
  String get authResetSentMsg =>
      'Password reset link has been sent to your email.';

  @override
  String get authVerifyAppBar => 'Verify Email';

  @override
  String get authVerifyHeading => 'Check Your Email';

  @override
  String authVerifyBody(String email) {
    return 'We have sent a verification link to your email ($email). Your account cannot access classes until the email is verified.';
  }

  @override
  String get authVerifyNotYet =>
      'Email not yet verified. Please click the link in your email first.';

  @override
  String get authBtnVerifyCheck => 'I\'ve Verified';

  @override
  String get authVerifyResent =>
      'Verification link has been resent to your email.';

  @override
  String get authBtnResendEmail => 'Resend Email';

  @override
  String get authBtnSwitchAccount => 'Sign Out / Switch Account';

  @override
  String get validEmailRequired => 'Email is required';

  @override
  String get validEmailFormat => 'Invalid email format';

  @override
  String get validPasswordRequired => 'Password is required';

  @override
  String validPasswordMin(int min) {
    return 'Minimum $min characters';
  }

  @override
  String get validNameRequired => 'Name is required';

  @override
  String get validPasswordMismatch => 'Passwords do not match';

  @override
  String get authErrUserNotFound => 'Account with this email was not found.';

  @override
  String get authErrWrongPassword => 'The password you entered is incorrect.';

  @override
  String get authErrInvalidCredential => 'Incorrect email or password.';

  @override
  String get authErrEmailInUse =>
      'This email is already registered. Please use Sign In.';

  @override
  String get authErrInvalidEmail => 'Invalid email address format.';

  @override
  String get authErrWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get authErrTooManyRequests =>
      'Too many failed attempts. Please wait a moment.';

  @override
  String get authErrNetworkFailed =>
      'Connection to Firebase failed. Make sure your network or Firebase Emulator is running and reachable.';

  @override
  String get authErrRequiresRecentLogin =>
      'Your session has expired. Please sign out and sign in again before changing your password.';

  @override
  String get authErrUserDisabled =>
      'This account has been disabled by an administrator.';

  @override
  String get authErrUnknown =>
      'An authentication error occurred. Please try again.';
}
