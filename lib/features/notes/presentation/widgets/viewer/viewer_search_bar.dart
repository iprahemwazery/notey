import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// The in-note search bar shown above the note body: a text field plus a live
/// match-count indicator. Pure presentation; the query and count are provided
/// by the parent.
class ViewerSearchBar extends StatelessWidget {
  const ViewerSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.matchCount,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final String matchCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.searchInNote,
                    prefixIcon: Icon(Icons.search_rounded, size: 20.w),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
              ),
              if (query.isNotEmpty) ...<Widget>[
                SizedBox(width: 8.w),
                Text(
                  matchCount,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
