import 'dart:convert';
import 'dart:math';

import 'package:notey/core/utils/attachment_utils.dart';


/// A note entity. Timestamps are set automatically on create/update.
/// Soft-deleted notes carry a [deletedAt] stamp until purged.
class Note {
  final String id;
  final String title;
  final String content;

  /// Paths of attached files (images and documents alike), stored in the
  /// legacy `images` DB column as a JSON array.
  final List<String> attachments;
  final int colorIndex;
  final bool pinned;

  /// When true the [title]/[content] fields hold ciphertext and the note
  /// is hidden behind a password until decrypted in memory.
  final bool isLocked;

  /// Base64 salt used for this note's password-derived key.
  final String? lockSalt;

  /// When non-null the note lives in the trash and can still be restored.
  final DateTime? deletedAt;

  /// User tags for grouping/filtering (trimmed, deduplicated on save).
  final List<String> tags;

  /// When non-null a reminder notification should fire at this time.
  final DateTime? reminderAt;

  /// Optional folder/category name for deeper organization.
  final String folder;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.attachments,
    required this.colorIndex,
    this.pinned = false,
    this.isLocked = false,
    this.lockSalt,
    this.deletedAt,
    this.tags = const <String>[],
    this.reminderAt,
    this.folder = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Collision-proof id: timestamp + cryptographically random suffix.
  static String newId() {
    final now = DateTime.now();
    return '${now.microsecondsSinceEpoch}_${Random.secure().nextInt(0xFFFFFFFF).toRadixString(16)}';
  }

  /// Builds a brand-new note stamping creation & update time automatically.
  factory Note.create({
    required String title,
    String content = '',
    List<String> attachments = const <String>[],
    int colorIndex = 0,
    bool pinned = false,
    List<String> tags = const <String>[],
    DateTime? reminderAt,
    String folder = '',
  }) {
    final now = DateTime.now();
    return Note(
      id: newId(),
      title: title,
      content: content,
      attachments: attachments,
      colorIndex: colorIndex,
      pinned: pinned,
      tags: tags,
      reminderAt: reminderAt,
      folder: folder,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isEmpty =>
      title.trim().isEmpty && content.trim().isEmpty && attachments.isEmpty;

  /// Subset of [attachments] that render as images (by extension).
  List<String> get imageAttachments =>
      attachments.where(AttachmentUtils.isImage).toList();

  /// Sentinel object so [copyWith] can distinguish "keep" from "set null".
  static const Object _unset = Object();

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? attachments,
    int? colorIndex,
    bool? pinned,
    bool? isLocked,
    Object? lockSalt = _unset,
    Object? deletedAt = _unset,
    List<String>? tags,
    Object? reminderAt = _unset,
    String? folder,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      colorIndex: colorIndex ?? this.colorIndex,
      pinned: pinned ?? this.pinned,
      isLocked: isLocked ?? this.isLocked,
      lockSalt: lockSalt == _unset ? this.lockSalt : lockSalt as String?,
      deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
      tags: tags ?? this.tags,
      reminderAt: reminderAt == _unset
          ? this.reminderAt
          : reminderAt as DateTime?,
      folder: folder ?? this.folder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'title': title,
    'content': content,
    'images': jsonEncode(attachments),
    'colorIndex': colorIndex,
    'pinned': pinned ? 1 : 0,
    'isLocked': isLocked ? 1 : 0,
    'lockSalt': lockSalt,
    'deletedAt': deletedAt?.millisecondsSinceEpoch,
    'tags': jsonEncode(tags),
    'reminderAt': reminderAt?.millisecondsSinceEpoch,
    'folder': folder,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Note.fromMap(Map<String, Object?> map) {
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
