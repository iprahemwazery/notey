import 'dart:ui' show Locale;

import 'package:notey/l10n/generated/app_localizations.dart';

/// Date & time helpers. Dependency-free and deterministic; every method
/// falls back to the Arabic wording when no [AppLocalizations] is passed.
abstract final class ArabicDateTime {
  static const List<String> _monthsAr = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> _monthsEn = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Monday-first, matching `DateTime.weekday - 1`.
  static const List<String> _weekdaysAr = <String>[
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> _weekdaysEn = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static bool _isArabic(AppLocalizations? l10n) =>
      (l10n?.localeName ?? 'ar').startsWith('ar');

  static List<String> _monthsOf(AppLocalizations? l10n) =>
      _isArabic(l10n) ? _monthsAr : _monthsEn;

  static List<String> _weekdaysOf(AppLocalizations? l10n) =>
      _isArabic(l10n) ? _weekdaysAr : _weekdaysEn;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _clock(DateTime dt, AppLocalizations? l10n) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? (l10n?.timeAm ?? 'ص') : (l10n?.timePm ?? 'م');
    return '${_two(hour12)}:${_two(dt.minute)} $period';
  }

  /// Full date: "16 أغسطس 2026 - 3:45 م" (ar) / "August 16, 2026 - 03:45 PM" (en).
  static String full(DateTime dt, {AppLocalizations? l10n}) {
    final local = dt.toLocal();
    if (l10n == null) {
      return '${local.day} ${_monthsAr[local.month - 1]} ${local.year} - ${_clock(local, null)}';
    }
    return l10n.fullDate(
      _two(local.day),
      _monthsOf(l10n)[local.month - 1],
      '${local.year}',
      _clock(local, l10n),
    );
  }

  /// Relative, friendly date used on note cards.
  static String relative(DateTime dt, {AppLocalizations? l10n}) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) return l10n?.timeNow ?? 'الآن';

    if (diff.inMinutes < 60) {
      return (l10n ?? _arbFallback).minutesAgo(diff.inMinutes);
    }

    if (diff.inHours < 24) return (l10n ?? _arbFallback).hoursAgo(diff.inHours);

    if (diff.inDays < 7) return (l10n ?? _arbFallback).daysAgo(diff.inDays);

    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(local.year, local.month, local.day);
    final daysBetween = today.difference(thatDay).inDays;

    final months = _monthsOf(l10n);
    final weekday = _weekdaysOf(l10n)[local.weekday - 1];

    if (daysBetween == 7) {
      return l10n?.lastWeekOn(weekday) ?? 'الأسبوع الماضي، $weekday';
    }

    if (l10n == null) {
      final dayMonth = '${local.day} ${months[local.month - 1]}';
      if (local.year == now.year) {
        return dayMonth;
      }
      return '$dayMonth ${local.year}';
    }
    if (local.year == now.year) {
      return l10n.dayMonth('${local.day}', months[local.month - 1]);
    }
    return l10n.dayMonthYear(
      '${local.day}',
      months[local.month - 1],
      '${local.year}',
    );
  }

  /// Legacy Arabic-only fallback for callers without a BuildContext.
  static AppLocalizations get _arbFallback =>
      lookupAppLocalizations(const Locale('ar'));
}
