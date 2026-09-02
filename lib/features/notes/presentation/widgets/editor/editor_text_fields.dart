import 'package:flutter/material.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// The editor's title field (large, single-line, auto-focused when creating).
class EditorTitleField extends StatelessWidget {
  const EditorTitleField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.contentFocusNode,
    required this.autofocus,
    required this.onTapOutside,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode contentFocusNode;
  final bool autofocus;
  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => contentFocusNode.requestFocus(),
      onTapOutside: (_) => onTapOutside(),
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).editorTitleHint,
      ),
    );
  }
}

/// The editor's content field (multiline, grows with the text).
class EditorContentField extends StatelessWidget {
  const EditorContentField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onTapOutside,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 8,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      onTapOutside: (_) => onTapOutside(),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).editorContentHint,
        alignLabelWithHint: true,
      ),
    );
  }
}
