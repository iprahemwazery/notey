import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/locale_controller.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A tile that shows the current app language and opens a chooser sheet.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance.locale,
      builder: (context, locale, _) {
        final currentCode = locale.languageCode;
        return ListTile(
          leading: const Icon(Icons.language_rounded),
          title: Text(l10n.language),
          subtitle: Text(
            currentCode == 'ar' ? l10n.langArabic : l10n.langEnglish,
          ),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: () => _pickLanguage(context),
        );
      },
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final current = LocaleController.instance.locale.value.languageCode;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Text('🇪🇬', style: TextStyle(fontSize: 22.sp)),
                title: Text(l10n.langArabic),
                trailing: current == 'ar'
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const Icon(Icons.radio_button_unchecked_rounded),
                onTap: () => Navigator.pop(sheetContext, 'ar'),
              ),
              ListTile(
                leading: Text('🇬🇧', style: TextStyle(fontSize: 22.sp)),
                title: Text(l10n.langEnglish),
                trailing: current == 'en'
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const Icon(Icons.radio_button_unchecked_rounded),
                onTap: () => Navigator.pop(sheetContext, 'en'),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != current) {
      await LocaleController.instance.set(Locale(picked));
    }
  }
}
