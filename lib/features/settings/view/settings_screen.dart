import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/theme/theme_controller.dart';
import 'package:notey/data/repositories/note_repository.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/settings/view/widgets/widgets.dart' as settings_widgets;

/// App settings: appearance, app-lock management, backups & about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.lockController,
    required this.biometricService,
  });

  final NoteRepository repository;
  final AppLockController lockController;
  final BiometricService biometricService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: ListView(
            children: <Widget>[
              settings_widgets.SecuritySection(
                lockController: widget.lockController,
                biometricService: widget.biometricService,
              ),
              SizedBox(height: 16.h),
              settings_widgets.SettingsSectionLabel(
                text: l10n.sectionAppearance,
              ),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.instance.mode,
                builder: (context, mode, _) => Column(
                  children: <Widget>[
                    settings_widgets.ThemeTile(
                      title: l10n.themeSystem,
                      icon: Icons.brightness_auto_rounded,
                      selected: mode == ThemeMode.system,
                      onTap: () =>
                          ThemeController.instance.set(ThemeMode.system),
                    ),
                    settings_widgets.ThemeTile(
                      title: l10n.themeLight,
                      icon: Icons.light_mode_rounded,
                      selected: mode == ThemeMode.light,
                      onTap: () =>
                          ThemeController.instance.set(ThemeMode.light),
                    ),
                    settings_widgets.ThemeTile(
                      title: l10n.themeDark,
                      icon: Icons.dark_mode_rounded,
                      selected: mode == ThemeMode.dark,
                      onTap: () => ThemeController.instance.set(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const settings_widgets.LanguageTile(),
              const settings_widgets.ReaderFontTile(),
              const settings_widgets.TrashRetentionTile(),
              Divider(height: 32.h, indent: 20.w, endIndent: 20.w),
              settings_widgets.BackupSection(repository: widget.repository),
              Divider(height: 32.h, indent: 20.w, endIndent: 20.w),
              settings_widgets.AboutSection(
                version: _version,
                lockController: widget.lockController,
                biometricService: widget.biometricService,
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.h),
            ],
          ),
        ),
      ),
    );
  }
}