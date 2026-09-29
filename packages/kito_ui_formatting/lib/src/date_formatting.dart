// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:intl/intl.dart';

import 'formatting_strings.dart';
import 'number_formatting.dart';

/// Picks a locale intl has date symbols for, falling back to English. Call
/// `initializeDateFormatting()` from `package:intl/date_symbol_data_local.dart` (or use
/// `flutter_localizations`) to enable other languages.
String kitoDateLocale(String? locale) => Intl.verifiedLocale(
    locale ?? Intl.getCurrentLocale(), DateFormat.localeExists,
    onFailure: (_) => 'en_US')!;

/// Dates for feeds, chats, receipts and bookings.
abstract final class KitoDateFormatting {
  /// "2 minutes ago", "in 3 hours", "yesterday", "just now" — measured from [now] (defaults to
  /// the current time).
  static String relative(DateTime date, {DateTime? now, String? locale}) {
    final ref = now ?? DateTime.now();
    final diff = date.difference(ref);
    final future = !diff.isNegative;
    final s = diff.inSeconds.abs();
    if (s < 45) return KitoFormattingStrings.lookup('justNow', locale: locale);
    final days = _calendarDays(ref, date);
    if (s >= 86400 && days.abs() == 1) {
      return KitoFormattingStrings.lookup(future ? 'tomorrow' : 'yesterday',
              locale: locale)
          .toLowerCase();
    }
    final String unit;
    final int n;
    if (s < 3600) {
      unit = 'minute';
      n = (s / 60).round().clamp(1, 59);
    } else if (s < 86400) {
      unit = 'hour';
      n = (s / 3600).round().clamp(1, 23);
    } else if (days.abs() < 7) {
      unit = 'day';
      n = days.abs().clamp(1, 6);
    } else if (days.abs() < 30) {
      unit = 'week';
      n = days.abs() ~/ 7;
    } else if (days.abs() < 365) {
      unit = 'month';
      n = (days.abs() / 30.44).floor().clamp(1, 11);
    } else {
      unit = 'year';
      n = (days.abs() / 365.25).floor().clamp(1, 1 << 30);
    }
    final amount = KitoFormattingStrings.unit(unit, n, locale: locale);
    return KitoFormattingStrings.lookup(future ? 'in' : 'ago', locale: locale)
        .replaceAll('{v}', amount);
  }

  static int _calendarDays(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// "now", "5m", "3h", "2d", "3w", then "Sep 21" — chat lists and notification rows.
  static String abbreviated(DateTime date, {DateTime? now, String? locale}) {
    final seconds = (now ?? DateTime.now()).difference(date).inSeconds;
    if (seconds < 0) return shortTime(date, locale: locale);
    if (seconds < 60) {
      return KitoFormattingStrings.lookup('now', locale: locale);
    }
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h';
    if (seconds < 604800) return '${seconds ~/ 86400}d';
    if (seconds < 2419200) return '${seconds ~/ 604800}w';
    return DateFormat.MMMd(kitoDateLocale(locale)).format(date);
  }

  /// "Today", "Yesterday", "Tomorrow", a weekday within a week either side, otherwise a medium
  /// date — the header above a day's transactions or messages.
  static String dayLabel(DateTime date, {DateTime? now, String? locale}) {
    final days = _calendarDays(now ?? DateTime.now(), date);
    if (days == 0) return KitoFormattingStrings.lookup('today', locale: locale);
    if (days == -1) {
      return KitoFormattingStrings.lookup('yesterday', locale: locale);
    }
    if (days == 1) {
      return KitoFormattingStrings.lookup('tomorrow', locale: locale);
    }
    if (days.abs() <= 6) {
      return DateFormat.EEEE(kitoDateLocale(locale)).format(date);
    }
    return mediumDate(date, locale: locale);
  }

  /// "9:00 – 10:30 AM" (a shared AM/PM is written once) — a booking slot or delivery window.
  static String timeRange(DateTime start, DateTime end, {String? locale}) {
    final l = kitoDateLocale(locale);
    if (!end.isAfter(start)) return shortTime(start, locale: locale);
    final full = DateFormat.jm(l);
    final a = full.format(start), b = full.format(end);
    final marker = DateFormat('a', l);
    final m = marker.format(end);
    if (marker.format(start) == m && a.endsWith(m) && b.endsWith(m)) {
      return '${a.substring(0, a.length - m.length).trimRight()} – $b';
    }
    return '$a – $b';
  }

  /// "Good morning" (5–12), "Good afternoon" (12–17), "Good evening" — a home-screen greeting.
  static String greeting({DateTime? at, String? locale}) {
    final hour = (at ?? DateTime.now()).hour;
    final key = hour >= 5 && hour < 12
        ? 'morning'
        : (hour >= 12 && hour < 17 ? 'afternoon' : 'evening');
    return KitoFormattingStrings.lookup(key, locale: locale);
  }

  /// "4:32 PM" / "16:32".
  static String shortTime(DateTime date, {String? locale}) =>
      DateFormat.jm(kitoDateLocale(locale)).format(date);

  /// "Sep 21, 2026".
  static String mediumDate(DateTime date, {String? locale}) =>
      DateFormat.yMMMd(kitoDateLocale(locale)).format(date);

  /// "September 21, 2026 at 4:32 PM".
  static String full(DateTime date, {String? locale}) {
    final l = kitoDateLocale(locale);
    return '${DateFormat.yMMMMd(l).format(date)}, ${DateFormat.jm(l).format(date)}';
  }
}

/// Durations for timers, voice notes, ETAs and tracks.
abstract final class KitoDurationFormatting {
  /// "45s", "12m 5s", "1h 5m", "2d 3h" — the two largest non-zero units.
  static String short(Duration duration) {
    final total = (duration.inMilliseconds.abs() / 1000).round();
    final sign = duration.isNegative && total > 0 ? '-' : '';
    final parts = [
      (total ~/ 86400, 'd'),
      ((total % 86400) ~/ 3600, 'h'),
      ((total % 3600) ~/ 60, 'm'),
      (total % 60, 's'),
    ];
    final first = parts.indexWhere((p) => p.$1 > 0);
    if (first < 0) return '0s';
    final shown = parts.skip(first).take(2).where((p) => p.$1 > 0);
    return sign + shown.map((p) => '${p.$1}${p.$2}').join(' ');
  }

