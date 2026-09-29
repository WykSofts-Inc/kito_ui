// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';

import 'math.dart';

/// Something on the calendar: a meeting, a class, a booking, a holiday.
@immutable
class KitoCalendarEvent {
  /// Creates an event. An [end] before [start] is treated as [start].
  KitoCalendarEvent({
    String? id,
    required this.title,
    required this.start,
    required DateTime end,
    this.color = const Color(0xFF1C6BF0),
    this.location,
    this.isAllDay = false,
  })  : id = id ?? '$title|${start.microsecondsSinceEpoch}',
        end = end.isBefore(start) ? start : end;

  /// Identifies the event across rebuilds, for animations.
  final String id;

  /// What it is.
  final String title;

  /// When it starts.
  final DateTime start;

  /// When it ends; never before [start].
  final DateTime end;

  /// Its dot, bar and block colour.
  final Color color;

  /// Where it happens.
  final String? location;

  /// Shown in the all-day strip rather than at a time.
  final bool isAllDay;

  /// How long it lasts.
  Duration get duration => end.difference(start);

  /// Whether it's running at [now].
  bool isOngoingAt(DateTime now) => !start.isAfter(now) && now.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is KitoCalendarEvent &&
      other.id == id &&
      other.title == title &&
      other.start == start &&
      other.end == end &&
      other.color == color &&
      other.location == location &&
      other.isAllDay == isAllDay;

  @override
  int get hashCode =>
      Object.hash(id, title, start, end, color, location, isAllDay);

  @override
  String toString() => 'KitoCalendarEvent($title, $start – $end)';
}

/// A span of whole days, both ends included: a stay, a trip, a reporting period.
@immutable
class KitoCalendarRange {
  /// Creates a range; the earlier date always becomes [start]. Times of day are dropped.
  KitoCalendarRange({required DateTime start, required DateTime end})
      : start = KitoCalendarMath.dateOnly(start.isAfter(end) ? end : start),
        end = KitoCalendarMath.dateOnly(start.isAfter(end) ? start : end);

  /// The first day, at midnight.
  final DateTime start;

  /// The last day, at midnight.
  final DateTime end;

  /// Nights from [start] to [end]: 12 to 18 October is 6 nights.
  int get nights => KitoCalendarMath.nights(start, end);

  /// Days covered, both ends included: 12 to 18 October is 7 days.
  int get dayCount => nights + 1;

  /// Whether [date] (any time that day) falls inside, ends included.
  bool contains(DateTime date) {
    final day = KitoCalendarMath.dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is KitoCalendarRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'KitoCalendarRange($start – $end)';
}

/// How a range's length is counted in labels.
enum KitoCalendarRangeUnit {
  /// Stays: 12 to 18 October is "6 nights".
  nights,

  /// Trips and periods: 12 to 18 October is "7 days".
  days;

  /// The count for [range].
  int count(KitoCalendarRange range) =>
      this == nights ? range.nights : range.dayCount;

  /// "1 night", "6 nights", "7 days".
  String label(KitoCalendarRange range) {
    final n = count(range);
    return switch (this) {
      nights => n == 1 ? '1 night' : '$n nights',
      days => n == 1 ? '1 day' : '$n days',
    };
  }
}

/// A range being picked on a calendar, following booking-app rules: the first tap sets the
/// start, a later day sets the end, an earlier day moves the start, tapping the start again
/// clears it (or, with [allowsSingleDay], picks that one day), and a tap on a finished range
/// starts a new one.
@immutable
class KitoCalendarRangeSelection {
  /// Creates a selection, optionally from an existing [range].
  KitoCalendarRangeSelection(
      {KitoCalendarRange? range, this.allowsSingleDay = false})
      : start = range?.start,
        end = range?.end;

  const KitoCalendarRangeSelection._(
      this.start, this.end, this.allowsSingleDay);

  /// The first picked day, or null.
  final DateTime? start;

  /// The last picked day, or null while waiting for it.
  final DateTime? end;

  /// Whether a second tap on the start picks that single day.
  final bool allowsSingleDay;

  /// The finished range, or null while it's empty or waiting for an end.
  KitoCalendarRange? get range {
    final s = start, e = end;
    return s == null || e == null ? null : KitoCalendarRange(start: s, end: e);
  }

  /// Nothing picked yet.
  bool get isEmpty => start == null;

  /// Both ends picked.
  bool get isComplete => start != null && end != null;

  /// A start is picked and the next tap picks the end.
  bool get isAwaitingEnd => start != null && end == null;

