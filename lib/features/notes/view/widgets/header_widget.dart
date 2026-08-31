import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'sort_menu_widget.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    super.key,
    required this.notesCount,
    required this.sort,
    required this.isGrid,
    required this.onToggleLayout,
    required this.onSortChanged,
    required this.onOpenSettings,
    required this.onOpenVault,
    required this.onOpenTrash,
  });

  final int notesCount;
  final NoteSort sort;
  final bool isGrid;
  final VoidCallback onToggleLayout;
  final ValueChanged<NoteSort> onSortChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenVault;
  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 18.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42.w,
              height: 42.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: Image.asset(
                  'asset/Gemini_Generated_Image_8o12p38o12p38o12.jpeg',
                  fit: BoxFit.cover,
                  width: 42.w,
                  height: 42.h,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context).homeNotesCount(notesCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 34.w,
                  height: 40.h,
                  child: IconButton(
                    tooltip: AppLocalizations.of(context).trashTitle,
                    onPressed: onOpenTrash,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34.w,
                  height: 40.h,
                  child: IconButton(
                    tooltip: isGrid
                        ? AppLocalizations.of(context).listViewTooltip
                        : AppLocalizations.of(context).gridViewTooltip,
                    onPressed: onToggleLayout,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34.w,
                  height: 40.h,
                  child: IconButton(
                    tooltip: AppLocalizations.of(context).vaultTitle,
                    onPressed: onOpenVault,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.shield_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34.w,
                  height: 40.h,
                  child: IconButton(
                    tooltip: AppLocalizations.of(context).settingsTitle,
                    onPressed: onOpenSettings,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34.w,
                  height: 40.h,
                  child: SortMenuWidget(
                    sort: sort,
                    onSortChanged: onSortChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