  /// "4:05" / "1:02:09" — a stopwatch, a voice note length, a track position.
  static String clock(Duration duration) {
    final total = duration.inSeconds.abs();
    final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
    final sign = duration.isNegative && total > 0 ? '-' : '';
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$sign$h:${two(m)}:${two(s)}' : '$sign$m:${two(s)}';
  }

  /// "1 hour, 5 minutes" — spelled out in [locale], for screen readers and long-form copy.
  static String spelledOut(Duration duration,
      {int maximumUnits = 2, String? locale}) {
    final total = duration.inSeconds.abs();
    final parts = [
      (total ~/ 86400, 'day'),
      ((total % 86400) ~/ 3600, 'hour'),
      ((total % 3600) ~/ 60, 'minute'),
      (total % 60, 'second'),
    ].where((p) => p.$1 > 0).take(maximumUnits < 1 ? 1 : maximumUnits);
    if (parts.isEmpty) {
      return KitoFormattingStrings.unit('second', 0, locale: locale);
    }
    return parts
        .map((p) => KitoFormattingStrings.unit(p.$2, p.$1, locale: locale))
        .join(KitoFormattingStrings.lookup('list', locale: locale));
  }
}

/// File and download sizes.
abstract final class KitoFileSizeFormatting {
  /// "845 bytes", "12 KB", "1.2 MB", "3.46 GB" — decimal units (1 KB = 1,000 bytes), as file
  /// managers show them. Pass `binary: true` for KiB-style 1,024 steps (still labelled KB, MB…).
  static String string(int bytes, {bool binary = false}) {
    final step = binary ? 1024.0 : 1000.0;
    final negative = bytes < 0;
    var v = bytes.abs().toDouble();
    if (v < step) {
      return '${negative ? '-' : ''}${bytes.abs()} ${bytes.abs() == 1 ? 'byte' : 'bytes'}';
    }
    const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
    var i = -1;
    while (v >= step && i < units.length - 1) {
      v /= step;
      i++;
    }
    final digits = i == 0 ? 0 : (i == 1 ? 1 : 2);
    var text = kitoFixedDecimal(v, digits);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return '${negative ? '-' : ''}$text ${units[i]}';
  }

  /// "1.2 MB of 4.5 MB" — a download in progress.
  static String progress(int received, int total, {String? locale}) =>
      '${string(received)} ${KitoFormattingStrings.lookup('of', locale: locale)} ${string(total)}';
}

/// Metric or imperial distances.
enum KitoDistanceSystem {
  /// Metres and kilometres.
  metric,

  /// Feet and miles.
  imperial,
}

/// Distances for delivery, ride and maps screens.
abstract final class KitoDistanceFormatting {
  /// "850 m", "1.2 km", "12 km" — or "320 ft", "0.5 mi", "12 mi". One decimal below 10, whole
  /// numbers above; short distances round to 5 or 10.
  static String string(num meters,
      {KitoDistanceSystem system = KitoDistanceSystem.metric}) {
    final v = meters < 0 ? 0.0 : meters.toDouble();
    switch (system) {
      case KitoDistanceSystem.metric:
        if (v < 1000) {
          final r = _roundTo(v, v < 100 ? 5 : 10);
          if (r < 1000) return '${r.toInt()} m';
        }
        return '${_oneDecimal(v / 1000)} km';
      case KitoDistanceSystem.imperial:
        final feet = v * 3.28084;
        if (feet < 1000) {
          final r = _roundTo(feet, 10);
          if (r < 1000) return '${r.toInt()} ft';
        }
        return '${_oneDecimal(v / 1609.344)} mi';
    }
  }

  static double _roundTo(double value, double step) =>
      (value / step).round() * step;

  static String _oneDecimal(double v) {
    if (v >= 10) return v.round().toString();
    final t = kitoFixedDecimal(v, 1);
    return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
  }
}
