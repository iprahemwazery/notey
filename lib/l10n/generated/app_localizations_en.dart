// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'Your notes.. kept safe';

  @override
  String get forgotPin => 'Forgot your PIN?';

  @override
  String get resetAppTitle => 'Reset app';

  @override
  String get resetAppWarning =>
      'This permanently erases all notes, files and lock settings. It can\'t be undone.';

  @override
  String get resetAppConfirm => 'Erase & reset';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get undoAction => 'Undo';

  @override
  String get continueLabel => 'Continue';

  @override
  String get homeNewNote => 'New note';

  @override
  String get homeSearchHint => 'Search your notes...';

  @override
  String get homeClearSearch => 'Clear search';

  @override
  String homeNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      two: '2 notes',
      one: '1 note',
      zero: 'Start writing your first note',
    );
    return '$_temp0';
  }

  @override
  String get themeLightTooltip => 'Light mode';

  @override
  String get themeDarkTooltip => 'Dark mode';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get sortByColor => 'By color';

  @override
  String get selectionClear => 'Clear selection';

  @override
  String selectionCount(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get selectionAll => 'Select all';

  @override
  String get selectionNone => 'Deselect all';

  @override
  String get actionColor => 'Color';

  @override
  String get actionPin => 'Pin';

  @override
  String get actionUnpin => 'Unpin';

  @override
  String colorSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Color $count notes',
      one: 'Color 1 note',
    );
    return '$_temp0';
  }

  @override
  String get applyColor => 'Apply color';

  @override
  String get deleteNoteTitle => 'Delete note?';

  @override
  String get deleteNoteTrashMessage =>
      'The note moves to the trash and can be restored for 30 days.';

  @override
  String get deleteManyTitle => 'Delete notes?';

  @override
  String deleteManyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes will move to the trash and can be restored.',
      one: '1 note will move to the trash and can be restored.',
    );
    return '$_temp0';
  }

  @override
  String get movedToTrashOne => 'Note moved to trash';

  @override
  String movedToTrashCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes moved to trash',
      one: 'Note moved to trash',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'No results';

  @override
  String get tryOtherSearch => 'Try another search term';

  @override
  String get emptyNotes => 'No notes yet';

  @override
  String get emptyNotesHint => 'Tap \"New note\" to get started';

  @override
  String get lockedNote => 'Protected note';

  @override
  String get untitled => 'Untitled';

  @override
  String get editorEditTitle => 'Edit note';

  @override
  String get editorNewTitle => 'New note';

  @override
  String get saving => 'Saving...';

  @override
  String get editorSaveButton => 'Save note';

  @override
  String get editorTitleHint => 'Note title...';

  @override
  String get editorContentHint => 'Write your note details here...';

  @override
  String get imagesSection => 'Images';

  @override
  String get addImageSheetTitle => 'Add attachment to note';

  @override
  String get cameraOption => 'Take with camera';

  @override
  String get galleryOption => 'Choose from gallery';

  @override
  String get imagePickFailed => 'Couldn\'t get the image';

  @override
  String get titleRequired => 'Write a note title first';

  @override
  String get reminderSection => 'Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get editReminder => 'Set reminder time';

  @override
  String get clearReminder => 'Remove reminder';

  @override
  String get pastReminderToast => 'Pick a time in the future';

  @override
  String get drawOption => 'Draw';

  @override
  String get drawTitle => 'New drawing';

  @override
  String get voiceNoteOption => 'Voice recording';

  @override
  String get voiceNoteRecHint => 'Tap the microphone to start recording';

  @override
  String get micDeniedToast => 'Microphone permission was not granted';

  @override
  String get onbTitle1 => 'Beautiful, organized notes';

  @override
  String get onbBody1 =>
      'Write notes with Markdown formatting and organize them with tags and colors.';

  @override
  String get onbTitle2 => 'Everything in its place';

  @override
  String get onbBody2 =>
      'Reminders, image/audio/file attachments, instant search and sharing from any app.';

  @override
  String get onbTitle3 => 'Privacy first';

  @override
  String get onbBody3 =>
      'Lock the app or single notes with a password — your data stays on your device only.';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbSkip => 'Skip';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get noteSaveFailed => 'Couldn\'t save the note, try again';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesMessage =>
      'Do you want to save or discard your changes?';

  @override
  String get discard => 'Discard';

  @override
  String get relockBeforeEditHint =>
      'Unlock the note with its password before editing';

  @override
  String get protectMenuTooltip => 'Protect note';

  @override
  String get setPasswordItem => 'Set password';

  @override
  String get removePasswordOnSave => 'Remove password on save';

  @override
  String get noteProtectedItem => 'Note is protected';

  @override
  String get secureDialogTitle => 'Secure note';

  @override
  String get secureDialogMessage =>
      'The contents will be encrypted and only visible with the password.';

  @override
  String get secureConfirm => 'Secure';

  @override
  String get willSaveUnprotected => 'The note will be saved without protection';

  @override
  String get viewerTitle => 'Note';

  @override
  String get shareTooltip => 'Share';

  @override
  String get noAppToOpenFile => 'No app can open this file type';

  @override
  String get unlockTooltip => 'Unlock note';

  @override
  String get wrongPasswordToast => 'Wrong password';

  @override
  String get unlockDialogMessage => 'Enter the password to unlock the note';

  @override
  String get unlockConfirm => 'Unlock';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get unlockPanelTitle => 'This note is protected by a password';

  @override
  String get unlockPanelButton => 'Unlock note';

  @override
  String get manageProtection => 'Manage protection';

  @override
  String get protectSheetTitle => 'Protect note';

  @override
  String get setPasswordSubtitle => 'Encrypt the note\'s title and details';

  @override
  String get changePassword => 'Change password';

  @override
  String get newPasswordMessage => 'Enter the new password';

  @override
  String get updateConfirm => 'Update';

  @override
  String get passwordUpdatedToast => 'Password updated';

  @override
  String get removePassword => 'Remove password';

  @override
  String get removePasswordTitle => 'Remove password?';

  @override
  String get removePasswordMessage =>
      'The note will be saved unprotected and readable by anyone.';

  @override
  String get removeConfirm => 'Remove';

  @override
  String get protectionRemovedToast => 'Protection removed';

  @override
  String get securedToast => 'Note secured';

  @override
  String get noDetails => 'No details';

  @override
  String get createdAtLabel => 'Created';

  @override
  String get lastModifiedLabel => 'Last modified';

  @override
  String imagesCountLabel(int count) {
    return 'Images ($count)';
  }

  @override
  String filesCountLabel(int count) {
    return 'Files ($count)';
  }

  @override
  String get enterCurrentPasswordMessage =>
      'Enter the current password to continue';

  @override
  String get enterCurrentToRemoveMessage =>
      'Enter the current password to remove it';

  @override
  String get setPasswordDialogTitle => 'Set a password for this note';

  @override
  String get setPasswordDialogMessage =>
      'The contents will be encrypted and only visible with the password.';

  @override
  String imageOfTotal(int index, int total) {
    return 'Image $index of $total';
  }

  @override
  String welcomeTitle(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get chooseLockSubtitle =>
      'Choose how to lock the app to protect your notes';

  @override
  String get methodBiometric => 'Fingerprint or face';

  @override
  String get methodBiometricSubtitle =>
      'Unlock with the fingerprint or face enrolled on your device';

  @override
  String get methodDevice => 'Device pattern or PIN';

  @override
  String get methodDeviceSubtitle =>
      'Unlock with your device\'s pattern or password';

  @override
  String get methodPin => 'App PIN';

  @override
  String methodPinSubtitle(String appName) {
    return 'Unlock with a PIN specific to $appName';
  }

  @override
  String get lockOptionDeviceTitle => 'Device Security';

  @override
  String get lockOptionDeviceSubtitle =>
      'Use fingerprint, pattern or PIN already set on your device';

  @override
  String get lockOptionPasswordTitle => 'App Password';

  @override
  String get lockOptionPasswordSubtitle =>
      'Create a custom PIN for the app, with optional biometric';

  @override
  String get lockOptionSkip => 'Skip for now';

  @override
  String get deviceSetupTitle => 'Verify your identity';

  @override
  String get deviceSetupBody =>
      'Use your device\'s fingerprint, pattern or PIN to unlock the app';

  @override
  String get biometricOfferTitle => 'Add fingerprint unlock?';

  @override
  String biometricOfferBody(Object appName) {
    return 'Your device supports fingerprint/face unlock. Enable it for faster access to $appName?';
  }

  @override
  String get biometricBackupNotice =>
      'You must create a backup PIN in case biometric is unavailable';

  @override
  String get enableBiometric => 'Enable fingerprint';

  @override
  String get skipBiometric => 'Skip, use PIN only';

  @override
  String get backupPinBody =>
      'Create a backup PIN in case biometric is unavailable';

  @override
  String get methodNone => 'No lock';

  @override
  String get pinCreateTitle => 'Create PIN';

  @override
  String get pinBackupTitle => 'Create backup PIN';

  @override
  String get pinConfirmTitle => 'Confirm PIN';

  @override
  String get pinReenterPrompt => 'Re-enter the PIN to confirm';

  @override
  String pinEnterLength(int length) {
    return 'Enter a $length-digit PIN';
  }

  @override
  String get pinMismatchError => 'PINs didn\'t match, try again';

  @override
  String get enterAppPin => 'Enter your app PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get bioCheckingSensor => 'Checking fingerprint sensor...';

  @override
  String get bioEnrollTitle => 'Enroll a fingerprint first';

  @override
  String bioPrivacyNote(String appName) {
    return 'Your fingerprint is never stored in $appName — it stays safely on the device itself; the app only uses the device sensor.';
  }

  @override
  String get bioStep1 =>
      'Open device settings with the \"Open biometric settings\" button';

  @override
  String get bioStep2 => 'Go to Settings → Security → Fingerprint';

  @override
  String get bioStep3 => 'Follow the steps to enroll your fingerprint';

  @override
  String get bioStep4 => 'Return to the app and tap \"Done — enrolled\"';

  @override
  String get bioNotYetNotice =>
      'Not yet — open biometric settings and enroll your fingerprint first';

  @override
  String get bioOpenSettings => 'Open biometric settings';

  @override
  String get bioDoneEnrolled => 'Done — I enrolled my fingerprint';

  @override
  String get bioReadyTitle => 'Fingerprint sensor ready';

  @override
  String bioReadyBody(String appName) {
    return 'A fingerprint is enrolled on your device. From now on $appName asks for it whenever you open the app.';
  }

  @override
  String get bioTryNow => 'Try fingerprint now';

  @override
  String get bioNotRecognizedLong => 'Fingerprint not recognized, try again';

  @override
  String get bioUnavailableNow => 'The sensor isn\'t available right now';

  @override
  String get bioUnsupportedTitle => 'Fingerprint not supported';

  @override
  String get bioUnsupportedBody =>
      'The fingerprint sensor is unavailable on this device. You can pick another lock method.';

  @override
  String get chooseAnotherMethod => 'Choose another method';

  @override
  String get cannotOpenSettings => 'Can\'t open device settings here';

  @override
  String get verifying => 'Verifying...';

  @override
  String get placeFinger => 'Place your finger';

  @override
  String get deviceCredentialPrimaryHint =>
      'Or use your device\'s pattern or PIN';

  @override
  String get deviceCredentialFallbackHint =>
      'Or verify with the device pattern or PIN';

  @override
  String get notRecognizedRetry => 'Not recognized, try again';

  @override
  String get retryButton => 'Retry';

  @override
  String get tryNowButton => 'Verify now';

  @override
  String get useDeviceCredential => 'Use pattern or device PIN';

  @override
  String get useBackupPin => 'Use backup PIN';

  @override
  String get biometricBackupHint =>
      'Use your fingerprint to unlock, or use your backup PIN';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionSecurity => 'Lock & security';

  @override
  String get lockMethodTile => 'App lock method';

  @override
  String get lockMethodUnset => 'Not set';

  @override
  String get changePin => 'Change PIN';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light mode';

  @override
  String get themeDark => 'Dark mode';

  @override
  String get sectionBackup => 'Backup';

  @override
  String get exportNotes => 'Export notes';

  @override
  String get exportSubtitle =>
      'JSON file including trashed notes, without images';

  @override
  String get importBackup => 'Import backup';

  @override
  String get importSubtitle => 'Notes are added to the existing ones';

  @override
  String get sectionAbout => 'About';

  @override
  String get disableLockTitle => 'Disable app lock?';

  @override
  String get disableLockMessage =>
      'Anyone opening the device will be able to read your notes directly.';

  @override
  String get disableLockConfirm => 'Disable lock';

  @override
  String get noNotesToExport => 'No notes to export';

  @override
  String get exportFileTooltip => 'Export as text file';

  @override
  String exportedWithLine(String app) {
    return 'Exported from $app';
  }

  @override
  String get exportFailed => 'Couldn\'t create the backup file';

  @override
  String get importConfirmTitle => 'Import backup?';

  @override
  String importConfirmMessage(int count) {
    return '$count notes will be added to your current notes. The backup doesn\'t include attached images.';
  }

  @override
  String get importConfirm => 'Import';

  @override
  String importedToast(int count) {
    return 'Imported $count notes';
  }

  @override
  String get invalidBackupFile => 'That file isn\'t a valid Notey backup';

  @override
  String get readFileFailed => 'Couldn\'t read the file';

  @override
  String get gridViewTooltip => 'Grid view';

  @override
  String get listViewTooltip => 'List view';

  @override
  String get readerFontSize => 'Reader font size';

  @override
  String get trashTitle => 'Trash';

  @override
  String get emptyTrashTooltip => 'Empty trash';

  @override
  String get emptyTrashTitle => 'Empty trash?';

  @override
  String emptyTrashMessage(int count) {
    return '$count notes and their images will be deleted forever.';
  }

  @override
  String get emptyTrashConfirm => 'Empty';

  @override
  String get trashEmptyTitle => 'Trash is empty';

  @override
  String get trashEmptyBody =>
      'Deleted notes appear here for 30 days before being removed forever';

  @override
  String get restoreTooltip => 'Restore';

  @override
  String get purgeForeverTooltip => 'Delete forever';

  @override
  String get purgeForeverTitle => 'Delete forever?';

  @override
  String get purgeForeverMessage => 'This step cannot be undone.';

  @override
  String get purgeForeverConfirm => 'Delete forever';

  @override
  String get deletedToday => 'Today';

  @override
  String get deletedYesterday => 'Yesterday';

  @override
  String deletedDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String restoredToast(String title) {
    return '\"$title\" restored';
  }

  @override
  String get passwordMinLengthError => 'Password must be at least 6 characters';

  @override
  String get passwordsNoMatch => 'Passwords don\'t match';

  @override
  String get biometricPrompt => 'Unlock Notey';

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get timeNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String lastWeekOn(String weekday) {
    return 'Last week, $weekday';
  }

  @override
  String dayMonth(String day, String month) {
    return '$month $day';
  }

  @override
  String dayMonthYear(String day, String month, String year) {
    return '$month $day, $year';
  }

  @override
  String fullDate(String day, String month, String year, String clock) {
    return '$month $day, $year - $clock';
  }

  @override
  String get fileFromDeviceOption => 'Pick a file from device';

  @override
  String get attachmentPickFailed => 'Couldn\'t add the file';

  @override
  String get tagsSection => 'Tags';

  @override
  String get addTagHint => 'Add a tag...';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatHeading => 'Heading';

  @override
  String get formatBullet => 'Bullet list';

  @override
  String get formatCheckbox => 'Task';

  @override
  String get formatCode => 'Code';

  @override
  String get addTag => 'Add tag';

  @override
  String get noNotesWithTag => 'No notes with this tag';

  @override
  String get allTags => 'All';

  @override
  String get attachmentsSection => 'Attachments';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get editHistoryTitle => 'Edit History';

  @override
  String get noEditHistory => 'No previous edits';

  @override
  String get currentVersion => 'Current';

  @override
  String get reminderScheduled => 'Reminder scheduled';

  @override
  String get reminderPermissionNeeded =>
      'Notification permission is required for reminders. Please enable it in settings.';

  @override
  String get reminderFailed =>
      'Could not set reminder. Please check notification settings.';

  @override
  String get pinLocked => 'Too many attempts. Try again in';

  @override
  String get seconds => 'seconds';

  @override
  String get language => 'Language';

  @override
  String get langArabic => 'Arabic';

  @override
  String get langEnglish => 'English';

  @override
  String get textPlaceholder => 'text';

  @override
  String get semNewNote => 'New note';

  @override
  String get semNewNoteHint => 'Create a new note';

  @override
  String get semBulkColor => 'Change color';

  @override
  String get semBulkPin => 'Pin';

  @override
  String get semBulkUnpin => 'Unpin';

  @override
  String get semBulkDelete => 'Delete selected';

  @override
  String semSelectColor(Object color) {
    return 'Select color $color';
  }

  @override
  String get semRemoveImage => 'Remove image';

  @override
  String get semAddAttachment => 'Add attachment';

  @override
  String get semAddPhoto => 'Add photo';

  @override
  String get semAddFile => 'Add file';

  @override
  String get semOpenFile => 'Open file';

  @override
  String get semRemoveFile => 'Remove file';

  @override
  String get semSaveNote => 'Save note';

  @override
  String get semSaveNoteHint => 'Save the current note';

  @override
  String get semCloseSheet => 'Close';

  @override
  String get semOpenImageViewer => 'View image';

  @override
  String get semChecklistItem => 'Checklist item';

  @override
  String get semChecklistHint => 'Double tap to toggle';

  @override
  String get semChecked => 'Checked';

  @override
  String get semUnchecked => 'Not checked';

  @override
  String get semThemeSystem => 'System theme';

  @override
  String get semThemeLight => 'Light theme';

  @override
  String get semThemeDark => 'Dark theme';

  @override
  String get semThemeHint => 'Tap to select';

  @override
  String get semReaderFont => 'Reader font size';

  @override
  String get semPickFromCamera => 'Take a photo with the camera';

  @override
  String get semPickFromGallery => 'Choose a photo from the gallery';

  @override
  String get semPickFile => 'Choose a file from the device';

  @override
  String get semRecordVoice => 'Record a voice note';

  @override
  String get semDrawSketch => 'Draw a sketch';

  @override
  String get redoAction => 'Redo';

  @override
  String get eraser => 'Eraser';

  @override
  String get trashRetention => 'Trash retention';

  @override
  String trashRetentionDays(int days) {
    return '$days days';
  }

  @override
  String trashRetentionLabel(int days) {
    return 'Deleted notes are kept for $days days';
  }

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get clearAllDataSubtitle =>
      'Erase all notes, files and settings permanently';

  @override
  String get clearAllDataTitle => 'Clear all data?';

  @override
  String get clearAllDataMessage =>
      'This will permanently erase all notes, files and lock settings. Enter your PIN or password to confirm.';

  @override
  String get clearAllDataConfirm => 'Erase everything';

  @override
  String get enterPasswordToConfirm => 'Enter your password to confirm';

  @override
  String get dataClearedToast => 'All data has been erased';

  @override
  String get restoreHistoryVersion => 'Restore this version';

  @override
  String get historyRestoredToast => 'Note restored to this version';

  @override
  String get exportPdfTooltip => 'Export as PDF';

  @override
  String get exportMarkdownTooltip => 'Export as Markdown';

  @override
  String get exportPdfFailed => 'Couldn\'t create the PDF file';

  @override
  String get exportMarkdownFailed => 'Couldn\'t create the Markdown file';

  @override
  String get folderSection => 'Folder';

  @override
  String get folderHint => 'Assign to a folder...';

  @override
  String get allFolders => 'All folders';

  @override
  String get sortCustom => 'Custom order';

  @override
  String get searchInNote => 'Search in note';

  @override
  String get searchNoMatches => 'No matches found';

  @override
  String searchMatchOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get searchHistoryTitle => 'Recent searches';

  @override
  String get searchHistoryClear => 'Clear';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get vaultTitle => 'Vault';

  @override
  String get vaultEmptyTitle => 'Nothing here yet';

  @override
  String get vaultEmptyHint =>
      'Keep passwords, cards, bank accounts and secure notes in the encrypted vault';

  @override
  String get vaultAdd => 'Add';

  @override
  String get vaultAddLogin => 'Password';

  @override
  String get vaultAddCard => 'Credit card';

  @override
  String get vaultAddBank => 'Bank account';

  @override
  String get vaultAddSecureNote => 'Secure note';

  @override
  String get vaultFilterAll => 'All';

  @override
  String get vaultFilterPasswords => 'Passwords';

  @override
  String get vaultFilterBanking => 'Banking';

  @override
  String get vaultFilterDocuments => 'Documents';

  @override
  String get vaultFilterAudio => 'Audio';

  @override
  String get vaultFilterCanvas => 'Canvas';

  @override
  String get vaultTitleLabel => 'Title';

  @override
  String get vaultTitleHint => 'e.g. Gmail account';

  @override
  String get vaultFieldUsername => 'Username';

  @override
  String get vaultFieldPassword => 'Password';

  @override
  String get vaultFieldCardHolder => 'Cardholder name';

  @override
  String get vaultFieldCardNumber => 'Card number';

  @override
  String get vaultFieldExpiry => 'Expiry (MM/YY)';

  @override
  String get vaultFieldCvv => 'Security code (CVV)';

  @override
  String get vaultFieldCardPin => 'Card PIN';

  @override
  String get vaultFieldBankName => 'Bank name';

  @override
  String get vaultFieldIban => 'IBAN';

  @override
  String get vaultFieldAccountName => 'Account holder';

  @override
  String get vaultFieldSwift => 'SWIFT code';

  @override
  String get vaultNotes => 'Notes';

  @override
  String get vaultNotesHint => 'Optional extra notes';

  @override
  String get vaultShow => 'Show';

  @override
  String get vaultHide => 'Hide';

  @override
  String get vaultCopy => 'Copy';

  @override
  String get vaultCopiedToast => 'Copied';

  @override
  String get vaultShareLabel => 'Share';

  @override
  String get vaultDeleteTitle => 'Delete item?';

  @override
  String get vaultDeleteMessage =>
      'This item can\'t be recovered after deletion.';

  @override
  String get vaultGeneratePassword => 'Generate password';

  @override
  String get vaultAttachmentAdd => 'Add attachment';

  @override
  String get vaultAttachmentHint =>
      'An encrypted file (document, image, audio…)';

  @override
  String get vaultOpenAttachment => 'Open';

  @override
  String get vaultMediaLabel => 'Type';

  @override
  String get vaultMediaAuto => 'Auto';

  @override
  String get vaultMediaDocument => 'Document';

  @override
  String get vaultMediaAudio => 'Audio';

  @override
  String get vaultMediaDrawing => 'Sketch';

  @override
  String get vaultScreenProtected => 'Screenshot protection is on';

  @override
  String get vaultErrorLoading => 'Couldn\'t load the vault';

  @override
  String get documentPreviewShare => 'Share';

  @override
  String get documentOpenFailed => 'Couldn\'t open the file';

  @override
  String get documentHandedToExternal =>
      'The file was handed to an external app';

  @override
  String get documentNoAppHint =>
      'No app is installed to open this type of file';

  @override
  String get documentOpenExternal => 'Open in external app';

  @override
  String get documentPlaybackFailed => 'Couldn\'t play this audio file';

  @override
  String get audioPlay => 'Play';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioUnavailable => 'Audio isn\'t available';

  @override
  String get reRecord => 'Re-record';

  @override
  String get attach => 'Attach';

  @override
  String get replayPreview => 'Preview';
}
