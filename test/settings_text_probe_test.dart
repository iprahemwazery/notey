import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/notes/data/repositories_impl/note_repository.dart';
import 'package:notey/features/settings/presentation/screens/settings_screen.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String?> m = <String, String?>{};
  @override
  Future<String?> read({required String key, AndroidOptions? aOptions, AppleOptions? iOptions, LinuxOptions? lOptions, AppleOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async => m[key];
  @override
  Future<void> write({required String key, String? value, AndroidOptions? aOptions, AppleOptions? iOptions, LinuxOptions? lOptions, AppleOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async => m[key] = value;
  @override
  Future<void> delete({required String key, AndroidOptions? aOptions, AppleOptions? iOptions, LinuxOptions? lOptions, AppleOptions? mOptions, WindowsOptions? wOptions, WebOptions? webOptions}) async => m.remove(key);
}

void main() {
  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('settings text color $mode', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SettingsScreen(
              repository: NoteRepositoryImpl(database: NoteDatabase(inMemory: true)),
              lockController: AppLockController(secureStorage: _FakeStorage()),
              biometricService: _AutoBio(),
            ),
          ),
        ),
      );
      await tester.pump();

      final target = 'طريقة قفل التطبيق'; // ListTile title
      final f = find.byWidgetPredicate((w) => w is Text && w.data == target);
      if (f.evaluate().isNotEmpty) {
        final e = f.evaluate().first;
        final style = (e.widget as Text).style;
        // ignore: avoid_print
        print('[$mode] "$target" explicitStyle=$style');
      } else {
        // ignore: avoid_print
        print('[$mode] text not found');
      }
      // theme onSurface + textTheme.bodyMedium
      final theme = Theme.of(tester.element(find.byType(Scaffold).first));
      // ignore: avoid_print
      print('[$mode] theme bright=${theme.brightness} onSurface=${theme.colorScheme.onSurface} bodyMedium=${theme.textTheme.bodyMedium?.color} listTileTitle=${theme.listTileTheme.titleTextStyle?.color}');
    });
  }
}

class _AutoBio implements BiometricService {
  @override
  Future<BiometricResult> authenticate({bool deviceCredential = false, String? localizedReason}) async => BiometricResult.authenticated;
  @override
  Future<BiometricAvailability> getAvailability() async => BiometricAvailability.supported;
  @override
  Future<bool> openBiometricsSettings() async => true;
  @override
  Future<void> stopAuthentication() async {}
}
