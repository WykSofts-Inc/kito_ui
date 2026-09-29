# kito_ui_calendar

Calendars for Flutter: a month grid you swipe through with single, multiple and range
selection, a week strip, a year overview that zooms into a month, bookable time slots, a day
timeline with a live "now" line, an agenda with sticky day headers, and a date range field with
presets. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything follows
`KitoTheme` (light, dark, neon), right-to-left layouts, text scaling and Reduce Motion.

Month and weekday names come from `intl`, and the first day of the week and the weekend come
from the locale's data. The kit only shows the events you pass in; it doesn't read the device
calendar, so there's no platform setup.

## Install

```yaml
dependencies:
  kito_ui_calendar: ^0.1.0
```

```dart
import 'package:kito_ui_calendar/kito_ui_calendar.dart';
```

## Quick start

```dart
DateTime? day;

KitoMonthCalendar.single(
  selected: day,
  onChanged: (d) => setState(() => day = d),
)
```

## Month calendar

```dart
// One day, several days, or a range.
KitoMonthCalendar.single(selected: day, onChanged: pickDay);
KitoMonthCalendar.multiple(selected: days, onChanged: pickDays, tint: Colors.green);
KitoMonthCalendar.range(
  selection: stay,                       // KitoCalendarRangeSelection
  onChanged: (s) => setState(() => stay = s),
  disablePastDates: true,
);

if (stay.range case final range?) Text(KitoCalendarConfig.of(context).formatRange(range));
// "12 – 18 Oct · 6 nights" (or "Oct 12 – 18 · 6 nights" where the month comes first)
```

Swipe or use the chevrons to change month; the title rolls to the new one and a **Today**
capsule brings you back. Set the selection from outside (a preset, a "tomorrow" button) and the
calendar pages to it. The selection circle glides between days and a finished range draws one
band between its caps, wrapping with rounded ends.

```dart
KitoMonthCalendar.single(
  selected: day,
  onChanged: pickDay,
  events: events,                              // up to three coloured dots per day
  heatmap: kilometresByDay,                    // or shade days by intensity, 0–1
  minDate: DateTime.now(),
  maxDate: DateTime.now().add(const Duration(days: 45)),
  isUnavailable: (d) => soldOut.contains(d),   // struck through
  onMonthChanged: (month) => load(month),
);
```

Range taps follow booking-app rules: the first tap sets the start, a later day sets the end, an
earlier day moves the start, tapping the start again clears it, and a tap on a finished range
starts a new one. `KitoCalendarRangeSelection(allowsSingleDay: true)` lets a second tap on the
start pick a one-day range.

## Date range field

```dart
KitoCalendarRange? stay;

KitoDateRangeBar(
  range: stay,
  onChanged: (r) => setState(() => stay = r),
  title: 'Check-in – Check-out',
);

KitoDateRangeBar(
  range: trip,
  onChanged: pickTrip,
  placeholder: 'Any week',
  unit: KitoCalendarRangeUnit.days,
  style: KitoDateRangeBarStyle.chip,
);
```

Tapping opens a sheet with preset chips, a range calendar and **Apply**. Past days are blocked
unless `allowPastDates: true`. Presets are resolved when tapped, so they stay right tomorrow:

```dart
final mashujaa = KitoCalendarPreset(
  'Mashujaa weekend',
  icon: Icons.star_rounded,
  resolve: (today, weekend) =>
      KitoCalendarRange(start: DateTime(2026, 10, 17), end: DateTime(2026, 10, 20)),
);

KitoDateRangeBar(
  range: weekend,
  onChanged: pickWeekend,
  presets: [KitoCalendarPreset.thisWeekend, mashujaa, KitoCalendarPreset.nextSevenDays],
);
```

## Week strip and year overview

```dart
KitoWeekStrip(
  selected: day,
  onChanged: (d) => setState(() => day = d),
  events: classes,
  disablePastDates: true,
);

KitoYearOverview(
  selected: picked,
  onChanged: (d) => setState(() => picked = d),
  events: holidays,               // tinted in the mini months
);
```

Swiping the week strip keeps the same weekday selected in the new week. Tap a mini month in the
year overview to zoom into it; the zoomed month lists the selected day's events.

## Time slots

```dart
final slots = const KitoCalendarSlotSchedule(
  opens: KitoCalendarClockTime(8, 30),
  closes: KitoCalendarClockTime(18),
  duration: 45,
  interval: 15,
).slotsOn(day, booked: bookings, notBefore: DateTime.now());

KitoTimeSlotPicker(
  slots: slots,
  selected: slot,
  onChanged: (s) => setState(() => slot = s),
  showsEndTime: true,
);
```

Slots are grouped into Morning, Afternoon and Evening with an "n open" count. A slot that
overlaps a booking or starts before `notBefore` is struck out and can't be picked.

## Day timeline and agenda

```dart
KitoDayTimeline(
  day: DateTime.now(),
  events: meetings,
  startHour: 7,
  endHour: 22,
  hourHeight: 56,
  onEventTap: open,
);

KitoAgendaList(
  events: events,
  onEventTap: open,
  emptyTitle: 'Hakuna matata',
  emptyMessage: 'Nothing planned this week.',
);
```

The timeline puts overlapping events side by side and draws a red line at the current time that
moves as the minutes pass. The agenda groups events by day under sticky headers, repeats
multi-day events on each day ("Until 11:00", "Next day"), marks the ones happening now, and
opens on today. Both lay out at full length inside another scroll view and scroll on their own
when given a height.

## Locale, first weekday and clock

```dart
KitoCalendarScope(
  locale: const Locale('sw', 'KE'),     // names and date patterns
  firstWeekday: DateTime.monday,        // otherwise from the locale
  weekendDays: {DateTime.saturday, DateTime.sunday},
  use24HourFormat: true,
  now: () => DateTime(2026, 10, 1, 9),  // handy for demos and tests
  child: MyScheduleScreen(),
);
```

Without a scope the widgets follow the app's `Locale`. `KitoCalendarConfig.of(context)` gives
you the same formatting (`monthTitle`, `time`, `rangeDates`, `formatRange`, `weekdaySymbols`).

## Models and logic

```dart
KitoCalendarEvent(
  title: 'Chama meeting',
  start: start,
  end: end,
  color: Colors.green,
  location: 'Lavington',
);

KitoCalendarMonthGrid(date, firstWeekday: DateTime.monday, fixedSixWeeks: true).weeks;
KitoCalendarEventLayout.placements(events);        // column and column count per event
KitoCalendarMath.startOfWeek(date, firstWeekday: DateTime.sunday);
KitoCalendarMath.nights(checkIn, checkOut);
KitoCalendarMath.agenda(events);
```

All of it is pure and covered by unit tests.

## Right-to-left and accessibility

Everything mirrors in right-to-left layouts: the month grid, week strip and paging run from the
right, range bands and timeline columns follow them, chevrons point the right way, and weekday
order still comes from the first weekday. Every day is a button with its full date, and a value
such as "Today, Start date, 2 events"; slots, pills, presets and events are buttons too, with
44-point targets. Reduce Motion turns the glides, pops and pulses into plain changes.

## License

MIT — see [LICENSE](LICENSE).
