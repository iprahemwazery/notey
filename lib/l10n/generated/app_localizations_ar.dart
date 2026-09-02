// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tagline => 'ملاحظاتك.. في أمان';

  @override
  String get forgotPin => 'نسيت الرمز؟';

  @override
  String get resetAppTitle => 'إعادة تعيين التطبيق';

  @override
  String get resetAppWarning =>
      'سيتم مسح جميع الملاحظات والملفات وإعدادات القفل نهائيًا. لا يمكن التراجع عن هذه الخطوة.';

  @override
  String get resetAppConfirm => 'مسح وإعادة التعيين';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get undoAction => 'تراجع';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get homeNewNote => 'ملاحظة جديدة';

  @override
  String get homeSearchHint => 'ابحث في ملاحظاتك...';

  @override
  String get homeClearSearch => 'مسح البحث';

  @override
  String homeNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظة',
      many: '$count ملاحظة',
      few: '$count ملاحظات',
      two: 'ملاحظتان',
      one: 'ملاحظة واحدة',
      zero: 'ابدأ بكتابة أول ملاحظة',
    );
    return '$_temp0';
  }

  @override
  String get themeLightTooltip => 'الوضع النهاري';

  @override
  String get themeDarkTooltip => 'الوضع الليلي';

  @override
  String get sortTooltip => 'ترتيب';

  @override
  String get sortNewestFirst => 'الأحدث أولًا';

  @override
  String get sortOldestFirst => 'الأقدم أولًا';

  @override
  String get sortByColor => 'حسب اللون';

  @override
  String get selectionClear => 'إلغاء التحديد';

  @override
  String selectionCount(int selected, int total) {
    return 'تم تحديد $selected من $total';
  }

  @override
  String get selectionAll => 'تحديد الكل';

  @override
  String get selectionNone => 'إلغاء تحديد الكل';

  @override
  String get actionColor => 'اللون';

  @override
  String get actionPin => 'تثبيت';

  @override
  String get actionUnpin => 'إلغاء التثبيت';

  @override
  String colorSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لون $count ملاحظة',
      many: 'لون $count ملاحظات',
      few: 'لون $count ملاحظات',
      one: 'لون ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get applyColor => 'تطبيق اللون';

  @override
  String get deleteNoteTitle => 'حذف الملاحظة؟';

  @override
  String get deleteNoteTrashMessage =>
      'تُنقل الملاحظة إلى المحذوفات ويمكن استعادتها خلال 30 يومًا.';

  @override
  String get deleteManyTitle => 'حذف الملاحظات؟';

  @override
  String deleteManyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيتم نقل $count ملاحظة إلى المحذوفات ويمكن استعادتها.',
      many: 'سيتم نقل $count ملاحظة إلى المحذوفات ويمكن استعادتها.',
      few: 'سيتم نقل $count ملاحظات إلى المحذوفات ويمكن استعادتها.',
      one: 'سيتم نقل ملاحظة واحدة إلى المحذوفات ويمكن استعادتها.',
    );
    return '$_temp0';
  }

  @override
  String get movedToTrashOne => 'تم نقل الملاحظة إلى المحذوفات';

  @override
  String movedToTrashCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم نقل $count ملاحظة إلى المحذوفات',
      many: 'تم نقل $count ملاحظة إلى المحذوفات',
      few: 'تم نقل $count ملاحظات إلى المحذوفات',
      one: 'تم نقل الملاحظة إلى المحذوفات',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get tryOtherSearch => 'جرّب كلمة بحث أخرى';

  @override
  String get emptyNotes => 'لا توجد ملاحظات بعد';

  @override
  String get emptyNotesHint => 'اضغط زر \"ملاحظة جديدة\" للبدء';

  @override
  String get lockedNote => 'ملاحظة محمية';

  @override
  String get untitled => 'بدون عنوان';

  @override
  String get editorEditTitle => 'تعديل ملاحظة';

  @override
  String get editorNewTitle => 'ملاحظة جديدة';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get editorSaveButton => 'حفظ الملاحظة';

  @override
  String get editorTitleHint => 'عنوان الملاحظة...';

  @override
  String get editorContentHint => 'اكتب تفاصيل ملاحظتك هنا...';

  @override
  String get imagesSection => 'الصور';

  @override
  String get addImageSheetTitle => 'إضافة مرفق للملاحظة';

  @override
  String get cameraOption => 'التقاط صورة بالكاميرا';

  @override
  String get galleryOption => 'اختيار من المعرض';

  @override
  String get imagePickFailed => 'تعذر الحصول على الصورة';

  @override
  String get titleRequired => 'اكتب عنوانًا للملاحظة أولًا';

  @override
  String get reminderSection => 'التذكير';

  @override
  String get noReminder => 'بدون تذكير';

  @override
  String get editReminder => 'تحديد وقت التذكير';

  @override
  String get clearReminder => 'إزالة التذكير';

  @override
  String get pastReminderToast => 'اختر وقتًا في المستقبل';

  @override
  String get drawOption => 'رسم';

  @override
  String get drawTitle => 'رسم جديد';

  @override
  String get voiceNoteOption => 'تسجيل صوتي';

  @override
  String get voiceNoteRecHint => 'اضغط على الميكروفون لبدء التسجيل';

  @override
  String get micDeniedToast => 'لم يتم منح إذن المايكروفون';

  @override
  String get onbTitle1 => 'ملاحظاتك، منسّقة وجميلة';

  @override
  String get onbBody1 =>
      'اكتب ملاحظاتك بتنسيق Markdown، ونظّمها بالوسوم والألوان.';

  @override
  String get onbTitle2 => 'كل شيء في مكانه';

  @override
  String get onbBody2 =>
      'تذكيرات، مرفقات صور وأصوات وملفات، بحث سريع، واستقبال المشاركة من أي تطبيق.';

  @override
  String get onbTitle3 => 'خصوصيتك أولاً';

  @override
  String get onbBody3 =>
      'اقفل التطبيق أو الملاحظات المنفردة بكلمة سر — وبياناتك تبقى على جهازك فقط.';

  @override
  String get onbNext => 'التالي';

  @override
  String get onbStart => 'ابدأ الآن';

  @override
  String get onbSkip => 'تخطي';

  @override
  String get noteSaved => 'تم حفظ الملاحظة';

  @override
  String get noteSaveFailed => 'تعذر حفظ الملاحظة، حاول مرة أخرى';

  @override
  String get unsavedChangesTitle => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesMessage => 'هل تريد حفظ التغييرات أم تجاهلها؟';

  @override
  String get discard => 'تجاهل';

  @override
  String get relockBeforeEditHint => 'أعد فتح الملاحظة بكلمة السر قبل تعديلها';

  @override
  String get protectMenuTooltip => 'حماية الملاحظة';

  @override
  String get setPasswordItem => 'تعيين كلمة سر';

  @override
  String get removePasswordOnSave => 'إزالة كلمة السر عند الحفظ';

  @override
  String get noteProtectedItem => 'الملاحظة محمية';

  @override
  String get secureDialogTitle => 'تأمين الملاحظة';

  @override
  String get secureDialogMessage =>
      'ستُشفَّر محتويات الملاحظة ولا يمكن عرضها إلا بكلمة السر.';

  @override
  String get secureConfirm => 'تأمين';

  @override
  String get willSaveUnprotected => 'ستُحفظ الملاحظة بدون حماية عند الحفظ';

  @override
  String get viewerTitle => 'الملاحظة';

  @override
  String get shareTooltip => 'مشاركة';

  @override
  String get noAppToOpenFile => 'مفيش تطبيق يقدر يفتح نوع الملف ده';

  @override
  String get unlockTooltip => 'فتح الملاحظة';

  @override
  String get wrongPasswordToast => 'كلمة السر غير صحيحة';

  @override
  String get unlockDialogMessage => 'أدخل كلمة السر لفتح الملاحظة';

  @override
  String get unlockConfirm => 'فتح';

  @override
  String get passwordHint => 'كلمة السر';

  @override
  String get confirmPasswordHint => 'تأكيد كلمة السر';

  @override
  String get unlockPanelTitle => 'هذه الملاحظة محمية بكلمة سر';

  @override
  String get unlockPanelButton => 'فتح الملاحظة';

  @override
  String get manageProtection => 'إدارة الحماية';

  @override
  String get protectSheetTitle => 'حماية الملاحظة';

  @override
  String get setPasswordSubtitle => 'حماية عنوان وتفاصيل الملاحظة';

  @override
  String get changePassword => 'تغيير كلمة السر';

  @override
  String get newPasswordMessage => 'أدخل كلمة السر الجديدة';

  @override
  String get updateConfirm => 'تحديث';

  @override
  String get passwordUpdatedToast => 'تم تحديث كلمة السر';

  @override
  String get removePassword => 'إزالة كلمة السر';

  @override
  String get removePasswordTitle => 'إزالة كلمة السر؟';

  @override
  String get removePasswordMessage =>
      'ستُحفظ الملاحظة بدون حماية ويمكن لأي شخص فتحها.';

  @override
  String get removeConfirm => 'إزالة';

  @override
  String get protectionRemovedToast => 'تمت إزالة الحماية';

  @override
  String get securedToast => 'تم تأمين الملاحظة';

  @override
  String get protectionFailedToast => 'تعذّر حماية الملاحظة، حاول مجددًا';

  @override
  String get noDetails => 'لا توجد تفاصيل';

  @override
  String get createdAtLabel => 'أُنشئت';

  @override
  String get lastModifiedLabel => 'آخر تعديل';

  @override
  String imagesCountLabel(int count) {
    return 'الصور ($count)';
  }

  @override
  String filesCountLabel(int count) {
    return 'الملفات ($count)';
  }

  @override
  String get enterCurrentPasswordMessage => 'أدخل كلمة السر الحالية للمتابعة';

  @override
  String get enterCurrentToRemoveMessage => 'أدخل كلمة السر الحالية لإزالتها';

  @override
  String get setPasswordDialogTitle => 'تعيين كلمة سر للملاحظة';

  @override
  String get setPasswordDialogMessage =>
      'ستُشفَّر محتويات الملاحظة ولا يمكن عرضها إلا بكلمة السر.';

  @override
  String imageOfTotal(int index, int total) {
    return 'صورة $index من $total';
  }

  @override
  String welcomeTitle(String appName) {
    return 'مرحبًا بك في $appName';
  }

  @override
  String get chooseLockSubtitle => 'اختر طريقة قفل التطبيق لحماية ملاحظاتك';

  @override
  String get methodBiometric => 'بصمة الإصبع أو الوجه';

  @override
  String get methodBiometricSubtitle => 'افتح ببصمتك أو وجهك المسجل على الجهاز';

  @override
  String get methodDevice => 'النمط أو الرقم السري للجهاز';

  @override
  String get methodDeviceSubtitle =>
      'افتح بالنمط أو الباسورد الذي قفلت به جهازك';

  @override
  String get methodPin => 'رقم سري للتطبيق';

  @override
  String methodPinSubtitle(String appName) {
    return 'افتح برقم سري خاص بـ $appName';
  }

  @override
  String get lockOptionDeviceTitle => 'أمان الجهاز';

  @override
  String get lockOptionDeviceSubtitle =>
      'استخدم البصمة أو النمط أو الرقم السري الموجود على جهازك';

  @override
  String get lockOptionPasswordTitle => 'باسورد للتطبيق';

  @override
  String get lockOptionPasswordSubtitle =>
      'أنشئ رقم سري خاص بالتطبيق مع خيار البصمة';

  @override
  String get lockOptionSkip => 'تخطي مؤقتًا';

  @override
  String get deviceSetupTitle => 'تحقق من هويتك';

  @override
  String get deviceSetupBody =>
      'استخدم بصمة جهازك أو النمط أو الرقم السري لفتح التطبيق';

  @override
  String get biometricOfferTitle => 'إضافة فتح بالبصمة؟';

  @override
  String biometricOfferBody(Object appName) {
    return 'جهازك يدعم فتح بالبصمة أو الوجه. فعّله للوصول أسرع إلى $appName؟';
  }

  @override
  String get biometricBackupNotice =>
      'يجب إنشاء رقم سري احتياطي في حالة عدم توفر البصمة';

  @override
  String get enableBiometric => 'تفعيل البصمة';

  @override
  String get skipBiometric => 'تخطي، استخدم الرقم السري فقط';

  @override
  String get backupPinBody => 'أنشئ رقم سري احتياطي في حالة عدم توفر البصمة';

  @override
  String get methodNone => 'بدون قفل';

  @override
  String get pinCreateTitle => 'إنشاء رقم سري';

  @override
  String get pinBackupTitle => 'إنشاء رقم سري احتياطي';

  @override
  String get pinConfirmTitle => 'تأكيد الرقم السري';

  @override
  String get pinReenterPrompt => 'أعد إدخال الرقم السري للتأكيد';

  @override
  String pinEnterLength(int length) {
    return 'أدخل رقمًا سريًا مكونًا من $length أرقام';
  }

  @override
  String get pinMismatchError => 'الرقمان غير متطابقين، حاول مرة أخرى';

  @override
  String get enterAppPin => 'أدخل الرقم السري للتطبيق';

  @override
  String get wrongPin => 'الرقم السري غير صحيح';

  @override
  String get bioCheckingSensor => 'جارٍ فحص مستشعر البصمة...';

  @override
  String get bioEnrollTitle => 'سجّل بصمتك في الجهاز أولًا';

  @override
  String bioPrivacyNote(String appName) {
    return 'البصمة ما بتتخزنش في $appName — بتفضل محفوظة في الجهاز نفسه بشكل آمن، والتطبيق بيستخدم مستشعر الجهاز بس.';
  }

  @override
  String get bioStep1 => 'افتح إعدادات الجهاز من زر \"فتح إعدادات البصمة\"';

  @override
  String get bioStep2 => 'دخّل الإعدادات → الأمان → بصمة الإصبع';

  @override
  String get bioStep3 => 'اتبع الخطوات وسجّل بصمتك';

  @override
  String get bioStep4 => 'ارجع للتطبيق واضغط \"تم — سجلت بصمتي\"';

  @override
  String get bioNotYetNotice =>
      'لسه مش متسجل — افتح إعدادات البصمة وسجّل بصمتك الأول';

  @override
  String get bioOpenSettings => 'فتح إعدادات البصمة';

  @override
  String get bioDoneEnrolled => 'تم — سجلت بصمتي';

  @override
  String get bioReadyTitle => 'مستشعر البصمة جاهز';

  @override
  String bioReadyBody(String appName) {
    return 'جهازك فيه بصمة متسجلة. من دلوقتي أي ما تفتح $appName هيطلب بصمتك من مستشعر الجهاز، ومتفتحش غير لما تطابق.';
  }

  @override
  String get bioTryNow => 'جرّب البصمة الآن';

  @override
  String get bioNotRecognizedLong => 'لم يتم التعرف على بصمتك، حاول مرة أخرى';

  @override
  String get bioUnavailableNow => 'الجهاز لا يستطيع تشغيل مستشعر البصمة الآن';

  @override
  String get bioUnsupportedTitle => 'جهازك لا يدعم البصمة';

  @override
  String get bioUnsupportedBody =>
      'مستشعر البصمة غير متاح على هذا الجهاز. تقدر تختار طريقة قفل تانية.';

  @override
  String get chooseAnotherMethod => 'اختيار طريقة أخرى';

  @override
  String get cannotOpenSettings => 'لا يمكن فتح إعدادات الجهاز هنا';

  @override
  String get verifying => 'جارٍ التحقق...';

  @override
  String get placeFinger => 'ضع بصمة إصبعك';

  @override
  String get deviceCredentialPrimaryHint =>
      'أو استخدم النمط أو الرقم السري الذي قفلت به جهازك';

  @override
  String get deviceCredentialFallbackHint =>
      'أو التحقق بالنمط أو الرقم السري للجهاز';

  @override
  String get notRecognizedRetry => 'لم يتم التعرف، حاول مرة أخرى';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get tryNowButton => 'التحقق الآن';

  @override
  String get useDeviceCredential => 'استخدام النمط أو الرقم السري';

  @override
  String get useBackupPin => 'استخدام الرقم السري الاحتياطي';

  @override
  String get biometricBackupHint =>
      'استخدم بصمتك للفتح، أو استخدم الرقم السري الاحتياطي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get sectionSecurity => 'القفل والتأمين';

  @override
  String get lockMethodTile => 'طريقة قفل التطبيق';

  @override
  String get lockMethodUnset => 'غير محددة';

  @override
  String get changePin => 'تغيير الرقم السري';

  @override
  String get sectionAppearance => 'المظهر';

  @override
  String get themeSystem => 'حسب إعداد الجهاز';

  @override
  String get themeLight => 'الوضع النهاري';

  @override
  String get themeDark => 'الوضع الليلي';

  @override
  String get sectionBackup => 'النسخ الاحتياطي';

  @override
  String get exportNotes => 'تصدير الملاحظات';

  @override
  String get exportSubtitle => 'ملف JSON يشمل المحذوفة، بدون الصور';

  @override
  String get importBackup => 'استيراد نسخة احتياطية';

  @override
  String get importSubtitle => 'تُضاف الملاحظات إلى الموجود حاليًا';

  @override
  String get sectionAbout => 'حول التطبيق';

  @override
  String get disableLockTitle => 'إلغاء قفل التطبيق؟';

  @override
  String get disableLockMessage =>
      'سيتمكن أي يفتح الجهاز من قراءة ملاحظاتك مباشرة.';

  @override
  String get disableLockConfirm => 'إلغاء القفل';

  @override
  String get noNotesToExport => 'لا توجد ملاحظات لتصديرها';

  @override
  String get exportFileTooltip => 'تصدير كملف نصي';

  @override
  String exportedWithLine(String app) {
    return 'مُصدَّرة من $app';
  }

  @override
  String get exportFailed => 'تعذر إنشاء ملف النسخة الاحتياطية';

  @override
  String get importConfirmTitle => 'استيراد النسخة؟';

  @override
  String importConfirmMessage(int count) {
    return 'سيتم إضافة $count ملاحظة إلى ملاحظاتك الحالية. لا تشمل النسخة الصور المرفقة.';
  }

  @override
  String get importConfirm => 'استيراد';

  @override
  String importedToast(int count) {
    return 'تم استيراد $count ملاحظة';
  }

  @override
  String get invalidBackupFile => 'الملف ليس نسخة احتياطية صالحة من Notey';

  @override
  String get readFileFailed => 'تعذر قراءة الملف';

  @override
  String get gridViewTooltip => 'عرض شبكي';

  @override
  String get listViewTooltip => 'عرض قائمة';

  @override
  String get readerFontSize => 'حجم خط القراءة';

  @override
  String get trashTitle => 'المحذوفات';

  @override
  String get emptyTrashTooltip => 'تفريغ السلة';

  @override
  String get emptyTrashTitle => 'تفريغ السلة؟';

  @override
  String emptyTrashMessage(int count) {
    return 'سيُحذف نهائيًا $count ملاحظة مع صورها.';
  }

  @override
  String get emptyTrashConfirm => 'تفريغ';

  @override
  String get trashEmptyTitle => 'السلة فارغة';

  @override
  String get trashEmptyBody =>
      'الملاحظات المحذوفة تظهر هنا لمدة 30 يومًا قبل حذفها نهائيًا';

  @override
  String get restoreTooltip => 'استعادة';

  @override
  String get purgeForeverTooltip => 'حذف نهائي';

  @override
  String get purgeForeverTitle => 'حذف نهائي؟';

  @override
  String get purgeForeverMessage => 'لا يمكن التراجع عن هذه الخطوة.';

  @override
  String get purgeForeverConfirm => 'حذف نهائيًا';

  @override
  String get deletedToday => 'اليوم';

  @override
  String get deletedYesterday => 'أمس';

  @override
  String deletedDaysAgo(int days) {
    return 'قبل $days يوم';
  }

  @override
  String restoredToast(String title) {
    return 'تمت استعادة \"$title\"';
  }

  @override
  String get passwordMinLengthError => 'كلمة السر يجب ألا تقل عن 6 أحرف';

  @override
  String get passwordsNoMatch => 'كلمتا السر غير متطابقتين';

  @override
  String get biometricPrompt => 'افتح تطبيق Notey';

  @override
  String get timeAm => 'ص';

  @override
  String get timePm => 'م';

  @override
  String get timeNow => 'الآن';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      many: 'قبل $count دقيقة',
      few: 'قبل $count دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      many: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      many: 'قبل $count يوم',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String lastWeekOn(String weekday) {
    return 'الأسبوع الماضي، $weekday';
  }

  @override
  String dayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String dayMonthYear(String day, String month, String year) {
    return '$day $month $year';
  }

  @override
  String fullDate(String day, String month, String year, String clock) {
    return '$day $month $year - $clock';
  }

  @override
  String get fileFromDeviceOption => 'اختيار ملف من الجهاز';

  @override
  String get attachmentPickFailed => 'تعذر إضافة الملف';

  @override
  String get tagsSection => 'الوسوم';

  @override
  String get addTagHint => 'أضف وسمًا...';

  @override
  String get formatBold => 'عريض';

  @override
  String get formatItalic => 'مائل';

  @override
  String get formatHeading => 'عنوان';

  @override
  String get formatBullet => 'قائمة نقطية';

  @override
  String get formatCheckbox => 'مهمة';

  @override
  String get formatCode => 'كود';

  @override
  String get addTag => 'إضافة وسم';

  @override
  String get noNotesWithTag => 'لا توجد ملاحظات بهذا الوسم';

  @override
  String get allTags => 'الكل';

  @override
  String get attachmentsSection => 'المرفقات';

  @override
  String get addAttachment => 'إضافة مرفق';

  @override
  String get editHistoryTitle => 'سجل التعديلات';

  @override
  String get noEditHistory => 'لا توجد تعديلات سابقة';

  @override
  String get currentVersion => 'الحالية';

  @override
  String get reminderScheduled => 'تم جدولة التذكير';

  @override
  String get reminderPermissionNeeded =>
      'إشعارات مطلوبة للتذكير. يرجى تفعيلها من الإعدادات.';

  @override
  String get reminderFailed =>
      'تعذر ضبط التذكير. يرجى التحقق من إعدادات الإشعارات.';

  @override
  String get pinLocked => 'محاولات كثيرة جداً. حاول مرة أخرى بعد';

  @override
  String get seconds => 'ثوانٍ';

  @override
  String get language => 'اللغة';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'English';

  @override
  String get textPlaceholder => 'نص';

  @override
  String get semNewNote => 'ملاحظة جديدة';

  @override
  String get semNewNoteHint => 'إنشاء ملاحظة جديدة';

  @override
  String get semBulkColor => 'تغيير اللون';

  @override
  String get semBulkPin => 'تثبيت';

  @override
  String get semBulkUnpin => 'إلغاء التثبيت';

  @override
  String get semBulkDelete => 'حذف المحدد';

  @override
  String semSelectColor(Object color) {
    return 'اختر اللون $color';
  }

  @override
  String get semRemoveImage => 'إزالة الصورة';

  @override
  String get semAddAttachment => 'إضافة مرفق';

  @override
  String get semAddPhoto => 'إضافة صورة';

  @override
  String get semAddFile => 'إضافة ملف';

  @override
  String get semOpenFile => 'فتح الملف';

  @override
  String get semRemoveFile => 'إزالة الملف';

  @override
  String get semSaveNote => 'حفظ الملاحظة';

  @override
  String get semSaveNoteHint => 'حفظ الملاحظة الحالية';

  @override
  String get semCloseSheet => 'إغلاق';

  @override
  String get semOpenImageViewer => 'عرض الصورة';

  @override
  String get semChecklistItem => 'عنصر قائمة';

  @override
  String get semChecklistHint => 'انقر مرتين للتبديل';

  @override
  String get semChecked => 'محدد';

  @override
  String get semUnchecked => 'غير محدد';

  @override
  String get semThemeSystem => 'سمة النظام';

  @override
  String get semThemeLight => 'سمة الفاتح';

  @override
  String get semThemeDark => 'سمة الداكن';

  @override
  String get semThemeHint => 'اضغط للاختيار';

  @override
  String get semReaderFont => 'حجم خط القارئ';

  @override
  String get semPickFromCamera => 'التقط صورة بالكاميرا';

  @override
  String get semPickFromGallery => 'اختر صورة من المعرض';

  @override
  String get semPickFile => 'اختر ملف من الجهاز';

  @override
  String get semRecordVoice => 'تسجيل ملاحظة صوتية';

  @override
  String get semDrawSketch => 'رسم مخطط';

  @override
  String get redoAction => 'إعادة';

  @override
  String get eraser => 'ممحاة';

  @override
  String get trashRetention => 'مدة الاحتفاظ بالمحذوفات';

  @override
  String trashRetentionDays(int days) {
    return '$days يوم';
  }

  @override
  String trashRetentionLabel(int days) {
    return 'تُحفظ الملاحظات المحذوفة لمدة $days يومًا';
  }

  @override
  String get clearAllData => 'مسح جميع البيانات';

  @override
  String get clearAllDataSubtitle =>
      'حذف جميع الملاحظات والملفات والإعدادات نهائيًا';

  @override
  String get clearAllDataTitle => 'مسح جميع البيانات؟';

  @override
  String get clearAllDataMessage =>
      'سيتم حذف جميع الملاحظات والملفات وإعدادات القفل نهائيًا. أدخل رقمك السري أو كلمة السر للتأكيد.';

  @override
  String get clearAllDataConfirm => 'مسح كل شيء';

  @override
  String get enterPasswordToConfirm => 'أدخل كلمة السر للتأكيد';

  @override
  String get dataClearedToast => 'تم مسح جميع البيانات';

  @override
  String get restoreHistoryVersion => 'استعادة هذا الإصدار';

  @override
  String get historyRestoredToast => 'تمت استعادة الملاحظة لهذا الإصدار';

  @override
  String get exportPdfTooltip => 'تصدير كـ PDF';

  @override
  String get exportMarkdownTooltip => 'تصدير كـ Markdown';

  @override
  String get exportPdfFailed => 'تعذر إنشاء ملف PDF';

  @override
  String get exportMarkdownFailed => 'تعذر إنشاء ملف Markdown';

  @override
  String get folderSection => 'المجلد';

  @override
  String get folderHint => 'تعيين لمجلد...';

  @override
  String get allFolders => 'كل المجلدات';

  @override
  String get sortCustom => 'ترتيب يدوي';

  @override
  String get searchInNote => 'بحث في الملاحظة';

  @override
  String get searchNoMatches => 'لا توجد نتائج';

  @override
  String searchMatchOf(int current, int total) {
    return '$current من $total';
  }

  @override
  String get searchHistoryTitle => 'عمليات البحث الأخيرة';

  @override
  String get searchHistoryClear => 'مسح الكل';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة',
      many: '$count نتيجة',
      few: '$count نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
      zero: 'لا توجد نتائج',
    );
    return '$_temp0';
  }

  @override
  String get vaultTitle => 'الخزنة';

  @override
  String get vaultEmptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get vaultEmptyHint =>
      'احفظ كلمات المرور والبطاقات والحسابات والملاحظات السرية في الخزنة المشفرة';

  @override
  String get vaultAdd => 'إضافة';

  @override
  String get vaultAddLogin => 'كلمة مرور';

  @override
  String get vaultAddCard => 'بطاقة ائتمان';

  @override
  String get vaultAddBank => 'حساب بنكي';

  @override
  String get vaultAddSecureNote => 'ملاحظة سرية';

  @override
  String get vaultFilterAll => 'الكل';

  @override
  String get vaultFilterPasswords => 'كلمات المرور';

  @override
  String get vaultFilterBanking => 'بنوك';

  @override
  String get vaultFilterDocuments => 'مستندات';

  @override
  String get vaultFilterAudio => 'صوتيات';

  @override
  String get vaultFilterCanvas => 'رسومات';

  @override
  String get vaultTitleLabel => 'العنوان';

  @override
  String get vaultTitleHint => 'مثال: بريد جيميل';

  @override
  String get vaultFieldUsername => 'اسم المستخدم';

  @override
  String get vaultFieldPassword => 'كلمة المرور';

  @override
  String get vaultFieldCardHolder => 'اسم حامل البطاقة';

  @override
  String get vaultFieldCardNumber => 'رقم البطاقة';

  @override
  String get vaultFieldExpiry => 'تاريخ الانتهاء (MM/YY)';

  @override
  String get vaultFieldCvv => 'رمز الأمان (CVV)';

  @override
  String get vaultFieldCardPin => 'الرقم السري للبطاقة';

  @override
  String get vaultFieldBankName => 'اسم البنك';

  @override
  String get vaultFieldIban => 'رقم الآيبان';

  @override
  String get vaultFieldAccountName => 'اسم صاحب الحساب';

  @override
  String get vaultFieldSwift => 'رمز السويفت';

  @override
  String get vaultNotes => 'ملاحظات';

  @override
  String get vaultNotesHint => 'إضافية (اختياري)';

  @override
  String get vaultShow => 'إظهار';

  @override
  String get vaultHide => 'إخفاء';

  @override
  String get vaultCopy => 'نسخ';

  @override
  String get vaultCopiedToast => 'تم النسخ';

  @override
  String get vaultShareLabel => 'مشاركة';

  @override
  String get vaultDeleteTitle => 'حذف العنصر؟';

  @override
  String get vaultDeleteMessage => 'لن يمكن التراجع عن حذف هذا العنصر.';

  @override
  String get vaultGeneratePassword => 'توليد كلمة مرور';

  @override
  String get vaultAttachmentAdd => 'إضافة مرفق';

  @override
  String get vaultAttachmentHint => 'ملف مشفر (مستند، صورة، صوت…)';

  @override
  String get vaultOpenAttachment => 'فتح';

  @override
  String get vaultMediaLabel => 'نوع الملف';

  @override
  String get vaultMediaAuto => 'تلقائي';

  @override
  String get vaultMediaDocument => 'مستند';

  @override
  String get vaultMediaAudio => 'صوتي';

  @override
  String get vaultMediaDrawing => 'رسم';

  @override
  String get vaultScreenProtected => 'الحماية من اللقطات مفعّلة';

  @override
  String get vaultErrorLoading => 'تعذر تحميل الخزنة';

  @override
  String get documentPreviewShare => 'مشاركة';

  @override
  String get documentOpenFailed => 'تعذر فتح الملف';

  @override
  String get documentHandedToExternal => 'تم فتح الملف في تطبيق خارجي';

  @override
  String get documentNoAppHint =>
      'لا يوجد تطبيق مثبت لفتح هذا النوع من الملفات';

  @override
  String get documentOpenExternal => 'فتح في تطبيق خارجي';

  @override
  String get documentPlaybackFailed => 'تعذر تشغيل هذا الملف الصوتي';

  @override
  String get audioPlay => 'تشغيل';

  @override
  String get audioPause => 'إيقاف';

  @override
  String get audioUnavailable => 'تعذر تشغيل الصوت';

  @override
  String get reRecord => 'إعادة التسجيل';

  @override
  String get attach => 'إرفاق';

  @override
  String get replayPreview => 'معاينة';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج';
}
