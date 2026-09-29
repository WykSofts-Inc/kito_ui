// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'math.dart';
import 'models.dart';

/// Overrides the calendar settings for every calendar widget below: the locale for names,
/// the first day of the week, the weekend, the clock and the 12/24-hour choice.
///
/// Without a scope the widgets follow the app's `Locale` (via `Localizations`) and take the
/// first weekday and weekend from that locale's data.
///
/// ```dart
/// KitoCalendarScope(
///   locale: const Locale('sw', 'KE'),
///   firstWeekday: DateTime.monday,
///   child: KitoMonthCalendar.single(selected: day, onChanged: pick),
/// )
/// ```
class KitoCalendarScope extends InheritedWidget {
  /// Creates a scope; anything left null follows the locale and the system.
  const KitoCalendarScope({
    super.key,
    this.locale,
    this.firstWeekday,
    this.weekendDays,
    this.now,
    this.use24HourFormat,
    required super.child,
  });

  /// The locale for month and weekday names and date patterns.
  final Locale? locale;

  /// `DateTime.monday` … `DateTime.sunday`.
  final int? firstWeekday;

  /// Weekday numbers that count as the weekend.
  final Set<int>? weekendDays;

  /// The clock "today" and the timeline's now line read; handy for tests and demos.
  final DateTime Function()? now;

  /// Forces 24-hour (or 12-hour) times; null follows `MediaQuery.alwaysUse24HourFormat`
  /// and the locale.
  final bool? use24HourFormat;

