import 'dart:convert';

import 'package:notey/core/services/vault_crypto.dart';

import 'package:notey/features/vault/domain/entities/vault_entry.dart';

/// Maps a pure domain [VaultEntry] to/from its at-rest SQLite row.
///
/// This lives in the data layer on purpose: sealing (encryption) and unsealing
/// (decryption) are data/infrastructure concerns and must not leak into the
/// domain entity or the UI.
class VaultEntryCodec {
  const VaultEntryCodec();

  /// Seals the sensitive payload ([title], [fields], [notes]) into an
  /// AES envelope and builds the plaintext-metadata row for SQLite.
  Future<Map<String, Object?>> toRow(
    VaultEntry entry,
    List<int> rootKey,
  ) async {
    final body = jsonEncode(<String, Object?>{
      'title': entry.title,
      'fields': entry.fields,
      'notes': entry.notes,
    });
    final envelope = await VaultCrypto.encrypt(body, rootKey: rootKey);
    return <String, Object?>{
      'id': entry.id,
      'category': entry.category.storageName,
      'mediaType': entry.mediaType.storageName,
      'attachments': jsonEncode(entry.attachments),
      'envelope': envelope,
      'createdAt': entry.createdAt.millisecondsSinceEpoch,
      'updatedAt': entry.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Unseals a single row back into a domain [VaultEntry].
  Future<VaultEntry> fromRow(
    Map<String, Object?> row,
    List<int> rootKey,
  ) async {
    final envelope = row['envelope'] as String? ?? '';
    final plain = await VaultCrypto.decrypt(envelope, rootKey: rootKey);
    return _build(row, plain);
  }

  /// Decrypts every envelope in a single background isolate (see
  /// [VaultCrypto.decryptBatch]) and builds the entries — corrupt rows are
  /// skipped so one damaged entry never bricks the whole list.
  Future<List<VaultEntry>> fromRows(
    List<Map<String, Object?>> rows,
    List<int> rootKey,
  ) async {
    if (rows.isEmpty) return <VaultEntry>[];
    final envelopes = <String>[
      for (final row in rows) row['envelope'] as String? ?? '',
    ];
    final bodies = await VaultCrypto.decryptBatch(envelopes, rootKey: rootKey);
    final entries = <VaultEntry>[];
    for (var i = 0; i < rows.length; i++) {
      final plain = bodies[i];
      if (plain == null) continue;
      try {
        entries.add(_build(rows[i], plain));
      } on FormatException {
        continue;
      }
    }
    return entries;
  }

  VaultEntry _build(Map<String, Object?> row, String plain) {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(plain) as Map<String, dynamic>;
    } on TypeError {
      throw const FormatException('Corrupt vault entry body');
    }

    final rawFields = body['fields'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        if (key is String) fields[key] = '${value ?? ''}';
      });
    }

    final createdAt =
        (row['createdAt'] as int?) ?? (row['updatedAt'] as int?) ?? 0;
    final updatedAt = (row['updatedAt'] as int?) ?? createdAt;

    return VaultEntry(
      id: row['id'] as String? ?? '',
      category: VaultCategory.fromStorage(row['category'] as String? ?? ''),
      title: '${body['title'] ?? ''}',
      fields: fields,
      notes: '${body['notes'] ?? ''}',
      mediaType: VaultMediaType.fromStorage(
        row['mediaType'] as String? ?? '',
      ),
      attachments: _parseList(row['attachments'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  static List<String> _parseList(String? raw) {
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } on FormatException {
      // Fall through.
    } on TypeError {
      // Fall through.
    }
    return <String>[];
  }
}
