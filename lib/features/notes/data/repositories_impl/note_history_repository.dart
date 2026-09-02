import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/notes/data/datasources/note_local_data_source.dart';
import 'package:notey/features/notes/domain/entities/note_history.dart';
import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

/// SQL-backed implementation of [NoteHistoryRepository].
class NoteHistoryRepositoryImpl implements NoteHistoryRepository {
  NoteHistoryRepositoryImpl({NoteDatabase? database})
      : _dataSource =
            NoteLocalDataSource(database: database ?? NoteDatabase.instance);

  final NoteLocalDataSource _dataSource;

  @override
  Future<void> log(NoteHistory entry) => _dataSource.logHistory(entry);

  @override
  Future<List<NoteHistory>> getHistory(String noteId) =>
      _dataSource.getHistory(noteId);

  @override
  Future<void> deleteAll(String noteId) => _dataSource.deleteHistory(noteId);

  @override
  Future<void> trim(String noteId, {int keep = 30}) =>
      _dataSource.trimHistory(noteId, keep: keep);
}