  /// The selection after a tap on [date].
  KitoCalendarRangeSelection select(DateTime date) {
    final day = KitoCalendarMath.dateOnly(date);
    final s = start;
    if (s == null || end != null) {
      return KitoCalendarRangeSelection._(day, null, allowsSingleDay);
    }
    if (day.isBefore(s)) {
      return KitoCalendarRangeSelection._(day, null, allowsSingleDay);
    }
    if (day == s) {
      return allowsSingleDay
          ? KitoCalendarRangeSelection._(s, s, allowsSingleDay)
          : KitoCalendarRangeSelection._(null, null, allowsSingleDay);
    }
    return KitoCalendarRangeSelection._(s, day, allowsSingleDay);
  }

  /// The selection replaced by [range] (e.g. from a preset), or cleared when null.
  KitoCalendarRangeSelection withRange(KitoCalendarRange? range) =>
      KitoCalendarRangeSelection._(range?.start, range?.end, allowsSingleDay);

  /// An empty selection with the same rules.
  KitoCalendarRangeSelection cleared() =>
      KitoCalendarRangeSelection._(null, null, allowsSingleDay);

  @override
  bool operator ==(Object other) =>
      other is KitoCalendarRangeSelection &&
      other.start == start &&
      other.end == end &&
      other.allowsSingleDay == allowsSingleDay;

  @override
  int get hashCode => Object.hash(start, end, allowsSingleDay);
}

/// A named, relative range for a date range field: "This weekend", "Next 7 days". It's
/// resolved when tapped, so it stays right tomorrow.
@immutable
class KitoCalendarPreset {
  /// Creates a preset. [resolve] gets today (at midnight) and the weekend days (1 = Monday …
  /// 7 = Sunday) for the current locale.
  const KitoCalendarPreset(this.title,
      {required this.resolve, this.icon = Icons.calendar_month_rounded});

  /// The chip's label.
  final String title;

  /// The chip's icon.
  final IconData icon;

  /// Works out the range for a given today.
  final KitoCalendarRange Function(DateTime today, Set<int> weekendDays)
      resolve;

  /// The range this preset stands for, relative to [now].
  KitoCalendarRange rangeFor(DateTime now,
          {Set<int> weekendDays = const {
            DateTime.saturday,
            DateTime.sunday
          }}) =>
      resolve(KitoCalendarMath.dateOnly(now), weekendDays);

  /// The weekend under way, or the next one, as the locale defines a weekend. Never starts
  /// before today.
  static final thisWeekend = KitoCalendarPreset(
    'This weekend',
    icon: Icons.wb_sunny_rounded,
    resolve: (today, weekend) {
      if (weekend.isEmpty) {
        return KitoCalendarRange(
            start: today, end: KitoCalendarMath.addDays(today, 1));
      }
      var start = today;
      var guard = 0;
      while (!weekend.contains(start.weekday) && guard++ < 7) {
        start = KitoCalendarMath.addDays(start, 1);
      }
      var end = start;
      guard = 0;
      while (weekend.contains(KitoCalendarMath.addDays(end, 1).weekday) &&
          guard++ < 6) {
        end = KitoCalendarMath.addDays(end, 1);
      }
      return KitoCalendarRange(start: start, end: end);
    },
  );

  /// Today and the six days after it.
  static final nextSevenDays = KitoCalendarPreset(
    'Next 7 days',
    icon: Icons.date_range_rounded,
    resolve: (today, _) => KitoCalendarRange(
        start: today, end: KitoCalendarMath.addDays(today, 6)),
  );

  /// Today to the last day of this month.
  static final thisMonth = KitoCalendarPreset(
    'This month',
    icon: Icons.calendar_month_rounded,
    resolve: (today, _) => KitoCalendarRange(
        start: today,
        end: KitoCalendarMath.addDays(
            KitoCalendarMath.addMonths(KitoCalendarMath.startOfMonth(today), 1),
            -1)),
  );

  /// This weekend, next 7 days and this month.
  static final standard = [thisWeekend, nextSevenDays, thisMonth];
}

/// One day of an agenda: the date and its events in order.
@immutable
class KitoCalendarAgendaDay {
  /// Creates a day.
  const KitoCalendarAgendaDay(this.date, this.events);

  /// Midnight on the day.
  final DateTime date;

  /// All-day events first, then by start time, then by title.
  final List<KitoCalendarEvent> events;
}

/// How long weekday names are.
enum KitoCalendarWeekdayStyle {
  /// "M", "T".
  narrow,

  /// "Mon", "Tue".
  short,

  /// "Monday", "Tuesday".
  full,
}
