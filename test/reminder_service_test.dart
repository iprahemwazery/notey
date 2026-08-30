import 'package:flutter_test/flutter_test.dart';

import 'package:notey/core/services/reminder_service.dart';
import 'package:notey/features/notes/model/note.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Note note({DateTime? reminderAt, String title = 'مذكرة'}) => Note.create(
    title: title,
    content: 'محتوى',
    reminderAt: reminderAt,
  );

  test('pending queue drains exactly once', () {
    ReminderService.takePendingNoteIds(); // clear any leftovers
    // No public enqueue on purpose; draining twice yields empty both times.
    expect(ReminderService.takePendingNoteIds(), isEmpty);
  });

  test('sync and cancel are safe before init (no platform)', () async {
    final past = note(
      reminderAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    await ReminderService.sync(past); // cancels -> no-op
    final future = note(
      reminderAt: DateTime.now().add(const Duration(days: 2)),
    );
    // Not initialized in tests: scheduling is skipped silently.
    await ReminderService.sync(future);
    await ReminderService.cancel(future.id);
  });

  test('notification ids are stable 31-bit ints', () {
    final a = ReminderService.notificationId('abc');
    expect(a, ReminderService.notificationId('abc'));
    expect(a, inInclusiveRange(0, 0x3fffffff));
    expect(ReminderService.notificationId('xyz'), isNot(a));
  });
}
