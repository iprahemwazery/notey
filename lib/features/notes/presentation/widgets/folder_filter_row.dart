import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Horizontal row of folder chips for filtering notes on the home screen.
class FolderFilterRow extends StatelessWidget {
  const FolderFilterRow({
    super.key,
    required this.folders,
    required this.activeFolder,
    required this.onSelected,
  });

  final List<String> folders;
  final String? activeFolder;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: folders.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isActive = activeFolder == null || activeFolder!.isEmpty;
            return ChoiceChip(
              label: Text(l10n.allFolders),
              selected: isActive,
              onSelected: (_) => onSelected(null),
              selectedColor: scheme.primaryContainer,
              labelStyle: TextStyle(
                color: isActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isActive
                    ? scheme.primaryContainer
                    : scheme.outlineVariant.withValues(alpha: .6),
              ),
            );
          }
          final folder = folders[index - 1];
          final isActive = activeFolder == folder;
          return ChoiceChip(
            avatar: Icon(
              Icons.folder_rounded,
              size: 16.w,
              color: isActive ? scheme.onPrimaryContainer : scheme.primary,
            ),
            label: Text(folder),
            selected: isActive,
            onSelected: (_) => onSelected(isActive ? null : folder),
            selectedColor: scheme.primaryContainer,
            labelStyle: TextStyle(
              color: isActive
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isActive
                  ? scheme.primaryContainer
                  : scheme.outlineVariant.withValues(alpha: .6),
            ),
          );
        },
      ),
    );
  }
}
