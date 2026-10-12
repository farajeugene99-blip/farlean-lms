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

  @override
  String get meetingStatusDraft => 'Draft';

  @override
  String get meetingStatusScheduled => 'Scheduled';

  @override
  String get meetingStatusPublished => 'Published';

  @override
  String get meetingStatusArchived => 'Archived';

  @override
  String get meetingListTitle => 'Materials & Meetings';

  @override
  String get meetingSyncTooltip => 'Sync Publication Schedule';

  @override
  String get meetingRefreshTooltip => 'Refresh';

  @override
  String get meetingAddFab => 'Add Meeting';

  @override
  String get meetingErrorPermissionStaff =>
      'Access denied: You are not authorized to manage this class.';

  @override
  String get meetingErrorPermissionStudent =>
      'Access denied: You are not enrolled as an active member in this class. Please ensure you have joined and been approved.';

  @override
  String get meetingErrorNetwork =>
      'Server connection issue. Check your network connection or emulator.';

  @override
  String meetingErrorLoadFailed(String detail) {
    return 'Failed to load meetings list: $detail';
  }

  @override
  String get meetingSelectClassFirst =>
      'Select a valid class first to create a meeting.';

  @override
  String get meetingCreateTitle => 'Create New Meeting';

  @override
  String get meetingNumberLabel => 'Meeting Number';

  @override
  String get meetingNumberRequired => 'Meeting number is required';

  @override
  String get meetingNumberMustBePositive => 'Number must be > 0';

  @override
  String get meetingTitleLabel => 'Meeting Title';

  @override
  String get meetingTitleRequired => 'Meeting title is required';

  @override
  String get meetingSaveDraftBtn => 'Save Draft';

  @override
  String meetingCreateFailed(String detail) {
    return 'Failed: $detail';
  }

  @override
  String meetingActionFailed(String detail) {
    return 'Failed: $detail';
  }

  @override
  String meetingSyncScheduleSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count due scheduled meetings were successfully published.',
      one: '1 due scheduled meeting was successfully published.',
      zero: 'No due scheduled meetings at this time.',
    );
    return '$_temp0';
  }

  @override
  String meetingSyncFailed(String detail) {
    return 'Failed to sync schedule: $detail';
  }

  @override
  String get meetingNoClassTitle => 'Select Learning Class';

  @override
  String get meetingNoClassBody =>
      'You haven\'t selected a class. Please join with a class code or select a class from Home to view meetings.';

  @override
  String get meetingJoinClassBtn => 'Join Class';

  @override
  String get meetingClassLabel => 'Class:';

  @override
  String get meetingLoading => 'Loading meetings...';

  @override
  String get meetingEmptyTitle => 'No Meetings Yet';

  @override
  String get meetingEmptyStaffDesc =>
      'Create a new meeting to start uploading materials, pretest quizzes, and learning videos.';

  @override
  String get meetingEmptyStudentDesc =>
      'Instructor has not published any learning meetings for this class yet.';

  @override
  String get meetingCreateFirstBtn => 'Create First Meeting';

  @override
  String meetingCardNumber(int number) {
    return 'Meeting $number';
  }

  @override
  String meetingPublishAtLabel(String when) {
    return 'Published: $when';
  }

  @override
  String get meetingModulePretest => 'Pretest';

  @override
  String get meetingModuleMateri => 'Material';

  @override
  String get meetingModuleVideo => 'Video';

  @override
  String get meetingModulePosttest => 'Post Test';

  @override
  String get meetingDetailLoading => 'Loading meeting hub...';

  @override
  String get meetingDetailTitle => 'Meeting Details';

  @override
  String get meetingNotFound => 'Meeting not found.';

  @override
  String meetingLoadDetailFailed(String detail) {
    return 'Failed to load meeting details: $detail';
  }

  @override
  String meetingScheduledLockedNotice(String when) {
    return 'This meeting is still Scheduled. Content will be opened at $when.';
  }

  @override
  String get meetingScheduledFutureFallback => 'upcoming scheduled time';

  @override
  String get meetingPickScheduleDateTitle => 'Select Meeting Publication Date';

  @override
  String get meetingPickScheduleTimeTitle => 'Select Publication Time (WIB)';

  @override
  String get meetingScheduleMustBeFuture =>
      'Scheduled publication time must be in the future.';

  @override
  String meetingScheduledSuccess(String when) {
    return 'Meeting successfully scheduled to be published at $when.';
  }

  @override
  String meetingScheduleFailed(String detail) {
    return 'Failed to schedule meeting: $detail';
  }

  @override
  String meetingChangeStatusConfirmTitle(String status) {
    return 'Change Status to $status?';
  }

  @override
  String get meetingChangeStatusPublishBody =>
      'This meeting will be accessible to all active class members.';

  @override
  String get meetingChangeStatusArchiveBody =>
      'This meeting will be archived and will no longer appear as an active session.';

  @override
  String meetingStatusChangedSuccess(String status) {
    return 'Status successfully changed to $status';
  }

  @override
  String get meetingEditDialogTitle => 'Edit Meeting Information';

  @override
  String get meetingDescriptionLabel => 'Description / Summary';

  @override
  String get meetingEditTooltip => 'Edit Meeting Info';

  @override
  String get meetingDeleteTooltip => 'Delete Meeting';

  @override
  String get meetingManageStatusTooltip => 'Manage Status';

  @override
  String get meetingMenuPublishNow => 'Publish Now (Published)';

  @override
  String get meetingMenuSchedule => 'Schedule Publication (Scheduled)';

  @override
  String get meetingMenuDraft => 'Make Draft / Cancel Schedule';

  @override
  String get meetingMenuArchive => 'Archive (Archived)';

  @override
  String get meetingDeleteConfirmTitle => 'Delete This Meeting?';

  @override
  String get meetingDeleteConfirmBody =>
      'This action will remove the meeting from the class list.';

  @override
  String get meetingDeleteAction => 'Delete';

  @override
  String get meetingDeletedSuccess => 'Meeting successfully deleted.';

  @override
  String meetingDeleteFailed(String detail) {
    return 'Failed to delete: $detail';
  }

  @override
  String get meetingDefaultDescription =>
      'One meeting connects pretest quizzes, structured reading materials, learning videos, and evaluation post tests.';

  @override
  String get meetingScheduledBannerTitle => 'Scheduled Meeting';

  @override
  String meetingScheduledBanner(String when) {
    return 'Scheduled to be published at $when. Publication runs during the next cron/sync (within scheduled range), not exact-minute automated.';
  }

  @override
  String get meetingScheduledBannerFallback =>
      'Meeting is prepared for future publication schedule.';

  @override
  String get meetingModulesTitle => 'Learning Modules';

  @override
  String get meetingModuleMaterialTitle => 'Learning Material';

  @override
  String get meetingModuleMaterialSubActive =>
      'Structured reading material in Quill Delta format';

  @override
  String get meetingModuleMaterialSubStaffEmpty =>
      'Material not yet created. Click to create new material.';

  @override
  String get meetingModuleMaterialSubStudentEmpty =>
      'Material not yet uploaded by the instructor';

  @override
  String get meetingModuleMaterialActionOpen => 'Open Material';

  @override
  String get meetingModuleMaterialActionCreate => 'Create Material';

  @override
  String get meetingModulePretestTitle => 'Pretest Quiz';

  @override
  String get meetingModulePretestSubActive =>
      'Initial understanding test before starting core material';

  @override
  String get meetingModulePretestSubStaffEmpty =>
      'Pretest not yet enabled. Click to create pretest.';

  @override
  String get meetingModulePretestSubStudentEmpty =>
      'Pretest is not enabled for this meeting';

  @override
  String get meetingModulePretestActionStart => 'Start Pretest';

  @override
  String get meetingModulePretestActionCreate => 'Create Pretest';

  @override
  String get meetingModulePretestManageQuestions => 'Manage Questions';

  @override
  String get meetingModulePretestBadgeNotice => 'Must have opened material';

  @override
  String get meetingModuleVideoTitle => 'Learning Video';

  @override
  String get meetingModuleVideoSubActive =>
      'Interactive tutorial & demonstration video';

  @override
  String get meetingModuleVideoSubStaffEmpty =>
      'Video not yet linked. Click to add video link.';

  @override
  String get meetingModuleVideoSubStudentEmpty =>
      'Video not linked to this meeting';

  @override
  String get meetingModuleVideoActionWatch => 'Watch Video';

  @override
  String get meetingModuleVideoActionAdd => 'Add Video';

  @override
  String get meetingModulePosttestTitle => 'Post Test Quiz';

  @override
  String get meetingModulePosttestSubActive =>
      'Final evaluation of learning achievements after studying material';

  @override
  String get meetingModulePosttestSubStaffEmpty =>
      'Post test not yet created. Click to create post test.';

  @override
  String get meetingModulePosttestSubStudentEmpty =>
      'Post test is not enabled for this meeting';

  @override
  String get meetingModulePosttestActionStart => 'Start Post Test';

  @override
  String get meetingModulePosttestActionCreate => 'Create Post Test';

  @override
  String get meetingModuleNotAvailable => 'Not Available';

  @override
  String get meetingCreatePretestTitle => 'Create Pretest Quiz';

  @override
  String meetingPretestDefaultTitle(int number) {
    return 'Meeting $number Pretest';
  }

  @override
  String get meetingPretestTitleLabel => 'Pretest Title';

  @override
  String get meetingDurationLabel => 'Duration (Minutes)';

  @override
  String get meetingDurationMustBePositive => 'Duration must be > 0 minutes';

  @override
  String get meetingSaveAndManageQuestionsBtn => 'Save & Manage Questions';

  @override
  String get meetingCreatePosttestTitle => 'Create Post Test Quiz';

  @override
  String meetingPosttestDefaultTitle(int number) {
    return 'Meeting $number Post Test';
  }

  @override
  String get meetingPosttestTitleLabel => 'Post Test Title';

  @override
  String get meetingAddVideoTitle => 'Add Learning Video';

  @override
  String get meetingVideoProviderLabel => 'Video Provider';

  @override
  String get meetingVideoUrlLabel => 'Video URL';

  @override
  String get meetingVideoUrlRequired => 'URL is required';

  @override
  String get meetingVideoUrlInvalid =>
      'URL must start with http:// or https://';

  @override
  String get meetingSaveVideoBtn => 'Save Video';

  @override
  String meetingManageQuestionsTitle(String testTitle) {
    return 'Manage Questions $testTitle';
  }

  @override
  String meetingQuestionCountActive(int count) {
    return 'Total Questions: $count active questions';
  }

  @override
  String get meetingAddQuestionBtn => 'Add Question';

  @override
  String get meetingPublishQuizBtn => 'Publish Quiz';

  @override
  String get meetingPublishMinOneQuestion =>
      'Add at least 1 question before publishing quiz.';

  @override
  String meetingPublishFailed(String detail) {
    return 'Failed to publish: $detail';
  }

  @override
  String get meetingQuizPublishedSuccess =>
      'Quiz successfully published! Students can now access this quiz.';

  @override
  String get meetingDraftNoQuestionsTitle => 'Draft, no active questions yet.';

  @override
  String get meetingDraftNoQuestionsBody =>
      'Click \"Add Question\" button to create your first quiz question.';

  @override
  String meetingPointsLabel(int points) {
    return '$points points';
  }

  @override
  String get meetingEditAction => 'Edit';

  @override
  String get meetingCannotDeleteLastPublished =>
      'Cannot delete the last active question of a Published quiz. Please archive the quiz first if you want to deactivate it.';

  @override
  String get meetingDeleteQuestionConfirmTitle => 'Confirm Delete Question';

  @override
  String meetingDeleteQuestionConfirmBody(int number) {
    return 'Are you sure you want to delete Question $number? If students have taken the quiz, questions will be archived (soft-deleted) and previous student scores remain safe.';
  }

  @override
  String get meetingDeleteQuestionBtn => 'Delete Question';

  @override
  String get meetingAddQuestionDialogTitle => 'Add New Question';

  @override
  String get meetingEditQuestionDialogTitle => 'Edit Question';

  @override
  String get meetingQuestionTextLabel => 'Question Text *';

  @override
  String get meetingQuestionTextHint => 'Enter question...';

  @override
  String get meetingQuestionTextRequired => 'Question text is required';

  @override
  String get meetingQuestionPointsLabel => 'Question Points (1 - 100) *';

  @override
  String get meetingQuestionPointsRequired => 'Points are required';

  @override
  String get meetingQuestionPointsInvalid => 'Points must be between 1 - 100';

  @override
  String get meetingOptionsSectionTitle => 'Answer Options & Key (A - E) *';

  @override
  String get meetingOptionsSectionSubtitle =>
      'Provide 5 answer options (A through E) and select one radio as the correct answer key.';

  @override
  String meetingOptionLabelKey(String letter) {
    return 'Option $letter (★ CORRECT KEY)';
  }

  @override
  String meetingOptionLabelRegular(String letter) {
    return 'Option $letter';
  }

  @override
  String meetingOptionRequired(String letter) {
    return 'Option $letter cannot be empty';
  }

  @override
  String get meetingLegacyOptionsTitle =>
      'Archived Extra Options (Legacy - Read Only):';
}
