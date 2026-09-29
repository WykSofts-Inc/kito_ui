// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Pure date arithmetic for the calendar widgets. Every function works on local dates at
/// midnight and steps by calendar days, so daylight-saving changes never add or lose a day.
abstract final class KitoCalendarMath {
  /// Midnight on the day of [date].
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Whether [a] and [b] fall on the same day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// [date] moved by [days] calendar days, at midnight.
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// The first of the month [months] after [date]'s month.
  static DateTime addMonths(DateTime date, int months) =>
      DateTime(date.year, date.month + months);

  /// Midnight on the first of [date]'s month.
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// How many days [date]'s month has.
  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  /// Midnight on the first day of the week holding [date], where weeks start on
  /// [firstWeekday] (`DateTime.monday` … `DateTime.sunday`).
  static DateTime startOfWeek(DateTime date,
      {int firstWeekday = DateTime.monday}) {
    final back = (date.weekday - firstWeekday) % 7;
    return addDays(dateOnly(date), -back);
  }

  /// The seven days of the week holding [date].
  static List<DateTime> week(DateTime date,
      {int firstWeekday = DateTime.monday}) {
    final start = startOfWeek(date, firstWeekday: firstWeekday);
    return [for (var i = 0; i < 7; i++) addDays(start, i)];
  }

