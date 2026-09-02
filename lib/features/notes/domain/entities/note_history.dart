/// A snapshot of a note's content at a point in time, used for edit history.
///
/// Pure domain entity: no I/O or serialization here (see `NoteHistoryModel`
/// in the data layer for column mapping).
class NoteHistory {
  final String id;
  final String noteId;
  final String title;
  final String content;
  final DateTime timestamp;

  const NoteHistory({
    required this.id,
    required this.noteId,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  factory NoteHistory.create({
    required String noteId,
    required String title,
    required String content,
  }) {
    final now = DateTime.now();
    return NoteHistory(
      id: '${now.microsecondsSinceEpoch}_${now.microsecondsSinceEpoch.toRadixString(16)}',
      noteId: noteId,
      title: title,
      content: content,
      timestamp: now,
    );
  }
}
