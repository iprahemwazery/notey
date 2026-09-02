import 'package:flutter/material.dart';

/// Centralised confirmation dialog helper so destructive / confirm screens
/// don't repeat the AlertDialog boilerplate.
class AppDialogs {
  AppDialogs._();

  /// Shows a confirm dialog. Returns true when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel ?? 'OK'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
