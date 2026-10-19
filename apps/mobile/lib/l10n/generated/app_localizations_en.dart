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
  String get authBtnGoogleSignIn => 'Sign in with Google';

  @override
  String get authBtnGoogleSignUp => 'Sign up with Google';

  @override
  String get authOrDivider => 'or';

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
  String get meetingVideoUrlInvalid => 'URL must start with https://';

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

  @override
  String get materialNotFound => 'Material not found.';

  @override
  String get materialNotFoundOrDeleted =>
      'Material not found or has been deleted.';

  @override
  String materialLoadFailed(String detail) {
    return 'Failed to load material: $detail';
  }

  @override
  String get materialLoading => 'Loading learning material...';

  @override
  String get materialAppBarTitle => 'Material';

  @override
  String get materialEditTooltip => 'Edit Material';

  @override
  String materialFormat(String format) {
    return 'Format: $format';
  }

  @override
  String get materialRecordingProgress => 'Recording Progress...';

  @override
  String get materialRecordedOpened => 'Recorded as Opened';

  @override
  String get materialNotSyncedTapRetry => 'Not Synced (Tap to retry)';

  @override
  String get materialEmptyPlaceholder => 'Material is empty.';

  @override
  String get materialInsertImageTitle => 'Insert Image (Cloudinary URL)';

  @override
  String get materialInsertImageSecurityNote =>
      'Per Farlean LMS security rules, images must source from external URLs (Cloudinary). Inline base64 images are forbidden.';

  @override
  String get materialImageUrlLabel => 'Image URL (https://...)';

  @override
  String get materialImageUrlRequired => 'Image URL is required';

  @override
  String get materialImageBase64Forbidden =>
      'Inline base64 images are forbidden.';

  @override
  String get materialImageUrlInvalid => 'URL must start with https://';

  @override
  String get materialInsertBtn => 'Insert';

  @override
  String get materialTemplateOnlyEmpty =>
      'Templates can only be inserted into an empty editor to prevent overwriting existing content.';

  @override
  String get materialTemplateSuccess =>
      'Material template successfully inserted. Please complete each section.';

  @override
  String materialTemplateFailed(String detail) {
    return 'Failed to insert template: $detail';
  }

  @override
  String get materialPreviewTitle => 'Material Preview';

  @override
  String get materialDiscardConfirmTitle => 'Discard Changes?';

  @override
  String get materialDiscardConfirmBody =>
      'There are unsaved changes to this material. Leaving now will discard those changes.';

  @override
  String get materialKeepEditingBtn => 'Keep Editing';

  @override
  String get materialDiscardChangesBtn => 'Discard Changes';

  @override
  String get materialTitleRequired => 'Material title is required.';

  @override
  String materialSavedAsStatus(String status) {
    return 'Material successfully saved as $status.';
  }

  @override
  String materialSaveFailed(String detail) {
    return 'Failed to save material: $detail';
  }

  @override
  String get materialCreateTitle => 'Create New Material';

  @override
  String get materialEditTitle => 'Edit Material';

  @override
  String get materialPreviewTooltip => 'Preview Student View';

  @override
  String get materialPublishBtn => 'Publish';

  @override
  String get materialTitleLabel => 'Learning Material Title';

  @override
  String get materialImageBtn => 'Image';

  @override
  String get materialTemplateBtn => 'Template';

  @override
  String materialCharCountDeltaJson(int count) {
    return '$count characters • Format: Delta JSON';
  }

  @override
  String get materialEmptyWarning =>
      'Material is still empty. Write content or insert a template before saving.';

  @override
  String get materialEditorPlaceholder =>
      'Write structured learning material here...';

  @override
  String classDetailLoadFailed(String detail) {
    return 'Failed to load class details: $detail';
  }

  @override
  String get classSaveMeetingBtn => 'Save Meeting';

  @override
  String get classArchiveConfirmTitle => 'Archive Class?';

  @override
  String get classArchiveConfirmBody =>
      'Archived classes will be locked from editing and will no longer accept new members. Existing members can still read materials.';

  @override
  String get classArchiveBtn => 'Archive';

  @override
  String get classArchiveSuccess => 'Class successfully archived.';

  @override
  String classArchiveFailed(String detail) {
    return 'Failed to archive: $detail';
  }

  @override
  String get classReactivateConfirmTitle => 'Reactivate Class?';

  @override
  String get classReactivateConfirmBody =>
      'Reactivated classes will be able to accept new members and allow management of meetings and quizzes as before.';

  @override
  String get classReactivateBtn => 'Reactivate';

  @override
  String get classReactivateSuccess => 'Class successfully reactivated.';

  @override
  String classReactivateFailed(String detail) {
    return 'Failed to reactivate class: $detail';
  }

  @override
  String get classDetailLoading => 'Loading class details...';

  @override
  String get classDetailTitle => 'Class Details';

  @override
  String get classNotFound => 'Class not found.';

  @override
  String get classArchiveTooltip => 'Archive Class';

  @override
  String get classReactivateTooltip => 'Reactivate Class';

  @override
  String classCodeCopied(String code) {
    return 'Class code $code copied to clipboard.';
  }

  @override
  String classMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Members',
      one: '1 Member',
    );
    return '$_temp0';
  }

  @override
  String classMeetingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '•  $count Meetings',
      one: '•  1 Meeting',
    );
    return '$_temp0';
  }

  @override
  String get classTabMeetings => 'Meetings';

  @override
  String get classTabGrades => 'Gradebook';

  @override
  String get classTabMembers => 'Class Members';

  @override
  String get classEmptyMeetingOwnerDesc =>
      'Create a new meeting to start adding materials, pretests, and learning videos.';

  @override
  String get classEmptyMeetingStudentDesc =>
      'The instructor has not published any meetings in this class yet.';

  @override
  String get classCreateMeetingBtn => 'Create Meeting';

  @override
  String get classGradebookRestrictedTitle => 'Restricted Gradebook Access';

  @override
  String get classGradebookRestrictedBody =>
      'Per Farlean LMS academic data protection policy, only the Class Owner Instructor and Admins are authorized to access student grade summaries in this class.';

  @override
  String get classGradebookNoStudents => 'No students in this class yet.';

  @override
  String get classGradebookAllMeetingsHint => 'All Meetings (Summary)';

  @override
  String classMeetingNumberTitle(int number, String title) {
    return 'Meeting $number: $title';
  }

  @override
  String get classKpiPretestAvg => 'Pretest Average';

  @override
  String classKpiSubCount(int submitted, int total) {
    return '$submitted of $total students';
  }

  @override
  String get classKpiPosttestAvg => 'Post Test Average';

  @override
  String get classKpiTotalMeetings => 'Total Meetings';

  @override
  String classKpiQuizModulesCount(int count) {
    return '$count with quiz modules';
  }

  @override
  String get classKpiTotalStudents => 'Total Students';

  @override
  String get classKpiEnrolledDesc => 'Enrolled in this class';

  @override
  String classPaginationInfo(int start, int end, int total) {
    return 'Showing $start-$end of $total students';
  }

  @override
  String classQuizProgress(int done, int total) {
    return 'Quiz Progress: $done of $total completed';
  }

  @override
  String get classQuizNoneDone =>
      'No quizzes have been completed in any meeting yet.';

  @override
  String get classScoreNotAvailable => 'None Yet';

  @override
  String get classNoMeetings => 'No meetings in this class yet.';

  @override
  String get classStudentProgressTitle => 'Your Learning Achievements';

  @override
  String classStudentProgressBody(String className) {
    return 'Showing your official pretest & post test scores for class $className.';
  }

  @override
  String get classNoMembers => 'No members enrolled in this class yet.';

  @override
  String classMemberTypeStatus(String type, String status) {
    return 'Type: $type • Status: $status';
  }

  @override
  String get joinClassSuccessTitle => 'Joined Successfully';

  @override
  String get joinClassPendingTitle => 'Pending Approval';

  @override
  String joinClassStatusPrefix(String status) {
    return 'Status: $status';
  }

  @override
  String get joinClassOpenBtn => 'Open Class';

  @override
  String get joinClassBackHomeBtn => 'Back to Home';

  @override
  String joinClassSyncFailed(String detail) {
    return 'Failed to sync class data: $detail';
  }

  @override
  String get joinClassAppBarTitle => 'Join Class';

  @override
  String get joinClassHeading => 'Enter Class Code';

  @override
  String get joinClassDescription =>
      'Class code consists of 6-12 alphanumeric characters. Students/Lecturers are automatically active, while General accounts are pending.';

  @override
  String get joinClassCodeLabel => 'Class Code (e.g., FARLEAN1)';

  @override
  String get joinClassSubmitBtn => 'Join Now';

  @override
  String get discussionErrorPermissionStaff =>
      'Access denied: You are not authorized to manage this class forum.';

  @override
  String get discussionErrorPermissionStudent =>
      'Access denied: You are not enrolled as an active member in this class.';

  @override
  String discussionErrorLoadFailed(String detail) {
    return 'Failed to load discussion forum: $detail';
  }

  @override
  String get discussionSelectClassFirst =>
      'Please select a class first to create a discussion.';

  @override
  String get discussionCreateTitle => 'Create New Discussion';

  @override
  String get discussionTitleLabel => 'Discussion Title *';

  @override
  String get discussionTitleHint => 'E.g., Question on Chapter 2...';

  @override
  String get discussionTitleMinLength => 'Title must be at least 3 characters';

  @override
  String get discussionTitleMaxLength => 'Title must be at most 200 characters';

  @override
  String get discussionBodyLabel => 'Question / Discussion Content *';

  @override
  String get discussionBodyHint => 'Write your question or topic clearly...';

  @override
  String get discussionBodyMinLength =>
      'Discussion content must be at least 3 characters';

  @override
  String get discussionBodyMaxLength =>
      'Discussion content must be at most 5000 characters';

  @override
  String get discussionSendBtn => 'Post Discussion';

  @override
  String get discussionForumTitle => 'Discussion Forum';

  @override
  String get discussionCreateFab => 'Create Discussion';

  @override
  String get discussionNoClassTitle => 'Select Class to Discuss';

  @override
  String get discussionNoClassBody =>
      'You haven\'t selected a class. Please join a class or select one from Home.';

  @override
  String get discussionLoading => 'Loading class discussions...';

  @override
  String get discussionFilterAll => 'All Discussions';

  @override
  String get discussionFilterUnanswered => 'Unanswered';

  @override
  String get discussionFilterUnread => 'Unread';

  @override
  String get discussionEmptyAllTitle => 'No Discussions Yet';

  @override
  String get discussionEmptyAllDesc =>
      'Be the first to start a Q&A and collaboration thread in this class.';

  @override
  String get discussionEmptyUnansweredTitle => 'No Unanswered Discussions';

  @override
  String get discussionEmptyUnansweredDesc =>
      'All discussion topics have received replies from the instructor or peers.';

  @override
  String get discussionEmptyUnreadTitle => 'All Discussions Read';

  @override
  String get discussionEmptyUnreadDesc =>
      'No new activity or unread replies on this page.';

  @override
  String discussionReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Replies',
      one: '1 Reply',
    );
    return '$_temp0';
  }

  @override
  String get discussionNotFound => 'Discussion not found or has been deleted.';

  @override
  String discussionLoadDetailFailed(String detail) {
    return 'Failed to load discussion details: $detail';
  }

  @override
  String get discussionArchivedSendBlocked =>
      'This discussion is archived. Sending replies is disabled.';

  @override
  String discussionSendReplyFailed(String detail) {
    return 'Failed to send reply: $detail';
  }

  @override
  String get discussionArchiveConfirmTitle => 'Archive Discussion?';

  @override
  String get discussionArchiveConfirmBody =>
      'Archived discussions will be locked from new replies and hidden from the class members list.';

  @override
  String get discussionArchiveSuccess => 'Discussion successfully archived.';

  @override
  String discussionArchiveFailed(String detail) {
    return 'Failed to archive: $detail';
  }

  @override
  String get discussionEditTitle => 'Edit Discussion';

  @override
  String get discussionEditTitleLabel => 'Discussion Title';

  @override
  String get discussionEditBodyLabel => 'Discussion Content';

  @override
  String discussionUpdateFailed(String detail) {
    return 'Failed to update: $detail';
  }

  @override
  String get discussionArchiveReplyTooltip => 'Archive Reply';

  @override
  String get discussionReplyAction => 'Reply';

  @override
  String get discussionThreadLoading => 'Loading discussion thread...';

  @override
  String get discussionDetailTitle => 'Discussion Details';

  @override
  String get discussionEditTooltip => 'Edit Discussion';

  @override
  String get discussionArchiveTooltip => 'Archive Discussion';

  @override
  String get discussionStatusArchivedTag => 'Status: Archived';

  @override
  String get discussionStatusActiveTag => 'Active Discussion Thread';

  @override
  String discussionDetailReplyCount(int count) {
    return 'Replies ($count)';
  }

  @override
  String get discussionNoRepliesYet => 'No replies on this discussion yet.';

  @override
  String discussionReplyingTo(String author, String snippet) {
    return 'Replying to @$author: \"$snippet\"';
  }

  @override
  String get discussionArchivedBanner =>
      'Discussion archived. Sending replies is disabled.';

  @override
  String discussionReplyToHint(String author) {
    return 'Write a reply to @$author...';
  }

  @override
  String get discussionReplyGeneralHint => 'Write a reply or response...';

  @override
  String get dashboardCreateClassTitle => 'Create New Class';

  @override
  String get dashboardClassNameLabel => 'Class Name';

  @override
  String get dashboardClassNameHint => 'Example: Mobile Programming';

  @override
  String get dashboardClassNameMinLength =>
      'Class name must be at least 3 characters';

  @override
  String get dashboardClassNameMaxLength =>
      'Class name must be at most 100 characters';

  @override
  String get dashboardClassDescLabel => 'Description (Optional)';

  @override
  String get dashboardClassDescHint => 'Brief description of class syllabus';

  @override
  String get dashboardClassCodeLabel => 'Custom Class Code (Optional)';

  @override
  String get dashboardClassCodeHint =>
      'Leave blank for random 8-character code';

  @override
  String get dashboardClassCodeLength => 'Code must be 6-12 characters';

  @override
  String get dashboardClassCodeAlphanumeric =>
      'Code must be uppercase letters and numbers only';

  @override
  String get dashboardCreateClassBtn => 'Create Class';

  @override
  String get dashboardClassCreatedSuccess => 'Class successfully created.';

  @override
  String get dashboardLoadingProfile => 'Loading profile and permissions...';

  @override
  String get dashboardProfileErrorTitle => 'Profile Failed to Load';

  @override
  String get dashboardProfileErrorNetwork =>
      'Database connection failed. Check your internet connection or emulator.';

  @override
  String get dashboardProfileErrorNotFound =>
      'User profile could not be loaded. Please tap Try Again.';

  @override
  String get dashboardProfileErrorPermission =>
      'Access denied when loading profile.';

  @override
  String get dashboardProfileErrorDefault =>
      'A problem occurred syncing your profile from the server. Please try again.';

  @override
  String get dashboardLoadingClasses => 'Loading your classes...';

  @override
  String get dashboardWelcomeBadge => 'Farlean LMS • Multi-Class Active';

  @override
  String get dashboardWelcomeTitle => 'Welcome to Farlean LMS';

  @override
  String get dashboardWelcomeBody =>
      'Access structured materials, server-graded pretest quizzes, learning videos, and discussion forums in one platform.';

  @override
  String get dashboardRoleOutOfSyncTitle => 'Account Role Out of Sync';

  @override
  String dashboardRoleOutOfSyncBody(String claimsRole, String profileRole) {
    return 'Token: $claimsRole vs Profile: $profileRole. Tap Refresh to align permissions.';
  }

  @override
  String get dashboardRefreshRoleBtn => 'Refresh';

  @override
  String get dashboardManagedClassesSection => 'Classes You Manage';

  @override
  String get dashboardEmptyOwnedTitle => 'No classes managed yet.';

  @override
  String get dashboardEmptyOwnedBody =>
      'Create a new class to start uploading materials and creating meetings.';

  @override
  String get dashboardCreateFirstClassBtn => 'Create First Class';

  @override
  String get dashboardJoinedClassesSection => 'Classes You Joined';

  @override
  String get dashboardJoinCodeBtn => 'Join with Code';

  @override
  String get dashboardEmptyJoinedTitle =>
      'Not enrolled in any learning classes yet.';

  @override
  String get dashboardEmptyJoinedBody =>
      'Ask for a class code from your Lecturer/Instructor to join a class.';

  @override
  String dashboardCodeCopied(String code) {
    return 'Code $code copied.';
  }

  @override
  String dashboardMeetingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meetings',
      one: '1 Meeting',
    );
    return '$_temp0';
  }

  @override
  String get dashboardManageClassBtn => 'Manage Class';

  @override
  String get dashboardOpenClassBtn => 'Open Class';

  @override
  String get navSelectClassFirst =>
      'Please select a class first to view meetings & materials.';

  @override
  String get navMaterials => 'Materials';

  @override
  String get navAiTutor => 'AI Tutor';

  @override
  String get navDiscussion => 'Discussion';

  @override
  String get manualBookErrorPermissionStaff =>
      'Access denied: You are not authorized to view this class guide files.';

  @override
  String get manualBookErrorPermissionStudent =>
      'Access denied: You are not enrolled as an active member in this class.';

  @override
  String manualBookErrorLoadFailed(String detail) {
    return 'Failed to load manual book: $detail';
  }

  @override
  String get manualBookOpenPdfFailed => 'Unable to open PDF link.';

  @override
  String manualBookOpenPdfError(String detail) {
    return 'Error opening file: $detail';
  }

  @override
  String get manualBookSelectClassFirst =>
      'Please select a valid class first to upload a guide book.';

  @override
  String get manualBookAddTitle => 'Add Manual Book';

  @override
  String get manualBookTitleLabel => 'Guide Title';

  @override
  String get manualBookTitleRequired => 'Title is required';

  @override
  String get manualBookDescLabel => 'Short Description';

  @override
  String get manualBookUrlLabel => 'Cloudinary File URL (PDF)';

  @override
  String get manualBookUrlRequired => 'File URL is required';

  @override
  String get manualBookUrlInvalid => 'URL must start with https://';

  @override
  String get manualBookFileNameLabel => 'File Name (.pdf)';

  @override
  String get manualBookAppBarTitle => 'Guide Book (Manual Book)';

  @override
  String get manualBookNoClassBody =>
      'You haven\'t selected a class. Please join using a class code or select a class from Home to access Guide Books.';

  @override
  String get manualBookJoinNewClassBtn => 'Join New Class';

  @override
  String get manualBookLoading => 'Loading guide book...';

  @override
  String get manualBookEmptyTitle => 'No Guide Books Yet';

  @override
  String get manualBookEmptyBody =>
      'Instructor has not added any PDF guide books (Manual Books) for this class yet.';

  @override
  String get manualBookNoDescription => 'No description';

  @override
  String get manualBookOpenPdfBtn => 'Open PDF Document';

  @override
  String get profileThemeTitle => 'Display Theme';

  @override
  String get profileThemeSubtitle => 'Set light, dark, or system default theme';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'System Default';

  @override
  String get profileLanguageTitle => 'Language';

  @override
  String get profileLanguageSubtitle => 'Select application display language';

  @override
  String get languageId => 'Bahasa Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String quizQuestionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String quizPoints(int points) {
    return '$points Points';
  }

  @override
  String get quizBtnPrev => 'Previous';

  @override
  String get quizBtnNext => 'Next';

  @override
  String get quizBtnSubmit => 'Submit';

  @override
  String get quizGateLockedTitle => 'Pretest Access Locked';

  @override
  String get quizGateLockedDesc =>
      'Per Farlean LMS learning guidelines, you must open and read this meeting\'s learning material first before being permitted to take the pretest.\n\nIf you have previously opened the material, tap the button below to reopen it so that your attendance progress is officially synced to the server.';

  @override
  String get quizGateOpenMaterialBtn => 'Open Learning Material';

  @override
  String get quizGateBackToMeetingBtn => 'Back to Meeting';

  @override
  String get quizConfirmSubmitTitle => 'Submit Answers?';

  @override
  String get quizConfirmSubmitBody =>
      'Are you sure you want to submit this quiz? Please ensure you have answered all questions carefully.';

  @override
  String get quizSubmitting => 'Submitting...';

  @override
  String get quizSubmitSuccessTitle => 'Quiz Graded';

  @override
  String quizSubmitSuccessBody(String score, int earned, int total) {
    return 'Your official score: $score ($earned/$total points).\nYour best score has been updated on the server.';
  }

  @override
  String get quizConnErrorTitle => 'Connection Lost';

  @override
  String get quizConnErrorBody =>
      'Network connection lost. The quiz grading status cannot be verified from the server. Please check your internet connection and try again.';

  @override
  String get quizDeadlineExpiredTitle => 'Time Expired';

  @override
  String get quizDeadlineExpiredBody =>
      'The quiz deadline has expired. The quiz session has been locked by the server.';

  @override
  String get quizUnderstand => 'Understood';

  @override
  String get quizDraftBlockedMessage =>
      'This quiz is still in Draft status and has not been opened by the instructor.';

  @override
  String videoProviderLabel(String provider) {
    return 'Provider: $provider';
  }

  @override
  String videoDurationLabel(int minutes, int seconds) {
    return 'Duration: ${minutes}m ${seconds}s';
  }

  @override
  String get videoIntegratedTitle => 'Integrated Learning Video';

  @override
  String videoSourceUrlLabel(String url) {
    return 'Source URL: $url';
  }

  @override
  String get videoStorageNote =>
      'This video is streamed directly without storing in Firebase Storage for storage efficiency per Blueprint architecture.';

  @override
  String videoLoadFailed(String error) {
    return 'Failed to load video: $error';
  }

  @override
  String meetingLockedUntilPublish(String date) {
    return 'This meeting is scheduled to be published on $date. All modules are locked until then.';
  }

  @override
  String get quizGateMateriNotOpened => 'Learning Material Not Opened';

  @override
  String get quizTimeUpAutosaved =>
      'Time has expired. Your answers have been automatically saved.';

  @override
  String get quizTimeUpAutosubmitted =>
      'Time has expired. Your answers have been automatically submitted.';

  @override
  String quizSubmitFailed(String error) {
    return 'Failed to submit quiz: $error';
  }

  @override
  String get quizPendingEvaluationTitle => 'Pending Evaluation';

  @override
  String get quizPendingEvaluationBody =>
      'Connection to grading server lost, but your quiz session remains active on the server. Your local answers have been saved automatically. Please tap Submit Quiz to retry.';

  @override
  String quizConfirmUnansweredBody(int unanswered) {
    return 'There are $unanswered unanswered questions. Submitted answers cannot be changed.';
  }

  @override
  String get quizPretestLoading => 'Preparing pretest quiz...';

  @override
  String get quizPretestLoadFailed => 'Failed to load pretest.';

  @override
  String get quizPosttestLoading => 'Preparing post test session...';

  @override
  String get quizPosttestUnavailable => 'Post test quiz is not available.';

  @override
  String get quizNoQuestionsConfigured =>
      'No questions have been configured for this post test yet.';

  @override
  String quizPosttestLoadFailed(String error) {
    return 'Failed to load post test quiz: $error';
  }

  @override
  String quizFinalScore(String score) {
    return 'Final Score: $score';
  }

  @override
  String quizPointsEarned(String earned, String total) {
    return 'Points earned: $earned of $total points';
  }

  @override
  String get quizPretestAnswersLocked =>
      'Your answers have been securely saved and the quiz session is locked.';

  @override
  String get quizPosttestAnswersLocked =>
      'Your answers have been locked and your learning evaluation score has been recorded on the server.';

  @override
  String get quizSessionNotActive => 'Your session is not active.';

  @override
  String get quizNotFound => 'Pretest quiz not found.';

  @override
  String get quizPosttestNotFound => 'Post test quiz not found.';

  @override
  String quizDraftBlocked(String status) {
    return 'Pretest quiz is still in $status status and has not been opened.';
  }

  @override
  String get quizInvalidClassMeeting =>
      'Quiz is not connected to a valid class or meeting.';

  @override
  String get quizInvalidClass =>
      'Post test quiz is not connected to a valid class.';

  @override
  String get quizNoQuestionsUploaded =>
      'Quiz questions have not been uploaded by the instructor.';

  @override
  String get quizStaleSessionEnded =>
      'The previous attempt session ended before answers were submitted.';

  @override
  String quizMaxAttemptsReached(String attempts) {
    return 'You have reached the maximum attempt limit (${attempts}x).';
  }

  @override
  String quizPosttestMaxAttemptsReached(String count, String max) {
    return 'You have reached the maximum attempt limit ($count/$max).';
  }

  @override
  String quizLoadFailedGeneric(String error) {
    return 'Failed to load quiz session: $error';
  }

  @override
  String get videoLoadingPlayer => 'Loading video player...';

  @override
  String get videoNotFound => 'Learning video not found.';

  @override
  String get videoYoutubeUrlInvalid => 'Invalid YouTube video URL.';

  @override
  String videoPlaybackFailed(String error) {
    return 'Failed to play Cloudinary video: $error';
  }
}