  /// Wraps [child] in a copy of the scope above [context], if any. Use it for routes pushed
  /// from inside a scope (sheets, dialogs), which otherwise sit above it.
  static Widget inherit(BuildContext context, {required Widget child}) {
    final scope = context.getInheritedWidgetOfExactType<KitoCalendarScope>();
    if (scope == null) return child;
    return KitoCalendarScope(
      locale: scope.locale,
      firstWeekday: scope.firstWeekday,
      weekendDays: scope.weekendDays,
      now: scope.now,
      use24HourFormat: scope.use24HourFormat,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(KitoCalendarScope oldWidget) =>
      locale != oldWidget.locale ||
      firstWeekday != oldWidget.firstWeekday ||
      weekendDays != oldWidget.weekendDays ||
      now != oldWidget.now ||
      use24HourFormat != oldWidget.use24HourFormat;
}

/// The resolved calendar settings for a place in the tree, with the date formatting every
/// calendar widget uses. Get one with [KitoCalendarConfig.of].
@immutable
class KitoCalendarConfig {
  /// Creates settings directly, e.g. for formatting outside a widget.
  KitoCalendarConfig({
    String? locale,
    int? firstWeekday,
    Set<int>? weekendDays,
    DateTime Function()? clock,
    this.use24HourFormat = false,
  })  : locale = _resolve(locale),
        clock = clock ?? DateTime.now,
        firstWeekday = firstWeekday ?? _firstWeekday(_resolve(locale)),
        weekendDays = weekendDays ?? _weekend(_resolve(locale));

  /// The settings at [context].
  factory KitoCalendarConfig.of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<KitoCalendarScope>();
    final locale = scope?.locale ?? Localizations.maybeLocaleOf(context);
    return KitoCalendarConfig(
      locale: locale?.toString(),
      firstWeekday: scope?.firstWeekday,
      weekendDays: scope?.weekendDays,
      clock: scope?.now,
      use24HourFormat: scope?.use24HourFormat ??
          MediaQuery.maybeAlwaysUse24HourFormatOf(context) ??
          false,
    );
  }

  /// The intl locale name in use, e.g. `en_GB` or `sw`.
  final String locale;

  /// The first day of the week, `DateTime.monday` … `DateTime.sunday`.
  final int firstWeekday;

  /// Weekday numbers that count as the weekend.
  final Set<int> weekendDays;

  /// Where "now" comes from.
  final DateTime Function() clock;

  /// Shows times as 14:30 rather than 2:30 PM.
  final bool use24HourFormat;

  /// The current time.
  DateTime get now => clock();

  /// Midnight today.
  DateTime get today => KitoCalendarMath.dateOnly(clock());

  static bool _loaded = false;
  static final Map<String, DateFormat> _formats = {};

  DateFormat _f(String skeleton) => _formats.putIfAbsent(
      '$locale|$skeleton', () => DateFormat(skeleton, locale));

  static String _resolve(String? locale) {
    if (!_loaded) {
      _loaded = true;
      initializeDateFormatting();
    }
    final tag = locale ?? Intl.getCurrentLocale();
    return Intl.verifiedLocale(tag, DateFormat.localeExists,
            onFailure: (_) => 'en') ??
        'en';
  }

  static int _firstWeekday(String locale) =>
      DateFormat('', locale).dateSymbols.FIRSTDAYOFWEEK + 1;

  static Set<int> _weekend(String locale) {
    final range = DateFormat('', locale).dateSymbols.WEEKENDRANGE;
    return {for (final d in range) d + 1};
  }

  /// Weekday numbers in display order.
  List<int> get weekdayOrder =>
      KitoCalendarMath.weekdayOrder(firstWeekday: firstWeekday);

  /// Weekday names in display order, starting at [firstWeekday].
  List<String> weekdaySymbols(
      [KitoCalendarWeekdayStyle style = KitoCalendarWeekdayStyle.narrow]) {
    final symbols = DateFormat('', locale).dateSymbols;
    final names = switch (style) {
      KitoCalendarWeekdayStyle.narrow => symbols.STANDALONENARROWWEEKDAYS,
      KitoCalendarWeekdayStyle.short => symbols.STANDALONESHORTWEEKDAYS,
      KitoCalendarWeekdayStyle.full => symbols.STANDALONEWEEKDAYS,
    };
    // intl lists Sunday first; DateTime.sunday is 7.
    return [for (final d in weekdayOrder) names[d % 7]];
  }

  /// Whether [date] falls on a weekend.
  bool isWeekend(DateTime date) => weekendDays.contains(date.weekday);

  /// "October 2026".
  String monthTitle(DateTime date) => _f('yMMMM').format(date);

  /// "October".
  String monthName(DateTime date) => _f('MMMM').format(date);

  /// "Oct".
  String shortMonth(DateTime date) => _f('MMM').format(date);

  /// "2026".
  String year(DateTime date) => _f('y').format(date);

  /// "18".
  String day(DateTime date) => _f('d').format(date);

  /// "Mon".
  String weekdayShort(DateTime date) => _f('E').format(date);

  /// "Monday, 18 October 2026" in the locale's order.
  String fullDate(DateTime date) => _f('yMMMMEEEEd').format(date);

  /// "Monday, 18 October".
  String dayHeading(DateTime date) => _f('MMMMEEEEd').format(date);

  /// "14:30" or "2:30 PM".
  String time(DateTime date) =>
      (use24HourFormat ? _f('Hm') : _f('jm')).format(date);

  /// The label for an hour line: "09" or "9 AM".
  String hourLabel(int hour) {
    final date = DateTime(2026, 1, 1, hour % 24);
    return (use24HourFormat ? _f('Hm') : _f('j')).format(date);
  }

  /// Whether this locale writes "18 Oct" (true) or "Oct 18" (false).
  bool get dayComesFirst {
    final pattern = _f('MMMd').pattern ?? 'd MMM';
    final d = pattern.indexOf('d');
    final m = pattern.indexOf(RegExp('[ML]'));
    return d < 0 || m < 0 || d < m;
  }

  /// Just the dates: "12 – 18 Oct", "28 Oct – 3 Nov", "30 Dec 2026 – 2 Jan 2027" (or month
  /// first where the locale puts it first).
  String rangeDates(KitoCalendarRange range) {
    final s = range.start, e = range.end;
    final md = _f('MMMd');
    if (KitoCalendarMath.isSameDay(s, e)) return md.format(s);
    if (s.year == e.year && s.month == e.month) {
      final d = _f('d');
      return dayComesFirst
          ? '${d.format(s)} – ${md.format(e)}'
          : '${md.format(s)} – ${d.format(e)}';
    }
    if (s.year == e.year) return '${md.format(s)} – ${md.format(e)}';
    final ymd = _f('yMMMd');
    return '${ymd.format(s)} – ${ymd.format(e)}';
  }

  /// "12 – 18 Oct · 6 nights"; with a null [unit], just the dates.
  String formatRange(KitoCalendarRange range,
          {KitoCalendarRangeUnit? unit = KitoCalendarRangeUnit.nights}) =>
      unit == null
          ? rangeDates(range)
          : '${rangeDates(range)} · ${unit.label(range)}';
}
