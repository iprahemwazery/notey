import 'dart:convert';

import 'package:path/path.dart' as p;

import 'package:notey/core/services/vault_crypto.dart';


/// Built-in vault entry categories with their structured field expectations.
enum VaultCategory {
  login,
  creditCard,
  bankAccount,
  secureNote;

  String get storageName => name;

  static VaultCategory fromStorage(String name) {
    for (final category in VaultCategory.values) {
      if (category.name == name) return category;
    }
    return VaultCategory.secureNote;
  }
}

/// Media nature of a vault entry's attachment bundle, used for the home-style
/// category chips (`Documents | Audio | Canvas`).
enum VaultMediaType {
  none,
  document,
  audio,
  drawing;

  String get storageName => name;

  static VaultMediaType fromStorage(String name) {
    for (final mediaType in VaultMediaType.values) {
      if (mediaType.name == name) return mediaType;
    }
    return VaultMediaType.none;
  }

  /// Infers a media type from a set of attachment paths. Audio wins first
  /// (matters most), otherwise non-empty bundles count as documents.
  static VaultMediaType infer(List<String> attachments) {
    if (attachments.isEmpty) return VaultMediaType.none;
    for (final path in attachments) {
      if (_audioExtensions.contains(p.extension(path).toLowerCase())) {
        return VaultMediaType.audio;
      }
    }
    return VaultMediaType.document;
  }

  static const Set<String> _audioExtensions = <String>{
    '.m4a',
    '.mp3',
    '.aac',
    '.wav',
    '.ogg',
    '.opus',
  };
}

/// A digital vault entry.
///
/// Only structural metadata is stored in plaintext on disk: [id], [category],
/// [mediaType] and the (opaque) attachment paths. Everything sensitive — the
/// title, every field value and the free note body — lives inside the
/// AES-256-CBC+HMAC [envelope] and is decrypted into memory on demand.
class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.fields,
    this.notes = '',
    this.mediaType = VaultMediaType.none,
    this.attachments = const <String>[],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final VaultCategory category;
  final String title;

  /// Structured key/value fields, decrypted in memory only.
  final Map<String, String> fields;
  final String notes;

  /// Inferred media classification used by the vault filter chips.
  final VaultMediaType mediaType;

  /// Absolute paths of at-rest encrypted attachments (`.enc` files).
  final List<String> attachments;

  final DateTime createdAt;
  final DateTime updatedAt;

  static String newId() {
    final now = DateTime.now();
    return '${now.microsecondsSinceEpoch}_${now.microsecondsSinceEpoch % 0xFFFF}';
  }

  VaultEntry copyWith({
    String? title,
    Map<String, String>? fields,
    String? notes,
    VaultMediaType? mediaType,
    List<String>? attachments,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id,
      category: category,
      title: title ?? this.title,
      fields: fields ?? this.fields,
      notes: notes ?? this.notes,
      mediaType: mediaType ?? this.mediaType,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Future<Map<String, Object?>> toEnvelopeRow(List<int> rootKey) async {
    final body = jsonEncode(<String, Object?>{
      'title': title,
      'fields': fields,
      'notes': notes,
    });
    final envelope = await VaultCrypto.encrypt(body, rootKey: rootKey);
    return <String, Object?>{
      'id': id,
      'category': category.storageName,
      'mediaType': mediaType.storageName,
      'attachments': jsonEncode(attachments),
      'envelope': envelope,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Future<VaultEntry> fromEnvelopeRow(
    Map<String, Object?> row,
    List<int> rootKey,
  ) async {
    final envelope = row['envelope'] as String? ?? '';
    final String plain;
    try {
      plain = await VaultCrypto.decrypt(envelope, rootKey: rootKey);
    } on FormatException {
      rethrow;
    }
    return _build(row, plain);
  }

  /// Decrypts every envelope in a single background isolate (see
  /// [VaultCrypto.decryptBatch]) and builds the entries — corrupt rows are
  /// skipped so one damaged entry never bricks the whole list.
  static Future<List<VaultEntry>> fromEnvelopeRows(
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

  static VaultEntry _build(Map<String, Object?> row, String plain) {
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