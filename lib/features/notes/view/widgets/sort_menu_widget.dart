import 'package:flutter/material.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

enum NoteSort { recent, oldest, color, custom }

class SortMenuWidget extends StatelessWidget {
  const SortMenuWidget({
    super.key,
    required this.sort,
    required this.onSortChanged,
  });

  final NoteSort sort;
  final ValueChanged<NoteSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).sortTooltip,
      child: PopupMenuButton<NoteSort>(
        tooltip: AppLocalizations.of(context).sortTooltip,
        icon: Icon(Icons.sort_rounded, color: scheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: onSortChanged,
        itemBuilder: (context) {
          final l10n = AppLocalizations.of(context);
          return <PopupMenuEntry<NoteSort>>[
            PopupMenuItem<NoteSort>(
              value: NoteSort.recent,
              child: ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(l10n.sortNewestFirst),
                dense: true,
              ),
            ),
            PopupMenuItem<NoteSort>(
              value: NoteSort.oldest,
              child: ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(l10n.sortOldestFirst),
                dense: true,
              ),
            ),
            PopupMenuItem<NoteSort>(
              value: NoteSort.color,
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.sortByColor),
                dense: true,
              ),
            ),
            PopupMenuItem<NoteSort>(
              value: NoteSort.custom,
              child: ListTile(
                leading: const Icon(Icons.drag_indicator_rounded),
                title: Text(l10n.sortCustom),
                dense: true,
              ),
            ),
          ];
        },
      ),
    );
  }
}
