import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/haptics.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Markdown formatting bar: wraps the current selection (or inserts a
/// template at the caret) with the chosen syntax.
class FormatToolbarWidget extends StatelessWidget {
  const FormatToolbarWidget({super.key, required this.controller});

  final TextEditingController controller;

  void _wrap(String marker, {String placeholder = ''}) {
    final selection = controller.selection;
    final text = controller.text;
    if (!selection.isValid) {
      controller.value = TextEditingValue(
        text: '$text$marker$placeholder$marker',
        selection: TextSelection.collapsed(
          offset: text.length + marker.length + placeholder.length,
        ),
      );
      return;
    }
    final start = selection.start;
    final end = selection.end;
    final selected = text.substring(start, end);
    final replaced = '$marker${selected.isEmpty ? placeholder : selected}$marker';
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, replaced),
      selection: TextSelection.collapsed(
        offset: start + marker.length + selected.length,
      ),
    );
  }

  void _prefixLines(String prefix) {
    final selection = controller.selection;
    final text = controller.text;
    var start = selection.start;
    if (!selection.isValid) start = text.length;
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }
    controller.value = TextEditingValue(
      text: text.replaceRange(start, start, prefix),
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + prefix.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    Widget button(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: tooltip,
          onPressed: () {
            Haptics.tap();
            onTap();
          },
          icon: Icon(icon, size: 20.w, color: scheme.onSurfaceVariant),
        );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            button(
              Icons.format_bold_rounded,
              l10n.formatBold,
              () => _wrap('**', placeholder: l10n.textPlaceholder),
            ),
            button(
              Icons.format_italic_rounded,
              l10n.formatItalic,
              () => _wrap('*', placeholder: l10n.textPlaceholder),
            ),
            button(
              Icons.text_fields_rounded,
              l10n.formatHeading,
              () => _prefixLines('# '),
            ),
            button(
              Icons.format_list_bulleted_rounded,
              l10n.formatBullet,
              () => _prefixLines('- '),
            ),
            button(
              Icons.check_box_outlined,
              l10n.formatCheckbox,
              () => _prefixLines('- [ ] '),
            ),
            button(
              Icons.code_rounded,
              l10n.formatCode,
              () => _wrap('`', placeholder: 'code'),
            ),
          ],
        ),
      ),
    );
  }
}
