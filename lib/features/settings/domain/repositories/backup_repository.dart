import 'package:notey/features/notes/domain/entities/note.dart';

/// Port – repository exposing backup, import, app-info and wipe operations
/// shown in the settings "Backup" and "About" sections.
///
/// Abstracts the file picker, share sheet, JSON serialization and platform
/// version lookups behind one interface so the UI never touches them directly.
abstract interface class BackupRepository {
  /// Exports every [notes] (active + trashed) to a shareable backup file and
  /// returns its path.
  Future<String> export(List<Note> notes);

  /// Lets the user pick a `.json` backup file and returns its path, or `null`
  /// when the selection is cancelled.
  Future<String?> pickImportFile();

  /// Parses a backup [filePath] and returns the recoverable notes.
  /// Throws [FormatException] when the file is not a valid Notey backup.
  Future<List<Note>> parse(String filePath);

  /// Shares a [filePath] with the system share sheet.
  Future<void> share(String filePath);

  /// The installed app version string (e.g. `v1.2.3`).
  Future<String> appVersion();

  /// Permanently wipes all app data.
  Future<void> wipeAllData();
}
