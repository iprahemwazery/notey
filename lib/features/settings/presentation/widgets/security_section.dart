import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/auth/presentation/screens/biometric_setup_screen.dart';
import 'package:notey/features/auth/presentation/screens/pin_change_screen.dart'
    show PinChangeScreen;

import 'settings_section.dart';

class SecuritySection extends StatefulWidget {
  const SecuritySection({
    super.key,
    required this.lockController,
    required this.biometricService,
  });

  final AppLockController lockController;
  final BiometricService biometricService;

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  String _methodLabel(AppLockController controller, AppLocalizations l10n) {
    final method = controller.method;
    if (method == null) return l10n.lockMethodUnset;
    return switch (method) {
      AppLockMethod.biometric => l10n.methodBiometric,
      AppLockMethod.device => l10n.methodDevice,
      AppLockMethod.pin => l10n.methodPin,
      AppLockMethod.none => l10n.methodNone,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final method = widget.lockController.method;
    final textColor = context.getAdaptiveTextColor(context);
    final mutedColor = context.getAdaptiveMutedTextColor(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          children: <Widget>[
            SettingsSectionLabel(text: l10n.sectionSecurity),
            ListTile(
              leading: Icon(Icons.lock_outline_rounded, color: textColor),
              title: Text(
                l10n.lockMethodTile,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: textColor),
              ),
              subtitle: Text(
                _methodLabel(widget.lockController, l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: mutedColor),
              ),
              trailing: Icon(Icons.chevron_left_rounded, color: mutedColor),
              onTap: _chooseLockMethod,
            ),
            if (method == AppLockMethod.pin ||
                method == AppLockMethod.biometric)
              ListTile(
                leading: Icon(Icons.password_rounded, color: textColor),
                title: Text(
                  l10n.changePin,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: textColor),
                ),
                onTap: _openPinSetup,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseLockMethod() async {
    final current = widget.lockController.method;
    final textColor = context.getAdaptiveTextColor(context);
    final picked = await showModalBottomSheet<AppLockMethod>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final method in AppLockMethod.values) ...<Widget>[
                  ListTile(
                    leading: Icon(
                      switch (method) {
                        AppLockMethod.biometric => Icons.fingerprint_rounded,
                        AppLockMethod.device => Icons.grid_on_rounded,
                        AppLockMethod.pin => Icons.pin_rounded,
                        AppLockMethod.none => Icons.lock_open_rounded,
                      },
                      color: textColor,
                    ),
                    title: Text(
                      switch (method) {
                        AppLockMethod.none => l10n.methodNone,
                        AppLockMethod.biometric => l10n.methodBiometric,
                        AppLockMethod.device => l10n.methodDevice,
                        AppLockMethod.pin => l10n.methodPin,
                      },
                      style: Theme.of(sheetContext).textTheme.bodyLarge
                          ?.copyWith(color: textColor),
                    ),
                    trailing: method == current
                        ? Icon(Icons.check_rounded, color: textColor)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, method),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted || picked == current) return;

    switch (picked) {
      case AppLockMethod.none:
        await _disableLock();
      case AppLockMethod.device:
        await widget.lockController.setMethod(AppLockMethod.device);
      case AppLockMethod.biometric:
        if (!mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => BiometricSetupScreen(
              controller: widget.lockController,
              biometricService: widget.biometricService,
            ),
          ),
        );
      case AppLockMethod.pin:
        await _openPinSetup();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openPinSetup() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PinChangeScreen(controller: widget.lockController),
      ),
    );
  }

  Future<void> _disableLock() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disableLockTitle),
        content: Text(l10n.disableLockMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.disableLockConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      await widget.lockController.setMethod(AppLockMethod.none);
    }
  }
}
