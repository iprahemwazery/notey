import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/core/widgets/note_snackbar.dart';
import 'package:notey/features/settings/data/repositories_impl/backup_repository.dart';
import 'package:notey/features/settings/domain/repositories/backup_repository.dart';
import 'package:notey/features/settings/domain/usecases/wipe_all_data.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'settings_section.dart';

class AboutSection extends StatefulWidget {
  AboutSection({
    super.key,
    required this.version,
    required this.lockController,
    required this.biometricService,
    BackupRepository? backupRepository,
  }) : backupRepository =
           backupRepository ??
           BackupRepositoryImpl(lockController: lockController);

  final String version;
  final AppLockController lockController;
  final BiometricService biometricService;
  final BackupRepository backupRepository;

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = context.getAdaptiveTextColor(context);
    final mutedColor = context.getAdaptiveMutedTextColor(context);
    return Column(
      children: <Widget>[
        SettingsSectionLabel(text: l10n.sectionAbout),
        ListTile(
          leading: Icon(Icons.sticky_note_2_rounded, color: textColor),
          title: Text(
            AppConstants.appName,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
          subtitle: Text(
            l10n.tagline,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          trailing: Text(
            widget.version.isEmpty ? '…' : widget.version,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: mutedColor),
          ),
        ),
        Divider(height: 32.h, indent: 20.w, endIndent: 20.w),
        ListTile(
          leading: Icon(
            Icons.delete_forever_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            l10n.clearAllData,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          subtitle: Text(
            l10n.clearAllDataSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          onTap: _busy ? null : _clearAllData,
        ),
      ],
    );
  }

  Future<void> _clearAllData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllDataTitle),
        content: Text(l10n.clearAllDataMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.clearAllDataConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Require PIN or password verification before wiping.
    final method = widget.lockController.method;
    if (method == AppLockMethod.pin) {
      final pinOk = await _verifyPinForClear(l10n);
      if (!pinOk) return;
    } else if (method == AppLockMethod.biometric ||
        method == AppLockMethod.device) {
      final bioOk = await _verifyBiometricForClear(l10n);
      if (!bioOk) return;
    }

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await WipeAllData(widget.backupRepository)();
      if (!mounted) return;
      GlassSnackbar.show(message: l10n.dataClearedToast);
    } on Exception {
      // Best effort.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _verifyPinForClear(AppLocalizations l10n) async {
    final controller = widget.lockController;
    String pin = '';
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.enterPasswordToConfirm),
              content: TextField(
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(hintText: '••••', counterText: ''),
                onChanged: (v) {
                  pin = v;
                  setDialogState(() {});
                },
                onSubmitted: (_) {
                  if (pin.length == 4) Navigator.pop(context, true);
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: pin.length == 4
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(l10n.continueLabel),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return false;
    return controller.verifyPin(pin);
  }

  Future<bool> _verifyBiometricForClear(AppLocalizations l10n) async {
    final result = await widget.biometricService.authenticate(
      localizedReason: l10n.enterPasswordToConfirm,
    );
    return result == BiometricResult.authenticated;
  }
}