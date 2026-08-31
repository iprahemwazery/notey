import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/locale_controller.dart';
import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A tile that shows the current app language and opens a chooser sheet.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = context.getAdaptiveTextColor(context);
    final mutedColor = context.getAdaptiveMutedTextColor(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance.locale,
      builder: (context, locale, _) {
        final currentCode = locale.languageCode;
        return ListTile(
          leading: Icon(Icons.language_rounded, color: textColor),
          title: Text(
            l10n.language,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
          subtitle: Text(
            currentCode == 'ar' ? l10n.langArabic : l10n.langEnglish,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          trailing: Icon(Icons.chevron_left_rounded, color: mutedColor),
          onTap: () => _pickLanguage(context),
        );
      },
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final current = LocaleController.instance.locale.value.languageCode;
    final textColor = context.getAdaptiveTextColor(context);
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
                title: Text(
                  l10n.langArabic,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.bodyLarge?.copyWith(color: textColor),
                ),
                trailing: current == 'ar'
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: context.getAdaptiveMutedTextColor(context),
                      ),
                onTap: () => Navigator.pop(sheetContext, 'ar'),
              ),
              ListTile(
                leading: Text('🇬🇧', style: TextStyle(fontSize: 22.sp)),
                title: Text(
                  l10n.langEnglish,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.bodyLarge?.copyWith(color: textColor),
                ),
                trailing: current == 'en'
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: context.getAdaptiveMutedTextColor(context),
                      ),
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
