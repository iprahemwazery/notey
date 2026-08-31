import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/haptics.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Password input panel shown for locked viewer notes.
class UnlockPanelWidget extends StatefulWidget {
  const UnlockPanelWidget({super.key, required this.onUnlock});

  final Future<bool> Function(String password) onUnlock;

  @override
  State<UnlockPanelWidget> createState() => _UnlockPanelWidgetState();
}

class _UnlockPanelWidgetState extends State<UnlockPanelWidget> {
  final TextEditingController _password = TextEditingController();
  bool _checking = false;
  bool _error = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_checking || _password.text.isEmpty) return;
    setState(() {
      _checking = true;
      _error = false;
    });
    final ok = await widget.onUnlock(_password.text);
    if (!mounted) return;
    if (!ok) {
      await Haptics.heavy();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = true;
      });
      _password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lock_rounded, color: scheme.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  l10n.unlockPanelTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_checking,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: l10n.passwordHint,
              prefixIcon: const Icon(Icons.key_rounded),
              errorText: _error ? l10n.wrongPasswordToast : null,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 50.h,
            child: FilledButton.icon(
              onPressed: _checking ? null : _submit,
              icon: _checking
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.lock_open_rounded),
              label: Text(l10n.unlockPanelButton),
            ),
          ),
        ],
      ),
    );
  }
}
