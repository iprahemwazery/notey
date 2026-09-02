import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/features/notes/domain/entities/note.dart';


/// Result of scheduling a reminder.
enum ScheduleResult { success, permissionDenied, failed }

/// Schedules local notifications for note reminders.
///
/// Every platform call is wrapped in a defensive try/catch so the app (and
/// the widget tests, which run without platform channels) never crashes when
/// notifications are unavailable.
class ReminderService {
  ReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _permissionsRequested = false;

  /// Reminders whose notification fired while the app was closed; drained by
  /// the home screen on startup so it can navigate to the note.
  static final List<String> _pendingNoteIds = <String>[];

  /// Invoked when a reminder is tapped while the app is running.
  static ValueChanged<String>? onOpenNote;

  static const String _channelId = 'notey_reminders';
  static const String _channelName = 'Notey reminders';

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onResponse,
      );

      _initialized = true;

      final NotificationAppLaunchDetails? launch = await _plugin
          .getNotificationAppLaunchDetails();
      final String? payload = launch?.notificationResponse?.payload;
      if (launch != null &&
          launch.didNotificationLaunchApp &&
          payload != null) {
        _pendingNoteIds.add(payload);
      }
    } on Exception catch (e) {
      debugPrint('ReminderService.init failed: $e');
    }
  }

  static Future<ScheduleResult> requestPermissionIfNeeded() async {
    if (_permissionsRequested) return ScheduleResult.success;
    _permissionsRequested = true;
    try {
      final bool? androidGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      final bool? iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (androidGranted == false || iosGranted == false) {
        return ScheduleResult.permissionDenied;
      }
      return ScheduleResult.success;
    } on Exception {
      return ScheduleResult.permissionDenied;
    }
  }

  static Future<void> openSystemSettings() async {
    try {
      await AppSettings.openAppSettings();
    } on Exception {
      // Ignore platform failures; the user can still enable notifications in
      // the system settings manually.
    }
  }

  /// Returns `true` when the OS guarantees the exact-alarm permission is
  /// currently granted (Android 12+ only; always `true` on other platforms).
  static Future<bool> canScheduleExact() async {
    if (kIsWeb) return true;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return (await android?.canScheduleExactNotifications()) ?? true;
    } on Exception {
      return true;
    }
  }

  static void _onResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (onOpenNote != null) {
      onOpenNote!(payload);
    } else {
      // Home screen isn't built yet (cold start); queue for later.
      _pendingNoteIds.add(payload);
    }
  }

  /// Drains and returns note ids from notifications tapped before the home
  /// screen existed.
  static List<String> takePendingNoteIds() {
    final List<String> ids = List<String>.of(_pendingNoteIds);
    _pendingNoteIds.clear();
    return ids;
  }

  /// Schedules [note]'s reminder when it lies in the future, cancels any
  /// pending one otherwise. Safe to call with locked notes — the body only
  /// ever contains the title.
  static Future<ScheduleResult> sync(Note note) async {
    final DateTime? at = note.reminderAt;
    if (at == null || !at.isAfter(DateTime.now())) {
      await cancel(note.id);
      return ScheduleResult.success;
    }
    if (!_initialized) {
      return ScheduleResult.failed;
    }

    final permissionResult = await requestPermissionIfNeeded();
    if (permissionResult == ScheduleResult.permissionDenied) {
      return ScheduleResult.permissionDenied;
    }

    try {
      final int id = notificationId(note.id);
      await cancel(note.id);
      final bool exact = await canScheduleExact();
      await _plugin.zonedSchedule(
        id: id,
        title: note.title.isEmpty ? AppConstants.appName : note.title,
        body: _preview(note),
        payload: note.id,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Note reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return ScheduleResult.success;
    } on Exception {
      try {
        await _plugin.zonedSchedule(
          id: notificationId(note.id),
          title: note.title.isEmpty ? AppConstants.appName : note.title,
          body: _preview(note),
          payload: note.id,
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: 'Note reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return ScheduleResult.success;
      } on Exception {
        return ScheduleResult.failed;
      }
    }
  }

  static Future<void> cancel(String noteId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: notificationId(noteId));
    } on Exception {
      // Nothing to cancel.
    }
  }

  static Future<void> cancelAll(Iterable<String> noteIds) async {
    for (final String id in noteIds) {
      await cancel(id);
    }
  }

  /// Stable 31-bit notification id derived from the note id.
  static int notificationId(String noteId) =>
      noteId.hashCode & 0x7fffffff & ~(1 << 30);

  static String _preview(Note note) {
    final String content = note.content.trim();
    if (content.isEmpty) return AppConstants.appName;
    final String flat = content.replaceAll('\n', ' ');
    return flat.length <= 120 ? flat : '${flat.substring(0, 120)}…';
  }
}
