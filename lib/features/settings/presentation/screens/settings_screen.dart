import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/theme/theme_controller.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/settings/data/repositories_impl/backup_repository.dart';
import 'package:notey/features/settings/domain/repositories/backup_repository.dart';
import 'package:notey/features/settings/domain/usecases/get_app_version.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/settings/presentation/widgets/widgets.dart' as settings_widgets;

/// App settings: appearance, app-lock management, backups & about.
class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    super.key,
    required this.repository,
    required this.lockController,
    required this.biometricService,
    BackupRepository? backupRepository,
  }) : backupRepository =
           backupRepository ??
           BackupRepositoryImpl(lockController: lockController);

  final NoteRepository repository;
  final AppLockController lockController;
  final BiometricService biometricService;
  final BackupRepository backupRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    GetAppVersion(widget.backupRepository)().then((v) {
      if (mounted) setState(() => _version = v);
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
              settings_widgets.ReaderFontTile(),
              settings_widgets.TrashRetentionTile(),
              Divider(height: 32.h, indent: 20.w, endIndent: 20.w),
              settings_widgets.BackupSection(
                repository: widget.repository,
                backupRepository: widget.backupRepository,
              ),
              Divider(height: 32.h, indent: 20.w, endIndent: 20.w),
              settings_widgets.AboutSection(
                version: _version,
                lockController: widget.lockController,
                biometricService: widget.biometricService,
                backupRepository: widget.backupRepository,
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.h),
            ],
          ),
        ),
      ),
    );
  }
}