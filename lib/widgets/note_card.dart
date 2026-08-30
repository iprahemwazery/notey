import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/utils/arabic_date_time.dart';

import 'package:notey/core/utils/color_utils.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note.dart';


/// A single compact, premium-styled note tile used inside the home grid.
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  /// When true the grid is in multi-select mode: badges replace actions.
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = AppConstants
        .noteColors[note.colorIndex % AppConstants.noteColors.length];
    final background = isDark
        ? Color.lerp(baseColor, const Color(0xFF171A21), .84)!
        : baseColor;
    final accent = isDark
        ? Color.lerp(baseColor, Colors.white, .12)!
        : Color.lerp(baseColor, const Color(0xFF20242C), .38)!;

    final onColor = ColorUtils.foregroundOn(background);
    final mutedOnColor = ColorUtils.foregroundMutedOn(background);
    final locked = note.isLocked;
    final l10n = AppLocalizations.of(context);
    final displayTitle = locked
        ? l10n.lockedNote
        : (note.title.isEmpty ? l10n.untitled : note.title);
    final hasSnippet = !locked && note.content.trim().isNotEmpty;
    final images = locked ? const <String>[] : note.imageAttachments;
    final fileCount = locked || widget.selectionMode
        ? 0
        : note.attachments.length - images.length;

    return AnimatedScale(
      scale: _highlighted ? .965 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .28 : .05),
              blurRadius: 3.r,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .30 : .07),
              blurRadius: 12.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(16.r),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: (value) => setState(() => _highlighted = value),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: widget.isSelected
                              ? accent
                              : Colors.transparent,
                          width: 2.4,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: 0,
                  top: 12.h,
                  bottom: 12.h,
                  width: 3.5.w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? .85 : .75),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
                if (widget.selectionMode)
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    end: 8.w,
                    top: 8.h,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      width: 21.w,
                      height: 21.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSelected ? accent : Colors.transparent,
                        border: Border.all(
                          width: 1.6,
                          color: widget.isSelected
                              ? accent
                              : onColor.withValues(alpha: .45),
                        ),
                      ),
                      child: widget.isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 13.w,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 14.w,
                    end: 12.w,
                    top: 10.h,
                    bottom: 8.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (locked) ...<Widget>[
                            Icon(Icons.lock_rounded, size: 11.5.w, color: accent),
                            SizedBox(width: 4.w),
                          ],
                          Expanded(
                            child: Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5.sp,
                                letterSpacing: -.1.sp,
                                color: onColor,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          if (!widget.selectionMode)
                            _IconButton(
                              tooltip: note.pinned
                                  ? l10n.actionUnpin
                                  : l10n.actionPin,
                              icon: note.pinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              onPressed: widget.onPin,
                              color: note.pinned
                                  ? const Color(0xFFE8930C)
                                  : mutedOnColor,
                              backgroundColor: onColor.withValues(alpha: .07),
                            ),
                        ],
                      ),
                      if (hasSnippet)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5.sp,
                                color: mutedOnColor,
                                height: 1.45,
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (images.isNotEmpty) ...<Widget>[
                        SizedBox(height: 5.h),
                        _Thumbnails(images: images),
                        SizedBox(height: 7.h),
                      ],
                      Divider(
                        height: 1,
                        thickness: .6,
                        color: onColor.withValues(alpha: .09),
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: <Widget>[
                          if (fileCount > 0) ...<Widget>[
                            Icon(
                              Icons.attach_file_rounded,
                              size: 10.5.w,
                              color: mutedOnColor,
                            ),
                            Text(
                              '$fileCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: mutedOnColor,
                              ),
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Icon(
                            Icons.schedule_rounded,
                            size: 10.5.w,
                            color: mutedOnColor,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              ArabicDateTime.relative(
                                note.updatedAt,
                                l10n: l10n,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                letterSpacing: .1.sp,
                                color: mutedOnColor,
                              ),
                            ),
                          ),
                          if (!widget.selectionMode) ...<Widget>[
                            _IconButton(
                              tooltip: l10n.edit,
                              icon: Icons.edit_rounded,
                              onPressed: widget.onEdit,
                              color: mutedOnColor,
                              backgroundColor: onColor.withValues(alpha: .07),
                            ),
                            SizedBox(width: 3.w),
                            _IconButton(
                              tooltip: l10n.delete,
                              icon: Icons.delete_outline_rounded,
                              onPressed: widget.onDelete,
                              color: ColorUtils.dangerOn(background),
                              backgroundColor: onColor.withValues(alpha: .07),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor = const Color(0x1FFFFFFF),
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.all(4.5.w),
              child: Icon(icon, size: 15.w, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final shown = images.take(3).toList();
    final extra = images.length - shown.length;
    final cacheWidth = (26 * MediaQuery.devicePixelRatioOf(context)).round();

    return Row(
      children: <Widget>[
        for (var i = 0; i < shown.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: 4.w),
          _thumb(
            shown[i],
            extra: i == shown.length - 1 ? extra : 0,
            cacheWidth: cacheWidth,
          ),
        ],
      ],
    );
  }

  Widget _thumb(String path, {int extra = 0, required int cacheWidth}) {
    final radius = BorderRadius.all(Radius.circular(7.r));
    // Decode at display resolution (26 logical px * DPR) — never the full
    // camera original — to keep list scrolling memory-flat.
    Widget thumb = ClipRRect(
      borderRadius: radius,
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: 26.w,
        height: 26.h,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => Container(
          width: 26.w,
          height: 26.h,
          color: Colors.black12,
          child: Icon(Icons.image_not_supported_rounded, size: 14.w, color: Colors.black26),
        ),
      ),
    );
    thumb = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.white24, width: .5),
      ),
      child: thumb,
    );
    if (extra > 0) {
      return Stack(
        children: <Widget>[
          thumb,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .48),
                borderRadius: radius,
              ),
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return thumb;
  }
}
