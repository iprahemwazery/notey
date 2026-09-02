import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/features/notes/presentation/cubits/viewer_cubit.dart';
import 'package:notey/features/notes/presentation/cubits/viewer_state.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A 2-column grid of the note's image attachments, isolated in its own
/// [BlocSelector] so checklist toggles / font changes never re-layout it.
class ViewerImageGrid extends StatelessWidget {
  const ViewerImageGrid({
    super.key,
    required this.noteId,
    required this.onOpen,
  });

  final String noteId;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocSelector<ViewerCubit, ViewerState, List<String>>(
      selector: (s) => s.note.imageAttachments,
      builder: (context, attachments) {
        if (attachments.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20.h),
            Text(
              l10n.imagesCountLabel(attachments.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: attachments.length,
              itemBuilder: (context, index) => Semantics(
                button: true,
                label: '${l10n.semOpenImageViewer} ${index + 1}',
                child: GestureDetector(
                  onTap: () => onOpen(index),
                  child: Hero(
                    tag: 'note-image-$noteId-$index',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.file(
                        File(attachments[index]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: (MediaQuery.sizeOf(context).width *
                                    MediaQuery.devicePixelRatioOf(context) /
                                    2)
                                .round(),
                        errorBuilder: (_, _, _) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
