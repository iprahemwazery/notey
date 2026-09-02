import 'package:notey/features/notes/domain/entities/note.dart';

/// Port – repository exposing all trash-bin operations.
///
/// Encapsulates the cross-cutting work of permanently removing a note: the
/// notes repository purge, cancelling its reminder and freeing its attached
/// files, so the UI (and its cubit) never touches storage or services directly.
/// The concrete implementation lives in the data layer.
abstract interface class TrashRepository {
  /// Loads the trash list, auto-purging notes past the retention window first
  /// (and cleaning up each purged note's reminder + files). Returns the notes
  /// currently in the trash, most recently deleted first.
  Future<List<Note>> load();

  /// The configured retention period (in days) before trashed notes are
  /// auto-purged.
  Future<int> retentionDays();

  /// Restores a trashed [note] back to the main list and re-arms its reminder.
  Future<void> restore(Note note);

  /// Permanently deletes every [note] from the trash.
  Future<void> purge(List<Note> notes);

  /// Permanently deletes every trashed note.
  Future<void> empty();
}
