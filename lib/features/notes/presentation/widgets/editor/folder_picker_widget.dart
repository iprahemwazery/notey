import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Folder name input used by the note editor.
class FolderPickerWidget extends StatefulWidget {
  const FolderPickerWidget({
    super.key,
    required this.folder,
    required this.onChanged,
  });

  final String folder;
  final ValueChanged<String> onChanged;

  @override
  State<FolderPickerWidget> createState() => _FolderPickerWidgetState();
}

class _FolderPickerWidgetState extends State<FolderPickerWidget> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.folder,
  );

  @override
  void didUpdateWidget(covariant FolderPickerWidget old) {
    super.didUpdateWidget(old);
    if (old.folder != widget.folder && _controller.text != widget.folder) {
      _controller.text = widget.folder;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.folderSection,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.folderHint,
            prefixIcon: const Icon(Icons.folder_rounded),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.w),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
          ),
          onChanged: (v) => widget.onChanged(v.trim()),
        ),
      ],
    );
  }
}
