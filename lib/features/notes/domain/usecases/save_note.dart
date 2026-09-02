import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/entities/note_history.dart';
import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Coordinates saving a note from the editor.
///
/// Inserts a brand-new note, or updates an existing one while logging a history
/// snapshot when its title/content changed (and trimming the history backlog).
class SaveNote {
  SaveNote(this._repository, this._historyRepo);

  final NoteRepository _repository;
  final NoteHistoryRepository _historyRepo;

  Future<void> call({
    required bool isEditing,
    Note? existing,
    required String title,
    required String content,
    List<String> attachments = const <String>[],
    List<String> tags = const <String>[],
    int colorIndex = 0,
    DateTime? reminderAt,
    String folder = '',
  }) async {
    final now = DateTime.now();
    if (isEditing && existing != null) {
      final original = existing;
      final updated = original.copyWith(
        title: title,
        content: content,
        attachments: attachments,
        tags: tags,
        colorIndex: colorIndex,
        reminderAt: reminderAt,
        folder: folder,
        updatedAt: now,
      );
      if (original.title != title || original.content != content) {
        await _historyRepo.log(
          NoteHistory.create(
            noteId: original.id,
            title: original.title,
            content: original.content,
          ),
        );
        await _historyRepo.trim(original.id, keep: 30);
      }
      await _repository.update(updated);
    } else {
      final note = Note.create(
        title: title,
        content: content,
        attachments: attachments,
        tags: tags,
        colorIndex: colorIndex,
        reminderAt: reminderAt,
        folder: folder,
      );
      await _repository.insert(note);
    }
  }
}
