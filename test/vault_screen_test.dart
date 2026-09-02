import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/presentation/screens/vault_entry_editor_screen.dart';
import 'package:notey/features/vault/presentation/screens/vault_screen.dart';

/// In-memory repository stub — keeps the widget tests off the real sqflite
/// ffi I/O, which never completes under the widget-tester's FakeAsync zone.
class _FakeVaultRepository extends SecureVaultRepository {
  _FakeVaultRepository() : super(database: NoteDatabase(inMemory: true));

  final Map<String, VaultEntry> _store = <String, VaultEntry>{};

  @override
  Future<List<VaultEntry>> getAll() async {
    final entries = _store.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  @override
  Future<VaultEntry?> get(String id) async => _store[id];

  @override
  Future<void> upsert(VaultEntry entry) async => _store[entry.id] = entry;

  @override
  Future<void> delete(String id) async => _store.remove(id);
}

VaultEntry _entry({
  required String id,
  required String title,
  VaultCategory category = VaultCategory.login,
}) {
  return VaultEntry(
    id: id,
    category: category,
    title: title,
    fields: <String, String>{'username': 'u', 'password': 'p'},
    notes: '',
    mediaType: VaultMediaType.none,
    createdAt: DateTime(2024, 5, 1),
    updatedAt: DateTime(2024, 5, 1, 0, 0, id.length),
  );
}

Widget _harness(SecureVaultRepository repository) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VaultScreen(repository: repository),
    ),
  );
}

void main() {
  testWidgets('vault list renders entries and filters by category chips', (
    tester,
  ) async {
    final repository = _FakeVaultRepository();
    await repository.upsert(
      _entry(
        id: 'login',
        title: 'Session Token',
        category: VaultCategory.login,
      ),
    );
    await repository.upsert(
      _entry(
        id: 'note',
        title: 'Recovery phrase',
        category: VaultCategory.secureNote,
      ),
    );

    await tester.pumpWidget(_harness(repository));
    await tester.pumpAndSettle();

    expect(find.text('Vault'), findsNWidgets(2));
    expect(find.text('Session Token'), findsOneWidget);
    expect(find.text('Recovery phrase'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Passwords'));
    await tester.pumpAndSettle();

    expect(find.text('Session Token'), findsOneWidget);
    expect(find.text('Recovery phrase'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Session Token'), findsOneWidget);
    expect(find.text('Recovery phrase'), findsOneWidget);
  });

  testWidgets('empty vault shows the friendly empty state', (tester) async {
    await tester.pumpWidget(_harness(_FakeVaultRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('vault editor exposes a drawing action', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VaultEntryEditorScreen(
            category: VaultCategory.secureNote,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(l10n.drawOption), findsOneWidget);
  });

  testWidgets('add sheet lists the four vault categories', (tester) async {
    await tester.pumpWidget(_harness(_FakeVaultRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    );
    expect(find.widgetWithText(ListTile, l10n.vaultAddCard), findsOneWidget);
    expect(find.widgetWithText(ListTile, l10n.vaultAddBank), findsOneWidget);
    expect(
      find.widgetWithText(ListTile, l10n.vaultAddSecureNote),
      findsOneWidget,
    );
  });
}
