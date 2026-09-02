import 'package:flutter/material.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// The "new note" floating action button with accessibility semantics.
class NewNoteFab extends StatelessWidget {
  const NewNoteFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.semNewNote,
      hint: l10n.semNewNoteHint,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.homeNewNote),
      ),
    );
  }
}
