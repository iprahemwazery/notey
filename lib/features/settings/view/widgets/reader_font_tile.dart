import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/ui_prefs.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A tile that lets the user change the reader (viewer) font size.
class ReaderFontTile extends StatefulWidget {
  const ReaderFontTile({super.key});

  @override
  State<ReaderFontTile> createState() => _ReaderFontTileState();
}

class _ReaderFontTileState extends State<ReaderFontTile> {
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    UiPrefs.readerFontScale().then((value) {
      if (mounted) setState(() => _scale = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.format_size_rounded),
      title: Text(l10n.readerFontSize),
      subtitle: Row(
        children: <Widget>[
          Icon(Icons.text_decrease_rounded, size: 18.w),
          Expanded(
            child: Semantics(
              label: l10n.semReaderFont,
              child: Slider(
                value: _scale,
                min: UiPrefs.minFontScale,
                max: UiPrefs.maxFontScale,
                divisions: ((UiPrefs.maxFontScale - UiPrefs.minFontScale) / .05)
                    .round(),
                label: '${(_scale * 100).round()}%',
                onChanged: (value) {
                  setState(() => _scale = value);
                  UiPrefs.setReaderFontScale(value);
                },
              ),
            ),
          ),
          Icon(Icons.text_increase_rounded, size: 22.w),
        ],
      ),
    );
  }
}
