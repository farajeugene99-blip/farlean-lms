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

  @override
  String get profileScreenTitle => 'User Profile';

  @override
  String get profileDefaultName => 'Farlean User';

  @override
  String get profileEditNameTooltip => 'Edit Name';

  @override
  String profileBadgeType(String type) {
    return 'Type: $type';
  }

  @override
  String profileBadgeRole(String role) {
    return 'Role: $role';
  }

  @override
  String get profileEditNameTitle => 'Edit Full Name';

  @override
  String profileNameMaxLength(int max) {
    return 'Maximum $max characters';
  }

  @override
  String profileNameUpdateFail(String detail) {
    return 'Failed to update name: $detail';
  }

  @override
  String get profileNameUpdated => 'Profile name successfully updated.';

  @override
  String profileIdentityTitle(String label) {
    return 'ID Number ($label)';
  }

  @override
  String get profileIdentityPrivacyNote =>
      'This data is stored in an isolated private/identity sub-collection and can only be accessed by you and Admins. Your class instructors only view it via official gradebooks, not from the app.';

  @override
  String profileIdentityRequired(String label) {
    return '$label is required';
  }

  @override
  String profileIdentitySaveFail(String label, String detail) {
    return 'Failed to save $label: $detail';
  }

  @override
  String profileIdentitySaved(String label) {
    return '$label successfully saved to private identity.';
  }

  @override
  String get profileIdentityNotSet => 'Not filled (Click to add)';

  @override
  String get profileSecurityTitle => 'Security & Password';

  @override
  String get profileSecuritySubtitle =>
      'Change account password for this device';

  @override
  String get profileCacheTitle => 'Storage & Cache';

  @override
  String get profileCacheSubtitle =>
      'Manage temporary memory and active class selection';

  @override
  String get profileEmailVerificationTitle => 'Email Verification Status';

  @override
  String get profileEmailVerified => 'Email Verified';

  @override
  String get profileEmailPending => 'Pending Verification';

  @override
  String get profileSyncTitle => 'Session & Role Sync';

  @override
  String profileSyncOutOfSync(String claimsRole, String profileRole) {
    return 'Role not in sync (Token: $claimsRole vs Profile: $profileRole). Tap to refresh.';
  }

  @override
  String get profileSyncUpToDate =>
      'Session and token permissions are up to date.';

  @override
  String get profileRefreshSessionTooltip => 'Refresh Session';

  @override
  String get profileSessionRefreshed =>
      'Session and access token successfully refreshed.';

  @override
  String get profileLogoutBtn => 'Sign Out of Account';

  @override
  String get profileLoggingOut => 'Signing Out...';

  @override
  String get profileLogoutConfirmTitle => 'Sign Out of Account?';

  @override
  String get profileLogoutConfirmBody =>
      'Are you sure you want to sign out of Farlean LMS on this device?';

  @override
  String get profileLogoutQuizWarning =>
      'Warning: You have a quiz in progress. If you sign out now, your quiz attempt may be interrupted and unsaved answers may be lost.';

  @override
  String get profileLogoutOfflineWarning =>
      'Cannot verify quiz status because the device is offline. If you are taking a quiz, unsynchronized answers may be lost.';

  @override
  String profileLogoutFailed(String detail) {
    return 'Failed to sign out: $detail';
  }

  @override
  String get profileChangePasswordTitle => 'Change Password';

  @override
  String profileChangePasswordNote(int min) {
    return 'For your account\'s security, enter your current password and create a new password of at least $min characters.';
  }

  @override
  String get profileCurrentPasswordLabel => 'Current Password';

  @override
  String get profileCurrentPasswordRequired => 'Current password is required';

  @override
  String profileNewPasswordLabel(int min) {
    return 'New Password (Min. $min Characters)';
  }

  @override
  String get profileNewPasswordRequired => 'New password is required';

  @override
  String profileNewPasswordMinError(int min) {
    return 'New password must be at least $min characters.';
  }

  @override
  String get profileNewPasswordSameAsCurrent =>
      'New password cannot be the same as current password.';

  @override
  String get profileConfirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get profileConfirmPasswordRequired => 'Confirm password is required';

  @override
  String get profileForgotCurrentPasswordLink => 'Forgot current password?';

  @override
  String get profileSavePasswordBtn => 'Save Password';

  @override
  String get profileCurrentPasswordWrong =>
      'The current password you entered is incorrect.';

  @override
  String profilePasswordUpdateFail(String detail) {
    return 'Failed to update password: $detail';
  }

  @override
  String get profilePwUpdated =>
      'Password successfully updated for this account.';

  @override
  String get profileCacheDesc =>
      'Safely manage temporary image memory and active class preferences on this device.';

  @override
  String get profileCacheEmpty => '0 KB (no images loaded in memory yet)';

  @override
  String profileCacheStats(int count, String kb) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$kb KB ($count images active in memory)',
      one: '$kb KB (1 image active in memory)',
    );
    return '$_temp0';
  }

  @override
  String get profileCacheImageSection => 'Image Cache in Memory (RAM)';

  @override
  String get profileCacheImageNote =>
      'Note: Memory cache holds images from materials currently opened. Clearing it is safe; images will be re-downloaded when viewed.';

  @override
  String get profileCacheClearBtn => 'Clear RAM Image Cache';

  @override
  String get profileCacheCleared => 'Image memory cache successfully cleared.';

  @override
  String get profileClassSavedSection => 'Saved Active Class Preference';

  @override
  String get profileClassNoneSelected => 'No active class selected yet';

  @override
  String get profileClassResetNote =>
      'Resetting active class will redirect you to Home to re-select a class.';

  @override
  String get profileActiveQuizTitle => 'Quiz In Progress';

  @override
  String get profileResetClassQuizBlocked =>
      'Cannot reset active class: You have a quiz in progress. Finish or submit the quiz first before resetting class.';

  @override
  String get profileBtnGotIt => 'Understood';

  @override
  String get profileOfflineTitle => 'Device Offline';

  @override
  String get profileResetClassOfflineBlocked =>
      'Cannot verify quiz status because the device is offline. For your quiz answers\' safety, resetting active class is deferred until reconnected.';

  @override
  String get profileResetClassConfirmTitle => 'Reset Active Class?';

  @override
  String get profileResetClassConfirmBody =>
      'You will be redirected to Home to re-select a learning class.';

  @override
  String get profileBtnReset => 'Reset';

  @override
  String get profileResetClassBtn => 'Reset Active Class';

  @override
  String get profileResetClassDone =>
      'Active class selection successfully reset.';
}
