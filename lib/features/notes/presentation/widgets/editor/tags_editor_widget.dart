import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Tag chips + inline input used by the editor.
class TagsEditorWidget extends StatefulWidget {
  const TagsEditorWidget({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<TagsEditorWidget> createState() => _TagsEditorWidgetState();
}

class _TagsEditorWidgetState extends State<TagsEditorWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    widget.onAdd(raw);
    setState(() => _controller.clear());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.tagsSection,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: <Widget>[
            for (final tag in widget.tags)
              InputChip(
                label: Text(tag),
                deleteIcon: Icon(Icons.close_rounded, size: 16.w),
                onDeleted: () => widget.onRemove(tag),
                backgroundColor: scheme.surfaceContainerHigh,
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: .6),
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.addTagHint,
            prefixIcon: const Icon(Icons.sell_outlined),
            isDense: true,
            suffixIcon: IconButton(
              tooltip: l10n.addTag,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _submit(_controller.text),
            ),
          ),
          onSubmitted: _submit,
        ),
      ],
    );
  }
}
