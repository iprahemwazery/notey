import 'dart:convert';

import 'package:notey/features/notes/domain/entities/note.dart';

/// Data-layer mapper between the [Note] domain entity and its SQLite row.
///
/// Holds every serialization concern (JSON-encoded columns, epoch timestamps,
/// booleans-as-integers) that is deliberately excluded from the pure entity.
class NoteModel {
  const NoteModel._();

  static Map<String, Object?> toMap(Note note) => <String, Object?>{
    'id': note.id,
    'title': note.title,
    'content': note.content,
    'images': jsonEncode(note.attachments),
    'colorIndex': note.colorIndex,
    'pinned': note.pinned ? 1 : 0,
    'isLocked': note.isLocked ? 1 : 0,
    'lockSalt': note.lockSalt,
    'deletedAt': note.deletedAt?.millisecondsSinceEpoch,
    'tags': jsonEncode(note.tags),
    'reminderAt': note.reminderAt?.millisecondsSinceEpoch,
    'folder': note.folder,
    'createdAt': note.createdAt.millisecondsSinceEpoch,
    'updatedAt': note.updatedAt.millisecondsSinceEpoch,
  };

  static Note fromMap(Map<String, Object?> map) {
    List<String> parseStringList(String? raw) {
      if (raw == null || raw.isEmpty) return <String>[];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.cast<String>();
        }
      } on FormatException {
        // Corrupt JSON — return empty list.
      } on TypeError {
        // JSON decoded to wrong type — return empty list.
      }
      return <String>[];
    }

    final attachments = parseStringList(map['images'] as String?);
    final createdAt =
        (map['createdAt'] as int?) ?? (map['updatedAt'] as int?) ?? 0;
    final updatedAt = (map['updatedAt'] as int?) ?? createdAt;
    final deletedAt = map['deletedAt'] as int?;
    final reminderAt = map['reminderAt'] as int?;
    return Note(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      attachments: attachments,
      colorIndex: map['colorIndex'] as int? ?? 0,
      pinned: (map['pinned'] as int? ?? 0) == 1,
      isLocked: (map['isLocked'] as int? ?? 0) == 1,
      lockSalt: map['lockSalt'] as String?,
      deletedAt: deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(deletedAt),
      tags: parseStringList(map['tags'] as String?),
      reminderAt: reminderAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reminderAt),
      folder: map['folder'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}
