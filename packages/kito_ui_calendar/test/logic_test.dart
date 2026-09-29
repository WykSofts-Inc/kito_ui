// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_calendar/kito_ui_calendar.dart';

DateTime d(int y, int m, [int day = 1, int h = 0, int min = 0]) =>
    DateTime(y, m, day, h, min);

KitoCalendarEvent ev(String title, DateTime start, DateTime end,
        {bool allDay = false}) =>
    KitoCalendarEvent(title: title, start: start, end: end, isAllDay: allDay);

void main() {
  group('KitoCalendarMath', () {
    test('day arithmetic', () {
      expect(KitoCalendarMath.dateOnly(d(2026, 9, 29, 14, 5)), d(2026, 9, 29));
      expect(KitoCalendarMath.addDays(d(2026, 9, 29), 3), d(2026, 10, 2));
      expect(KitoCalendarMath.addMonths(d(2026, 12, 31), 2), d(2027, 2));
      expect(KitoCalendarMath.daysInMonth(d(2028, 2, 10)), 29);
      expect(
          KitoCalendarMath.nights(d(2026, 10, 12, 23), d(2026, 10, 18, 1)), 6);
      expect(KitoCalendarMath.nights(d(2026, 10, 18), d(2026, 10, 12)), -6);
    });

    test('weeks start on the given weekday', () {
      final tue = d(2026, 9, 29);
      expect(KitoCalendarMath.startOfWeek(tue), d(2026, 9, 28));
      expect(KitoCalendarMath.startOfWeek(tue, firstWeekday: DateTime.sunday),
          d(2026, 9, 27));
      expect(KitoCalendarMath.startOfWeek(tue, firstWeekday: DateTime.saturday),
          d(2026, 9, 26));
      expect(KitoCalendarMath.week(tue).last, d(2026, 10, 4));
      expect(KitoCalendarMath.weekdayOrder(firstWeekday: DateTime.sunday),
          [7, 1, 2, 3, 4, 5, 6]);
    });

    test('events touch the right days', () {
      expect(
          KitoCalendarMath.daysSpannedBy(
              ev('Safari', d(2026, 10, 1, 20), d(2026, 10, 3))),
          [d(2026, 10, 1), d(2026, 10, 2)],
          reason: 'ending at midnight does not touch that day');
      expect(
          KitoCalendarMath.daysSpannedBy(
              ev('Reminder', d(2026, 10, 1, 9), d(2026, 10, 1, 9))),
          [d(2026, 10, 1)]);
    });

    test('agenda orders all-day first, then start, then title', () {
      final days = KitoCalendarMath.agenda([
        ev('Standup', d(2026, 10, 1, 9), d(2026, 10, 1, 9, 15)),
        ev('Chama', d(2026, 10, 1, 18), d(2026, 10, 1, 20)),
        ev('Mashujaa prep', d(2026, 10, 1), d(2026, 10, 2), allDay: true),
        ev('Airport run', d(2026, 9, 30, 22), d(2026, 10, 1, 1)),
        ev('breakfast', d(2026, 10, 1, 9), d(2026, 10, 1, 10)),
      ]);
      expect(days.map((x) => x.date), [d(2026, 9, 30), d(2026, 10, 1)]);
      expect(days[1].events.map((e) => e.title), [
        'Mashujaa prep',
        'Airport run',
        'breakfast',
        'Standup',
        'Chama',
      ]);
    });

    test('months and weeks between two dates', () {
      expect(KitoCalendarMath.months(d(2026, 11, 20), d(2027, 2, 1)),
          [d(2026, 11), d(2026, 12), d(2027, 1), d(2027, 2)]);
      expect(KitoCalendarMath.weeks(d(2026, 9, 29), d(2026, 10, 12)).length, 3);
    });
  });

  group('KitoCalendarMonthGrid', () {
    test('October 2026 with Monday first', () {
      final grid = KitoCalendarMonthGrid(d(2026, 10, 15));
      expect(grid.month, d(2026, 10));
      expect(grid.leadingCount, 3, reason: 'the 1st is a Thursday');
      expect(grid.days.first.date, d(2026, 9, 28));
      expect(grid.days.length, 35);
      expect(grid.trailingCount, 1);
      expect(grid.daysInMonth.length, 31);
      expect(grid.weeks.every((w) => w.length == 7), isTrue);
    });

    test('Sunday first and fixed six weeks', () {
      final grid = KitoCalendarMonthGrid(d(2026, 10),
          firstWeekday: DateTime.sunday, fixedSixWeeks: true);
      expect(grid.leadingCount, 4);
      expect(grid.days.length, 42);
      expect(grid.days.first.date, d(2026, 9, 27));
      expect(grid.days.first.isInMonth, isFalse);
    });

    test('a month that starts on the first weekday has no lead', () {
      final grid =
          KitoCalendarMonthGrid(d(2026, 2), firstWeekday: DateTime.sunday);
      expect(grid.leadingCount, 0);
      expect(grid.days.length, 28);
    });
  });

  group('KitoCalendarEventLayout', () {
    test('overlaps sit side by side and share a column count', () {
      final a = ev('A', d(2026, 10, 1, 9), d(2026, 10, 1, 11));
      final b = ev('B', d(2026, 10, 1, 10), d(2026, 10, 1, 12));
      final c = ev('C', d(2026, 10, 1, 11), d(2026, 10, 1, 12));
      final e = ev('E', d(2026, 10, 1, 14), d(2026, 10, 1, 15));
      final placed = {
        for (final p in KitoCalendarEventLayout.placements([c, e, b, a]))
          p.event.title: (p.column, p.columnCount)
      };
      expect(placed['A'], (0, 2));
      expect(placed['B'], (1, 2));
      expect(placed['C'], (0, 2), reason: 'reuses the column A freed');
      expect(placed['E'], (0, 1));
    });

    test('a minimum duration keeps short events apart', () {
      final a = ev('A', d(2026, 10, 1, 9), d(2026, 10, 1, 9, 5));
      final b = ev('B', d(2026, 10, 1, 9, 10), d(2026, 10, 1, 9, 20));
      expect(
          KitoCalendarEventLayout.placements([a, b]).map((p) => p.columnCount),
          [1, 1]);
      expect(
          KitoCalendarEventLayout.placements([a, b],
                  minimumDuration: const Duration(minutes: 30))
              .map((p) => p.columnCount),
          [2, 2]);
    });
  });

  group('ranges', () {
    test('nights, days and containment', () {
      final stay =
          KitoCalendarRange(start: d(2026, 10, 18), end: d(2026, 10, 12, 15));
      expect(stay.start, d(2026, 10, 12));
      expect(stay.nights, 6);
      expect(stay.dayCount, 7);
      expect(stay.contains(d(2026, 10, 18, 23)), isTrue);
      expect(stay.contains(d(2026, 10, 19)), isFalse);
      expect(KitoCalendarRangeUnit.nights.label(stay), '6 nights');
      expect(KitoCalendarRangeUnit.days.label(stay), '7 days');
      expect(
          KitoCalendarRangeUnit.nights.label(
              KitoCalendarRange(start: d(2026, 1, 1), end: d(2026, 1, 2))),
          '1 night');
    });

    test('selection follows booking-app rules', () {
      var s = KitoCalendarRangeSelection();
      expect(s.isEmpty, isTrue);
      s = s.select(d(2026, 10, 12, 9));
      expect(s.start, d(2026, 10, 12));
      expect(s.isAwaitingEnd, isTrue);
      s = s.select(d(2026, 10, 10));
      expect(s.start, d(2026, 10, 10), reason: 'earlier moves the start');
      s = s.select(d(2026, 10, 14));
      expect(s.range,
          KitoCalendarRange(start: d(2026, 10, 10), end: d(2026, 10, 14)));
      s = s.select(d(2026, 10, 20));
      expect((s.start, s.end), (d(2026, 10, 20), null),
          reason: 'a tap on a finished range starts again');
      s = s.select(d(2026, 10, 20));
      expect(s.isEmpty, isTrue, reason: 'tapping the start again clears it');
      var one = KitoCalendarRangeSelection(allowsSingleDay: true);
      one = one.select(d(2026, 10, 5)).select(d(2026, 10, 5));
      expect(one.range?.nights, 0);
      expect(one.withRange(null).isEmpty, isTrue);
    });

    test('presets resolve against today', () {
      const weekend = {DateTime.saturday, DateTime.sunday};
      final wed = d(2026, 9, 30, 15);
      expect(KitoCalendarPreset.thisWeekend.rangeFor(wed, weekendDays: weekend),
          KitoCalendarRange(start: d(2026, 10, 3), end: d(2026, 10, 4)));
      expect(
          KitoCalendarPreset.thisWeekend
              .rangeFor(d(2026, 10, 4), weekendDays: weekend),
          KitoCalendarRange(start: d(2026, 10, 4), end: d(2026, 10, 4)),
          reason: 'never starts before today');
      expect(
          KitoCalendarPreset.thisWeekend.rangeFor(wed,
              weekendDays: const {DateTime.friday, DateTime.saturday}),
          KitoCalendarRange(start: d(2026, 10, 2), end: d(2026, 10, 3)));
      expect(KitoCalendarPreset.nextSevenDays.rangeFor(wed).dayCount, 7);
      expect(KitoCalendarPreset.thisMonth.rangeFor(wed),
          KitoCalendarRange(start: d(2026, 9, 30), end: d(2026, 9, 30)));
    });
  });

  group('slots', () {
    test('back to back, booked and past', () {
      const schedule = KitoCalendarSlotSchedule();
      final day = d(2026, 10, 1);
      final slots = schedule.slotsOn(day,
          booked: [
            DateTimeRange(
                start: d(2026, 10, 1, 10, 15), end: d(2026, 10, 1, 11))
          ],
          notBefore: d(2026, 10, 1, 9, 10));
      expect(slots.length, 16);
      expect(slots.first.start, d(2026, 10, 1, 9));
      expect(slots.last.end, d(2026, 10, 1, 17));
      expect(slots[0].isAvailable, isFalse, reason: 'already started');
      expect(slots[1].isAvailable, isTrue);
      expect(slots[2].isAvailable, isFalse, reason: '10:00 overlaps 10:15');
      expect(slots[3].isAvailable, isFalse);
      expect(slots[4].isAvailable, isTrue, reason: '11:00 starts as it ends');
      expect(slots.first.period, KitoCalendarDayPeriod.morning);
      expect(slots.last.period, KitoCalendarDayPeriod.afternoon);
    });

    test('an interval overlaps slots; a bad schedule has none', () {
      const schedule = KitoCalendarSlotSchedule(
          opens: KitoCalendarClockTime(8, 30),
          closes: KitoCalendarClockTime(18),
          duration: 45,
          interval: 15);
      final slots = schedule.slotsOn(d(2026, 10, 1));
      expect(slots[1].start, d(2026, 10, 1, 8, 45));
      expect(slots.last.end, d(2026, 10, 1, 18));
      expect(slots.where((s) => s.period == KitoCalendarDayPeriod.evening),
          isNotEmpty);
      expect(
          const KitoCalendarSlotSchedule(
                  opens: KitoCalendarClockTime(12),
                  closes: KitoCalendarClockTime(9))
              .slotsOn(d(2026, 10, 1)),
          isEmpty);
    });
  });

  group('KitoCalendarConfig', () {
    test('first weekday and weekend come from the locale', () {
      expect(KitoCalendarConfig(locale: 'en_US').firstWeekday, DateTime.sunday);
      expect(KitoCalendarConfig(locale: 'en_GB').firstWeekday, DateTime.monday);
      expect(KitoCalendarConfig(locale: 'en_GB').weekendDays,
          {DateTime.saturday, DateTime.sunday});
      expect(KitoCalendarConfig(locale: 'ar_EG').weekendDays,
          {DateTime.friday, DateTime.saturday});
      expect(KitoCalendarConfig(locale: 'xx_YY').locale, 'en');
    });

    test('weekday names in display order', () {
      expect(KitoCalendarConfig(locale: 'en_US').weekdaySymbols(),
          ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
      expect(
          KitoCalendarConfig(locale: 'en_GB')
              .weekdaySymbols(KitoCalendarWeekdayStyle.short)
              .first,
          'Mon');
      expect(
          KitoCalendarConfig(locale: 'sw', firstWeekday: DateTime.monday)
              .weekdaySymbols(KitoCalendarWeekdayStyle.full)
              .first,
          'Jumatatu');
    });

    test('range formatting follows the locale order', () {
      final gb = KitoCalendarConfig(locale: 'en_GB');
      final us = KitoCalendarConfig(locale: 'en_US');
      final stay =
          KitoCalendarRange(start: d(2026, 10, 12), end: d(2026, 10, 18));
      expect(gb.formatRange(stay), '12 – 18 Oct · 6 nights');
      expect(us.formatRange(stay, unit: KitoCalendarRangeUnit.days),
          'Oct 12 – 18 · 7 days');
      expect(
          gb.rangeDates(
              KitoCalendarRange(start: d(2026, 10, 28), end: d(2026, 11, 3))),
          '28 Oct – 3 Nov');
      expect(
          gb.rangeDates(
              KitoCalendarRange(start: d(2026, 12, 30), end: d(2027, 1, 2))),
          '30 Dec 2026 – 2 Jan 2027');
      expect(gb.formatRange(stay, unit: null), '12 – 18 Oct');
    });

    test('times in 12 and 24 hours', () {
      final t = d(2026, 10, 1, 14, 30);
      expect(KitoCalendarConfig(locale: 'en_US').time(t), contains('2:30'));
      expect(KitoCalendarConfig(locale: 'en_US', use24HourFormat: true).time(t),
          '14:30');
      expect(KitoCalendarConfig(locale: 'en_GB').monthTitle(t), 'October 2026');
    });
  });
}
