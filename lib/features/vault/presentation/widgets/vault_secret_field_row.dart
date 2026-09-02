import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// A single vault field row with optional hide/reveal and copy actions.
///
/// Renders a generic card; sensitive (password/cvv/pin) values are masked with
/// dots until [revealed] is true.
class VaultSecretFieldRow extends StatefulWidget {
  const VaultSecretFieldRow({
    super.key,
    required this.label,
    required this.value,
    required this.sensitive,
    required this.revealed,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final String label;
  final String value;
  final bool sensitive;

  /// Whether sensitive values are currently displayed in clear text.
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onCopy;

  @override
  State<VaultSecretFieldRow> createState() => _VaultSecretFieldRowState();
}

class _VaultSecretFieldRowState extends State<VaultSecretFieldRow> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hidden =
        widget.sensitive && !widget.revealed && widget.value.isNotEmpty;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 6.w, 6.h),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    hidden
                        ? '••••••••'
                        : (widget.value.isEmpty ? '—' : widget.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.sensitive && widget.value.isNotEmpty)
              IconButton(
                tooltip: hidden ? l10n.vaultShow : l10n.vaultHide,
                onPressed: widget.onToggleReveal,
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            IconButton(
              tooltip: l10n.vaultCopy,
              onPressed: widget.onCopy,
              icon: Icon(Icons.copy_rounded, size: 20.w),
            ),
          ],
        ),
      ),
    );
  }
}
