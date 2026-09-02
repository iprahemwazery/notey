import 'package:flutter_test/flutter_test.dart';

import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/presentation/cubits/vault_cubit.dart';
import 'package:notey/features/vault/presentation/cubits/vault_state.dart';

List<int> _fixedKeyBytes() => List<int>.filled(32, 7);

Future<List<int>> _fixedKey() async => _fixedKeyBytes();

VaultEntry _entry({
  required String id,
  VaultCategory category = VaultCategory.login,
  VaultMediaType mediaType = VaultMediaType.none,
}) {
  final now = DateTime(2024, 5, 1);
  return VaultEntry(
    id: id,
    category: category,
    title: 'Title $id',
    fields: <String, String>{'username': 'u', 'password': 'p'},
    notes: '',
    mediaType: mediaType,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late NoteDatabase database;
  late SecureVaultRepository repository;
  late VaultCubit cubit;

  setUp(() async {
    database = NoteDatabase(inMemory: true);
    repository = SecureVaultRepository(database: database, rootKey: _fixedKey);
    cubit = VaultCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('load from an empty vault emits ready with no entries', () async {
    await cubit.load();
    expect(cubit.state.phase, VaultPhase.ready);
    expect(cubit.state.entries, isEmpty);
    expect(cubit.state.filteredEntries, isEmpty);
  });

  test('upsert makes entries visible and persists them', () async {
    await cubit.upsert(_entry(id: 'a', category: VaultCategory.login));
    await cubit.upsert(
      _entry(id: 'b', category: VaultCategory.secureNote),
    );

    expect(cubit.state.phase, VaultPhase.ready);
    expect(cubit.state.entries, hasLength(2));
    expect(cubit.state.filteredEntries, hasLength(2));

    final reloaded = await repository.getAll();
    expect(reloaded.map((e) => e.id).toSet(), <String>{'a', 'b'});
  });

  test('remove deletes the entry and reloads the list', () async {
    await cubit.upsert(_entry(id: 'a'));
    await cubit.upsert(_entry(id: 'b'));

    await cubit.remove('a');

    expect(cubit.state.entries.map((e) => e.id), <String>['b']);
    expect(await repository.get('a'), isNull);
  });

  test('filters by category and media type', () async {
    await cubit.upsert(_entry(id: 'login', category: VaultCategory.login));
    await cubit.upsert(
      _entry(id: 'card', category: VaultCategory.creditCard),
    );
    await cubit.upsert(
      _entry(id: 'bank', category: VaultCategory.bankAccount),
    );
    await cubit.upsert(
      _entry(
        id: 'doc',
        category: VaultCategory.secureNote,
        mediaType: VaultMediaType.document,
      ),
    );
    await cubit.upsert(
      _entry(
        id: 'audio',
        category: VaultCategory.secureNote,
        mediaType: VaultMediaType.audio,
      ),
    );

    // Default filter is `all`.
    expect(cubit.state.filteredEntries, hasLength(5));

    cubit.setFilter(VaultFilter.all);
    expect(cubit.state.filteredEntries, hasLength(5));

    cubit.setFilter(VaultFilter.passwords);
    expect(cubit.state.filteredEntries.map((e) => e.id), <String>['login']);

    cubit.setFilter(VaultFilter.banking);
    expect(
      cubit.state.filteredEntries.map((e) => e.id).toSet(),
      <String>{'card', 'bank'},
    );

    cubit.setFilter(VaultFilter.documents);
    expect(cubit.state.filteredEntries.map((e) => e.id), <String>['doc']);

    cubit.setFilter(VaultFilter.audio);
    expect(cubit.state.filteredEntries.map((e) => e.id), <String>['audio']);

    cubit.setFilter(VaultFilter.canvas);
    expect(cubit.state.filteredEntries, isEmpty);
  });

  test('filter toggle does not emit when unchanged', () async {
    var emissions = 0;
    final subscription = cubit.stream.listen((_) => emissions++);
    cubit.setFilter(VaultFilter.all);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    expect(emissions, 0);
  });

  test('a failing repository surfaces an error phase without crashing',
      () async {
    var shouldFail = false;
    cubit = VaultCubit(
      SecureVaultRepository(
        database: database,
        rootKey: () async {
          if (shouldFail) throw Exception('secure storage unavailable');
          return List<int>.filled(32, 7);
        },
      ),
    );
    await cubit.upsert(_entry(id: 'a'));

    shouldFail = true;
    await cubit.load();
    expect(cubit.state.phase, VaultPhase.error);
    expect(cubit.state.error, isNotNull);
  });
}