  /// Nights from [start] to [end], ignoring times of day. Negative when [end] is earlier.
  static int nights(DateTime start, DateTime end) {
    final a = DateTime.utc(start.year, start.month, start.day);
    final b = DateTime.utc(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }

  /// Weekday numbers (1 = Monday … 7 = Sunday) in display order from [firstWeekday].
  static List<int> weekdayOrder({int firstWeekday = DateTime.monday}) =>
      [for (var i = 0; i < 7; i++) (firstWeekday - 1 + i) % 7 + 1];

  /// Every day [event] touches. A zero-length event touches the day it starts; an event
  /// ending exactly at midnight doesn't touch the day that midnight begins.
  static List<DateTime> daysSpannedBy(KitoCalendarEvent event) {
    final first = dateOnly(event.start);
    final lastInstant = event.end.isAfter(event.start)
        ? event.end.subtract(const Duration(microseconds: 1))
        : event.start;
    final last = dateOnly(lastInstant);
    final days = <DateTime>[];
    var day = first;
    while (!day.isAfter(last) && days.length < 3660) {
      days.add(day);
      day = addDays(day, 1);
    }
    return days;
  }

  /// Events bucketed by the days they touch, keyed by midnight.
  static Map<DateTime, List<KitoCalendarEvent>> eventsByDay(
      Iterable<KitoCalendarEvent> events) {
    final buckets = <DateTime, List<KitoCalendarEvent>>{};
    for (final event in events) {
      for (final day in daysSpannedBy(event)) {
        (buckets[day] ??= []).add(event);
      }
    }
    return buckets;
  }

  /// Events grouped into days, in order; within a day all-day events first, then by start,
  /// then by title. A multi-day event appears on every day it touches.
  static List<KitoCalendarAgendaDay> agenda(
      Iterable<KitoCalendarEvent> events) {
    final days = eventsByDay(events).entries.map((entry) {
      final sorted = [...entry.value]..sort((a, b) {
          if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
          final byStart = a.start.compareTo(b.start);
          if (byStart != 0) return byStart;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      return KitoCalendarAgendaDay(entry.key, sorted);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return days;
  }

  /// The firsts of every month from [from]'s to [to]'s, both included.
  static List<DateTime> months(DateTime from, DateTime to) {
    final out = <DateTime>[];
    var month = startOfMonth(from);
    final last = startOfMonth(to);
    while (!month.isAfter(last) && out.length < 1200) {
      out.add(month);
      month = addMonths(month, 1);
    }
    return out;
  }

  /// The week starts from [from]'s week to [to]'s, both included.
  static List<DateTime> weeks(DateTime from, DateTime to,
      {int firstWeekday = DateTime.monday}) {
    final out = <DateTime>[];
    var week = startOfWeek(from, firstWeekday: firstWeekday);
    final last = startOfWeek(to, firstWeekday: firstWeekday);
    while (!week.isAfter(last) && out.length < 2000) {
      out.add(week);
      week = addDays(week, 7);
    }
    return out;
  }
}

/// One square of a [KitoCalendarMonthGrid].
@immutable
class KitoCalendarGridDay {
  /// Creates a square.
  const KitoCalendarGridDay(this.date, {required this.isInMonth});

  /// Midnight on the day.
  final DateTime date;

  /// False for the leading and trailing days borrowed from the neighbouring months.
  final bool isInMonth;

  @override
  bool operator ==(Object other) =>
      other is KitoCalendarGridDay &&
      other.date == date &&
      other.isInMonth == isInMonth;

  @override
  int get hashCode => Object.hash(date, isInMonth);
}

/// The squares of one month laid out in weeks, with the neighbouring months' days filling the
/// first and last rows.
@immutable
class KitoCalendarMonthGrid {
  /// Lays out [month]. With [fixedSixWeeks] every month gets six rows, so a paging calendar
  /// keeps its height.
  factory KitoCalendarMonthGrid(DateTime month,
      {int firstWeekday = DateTime.monday, bool fixedSixWeeks = false}) {
    final first = KitoCalendarMath.startOfMonth(month);
    final count = KitoCalendarMath.daysInMonth(first);
    final leading = (first.weekday - firstWeekday) % 7;
    final used = leading + count;
    final whole = (used / 7).ceil() * 7;
    final total = fixedSixWeeks ? math.max(42, whole) : whole;
    return KitoCalendarMonthGrid._(
      first,
      [
        for (var i = 0; i < total; i++)
          KitoCalendarGridDay(KitoCalendarMath.addDays(first, i - leading),
              isInMonth: i >= leading && i < used),
      ],
      leading,
      total - used,
    );
  }

  const KitoCalendarMonthGrid._(
      this.month, this.days, this.leadingCount, this.trailingCount);

  /// Midnight on the first of the month.
  final DateTime month;

  /// Every square, a multiple of seven long.
  final List<KitoCalendarGridDay> days;

  /// Days of the previous month that open the grid.
  final int leadingCount;

  /// Days of the next month that close it.
  final int trailingCount;

  /// The squares in rows of seven.
  List<List<KitoCalendarGridDay>> get weeks => [
        for (var i = 0; i < days.length; i += 7)
          days.sublist(i, math.min(i + 7, days.length))
      ];

  /// Only the month's own days.
  List<KitoCalendarGridDay> get daysInMonth =>
      days.where((d) => d.isInMonth).toList();
}

/// Where an event goes on a day timeline.
@immutable
class KitoCalendarEventPlacement {
  /// Creates a placement.
  const KitoCalendarEventPlacement(this.event, this.column, this.columnCount);

  /// The event.
  final KitoCalendarEvent event;

  /// Its zero-based column.
  final int column;

  /// The columns in its overlap group; it takes `1 / columnCount` of the width.
  final int columnCount;
}

/// Puts overlapping events side by side.
abstract final class KitoCalendarEventLayout {
  /// Columns for [events]: each event takes the first column that's free when it starts, and
  /// every event in an overlap group shares that group's column count. Events shorter than
  /// [minimumDuration] are treated as that long, so blocks drawn at a minimum height don't
  /// overlap.
  static List<KitoCalendarEventPlacement> placements(
      List<KitoCalendarEvent> events,
      {Duration minimumDuration = Duration.zero}) {
    DateTime effectiveEnd(KitoCalendarEvent e) {
      final min = e.start.add(minimumDuration);
      return e.end.isAfter(min) ? e.end : min;
    }

    final sorted = [...events]..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        if (byStart != 0) return byStart;
        final byEnd = effectiveEnd(b).compareTo(effectiveEnd(a));
        if (byEnd != 0) return byEnd;
        return a.id.compareTo(b.id);
      });

    final placements = <KitoCalendarEventPlacement>[];
    final group = <(KitoCalendarEvent, int)>[];
    final columnEnds = <DateTime>[];
    DateTime? groupEnd;

    void close() {
      final count = math.max(columnEnds.length, 1);
      placements.addAll(
          group.map((g) => KitoCalendarEventPlacement(g.$1, g.$2, count)));
      group.clear();
      columnEnds.clear();
      groupEnd = null;
    }

    for (final event in sorted) {
      final open = groupEnd;
      if (open != null && !event.start.isBefore(open)) close();
      final end = effectiveEnd(event);
      var column = columnEnds.indexWhere((e) => !e.isAfter(event.start));
      if (column == -1) {
        columnEnds.add(end);
        column = columnEnds.length - 1;
      } else {
        columnEnds[column] = end;
      }
      group.add((event, column));
      final current = groupEnd;
      groupEnd = current == null || end.isAfter(current) ? end : current;
    }
    close();
    return placements;
  }
}
