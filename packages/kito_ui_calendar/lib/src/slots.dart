// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';

import 'math.dart';

/// Morning, afternoon or evening, for grouping time slots.
enum KitoCalendarDayPeriod {
  /// Before noon.
  morning('Morning', Icons.wb_twilight_rounded),

  /// Noon to 17:00.
  afternoon('Afternoon', Icons.light_mode_rounded),

  /// 17:00 onwards.
  evening('Evening', Icons.nights_stay_rounded);

  const KitoCalendarDayPeriod(this.title, this.icon);

  /// The group heading.
  final String title;

  /// The group icon.
  final IconData icon;

  /// The period an [hour] (0–23) falls in.
  static KitoCalendarDayPeriod ofHour(int hour) => hour < 12
      ? morning
      : hour < 17
          ? afternoon
          : evening;
}

/// A time of day without a date: opening hours, a slot boundary.
@immutable
class KitoCalendarClockTime implements Comparable<KitoCalendarClockTime> {
  /// Creates a time, e.g. `KitoCalendarClockTime(8, 30)`.
  const KitoCalendarClockTime(this.hour, [this.minute = 0]);

  /// 0–24.
  final int hour;

  /// 0–59.
  final int minute;

  /// Minutes since midnight.
  int get minutesSinceMidnight => hour * 60 + minute;

  @override
  int compareTo(KitoCalendarClockTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is KitoCalendarClockTime &&
      other.minutesSinceMidnight == minutesSinceMidnight;

  @override
  int get hashCode => minutesSinceMidnight.hashCode;
}

/// One bookable slot.
@immutable
class KitoCalendarTimeSlot {
  /// Creates a slot. An [end] before [start] is treated as [start].
  KitoCalendarTimeSlot(
      {required this.start, required DateTime end, this.isAvailable = true})
      : end = end.isBefore(start) ? start : end;

  /// When it starts.
  final DateTime start;

  /// When it ends.
  final DateTime end;

  /// False when it's booked or already past; shown struck out and can't be picked.
  final bool isAvailable;

  /// Morning, afternoon or evening, from the start hour.
  KitoCalendarDayPeriod get period => KitoCalendarDayPeriod.ofHour(start.hour);

  @override
  bool operator ==(Object other) =>
      other is KitoCalendarTimeSlot &&
      other.start == start &&
      other.end == end &&
      other.isAvailable == isAvailable;

  @override
  int get hashCode => Object.hash(start, end, isAvailable);
}

/// Opening hours cut into slots.
///
/// ```dart
/// final slots = const KitoCalendarSlotSchedule(
///   opens: KitoCalendarClockTime(8, 30),
///   closes: KitoCalendarClockTime(18),
///   duration: 45,
///   interval: 15,
/// ).slotsOn(day, booked: bookings, notBefore: DateTime.now());
/// ```
@immutable
class KitoCalendarSlotSchedule {
  /// Creates a schedule. [interval] is the minutes between starts; null means back to back.
  const KitoCalendarSlotSchedule({
    this.opens = const KitoCalendarClockTime(9),
    this.closes = const KitoCalendarClockTime(17),
    this.duration = 30,
    int? interval,
  }) : _interval = interval;

  /// The first slot starts here.
  final KitoCalendarClockTime opens;

  /// The last slot ends by here.
  final KitoCalendarClockTime closes;

  /// Slot length in minutes.
  final int duration;

  final int? _interval;

  /// Minutes between slot starts.
  int get interval => _interval ?? duration;

  /// The slots on [day]. A slot is unavailable when it overlaps any of [booked] or starts
  /// before [notBefore] (pass `DateTime.now()` to grey out what's already passed today).
  List<KitoCalendarTimeSlot> slotsOn(DateTime day,
      {List<DateTimeRange> booked = const [], DateTime? notBefore}) {
    if (duration <= 0 || interval <= 0 || opens.compareTo(closes) >= 0) {
      return const [];
    }
    final midnight = KitoCalendarMath.dateOnly(day);
    DateTime at(int minutes) => DateTime(midnight.year, midnight.month,
        midnight.day, minutes ~/ 60, minutes % 60);
    final slots = <KitoCalendarTimeSlot>[];
    var minute = opens.minutesSinceMidnight;
    while (minute + duration <= closes.minutesSinceMidnight &&
        slots.length < 1440) {
      final start = at(minute), end = at(minute + duration);
      final clashes =
          booked.any((b) => start.isBefore(b.end) && end.isAfter(b.start));
      final passed = notBefore != null && start.isBefore(notBefore);
      slots.add(KitoCalendarTimeSlot(
          start: start, end: end, isAvailable: !clashes && !passed));
      minute += interval;
    }
    return slots;
  }
}
