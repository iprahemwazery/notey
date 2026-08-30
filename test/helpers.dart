import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/app.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/services/crypto_service.dart';
import 'package:notey/data/database/note_database.dart';
import 'package:notey/data/repositories/note_repository.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note.dart';
import 'package:notey/features/notes/model/note_search_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake secure storage backed by an in-memory map.
class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async =>
      values.remove(key);

  @override
  Future<bool> containsKey({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async =>
      values.containsKey(key);

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async =>
      Map<String, String>.of(values);
}

/// In-memory note repository for tests.
class FakeRepository extends NoteRepository {
  FakeRepository() : super(database: NoteDatabase(inMemory: true));

  final List<Note> notes = <Note>[];

  @override
  Future<List<Note>> getNotes({String? search, String? folder}) async {
    final term = search?.trim() ?? '';
    final filtered = notes
        .where((n) => n.deletedAt == null)
        .where(
          (n) =>
              term.isEmpty ||
              n.title.toLowerCase().contains(term.toLowerCase()) ||
              n.content.toLowerCase().contains(term.toLowerCase()),
        )
        .where((n) => folder == null || folder.isEmpty || n.folder == folder)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  @override
  Future<List<NoteSearchMatch>> searchNotes({
    required String search,
    String? folder,
  }) async {
    final term = search.trim();
    if (term.isEmpty) return const <NoteSearchMatch>[];
    final termLower = term.toLowerCase();
    final base = await getNotes(search: term, folder: folder);
    final results = <NoteSearchMatch>[];
    for (final note in base) {
      if (note.isLocked) continue;
      if (note.content.toLowerCase().contains(termLower)) {
        results.add(
          NoteSearchMatch(
            note: note,
            location: SearchMatchLocation.content,
            preview: searchSnippetAround(note.content, term),
          ),
        );
      } else {
        results.add(
          NoteSearchMatch(
            note: note,
            location: SearchMatchLocation.title,
            preview: firstContentLine(note.content),
          ),
        );
      }
    }
    return results;
  }

  @override
  Future<List<Note>> getAllNotesIncludingDeleted() async =>
      List<Note>.of(notes);

  @override
  Future<List<String>> getFolders() async {
    final folders = notes
        .where((n) => n.deletedAt == null && n.folder.isNotEmpty)
        .map((n) => n.folder)
        .toSet()
        .toList()
      ..sort();
    return folders;
  }

  @override
  Future<Note?> getNote(String id) async {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<void> insert(Note note) async => notes.add(note);

  @override
  Future<void> insertAll(List<Note> inserted) async =>
      notes.addAll(inserted);

  @override
  Future<void> update(Note note) async {
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) notes[index] = note;
  }

  @override
  Future<void> updateAll(List<Note> updated) async {
    for (final note in updated) {
      await update(note);
    }
  }

  @override
  Future<void> softDelete(String id, {DateTime? at}) async {
    final note = await getNote(id);
    if (note != null) {
      await update(note.copyWith(deletedAt: at ?? DateTime.now()));
    }
  }

  @override
  Future<void> softDeleteAll(List<String> ids, {DateTime? at}) async {
    for (final id in ids) {
      await softDelete(id, at: at);
    }
  }

  @override
  Future<void> restore(String id) => _restoreAll(<String>[id]);

  @override
  Future<void> restoreAll(List<String> ids) => _restoreAll(ids);

  Future<void> _restoreAll(List<String> ids) async {
    for (final id in ids) {
      final note = await getNote(id);
      if (note != null) await update(note.copyWith(deletedAt: null));
    }
  }

  @override
  Future<List<Note>> getDeletedNotes() async =>
      notes.where((n) => n.deletedAt != null).toList();

  @override
  Future<void> purge(String id) async =>
      notes.removeWhere((n) => n.id == id);
}

/// Always-authenticates immediately.
class AutoBiometricService implements BiometricService {
  @override
  Future<BiometricResult> authenticate({
    bool deviceCredential = false,
    String? localizedReason,
  }) async =>
      BiometricResult.authenticated;

  @override
  Future<BiometricAvailability> getAvailability() async =>
      BiometricAvailability.supported;

  @override
  Future<bool> openBiometricsSettings() async => true;

  @override
  Future<void> stopAuthentication() async {}
}

/// Builds a [NoteyApp] with the given fakes, bypassing lock for convenience.
NoteyApp buildApp(NoteRepository repository, {BiometricService? biometric}) {
  return NoteyApp(
    repository: repository,
    biometricService: biometric ?? AutoBiometricService(),
    secureStorage: FakeSecureStorage(),
  );
}

/// Wraps [action] in [tester.runAsync] so real async I/O works in tests.
Future<void> runAsyncSafe(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  try {
    await tester.runAsync(action);
  } on Exception {
    // Ignore cleanup failures.
  }
}

/// Common test setup: fast crypto, deterministic cursor, default prefs.
void setUpCommon({Map<String, Object>? prefs}) {
  CryptoService.pbkdf2Iterations = 1000;
  CryptoService.minIterations = 0;
  PinHasher.pbkdf2Iterations = 1000;
  PinHasher.minIterations = 0;
  EditableText.debugDeterministicCursor = true;
  SharedPreferences.setMockInitialValues(
    prefs ??
        <String, Object>{
          'appLockMethod': 'none',
          'onboardingDone': true,
        },
  );
}

/// Creates a note and inserts it into the repository.
Future<Note> createTestNote(
  FakeRepository repo, {
  String title = 'Test Note',
  String content = 'Test content',
  bool pinned = false,
}) async {
  final note = Note(
    id: Note.newId(),
    title: title,
    content: content,
    pinned: pinned,
    colorIndex: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    attachments: const <String>[],
    tags: const <String>[],
  );
  await repo.insert(note);
  return note;
}

/// Wraps any widget in a MaterialApp with localization for isolated screen tests.
/// Pushes [child] as a second route so a back button is always available.
/// Also initializes ScreenUtil so responsive `.sp`/`.w`/`.h` extensions work.
Widget buildTestApp(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _RouteShell(child: child),
    ),
  );
}

/// Puts a placeholder route behind [child] so AppBar back buttons work.
class _RouteShell extends StatefulWidget {
  const _RouteShell({required this.child});
  final Widget child;
  @override
  State<_RouteShell> createState() => _RouteShellState();
}

class _RouteShellState extends State<_RouteShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => widget.child),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
