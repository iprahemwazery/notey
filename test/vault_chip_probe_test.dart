import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/theme/app_theme.dart';
import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/features/vault/presentation/screens/vault_screen.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';

class _FakeVaultRepository extends SecureVaultRepository {
  _FakeVaultRepository() : super(database: NoteDatabase(inMemory: true));
  @override
  Future<List<VaultEntry>> getAll() async => const <VaultEntry>[];
}

Future<void> _probe(WidgetTester tester, String label, bool dark) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: VaultScreen(repository: _FakeVaultRepository()),
      ),
    ),
  );
  await tester.pump();

  // print the ChipThemeData labelStyle and ColorScheme
  final t = Theme.of(tester.element(find.byType(Scaffold).first));
  // ignore: avoid_print
  print('$label labelStyle=${t.chipTheme.labelStyle}');
  // ignore: avoid_print
  print('$label chipFill=${t.chipTheme.backgroundColor} chipSelected=${t.chipTheme.selectedColor}');
  // ignore: avoid_print
  print('$label onSurfaceVariant=${t.colorScheme.onSurfaceVariant} onSecondaryContainer=${t.colorScheme.onSecondaryContainer}');

  for (final f in find.byType(ChoiceChip).evaluate()) {
    final e = find.descendant(
      of: find.byElementPredicate((x) => x == f),
      matching: find.byType(Text),
    );
    for (final te in e.evaluate()) {
      final widget = te.widget as Text;
      final dts = DefaultTextStyle.of(te);
      // ignore: avoid_print
      print('$label CHIP "${widget.data}" dts=${dts.style}');
    }
  }
}

void main() {
  testWidgets('vault chips LIGHT', (tester) async { await _probe(tester, 'LIGHT', false); });
  testWidgets('vault chips DARK', (tester) async { await _probe(tester, 'DARK', true); });
}
