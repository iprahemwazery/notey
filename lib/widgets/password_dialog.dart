import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Prompts for a password. When [confirmRequired] is true the user must
/// type it twice. Returns the entered password, or null when cancelled.
Future<String?> showPasswordDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmButtonLabel,
  bool confirmRequired = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(
      title: title,
      message: message,
      confirmButtonLabel:
          confirmButtonLabel ?? AppLocalizations.of(context).save,
      confirmRequired: confirmRequired,
    ),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({
    required this.title,
    required this.message,
    required this.confirmButtonLabel,
    required this.confirmRequired,
  });

  final String title;
  final String? message;
  final String confirmButtonLabel;
  final bool confirmRequired;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _password.text;
    if (value.length < 6) {
      setState(
        () => _error = AppLocalizations.of(context).passwordMinLengthError,
      );
      return;
    }
    if (widget.confirmRequired && _confirm.text != value) {
      setState(() => _error = AppLocalizations.of(context).passwordsNoMatch);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.message != null) ...<Widget>[
              Text(widget.message!),
              SizedBox(height: 12.h),
            ],
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: widget.confirmRequired
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) => widget.confirmRequired ? null : _submit(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).passwordHint,
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            if (widget.confirmRequired) ...<Widget>[
              SizedBox(height: 10.h),
              TextField(
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).confirmPasswordHint,
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
            ],
            if (_error.isNotEmpty) ...<Widget>[
              SizedBox(height: 10.h),
              Text(
                _error,
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmButtonLabel),
        ),
      ],
    );
  }
}
