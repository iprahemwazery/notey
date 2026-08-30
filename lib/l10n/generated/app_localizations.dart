import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك.. في أمان'**
  String get tagline;

  /// No description provided for @forgotPin.
  ///
  /// In ar, this message translates to:
  /// **'نسيت الرمز؟'**
  String get forgotPin;

  /// No description provided for @resetAppTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين التطبيق'**
  String get resetAppTitle;

  /// No description provided for @resetAppWarning.
  ///
  /// In ar, this message translates to:
  /// **'سيتم مسح جميع الملاحظات والملفات وإعدادات القفل نهائيًا. لا يمكن التراجع عن هذه الخطوة.'**
  String get resetAppWarning;

  /// No description provided for @resetAppConfirm.
  ///
  /// In ar, this message translates to:
  /// **'مسح وإعادة التعيين'**
  String get resetAppConfirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @undoAction.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undoAction;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueLabel;

  /// No description provided for @homeNewNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get homeNewNote;

  /// No description provided for @homeSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في ملاحظاتك...'**
  String get homeSearchHint;

  /// No description provided for @homeClearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get homeClearSearch;

  /// No description provided for @homeNotesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{ابدأ بكتابة أول ملاحظة} =1{ملاحظة واحدة} =2{ملاحظتان} few{{count} ملاحظات} many{{count} ملاحظة} other{{count} ملاحظة}}'**
  String homeNotesCount(int count);

  /// No description provided for @themeLightTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get themeLightTooltip;

  /// No description provided for @themeDarkTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get themeDarkTooltip;

  /// No description provided for @sortTooltip.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب'**
  String get sortTooltip;

  /// No description provided for @sortNewestFirst.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث أولًا'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In ar, this message translates to:
  /// **'الأقدم أولًا'**
  String get sortOldestFirst;

  /// No description provided for @sortByColor.
  ///
  /// In ar, this message translates to:
  /// **'حسب اللون'**
  String get sortByColor;

  /// No description provided for @selectionClear.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التحديد'**
  String get selectionClear;

  /// No description provided for @selectionCount.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد {selected} من {total}'**
  String selectionCount(int selected, int total);

  /// No description provided for @selectionAll.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل'**
  String get selectionAll;

  /// No description provided for @selectionNone.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء تحديد الكل'**
  String get selectionNone;

  /// No description provided for @actionColor.
  ///
  /// In ar, this message translates to:
  /// **'اللون'**
  String get actionColor;

  /// No description provided for @actionPin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت'**
  String get actionPin;

  /// No description provided for @actionUnpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get actionUnpin;

  /// No description provided for @colorSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{لون ملاحظة واحدة} few{لون {count} ملاحظات} many{لون {count} ملاحظات} other{لون {count} ملاحظة}}'**
  String colorSheetTitle(int count);

  /// No description provided for @applyColor.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق اللون'**
  String get applyColor;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة؟'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteTrashMessage.
  ///
  /// In ar, this message translates to:
  /// **'تُنقل الملاحظة إلى المحذوفات ويمكن استعادتها خلال 30 يومًا.'**
  String get deleteNoteTrashMessage;

  /// No description provided for @deleteManyTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظات؟'**
  String get deleteManyTitle;

  /// No description provided for @deleteManyMessage.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{سيتم نقل ملاحظة واحدة إلى المحذوفات ويمكن استعادتها.} few{سيتم نقل {count} ملاحظات إلى المحذوفات ويمكن استعادتها.} many{سيتم نقل {count} ملاحظة إلى المحذوفات ويمكن استعادتها.} other{سيتم نقل {count} ملاحظة إلى المحذوفات ويمكن استعادتها.}}'**
  String deleteManyMessage(int count);

  /// No description provided for @movedToTrashOne.
  ///
  /// In ar, this message translates to:
  /// **'تم نقل الملاحظة إلى المحذوفات'**
  String get movedToTrashOne;

  /// No description provided for @movedToTrashCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تم نقل الملاحظة إلى المحذوفات} few{تم نقل {count} ملاحظات إلى المحذوفات} many{تم نقل {count} ملاحظة إلى المحذوفات} other{تم نقل {count} ملاحظة إلى المحذوفات}}'**
  String movedToTrashCount(int count);

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @tryOtherSearch.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة بحث أخرى'**
  String get tryOtherSearch;

  /// No description provided for @emptyNotes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات بعد'**
  String get emptyNotes;

  /// No description provided for @emptyNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط زر \"ملاحظة جديدة\" للبدء'**
  String get emptyNotesHint;

  /// No description provided for @lockedNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة محمية'**
  String get lockedNote;

  /// No description provided for @untitled.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان'**
  String get untitled;

  /// No description provided for @editorEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل ملاحظة'**
  String get editorEditTitle;

  /// No description provided for @editorNewTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get editorNewTitle;

  /// No description provided for @saving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ...'**
  String get saving;

  /// No description provided for @editorSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الملاحظة'**
  String get editorSaveButton;

  /// No description provided for @editorTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الملاحظة...'**
  String get editorTitleHint;

  /// No description provided for @editorContentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تفاصيل ملاحظتك هنا...'**
  String get editorContentHint;

  /// No description provided for @imagesSection.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get imagesSection;

  /// No description provided for @addImageSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مرفق للملاحظة'**
  String get addImageSheetTitle;

  /// No description provided for @cameraOption.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة بالكاميرا'**
  String get cameraOption;

  /// No description provided for @galleryOption.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get galleryOption;

  /// No description provided for @imagePickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحصول على الصورة'**
  String get imagePickFailed;

  /// No description provided for @titleRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنوانًا للملاحظة أولًا'**
  String get titleRequired;

  /// No description provided for @reminderSection.
  ///
  /// In ar, this message translates to:
  /// **'التذكير'**
  String get reminderSection;

  /// No description provided for @noReminder.
  ///
  /// In ar, this message translates to:
  /// **'بدون تذكير'**
  String get noReminder;

  /// No description provided for @editReminder.
  ///
  /// In ar, this message translates to:
  /// **'تحديد وقت التذكير'**
  String get editReminder;

  /// No description provided for @clearReminder.
  ///
  /// In ar, this message translates to:
  /// **'إزالة التذكير'**
  String get clearReminder;

  /// No description provided for @pastReminderToast.
  ///
  /// In ar, this message translates to:
  /// **'اختر وقتًا في المستقبل'**
  String get pastReminderToast;

  /// No description provided for @drawOption.
  ///
  /// In ar, this message translates to:
  /// **'رسم'**
  String get drawOption;

  /// No description provided for @drawTitle.
  ///
  /// In ar, this message translates to:
  /// **'رسم جديد'**
  String get drawTitle;

  /// No description provided for @voiceNoteOption.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل صوتي'**
  String get voiceNoteOption;

  /// No description provided for @voiceNoteRecHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الميكروفون لبدء التسجيل'**
  String get voiceNoteRecHint;

  /// No description provided for @micDeniedToast.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم منح إذن المايكروفون'**
  String get micDeniedToast;

  /// No description provided for @onbTitle1.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك، منسّقة وجميلة'**
  String get onbTitle1;

  /// No description provided for @onbBody1.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظاتك بتنسيق Markdown، ونظّمها بالوسوم والألوان.'**
  String get onbBody1;

  /// No description provided for @onbTitle2.
  ///
  /// In ar, this message translates to:
  /// **'كل شيء في مكانه'**
  String get onbTitle2;

  /// No description provided for @onbBody2.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات، مرفقات صور وأصوات وملفات، بحث سريع، واستقبال المشاركة من أي تطبيق.'**
  String get onbBody2;

  /// No description provided for @onbTitle3.
  ///
  /// In ar, this message translates to:
  /// **'خصوصيتك أولاً'**
  String get onbTitle3;

  /// No description provided for @onbBody3.
  ///
  /// In ar, this message translates to:
  /// **'اقفل التطبيق أو الملاحظات المنفردة بكلمة سر — وبياناتك تبقى على جهازك فقط.'**
  String get onbBody3;

  /// No description provided for @onbNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onbNext;

  /// No description provided for @onbStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get onbStart;

  /// No description provided for @onbSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onbSkip;

  /// No description provided for @noteSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملاحظة'**
  String get noteSaved;

  /// No description provided for @noteSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ الملاحظة، حاول مرة أخرى'**
  String get noteSaveFailed;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغييرات غير محفوظة'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حفظ التغييرات أم تجاهلها؟'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get discard;

  /// No description provided for @relockBeforeEditHint.
  ///
  /// In ar, this message translates to:
  /// **'أعد فتح الملاحظة بكلمة السر قبل تعديلها'**
  String get relockBeforeEditHint;

  /// No description provided for @protectMenuTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حماية الملاحظة'**
  String get protectMenuTooltip;

  /// No description provided for @setPasswordItem.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة سر'**
  String get setPasswordItem;

  /// No description provided for @removePasswordOnSave.
  ///
  /// In ar, this message translates to:
  /// **'إزالة كلمة السر عند الحفظ'**
  String get removePasswordOnSave;

  /// No description provided for @noteProtectedItem.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة محمية'**
  String get noteProtectedItem;

  /// No description provided for @secureDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأمين الملاحظة'**
  String get secureDialogTitle;

  /// No description provided for @secureDialogMessage.
  ///
  /// In ar, this message translates to:
  /// **'ستُشفَّر محتويات الملاحظة ولا يمكن عرضها إلا بكلمة السر.'**
  String get secureDialogMessage;

  /// No description provided for @secureConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأمين'**
  String get secureConfirm;

  /// No description provided for @willSaveUnprotected.
  ///
  /// In ar, this message translates to:
  /// **'ستُحفظ الملاحظة بدون حماية عند الحفظ'**
  String get willSaveUnprotected;

  /// No description provided for @viewerTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة'**
  String get viewerTitle;

  /// No description provided for @shareTooltip.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get shareTooltip;

  /// No description provided for @noAppToOpenFile.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تطبيق يقدر يفتح نوع الملف ده'**
  String get noAppToOpenFile;

  /// No description provided for @unlockTooltip.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملاحظة'**
  String get unlockTooltip;

  /// No description provided for @wrongPasswordToast.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر غير صحيحة'**
  String get wrongPasswordToast;

  /// No description provided for @unlockDialogMessage.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة السر لفتح الملاحظة'**
  String get unlockDialogMessage;

  /// No description provided for @unlockConfirm.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get unlockConfirm;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة السر'**
  String get confirmPasswordHint;

  /// No description provided for @unlockPanelTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذه الملاحظة محمية بكلمة سر'**
  String get unlockPanelTitle;

  /// No description provided for @unlockPanelButton.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملاحظة'**
  String get unlockPanelButton;

  /// No description provided for @manageProtection.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحماية'**
  String get manageProtection;

  /// No description provided for @protectSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'حماية الملاحظة'**
  String get protectSheetTitle;

  /// No description provided for @setPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حماية عنوان وتفاصيل الملاحظة'**
  String get setPasswordSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة السر'**
  String get changePassword;

  /// No description provided for @newPasswordMessage.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة السر الجديدة'**
  String get newPasswordMessage;

  /// No description provided for @updateConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get updateConfirm;

  /// No description provided for @passwordUpdatedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث كلمة السر'**
  String get passwordUpdatedToast;

  /// No description provided for @removePassword.
  ///
  /// In ar, this message translates to:
  /// **'إزالة كلمة السر'**
  String get removePassword;

  /// No description provided for @removePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة كلمة السر؟'**
  String get removePasswordTitle;

  /// No description provided for @removePasswordMessage.
  ///
  /// In ar, this message translates to:
  /// **'ستُحفظ الملاحظة بدون حماية ويمكن لأي شخص فتحها.'**
  String get removePasswordMessage;

  /// No description provided for @removeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get removeConfirm;

  /// No description provided for @protectionRemovedToast.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة الحماية'**
  String get protectionRemovedToast;

  /// No description provided for @securedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم تأمين الملاحظة'**
  String get securedToast;

  /// No description provided for @noDetails.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تفاصيل'**
  String get noDetails;

  /// No description provided for @createdAtLabel.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئت'**
  String get createdAtLabel;

  /// No description provided for @lastModifiedLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر تعديل'**
  String get lastModifiedLabel;

  /// No description provided for @imagesCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصور ({count})'**
  String imagesCountLabel(int count);

  /// No description provided for @filesCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'الملفات ({count})'**
  String filesCountLabel(int count);

  /// No description provided for @enterCurrentPasswordMessage.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة السر الحالية للمتابعة'**
  String get enterCurrentPasswordMessage;

  /// No description provided for @enterCurrentToRemoveMessage.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة السر الحالية لإزالتها'**
  String get enterCurrentToRemoveMessage;

  /// No description provided for @setPasswordDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة سر للملاحظة'**
  String get setPasswordDialogTitle;

  /// No description provided for @setPasswordDialogMessage.
  ///
  /// In ar, this message translates to:
  /// **'ستُشفَّر محتويات الملاحظة ولا يمكن عرضها إلا بكلمة السر.'**
  String get setPasswordDialogMessage;

  /// No description provided for @imageOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'صورة {index} من {total}'**
  String imageOfTotal(int index, int total);

  /// No description provided for @welcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بك في {appName}'**
  String welcomeTitle(String appName);

  /// No description provided for @chooseLockSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة قفل التطبيق لحماية ملاحظاتك'**
  String get chooseLockSubtitle;

  /// No description provided for @methodBiometric.
  ///
  /// In ar, this message translates to:
  /// **'بصمة الإصبع أو الوجه'**
  String get methodBiometric;

  /// No description provided for @methodBiometricSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح ببصمتك أو وجهك المسجل على الجهاز'**
  String get methodBiometricSubtitle;

  /// No description provided for @methodDevice.
  ///
  /// In ar, this message translates to:
  /// **'النمط أو الرقم السري للجهاز'**
  String get methodDevice;

  /// No description provided for @methodDeviceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح بالنمط أو الباسورد الذي قفلت به جهازك'**
  String get methodDeviceSubtitle;

  /// No description provided for @methodPin.
  ///
  /// In ar, this message translates to:
  /// **'رقم سري للتطبيق'**
  String get methodPin;

  /// No description provided for @methodPinSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح برقم سري خاص بـ {appName}'**
  String methodPinSubtitle(String appName);

  /// No description provided for @lockOptionDeviceTitle.
  ///
  /// In ar, this message translates to:
  /// **'أمان الجهاز'**
  String get lockOptionDeviceTitle;

  /// No description provided for @lockOptionDeviceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استخدم البصمة أو النمط أو الرقم السري الموجود على جهازك'**
  String get lockOptionDeviceSubtitle;

  /// No description provided for @lockOptionPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'باسورد للتطبيق'**
  String get lockOptionPasswordTitle;

  /// No description provided for @lockOptionPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رقم سري خاص بالتطبيق مع خيار البصمة'**
  String get lockOptionPasswordSubtitle;

  /// No description provided for @lockOptionSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي مؤقتًا'**
  String get lockOptionSkip;

  /// No description provided for @deviceSetupTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من هويتك'**
  String get deviceSetupTitle;

  /// No description provided for @deviceSetupBody.
  ///
  /// In ar, this message translates to:
  /// **'استخدم بصمة جهازك أو النمط أو الرقم السري لفتح التطبيق'**
  String get deviceSetupBody;

  /// No description provided for @biometricOfferTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فتح بالبصمة؟'**
  String get biometricOfferTitle;

  /// No description provided for @biometricOfferBody.
  ///
  /// In ar, this message translates to:
  /// **'جهازك يدعم فتح بالبصمة أو الوجه. فعّله للوصول أسرع إلى {appName}؟'**
  String biometricOfferBody(Object appName);

  /// No description provided for @biometricBackupNotice.
  ///
  /// In ar, this message translates to:
  /// **'يجب إنشاء رقم سري احتياطي في حالة عدم توفر البصمة'**
  String get biometricBackupNotice;

  /// No description provided for @enableBiometric.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل البصمة'**
  String get enableBiometric;

  /// No description provided for @skipBiometric.
  ///
  /// In ar, this message translates to:
  /// **'تخطي، استخدم الرقم السري فقط'**
  String get skipBiometric;

  /// No description provided for @backupPinBody.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رقم سري احتياطي في حالة عدم توفر البصمة'**
  String get backupPinBody;

  /// No description provided for @methodNone.
  ///
  /// In ar, this message translates to:
  /// **'بدون قفل'**
  String get methodNone;

  /// No description provided for @pinCreateTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رقم سري'**
  String get pinCreateTitle;

  /// No description provided for @pinBackupTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رقم سري احتياطي'**
  String get pinBackupTitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرقم السري'**
  String get pinConfirmTitle;

  /// No description provided for @pinReenterPrompt.
  ///
  /// In ar, this message translates to:
  /// **'أعد إدخال الرقم السري للتأكيد'**
  String get pinReenterPrompt;

  /// No description provided for @pinEnterLength.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقمًا سريًا مكونًا من {length} أرقام'**
  String pinEnterLength(int length);

  /// No description provided for @pinMismatchError.
  ///
  /// In ar, this message translates to:
  /// **'الرقمان غير متطابقين، حاول مرة أخرى'**
  String get pinMismatchError;

  /// No description provided for @enterAppPin.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرقم السري للتطبيق'**
  String get enterAppPin;

  /// No description provided for @wrongPin.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري غير صحيح'**
  String get wrongPin;

  /// No description provided for @bioCheckingSensor.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فحص مستشعر البصمة...'**
  String get bioCheckingSensor;

  /// No description provided for @bioEnrollTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل بصمتك في الجهاز أولًا'**
  String get bioEnrollTitle;

  /// No description provided for @bioPrivacyNote.
  ///
  /// In ar, this message translates to:
  /// **'البصمة ما بتتخزنش في {appName} — بتفضل محفوظة في الجهاز نفسه بشكل آمن، والتطبيق بيستخدم مستشعر الجهاز بس.'**
  String bioPrivacyNote(String appName);

  /// No description provided for @bioStep1.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الجهاز من زر \"فتح إعدادات البصمة\"'**
  String get bioStep1;

  /// No description provided for @bioStep2.
  ///
  /// In ar, this message translates to:
  /// **'دخّل الإعدادات → الأمان → بصمة الإصبع'**
  String get bioStep2;

  /// No description provided for @bioStep3.
  ///
  /// In ar, this message translates to:
  /// **'اتبع الخطوات وسجّل بصمتك'**
  String get bioStep3;

  /// No description provided for @bioStep4.
  ///
  /// In ar, this message translates to:
  /// **'ارجع للتطبيق واضغط \"تم — سجلت بصمتي\"'**
  String get bioStep4;

  /// No description provided for @bioNotYetNotice.
  ///
  /// In ar, this message translates to:
  /// **'لسه مش متسجل — افتح إعدادات البصمة وسجّل بصمتك الأول'**
  String get bioNotYetNotice;

  /// No description provided for @bioOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات البصمة'**
  String get bioOpenSettings;

  /// No description provided for @bioDoneEnrolled.
  ///
  /// In ar, this message translates to:
  /// **'تم — سجلت بصمتي'**
  String get bioDoneEnrolled;

  /// No description provided for @bioReadyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مستشعر البصمة جاهز'**
  String get bioReadyTitle;

  /// No description provided for @bioReadyBody.
  ///
  /// In ar, this message translates to:
  /// **'جهازك فيه بصمة متسجلة. من دلوقتي أي ما تفتح {appName} هيطلب بصمتك من مستشعر الجهاز، ومتفتحش غير لما تطابق.'**
  String bioReadyBody(String appName);

  /// No description provided for @bioTryNow.
  ///
  /// In ar, this message translates to:
  /// **'جرّب البصمة الآن'**
  String get bioTryNow;

  /// No description provided for @bioNotRecognizedLong.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم التعرف على بصمتك، حاول مرة أخرى'**
  String get bioNotRecognizedLong;

  /// No description provided for @bioUnavailableNow.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز لا يستطيع تشغيل مستشعر البصمة الآن'**
  String get bioUnavailableNow;

  /// No description provided for @bioUnsupportedTitle.
  ///
  /// In ar, this message translates to:
  /// **'جهازك لا يدعم البصمة'**
  String get bioUnsupportedTitle;

  /// No description provided for @bioUnsupportedBody.
  ///
  /// In ar, this message translates to:
  /// **'مستشعر البصمة غير متاح على هذا الجهاز. تقدر تختار طريقة قفل تانية.'**
  String get bioUnsupportedBody;

  /// No description provided for @chooseAnotherMethod.
  ///
  /// In ar, this message translates to:
  /// **'اختيار طريقة أخرى'**
  String get chooseAnotherMethod;

  /// No description provided for @cannotOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن فتح إعدادات الجهاز هنا'**
  String get cannotOpenSettings;

  /// No description provided for @verifying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق...'**
  String get verifying;

  /// No description provided for @placeFinger.
  ///
  /// In ar, this message translates to:
  /// **'ضع بصمة إصبعك'**
  String get placeFinger;

  /// No description provided for @deviceCredentialPrimaryHint.
  ///
  /// In ar, this message translates to:
  /// **'أو استخدم النمط أو الرقم السري الذي قفلت به جهازك'**
  String get deviceCredentialPrimaryHint;

  /// No description provided for @deviceCredentialFallbackHint.
  ///
  /// In ar, this message translates to:
  /// **'أو التحقق بالنمط أو الرقم السري للجهاز'**
  String get deviceCredentialFallbackHint;

  /// No description provided for @notRecognizedRetry.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم التعرف، حاول مرة أخرى'**
  String get notRecognizedRetry;

  /// No description provided for @retryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryButton;

  /// No description provided for @tryNowButton.
  ///
  /// In ar, this message translates to:
  /// **'التحقق الآن'**
  String get tryNowButton;

  /// No description provided for @useDeviceCredential.
  ///
  /// In ar, this message translates to:
  /// **'استخدام النمط أو الرقم السري'**
  String get useDeviceCredential;

  /// No description provided for @useBackupPin.
  ///
  /// In ar, this message translates to:
  /// **'استخدام الرقم السري الاحتياطي'**
  String get useBackupPin;

  /// No description provided for @biometricBackupHint.
  ///
  /// In ar, this message translates to:
  /// **'استخدم بصمتك للفتح، أو استخدم الرقم السري الاحتياطي'**
  String get biometricBackupHint;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @sectionSecurity.
  ///
  /// In ar, this message translates to:
  /// **'القفل والتأمين'**
  String get sectionSecurity;

  /// No description provided for @lockMethodTile.
  ///
  /// In ar, this message translates to:
  /// **'طريقة قفل التطبيق'**
  String get lockMethodTile;

  /// No description provided for @lockMethodUnset.
  ///
  /// In ar, this message translates to:
  /// **'غير محددة'**
  String get lockMethodUnset;

  /// No description provided for @changePin.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم السري'**
  String get changePin;

  /// No description provided for @sectionAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get sectionAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب إعداد الجهاز'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get themeDark;

  /// No description provided for @sectionBackup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get sectionBackup;

  /// No description provided for @exportNotes.
  ///
  /// In ar, this message translates to:
  /// **'تصدير الملاحظات'**
  String get exportNotes;

  /// No description provided for @exportSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف JSON يشمل المحذوفة، بدون الصور'**
  String get exportSubtitle;

  /// No description provided for @importBackup.
  ///
  /// In ar, this message translates to:
  /// **'استيراد نسخة احتياطية'**
  String get importBackup;

  /// No description provided for @importSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تُضاف الملاحظات إلى الموجود حاليًا'**
  String get importSubtitle;

  /// No description provided for @sectionAbout.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get sectionAbout;

  /// No description provided for @disableLockTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء قفل التطبيق؟'**
  String get disableLockTitle;

  /// No description provided for @disableLockMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتمكن أي يفتح الجهاز من قراءة ملاحظاتك مباشرة.'**
  String get disableLockMessage;

  /// No description provided for @disableLockConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء القفل'**
  String get disableLockConfirm;

  /// No description provided for @noNotesToExport.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات لتصديرها'**
  String get noNotesToExport;

  /// No description provided for @exportFileTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تصدير كملف نصي'**
  String get exportFileTooltip;

  /// No description provided for @exportedWithLine.
  ///
  /// In ar, this message translates to:
  /// **'مُصدَّرة من {app}'**
  String exportedWithLine(String app);

  /// No description provided for @exportFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء ملف النسخة الاحتياطية'**
  String get exportFailed;

  /// No description provided for @importConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'استيراد النسخة؟'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة {count} ملاحظة إلى ملاحظاتك الحالية. لا تشمل النسخة الصور المرفقة.'**
  String importConfirmMessage(int count);

  /// No description provided for @importConfirm.
  ///
  /// In ar, this message translates to:
  /// **'استيراد'**
  String get importConfirm;

  /// No description provided for @importedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد {count} ملاحظة'**
  String importedToast(int count);

  /// No description provided for @invalidBackupFile.
  ///
  /// In ar, this message translates to:
  /// **'الملف ليس نسخة احتياطية صالحة من Notey'**
  String get invalidBackupFile;

  /// No description provided for @readFileFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة الملف'**
  String get readFileFailed;

  /// No description provided for @gridViewTooltip.
  ///
  /// In ar, this message translates to:
  /// **'عرض شبكي'**
  String get gridViewTooltip;

  /// No description provided for @listViewTooltip.
  ///
  /// In ar, this message translates to:
  /// **'عرض قائمة'**
  String get listViewTooltip;

  /// No description provided for @readerFontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم خط القراءة'**
  String get readerFontSize;

  /// No description provided for @trashTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحذوفات'**
  String get trashTitle;

  /// No description provided for @emptyTrashTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ السلة'**
  String get emptyTrashTooltip;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ السلة؟'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrashMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف نهائيًا {count} ملاحظة مع صورها.'**
  String emptyTrashMessage(int count);

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ'**
  String get emptyTrashConfirm;

  /// No description provided for @trashEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get trashEmptyTitle;

  /// No description provided for @trashEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات المحذوفة تظهر هنا لمدة 30 يومًا قبل حذفها نهائيًا'**
  String get trashEmptyBody;

  /// No description provided for @restoreTooltip.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get restoreTooltip;

  /// No description provided for @purgeForeverTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي'**
  String get purgeForeverTooltip;

  /// No description provided for @purgeForeverTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي؟'**
  String get purgeForeverTitle;

  /// No description provided for @purgeForeverMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذه الخطوة.'**
  String get purgeForeverMessage;

  /// No description provided for @purgeForeverConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائيًا'**
  String get purgeForeverConfirm;

  /// No description provided for @deletedToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get deletedToday;

  /// No description provided for @deletedYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get deletedYesterday;

  /// No description provided for @deletedDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'قبل {days} يوم'**
  String deletedDaysAgo(int days);

  /// No description provided for @restoredToast.
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة \"{title}\"'**
  String restoredToast(String title);

  /// No description provided for @passwordMinLengthError.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر يجب ألا تقل عن 6 أحرف'**
  String get passwordMinLengthError;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا السر غير متطابقتين'**
  String get passwordsNoMatch;

  /// No description provided for @biometricPrompt.
  ///
  /// In ar, this message translates to:
  /// **'افتح تطبيق Notey'**
  String get biometricPrompt;

  /// No description provided for @timeAm.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get timeAm;

  /// No description provided for @timePm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get timePm;

  /// No description provided for @timeNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get timeNow;

  /// No description provided for @minutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل دقيقة واحدة} =2{قبل دقيقتين} few{قبل {count} دقائق} many{قبل {count} دقيقة} other{قبل {count} دقيقة}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل ساعة واحدة} =2{قبل ساعتين} few{قبل {count} ساعات} many{قبل {count} ساعة} other{قبل {count} ساعة}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل يوم واحد} =2{قبل يومين} few{قبل {count} أيام} many{قبل {count} يوم} other{قبل {count} يوم}}'**
  String daysAgo(int count);

  /// No description provided for @lastWeekOn.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع الماضي، {weekday}'**
  String lastWeekOn(String weekday);

  /// No description provided for @dayMonth.
  ///
  /// In ar, this message translates to:
  /// **'{day} {month}'**
  String dayMonth(String day, String month);

  /// No description provided for @dayMonthYear.
  ///
  /// In ar, this message translates to:
  /// **'{day} {month} {year}'**
  String dayMonthYear(String day, String month, String year);

  /// No description provided for @fullDate.
  ///
  /// In ar, this message translates to:
  /// **'{day} {month} {year} - {clock}'**
  String fullDate(String day, String month, String year, String clock);

  /// No description provided for @fileFromDeviceOption.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف من الجهاز'**
  String get fileFromDeviceOption;

  /// No description provided for @attachmentPickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إضافة الملف'**
  String get attachmentPickFailed;

  /// No description provided for @tagsSection.
  ///
  /// In ar, this message translates to:
  /// **'الوسوم'**
  String get tagsSection;

  /// No description provided for @addTagHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف وسمًا...'**
  String get addTagHint;

  /// No description provided for @formatBold.
  ///
  /// In ar, this message translates to:
  /// **'عريض'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In ar, this message translates to:
  /// **'مائل'**
  String get formatItalic;

  /// No description provided for @formatHeading.
  ///
  /// In ar, this message translates to:
  /// **'عنوان'**
  String get formatHeading;

  /// No description provided for @formatBullet.
  ///
  /// In ar, this message translates to:
  /// **'قائمة نقطية'**
  String get formatBullet;

  /// No description provided for @formatCheckbox.
  ///
  /// In ar, this message translates to:
  /// **'مهمة'**
  String get formatCheckbox;

  /// No description provided for @formatCode.
  ///
  /// In ar, this message translates to:
  /// **'كود'**
  String get formatCode;

  /// No description provided for @addTag.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وسم'**
  String get addTag;

  /// No description provided for @noNotesWithTag.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات بهذا الوسم'**
  String get noNotesWithTag;

  /// No description provided for @allTags.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allTags;

  /// No description provided for @attachmentsSection.
  ///
  /// In ar, this message translates to:
  /// **'المرفقات'**
  String get attachmentsSection;

  /// No description provided for @addAttachment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مرفق'**
  String get addAttachment;

  /// No description provided for @editHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل التعديلات'**
  String get editHistoryTitle;

  /// No description provided for @noEditHistory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تعديلات سابقة'**
  String get noEditHistory;

  /// No description provided for @currentVersion.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get currentVersion;

  /// No description provided for @reminderScheduled.
  ///
  /// In ar, this message translates to:
  /// **'تم جدولة التذكير'**
  String get reminderScheduled;

  /// No description provided for @reminderPermissionNeeded.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات مطلوبة للتذكير. يرجى تفعيلها من الإعدادات.'**
  String get reminderPermissionNeeded;

  /// No description provided for @reminderFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر ضبط التذكير. يرجى التحقق من إعدادات الإشعارات.'**
  String get reminderFailed;

  /// No description provided for @pinLocked.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة جداً. حاول مرة أخرى بعد'**
  String get pinLocked;

  /// No description provided for @seconds.
  ///
  /// In ar, this message translates to:
  /// **'ثوانٍ'**
  String get seconds;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @langArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @langEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @textPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'نص'**
  String get textPlaceholder;

  /// No description provided for @semNewNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get semNewNote;

  /// No description provided for @semNewNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ملاحظة جديدة'**
  String get semNewNoteHint;

  /// No description provided for @semBulkColor.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللون'**
  String get semBulkColor;

  /// No description provided for @semBulkPin.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت'**
  String get semBulkPin;

  /// No description provided for @semBulkUnpin.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التثبيت'**
  String get semBulkUnpin;

  /// No description provided for @semBulkDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف المحدد'**
  String get semBulkDelete;

  /// No description provided for @semSelectColor.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللون {color}'**
  String semSelectColor(Object color);

  /// No description provided for @semRemoveImage.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الصورة'**
  String get semRemoveImage;

  /// No description provided for @semAddAttachment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مرفق'**
  String get semAddAttachment;

  /// No description provided for @semAddPhoto.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get semAddPhoto;

  /// No description provided for @semAddFile.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملف'**
  String get semAddFile;

  /// No description provided for @semOpenFile.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملف'**
  String get semOpenFile;

  /// No description provided for @semRemoveFile.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الملف'**
  String get semRemoveFile;

  /// No description provided for @semSaveNote.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الملاحظة'**
  String get semSaveNote;

  /// No description provided for @semSaveNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الملاحظة الحالية'**
  String get semSaveNoteHint;

  /// No description provided for @semCloseSheet.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get semCloseSheet;

  /// No description provided for @semOpenImageViewer.
  ///
  /// In ar, this message translates to:
  /// **'عرض الصورة'**
  String get semOpenImageViewer;

  /// No description provided for @semChecklistItem.
  ///
  /// In ar, this message translates to:
  /// **'عنصر قائمة'**
  String get semChecklistItem;

  /// No description provided for @semChecklistHint.
  ///
  /// In ar, this message translates to:
  /// **'انقر مرتين للتبديل'**
  String get semChecklistHint;

  /// No description provided for @semChecked.
  ///
  /// In ar, this message translates to:
  /// **'محدد'**
  String get semChecked;

  /// No description provided for @semUnchecked.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get semUnchecked;

  /// No description provided for @semThemeSystem.
  ///
  /// In ar, this message translates to:
  /// **'سمة النظام'**
  String get semThemeSystem;

  /// No description provided for @semThemeLight.
  ///
  /// In ar, this message translates to:
  /// **'سمة الفاتح'**
  String get semThemeLight;

  /// No description provided for @semThemeDark.
  ///
  /// In ar, this message translates to:
  /// **'سمة الداكن'**
  String get semThemeDark;

  /// No description provided for @semThemeHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للاختيار'**
  String get semThemeHint;

  /// No description provided for @semReaderFont.
  ///
  /// In ar, this message translates to:
  /// **'حجم خط القارئ'**
  String get semReaderFont;

  /// No description provided for @semPickFromCamera.
  ///
  /// In ar, this message translates to:
  /// **'التقط صورة بالكاميرا'**
  String get semPickFromCamera;

  /// No description provided for @semPickFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة من المعرض'**
  String get semPickFromGallery;

  /// No description provided for @semPickFile.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف من الجهاز'**
  String get semPickFile;

  /// No description provided for @semRecordVoice.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل ملاحظة صوتية'**
  String get semRecordVoice;

  /// No description provided for @semDrawSketch.
  ///
  /// In ar, this message translates to:
  /// **'رسم مخطط'**
  String get semDrawSketch;

  /// No description provided for @redoAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة'**
  String get redoAction;

  /// No description provided for @eraser.
  ///
  /// In ar, this message translates to:
  /// **'ممحاة'**
  String get eraser;

  /// No description provided for @trashRetention.
  ///
  /// In ar, this message translates to:
  /// **'مدة الاحتفاظ بالمحذوفات'**
  String get trashRetention;

  /// No description provided for @trashRetentionDays.
  ///
  /// In ar, this message translates to:
  /// **'{days} يوم'**
  String trashRetentionDays(int days);

  /// No description provided for @trashRetentionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ الملاحظات المحذوفة لمدة {days} يومًا'**
  String trashRetentionLabel(int days);

  /// No description provided for @clearAllData.
  ///
  /// In ar, this message translates to:
  /// **'مسح جميع البيانات'**
  String get clearAllData;

  /// No description provided for @clearAllDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف جميع الملاحظات والملفات والإعدادات نهائيًا'**
  String get clearAllDataSubtitle;

  /// No description provided for @clearAllDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح جميع البيانات؟'**
  String get clearAllDataTitle;

  /// No description provided for @clearAllDataMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف جميع الملاحظات والملفات وإعدادات القفل نهائيًا. أدخل رقمك السري أو كلمة السر للتأكيد.'**
  String get clearAllDataMessage;

  /// No description provided for @clearAllDataConfirm.
  ///
  /// In ar, this message translates to:
  /// **'مسح كل شيء'**
  String get clearAllDataConfirm;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة السر للتأكيد'**
  String get enterPasswordToConfirm;

  /// No description provided for @dataClearedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح جميع البيانات'**
  String get dataClearedToast;

  /// No description provided for @restoreHistoryVersion.
  ///
  /// In ar, this message translates to:
  /// **'استعادة هذا الإصدار'**
  String get restoreHistoryVersion;

  /// No description provided for @historyRestoredToast.
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة الملاحظة لهذا الإصدار'**
  String get historyRestoredToast;

  /// No description provided for @exportPdfTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تصدير كـ PDF'**
  String get exportPdfTooltip;

  /// No description provided for @exportMarkdownTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تصدير كـ Markdown'**
  String get exportMarkdownTooltip;

  /// No description provided for @exportPdfFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء ملف PDF'**
  String get exportPdfFailed;

  /// No description provided for @exportMarkdownFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء ملف Markdown'**
  String get exportMarkdownFailed;

  /// No description provided for @folderSection.
  ///
  /// In ar, this message translates to:
  /// **'المجلد'**
  String get folderSection;

  /// No description provided for @folderHint.
  ///
  /// In ar, this message translates to:
  /// **'تعيين لمجلد...'**
  String get folderHint;

  /// No description provided for @allFolders.
  ///
  /// In ar, this message translates to:
  /// **'كل المجلدات'**
  String get allFolders;

  /// No description provided for @sortCustom.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب يدوي'**
  String get sortCustom;

  /// No description provided for @searchInNote.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الملاحظة'**
  String get searchInNote;

  /// No description provided for @searchNoMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get searchNoMatches;

  /// No description provided for @searchMatchOf.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total}'**
  String searchMatchOf(int current, int total);

  /// No description provided for @searchHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمليات البحث الأخيرة'**
  String get searchHistoryTitle;

  /// No description provided for @searchHistoryClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get searchHistoryClear;

  /// No description provided for @searchResultsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد نتائج} =1{نتيجة واحدة} =2{نتيجتان} few{{count} نتائج} many{{count} نتيجة} other{{count} نتيجة}}'**
  String searchResultsCount(int count);

  /// No description provided for @vaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخزنة'**
  String get vaultTitle;

  /// No description provided for @vaultEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء هنا بعد'**
  String get vaultEmptyTitle;

  /// No description provided for @vaultEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'احفظ كلمات المرور والبطاقات والحسابات والملاحظات السرية في الخزنة المشفرة'**
  String get vaultEmptyHint;

  /// No description provided for @vaultAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get vaultAdd;

  /// No description provided for @vaultAddLogin.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور'**
  String get vaultAddLogin;

  /// No description provided for @vaultAddCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة ائتمان'**
  String get vaultAddCard;

  /// No description provided for @vaultAddBank.
  ///
  /// In ar, this message translates to:
  /// **'حساب بنكي'**
  String get vaultAddBank;

  /// No description provided for @vaultAddSecureNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة سرية'**
  String get vaultAddSecureNote;

  /// No description provided for @vaultFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get vaultFilterAll;

  /// No description provided for @vaultFilterPasswords.
  ///
  /// In ar, this message translates to:
  /// **'كلمات المرور'**
  String get vaultFilterPasswords;

  /// No description provided for @vaultFilterBanking.
  ///
  /// In ar, this message translates to:
  /// **'بنوك'**
  String get vaultFilterBanking;

  /// No description provided for @vaultFilterDocuments.
  ///
  /// In ar, this message translates to:
  /// **'مستندات'**
  String get vaultFilterDocuments;

  /// No description provided for @vaultFilterAudio.
  ///
  /// In ar, this message translates to:
  /// **'صوتيات'**
  String get vaultFilterAudio;

  /// No description provided for @vaultFilterCanvas.
  ///
  /// In ar, this message translates to:
  /// **'رسومات'**
  String get vaultFilterCanvas;

  /// No description provided for @vaultTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get vaultTitleLabel;

  /// No description provided for @vaultTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: بريد جيميل'**
  String get vaultTitleHint;

  /// No description provided for @vaultFieldUsername.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get vaultFieldUsername;

  /// No description provided for @vaultFieldPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get vaultFieldPassword;

  /// No description provided for @vaultFieldCardHolder.
  ///
  /// In ar, this message translates to:
  /// **'اسم حامل البطاقة'**
  String get vaultFieldCardHolder;

  /// No description provided for @vaultFieldCardNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم البطاقة'**
  String get vaultFieldCardNumber;

  /// No description provided for @vaultFieldExpiry.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء (MM/YY)'**
  String get vaultFieldExpiry;

  /// No description provided for @vaultFieldCvv.
  ///
  /// In ar, this message translates to:
  /// **'رمز الأمان (CVV)'**
  String get vaultFieldCvv;

  /// No description provided for @vaultFieldCardPin.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري للبطاقة'**
  String get vaultFieldCardPin;

  /// No description provided for @vaultFieldBankName.
  ///
  /// In ar, this message translates to:
  /// **'اسم البنك'**
  String get vaultFieldBankName;

  /// No description provided for @vaultFieldIban.
  ///
  /// In ar, this message translates to:
  /// **'رقم الآيبان'**
  String get vaultFieldIban;

  /// No description provided for @vaultFieldAccountName.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحب الحساب'**
  String get vaultFieldAccountName;

  /// No description provided for @vaultFieldSwift.
  ///
  /// In ar, this message translates to:
  /// **'رمز السويفت'**
  String get vaultFieldSwift;

  /// No description provided for @vaultNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get vaultNotes;

  /// No description provided for @vaultNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'إضافية (اختياري)'**
  String get vaultNotesHint;

  /// No description provided for @vaultShow.
  ///
  /// In ar, this message translates to:
  /// **'إظهار'**
  String get vaultShow;

  /// No description provided for @vaultHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get vaultHide;

  /// No description provided for @vaultCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get vaultCopy;

  /// No description provided for @vaultCopiedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get vaultCopiedToast;

  /// No description provided for @vaultShareLabel.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get vaultShareLabel;

  /// No description provided for @vaultDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنصر؟'**
  String get vaultDeleteTitle;

  /// No description provided for @vaultDeleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'لن يمكن التراجع عن حذف هذا العنصر.'**
  String get vaultDeleteMessage;

  /// No description provided for @vaultGeneratePassword.
  ///
  /// In ar, this message translates to:
  /// **'توليد كلمة مرور'**
  String get vaultGeneratePassword;

  /// No description provided for @vaultAttachmentAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مرفق'**
  String get vaultAttachmentAdd;

  /// No description provided for @vaultAttachmentHint.
  ///
  /// In ar, this message translates to:
  /// **'ملف مشفر (مستند، صورة، صوت…)'**
  String get vaultAttachmentHint;

  /// No description provided for @vaultOpenAttachment.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get vaultOpenAttachment;

  /// No description provided for @vaultMediaLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الملف'**
  String get vaultMediaLabel;

  /// No description provided for @vaultMediaAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get vaultMediaAuto;

  /// No description provided for @vaultMediaDocument.
  ///
  /// In ar, this message translates to:
  /// **'مستند'**
  String get vaultMediaDocument;

  /// No description provided for @vaultMediaAudio.
  ///
  /// In ar, this message translates to:
  /// **'صوتي'**
  String get vaultMediaAudio;

  /// No description provided for @vaultMediaDrawing.
  ///
  /// In ar, this message translates to:
  /// **'رسم'**
  String get vaultMediaDrawing;

  /// No description provided for @vaultScreenProtected.
  ///
  /// In ar, this message translates to:
  /// **'الحماية من اللقطات مفعّلة'**
  String get vaultScreenProtected;

  /// No description provided for @vaultErrorLoading.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الخزنة'**
  String get vaultErrorLoading;

  /// No description provided for @documentPreviewShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get documentPreviewShare;

  /// No description provided for @documentOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الملف'**
  String get documentOpenFailed;

  /// No description provided for @documentHandedToExternal.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح الملف في تطبيق خارجي'**
  String get documentHandedToExternal;

  /// No description provided for @documentNoAppHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تطبيق مثبت لفتح هذا النوع من الملفات'**
  String get documentNoAppHint;

  /// No description provided for @documentOpenExternal.
  ///
  /// In ar, this message translates to:
  /// **'فتح في تطبيق خارجي'**
  String get documentOpenExternal;

  /// No description provided for @documentPlaybackFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل هذا الملف الصوتي'**
  String get documentPlaybackFailed;

  /// No description provided for @audioPlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get audioPlay;

  /// No description provided for @audioPause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get audioPause;

  /// No description provided for @audioUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل الصوت'**
  String get audioUnavailable;

  /// No description provided for @reRecord.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التسجيل'**
  String get reRecord;

  /// No description provided for @attach.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق'**
  String get attach;

  /// No description provided for @replayPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get replayPreview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
