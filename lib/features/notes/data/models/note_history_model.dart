import 'package:notey/features/notes/domain/entities/note_history.dart';

/// Data-layer mapper between the [NoteHistory] domain entity and its SQLite
/// row. Keeps column serialization out of the pure entity.
class NoteHistoryModel {
  const NoteHistoryModel._();

  static Map<String, Object?> toMap(NoteHistory entry) => <String, Object?>{
    'id': entry.id,
    'noteId': entry.noteId,
    'title': entry.title,
    'content': entry.content,
    'timestamp': entry.timestamp.millisecondsSinceEpoch,
  };

  static NoteHistory fromMap(Map<String, Object?> map) {
    return NoteHistory(
      id: map['id'] as String,
      noteId: map['noteId'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
