import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/app.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/core/services/crypto_service.dart';
import 'package:notey/data/database/note_database.dart';
import 'package:notey/data/repositories/note_repository.dart';
import 'package:notey/features/notes/model/note.dart';
import 'package:notey/features/notes/model/note_search_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
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
  }) async => values[key];

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
  }) async => values.remove(key);

  @override
  Future<bool> containsKey({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async => values.containsKey(key);

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async => Map<String, String>.of(values);
}

class _FakeRepository extends NoteRepository {
  _FakeRepository() : super(database: NoteDatabase(inMemory: true));

  final List<Note> notes = <Note>[];

  @override
  Future<List<Note>> getNotes({String? search, String? folder}) async {
    final term = search?.trim() ?? '';
    final filtered =
        notes
            .where((n) => n.deletedAt == null)
            .where(
              (n) =>
                  term.isEmpty ||
                  n.title.contains(term) ||
                  n.content.contains(term),
            )
            .where(
              (n) => folder == null || folder.isEmpty || n.folder == folder,
            )
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
    final folders =
        notes
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
  Future<void> insertAll(List<Note> inserted) async => notes.addAll(inserted);

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
  Future<void> purge(String id) async => notes.removeWhere((n) => n.id == id);
}

class _AutoBiometricService implements BiometricService {
  @override
  Future<BiometricResult> authenticate({
    bool deviceCredential = false,
    String? localizedReason,
  }) async => BiometricResult.authenticated;

  @override
  Future<BiometricAvailability> getAvailability() async =>
      BiometricAvailability.supported;

  @override
  Future<bool> openBiometricsSettings() async => true;

  @override
  Future<void> stopAuthentication() async {}
}

class _ManualBiometricService implements BiometricService {
  final Completer<BiometricResult> completer = Completer<BiometricResult>();

  @override
  Future<BiometricResult> authenticate({
    bool deviceCredential = false,
    String? localizedReason,
  }) => completer.future;

  @override
  Future<BiometricAvailability> getAvailability() async =>
      BiometricAvailability.supported;

  @override
  Future<bool> openBiometricsSettings() async => true;

  @override
  Future<void> stopAuthentication() async {}
}

NoteyApp _buildApp(
  NoteRepository repository, {
  BiometricService? biometricService,
}) {
  return NoteyApp(
    repository: repository,
    biometricService: biometricService ?? _AutoBiometricService(),
    secureStorage: _FakeSecureStorage(),
  );
}

/// Pumps the app on a realistic phone-sized surface (360×780 logical @3x)
/// instead of the flutter_test default 800×600 physical @3.0 (266.7×200
/// logical), which overflowed the real layouts (e.g. the lock menu and the
/// password dialog in the protect test).
Future<void> _pumpApp(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  // Home defers its DB load 150ms after the first frame (post-unlock race
  // guard). Frame one mounts HomeScreen and arms the timer; frame two must
  // advance the clock past it so no timer is left pending.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Advances the fake clock enough for a PIN auto-submit (80/160 ms) plus any
/// finite shake/transition animation to finish, then lets frames settle.
Future<void> _pumpPinFlow(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}

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

void main() {
  setUp(() {
    // Keep PBKDF2 fast inside widget tests.
    CryptoService.pbkdf2Iterations = 1000;
    CryptoService.minIterations = 0;
    PinHasher.pbkdf2Iterations = 1000;
    PinHasher.minIterations = 0;
    // Stop the text cursor from blinking so pumpAndSettle can settle.
    EditableText.debugDeterministicCursor = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'appLockMethod': 'none',
      'onboardingDone': true,
    });
  });

  test('lifecycle relock only triggers after a real background pause', () {
    expect(
      AppLifecycleRelockerPolicy.shouldRelock(
        const Duration(milliseconds: 250),
      ),
      isFalse,
    );
    expect(
      AppLifecycleRelockerPolicy.shouldRelock(const Duration(seconds: 2)),
      isTrue,
    );
  });

  testWidgets('app renders the home screen with add note button', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Notey'), findsNothing);
    expect(find.text('ملاحظة جديدة'), findsOneWidget);
    expect(find.text('لا توجد ملاحظات بعد'), findsOneWidget);
  });

  testWidgets('lock screen shows first and unlocks before home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'appLockMethod': 'biometric',
      'onboardingDone': true,
    });
    final biometric = _ManualBiometricService();
    await _pumpApp(
      tester,
      _buildApp(_FakeRepository(), biometricService: biometric),
    );
    await tester.pump();

    expect(find.text('استخدام الرقم السري الاحتياطي'), findsOneWidget);
    expect(find.text('ملاحظة جديدة'), findsNothing);

    biometric.completer.complete(BiometricResult.authenticated);
    await tester.pumpAndSettle();
    expect(find.text('ملاحظة جديدة'), findsOneWidget);
  });

  testWidgets('first run requires a lock method before showing home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboardingDone': true,
    });
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('اختر طريقة قفل التطبيق لحماية ملاحظاتك'), findsOneWidget);
    expect(find.text('أمان الجهاز'), findsOneWidget);
    expect(find.text('باسورد للتطبيق'), findsOneWidget);
    expect(find.text('تخطي مؤقتًا'), findsOneWidget);
    expect(find.text('ملاحظة جديدة'), findsNothing);

    // Choosing a PIN must not reveal home until the PIN is fully configured.
    await tester.tap(find.text('باسورد للتطبيق'));
    await tester.pumpAndSettle();
    expect(find.text('إنشاء رقم سري'), findsOneWidget);
    expect(find.text('ملاحظة جديدة'), findsNothing);

    // Enter the PIN (create) then confirm it.
    for (final digit in <String>['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await _pumpPinFlow(tester);

    for (final digit in <String>['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await _pumpPinFlow(tester);

    // Biometrics are offered before home is revealed; skipping completes setup.
    expect(find.text('إضافة فتح بالبصمة؟'), findsOneWidget);
    expect(find.text('ملاحظة جديدة'), findsNothing);
    await tester.tap(find.text('تخطي، استخدم الرقم السري فقط'));
    await tester.pumpAndSettle();

    expect(find.text('ملاحظة جديدة'), findsOneWidget);
  });

  testWidgets('first run can enable fingerprint unlock', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboardingDone': true,
    });
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    // New flow: set a PIN first, then the biometric offer is shown.
    await tester.tap(find.text('باسورد للتطبيق'));
    await tester.pumpAndSettle();

    for (final digit in <String>['5', '6', '7', '8']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await _pumpPinFlow(tester);

    for (final digit in <String>['5', '6', '7', '8']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await _pumpPinFlow(tester);

    expect(find.text('إضافة فتح بالبصمة؟'), findsOneWidget);
    await tester.tap(find.text('تفعيل البصمة'));
    await tester.pumpAndSettle();

    // After enabling biometrics, a backup PIN setup is required.
    expect(find.text('إنشاء رقم سري احتياطي'), findsOneWidget);

    // Enter the backup PIN (create) then confirm it.
    for (final digit in <String>['5', '6', '7', '8']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await _pumpPinFlow(tester);

    for (final digit in <String>['5', '6', '7', '8']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await _pumpPinFlow(tester);

    await tester.pumpAndSettle();
    expect(find.text('ملاحظة جديدة'), findsOneWidget);
  });

  testWidgets('creating a note from the editor stores it and shows on home', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ملاحظة جديدة'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'عنوان الملاحظة...'),
      'أفكاري الأولى',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'اكتب تفاصيل ملاحظتك هنا...'),
      'تفاصيل الملاحظة التجريبية',
    );
    await tester.pump();

    await tester.tap(find.text('حفظ الملاحظة'));
    await tester.pumpAndSettle();

    expect(find.text('Notey'), findsNothing);
    expect(find.text('أفكاري الأولى'), findsOneWidget);
    expect(find.text('تفاصيل الملاحظة التجريبية'), findsOneWidget);
  });

  testWidgets('a note can be pinned and opened in the viewer', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ملاحظة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'عنوان الملاحظة...'),
      'أفكار مميزة',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'اكتب تفاصيل ملاحظتك هنا...'),
      'تفاصيل',
    );
    await tester.pump();
    await tester.tap(find.text('حفظ الملاحظة'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);

    await tester.tap(find.text('أفكار مميزة'));
    await tester.pumpAndSettle();
    expect(find.text('الملاحظة'), findsOneWidget);
    expect(find.text('أُنشئت'), findsOneWidget);
    expect(find.text('آخر تعديل'), findsOneWidget);
  });

  testWidgets('a note can be protected with a password and unlocked', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    // Create a note with a secret.
    await tester.tap(find.text('ملاحظة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'عنوان الملاحظة...'),
      'سرية',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'اكتب تفاصيل ملاحظتك هنا...'),
      'محتوى سري للغاية',
    );
    await tester.pump();
    await tester.tap(find.text('حفظ الملاحظة'));
    await tester.pumpAndSettle();

    // Open it and protect it with a password.
    await tester.tap(find.text('سرية'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.lock_open_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعيين كلمة سر'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'كلمة السر'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'تأكيد كلمة السر'),
      '123456',
    );
    await tester.tap(find.text('تأمين'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ملاحظة محمية'), findsOneWidget);
    expect(find.text('هذه الملاحظة محمية بكلمة سر'), findsOneWidget);

    // Back home: card is masked.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('ملاحظة محمية'), findsOneWidget);
    expect(find.text('محتوى سري للغاية'), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    // Re-open and unlock with the correct password.
    await tester.tap(find.text('ملاحظة محمية'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'كلمة السر'),
      '123456',
    );
    await tester.tap(find.text('فتح الملاحظة'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();

    expect(find.text('محتوى سري للغاية'), findsOneWidget);
  });

  testWidgets('onboarding shows once then hands over to lock setup', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _pumpApp(tester, _buildApp(_FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('ملاحظاتك، منسّقة وجميلة'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);

    // Skip lands on the lock setup screen.
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('اختر طريقة قفل التطبيق لحماية ملاحظاتك'), findsOneWidget);

    // A second launch goes straight to setup (flag persisted in prefs).
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboardingDone': true,
    });
  });

  testWidgets(
    'forgot PIN recovery wipes the app and returns to first-run setup',
    (WidgetTester tester) async {
      final storage = _FakeSecureStorage();
      storage.values['appPinHash'] = await PinHasher.create('9876');
      SharedPreferences.setMockInitialValues(<String, Object>{
        'appLockMethod': 'pin',
        'onboardingDone': true,
      });

      // Back the reset service with a real temp "documents" directory so the
      // wipe can be verified end-to-end. Real file IO must run on the real
      // event loop, hence tester.runAsync.
      late final Directory docs;
      await tester.runAsync(() async {
        docs = await Directory.systemTemp.createTemp('notey_reset_test');
        File('${docs.path}/notey.db').writeAsStringSync('db');
        Directory('${docs.path}/note_images').createSync();
        File('${docs.path}/note_images/x.png').writeAsBytesSync(<int>[1]);
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => docs.path,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
        runAsyncSafe(tester, () => docs.delete(recursive: true));
      });

      await _pumpApp(
        tester,
        NoteyApp(
          repository: _FakeRepository(),
          biometricService: _AutoBiometricService(),
          secureStorage: storage,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Locked out: wrong PIN is rejected.
      for (final digit in <String>['1', '1', '1', '1']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await _pumpPinFlow(tester);
      expect(find.text('الرقم السري غير صحيح'), findsOneWidget);

      // Recovery path: forgot PIN → confirm full reset.
      await tester.ensureVisible(find.text('نسيت الرمز؟'));
      await tester.pump();
      await tester.tap(find.text('نسيت الرمز؟'));
      await _pumpPinFlow(tester);
      await tester.tap(find.text('مسح وإعادة التعيين'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 900));

      expect(
        find.text('اختر طريقة قفل التطبيق لحماية ملاحظاتك'),
        findsOneWidget,
      );
      // Lock configuration is gone…
      expect(storage.values.containsKey('appPinHash'), isFalse);
      // …and so is every data file on disk.
      var dbGone = FileSystemEntityType.notFound;
      var folderGone = FileSystemEntityType.notFound;
      await tester.runAsync(() async {
        dbGone = FileSystemEntity.typeSync('${docs.path}/notey.db');
        folderGone = FileSystemEntity.typeSync('${docs.path}/note_images');
      });
      expect(dbGone, FileSystemEntityType.notFound);
      expect(folderGone, FileSystemEntityType.notFound);
    },
  );
}
