import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/presentation/screens/vault_entry_detail_screen.dart';
import 'package:notey/features/vault/presentation/screens/vault_screen.dart';

/// Fast in-memory repo (no crypto/isolates) that counts every `getAll()`.
/// `VaultScreen` builds its own cubit from `widget.repository`, so handing it
/// this repo makes the test exercise the real navigation/reload behaviour.
class _FastRepo extends SecureVaultRepository {
  _FastRepo() : super(rootKey: () async => List<int>.generate(32, (i) => i));

  final Map<String, VaultEntry> store = <String, VaultEntry>{};
  int loadCount = 0;

  @override
  Future<List<VaultEntry>> getAll() async {
    loadCount++;
    final list = store.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }
}

VaultEntry _entry(String id) {
  return VaultEntry(
    id: id,
    category: VaultCategory.login,
    title: 'Entry $id with a reasonably long title to test wrapping',
    fields: const <String, String>{'username': 'u', 'password': 'p'},
    notes: 'secret note body for $id',
    mediaType: VaultMediaType.none,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Widget _harness(_FastRepo repo) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VaultScreen(repository: repo),
    ),
  );
}

void main() {
  testWidgets(
      'vault loads once and returning from a card does not reload/re-decrypt',
      (tester) async {
    final repo = _FastRepo();
    for (var i = 0; i < 30; i++) {
      repo.store['id_$i'] = _entry('id_$i');
    }

    await tester.pumpWidget(_harness(repo));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // The vault's cubit must have loaded exactly once (one decrypt pass).
    expect(repo.loadCount, 1,
        reason: 'Opening the vault should decrypt/load exactly once');

    // Scroll to an entry card, open its detail, then go back.
    final scrollable = find.byType(CustomScrollView);
    for (var i = 0; i < 8; i++) {
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 50));
    }
    final title = find.text(
      'Entry id_29 with a reasonably long title to test wrapping',
    );
    expect(title, findsOneWidget,
        reason: 'Entry cards should be built after scrolling');
    await tester.ensureVisible(title);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VaultEntryDetailScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));

    final countAfterOpen = repo.loadCount;
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.loadCount, countAfterOpen,
        reason: 'Returning from an entry must NOT reload/re-decrypt the vault');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
