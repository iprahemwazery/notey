import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:notey/core/services/vault_crypto.dart';
import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/data/services/vault_file_store.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getTemporaryPath() async => p.join(root, 'tmp');

  @override
  Future<String?> getApplicationDocumentsPath() async => p.join(root, 'docs');
}

List<int> _fixedKeyBytes() => List<int>.filled(32, 7);

Future<List<int>> _fixedKey() async => _fixedKeyBytes();

VaultEntry _sampleEntry({VaultCategory category = VaultCategory.login}) {
  final now = DateTime(2024, 5, 1);
  return VaultEntry(
    id: VaultEntry.newId(),
    category: category,
    title: 'Session A',
    fields: <String, String>{'username': 'mr-robot', 'password': 'P@ssw0rd!'},
    notes: 'Keep me safe',
    mediaType: VaultMediaType.none,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('VaultCrypto', () {
    test('encrypt/decrypt round-trips a payload', () async {
      const plain = '{"title":"sensitive"}';
      final envelope = await VaultCrypto.encrypt(
        plain,
        rootKey: _fixedKeyBytes(),
      );
      expect(envelope.split('.'), hasLength(3));

      final decoded = await VaultCrypto.decrypt(
        envelope,
        rootKey: _fixedKeyBytes(),
      );
      expect(decoded, plain);
    });

    test('different writes produce different IVs/envelopes', () async {
      final a = await VaultCrypto.encrypt('same', rootKey: _fixedKeyBytes());
      final b = await VaultCrypto.encrypt('same', rootKey: _fixedKeyBytes());
      expect(a, isNot(b));
    });

    test('a modified ciphertext is rejected (tamper detection)', () async {
      final envelope = await VaultCrypto.encrypt(
        'secret',
        rootKey: _fixedKeyBytes(),
      );
      final parts = envelope.split('.');
      final bytes = Uint8List.fromList(parts[1].codeUnits);
      bytes[bytes.length ~/ 2] = bytes[bytes.length ~/ 2] == 0x41 ? 0x42 : 0x41;
      final tampered = '${parts[0]}.${String.fromCharCodes(bytes)}.${parts[2]}';
      await expectLater(
        VaultCrypto.decrypt(tampered, rootKey: _fixedKeyBytes()),
        throwsA(isA<FormatException>()),
      );
    });

    test('a wrong root key fails to decrypt', () async {
      final envelope = await VaultCrypto.encrypt(
        'secret',
        rootKey: _fixedKeyBytes(),
      );
      await expectLater(
        VaultCrypto.decrypt(envelope, rootKey: List<int>.filled(32, 9)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  Future<void> insertRawRow(
    NoteDatabase database,
    String id, {
    required String envelope,
    required int updatedAt,
  }) async {
    final db = await database.database;
    await db.insert('vault_entries', <String, Object?>{
      'id': id,
      'category': VaultCategory.login.storageName,
      'mediaType': VaultMediaType.none.storageName,
      'attachments': '[]',
      'envelope': envelope,
      'createdAt': 0,
      'updatedAt': updatedAt,
    });
  }

  group('SecureVaultRepository', () {
    late NoteDatabase database;
    late SecureVaultRepository repository;

    setUp(() async {
      database = NoteDatabase(inMemory: true);
      repository = SecureVaultRepository(
        database: database,
        rootKey: _fixedKey,
      );
    });

    tearDown(() => database.close());

    test(
      'upsert then getAll round-trips decrypted entries newest-first',
      () async {
        final first = _sampleEntry();
        final second = _sampleEntry(
          category: VaultCategory.secureNote,
        ).copyWith(updatedAt: first.updatedAt.add(const Duration(days: 1)));

        await repository.upsert(first);
        await repository.upsert(second);

        final entries = await repository.getAll();
        expect(entries, hasLength(2));
        expect(entries.first.id, second.id);
        expect(entries.first.title, 'Session A');
        expect(entries.first.fields['password'], 'P@ssw0rd!');
        expect(entries.first.notes, 'Keep me safe');
      },
    );

    test('upsert with the same id replaces the previous row', () async {
      final entry = _sampleEntry();
      await repository.upsert(entry);
      await repository.upsert(
        entry.copyWith(
          title: 'Renamed',
          fields: <String, String>{'username': 'neo'},
        ),
      );

      final entries = await repository.getAll();
      expect(entries, hasLength(1));
      expect(entries.single.title, 'Renamed');
      expect(entries.single.fields['username'], 'neo');
    });

    test('get returns null for a missing or tampered row', () async {
      final entry = _sampleEntry();
      await repository.upsert(entry);
      expect(await repository.get(entry.id), isNotNull);

      await repository.delete(entry.id);
      expect(await repository.get(entry.id), isNull);

      await insertRawRow(
        database,
        'bad',
        envelope: 'garbage.garbage.garbage',
        updatedAt: 1,
      );
      expect(await repository.get('bad'), isNull);
    });

    test('a single tampered row is skipped without breaking getAll', () async {
      final good = _sampleEntry();
      await repository.upsert(good);
      await insertRawRow(
        database,
        'boycotted',
        envelope: 'bad.bad.bad',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final entries = await repository.getAll();
      expect(entries, hasLength(1));
      expect(entries.single.id, good.id);
    });
  });

  group('VaultFileStore', () {
    late Directory root;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      root = await Directory.systemTemp.createTemp('notey_vault_test');
      await Directory(p.join(root.path, 'tmp')).create(recursive: true);
      await Directory(p.join(root.path, 'docs')).create(recursive: true);
      PathProviderPlatform.instance = _FakePathProvider(root.path);
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('persists an encrypted attachment and decrypts it back', () async {
      final source = File(p.join(root.path, 'original.txt'))
        ..writeAsStringSync('top secret notes');
      final store = VaultFileStore(rootKey: _fixedKey);

      final encPath = await store.persistEncrypted(source.path);
      expect(p.extension(encPath).toLowerCase(), '.enc');
      expect(await File(encPath).exists(), isTrue);

      final onDisk = await File(encPath).readAsString();
      expect(onDisk, isNot(contains('top secret')));

      final temp = await store.decryptToTemp(encPath);
      expect(p.extension(temp).toLowerCase(), '.txt');
      expect(await File(temp).readAsString(), 'top secret notes');

      await VaultFileStore.disposeOf(temp);
      expect(await File(temp).exists(), isFalse);
    });

    test('delete removes the encrypted file', () async {
      final source = File(p.join(root.path, 'a.bin'))
        ..writeAsBytesSync(List<int>.generate(64, (i) => i));
      final store = VaultFileStore(rootKey: _fixedKey);

      final encPath = await store.persistEncrypted(source.path);
      expect(await File(encPath).exists(), isTrue);

      await store.delete(encPath);
      expect(await File(encPath).exists(), isFalse);
    });
  });
}
