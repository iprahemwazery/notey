import 'package:path/path.dart' as p;

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
/// A pure domain entity carrying only in-memory (decrypted) business data.
/// It performs no I/O and no cryptography: sealing/encryption and the SQLite
/// row mapping live in the data layer (see `VaultEntryCodec`), never here.
///
/// Only structural metadata is stored in plaintext on disk: [id], [category],
/// [mediaType] and the (opaque) attachment paths. Everything sensitive — the
/// title, every field value and the free note body — lives inside an
/// AES-256-CBC+HMAC envelope produced by the data layer.
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
}
