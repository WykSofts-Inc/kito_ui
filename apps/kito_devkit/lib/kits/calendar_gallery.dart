// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_calendar/kito_ui_calendar.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';

DateTime _today() => KitoCalendarMath.dateOnly(DateTime.now());
DateTime _day(int offset, [int hour = 0, int minute = 0]) {
  final t = _today();
  return DateTime(t.year, t.month, t.day + offset, hour, minute);
}

List<KitoCalendarEvent> _week() => [
      KitoCalendarEvent(
          title: 'Standup',
          start: _day(0, 9),
          end: _day(0, 9, 30),
          location: 'Kilimani office'),
      KitoCalendarEvent(
          title: 'Design review with Amina',
          start: _day(0, 11),
          end: _day(0, 12, 30),
          color: const Color(0xFF8C5CF0)),
      KitoCalendarEvent(
          title: 'Lunch at Java House',
          start: _day(0, 12),
          end: _day(0, 13),
          color: const Color(0xFFF58C29),
          location: 'Westlands'),
      KitoCalendarEvent(
          title: 'Chama meeting',
          start: _day(1, 18),
          end: _day(1, 20),
          color: const Color(0xFF21A86B),
          location: 'Lavington'),
      KitoCalendarEvent(
          title: 'Gym with Otieno',
          start: _day(2, 6, 30),
          end: _day(2, 7, 30),
          color: const Color(0xFFD13D6B)),
      KitoCalendarEvent(
          title: 'Maasai Mara safari',
          start: _day(4, 7),
          end: _day(6, 16),
          color: const Color(0xFFF5A524)),
      KitoCalendarEvent(
          title: 'Utamaduni Day',
          start: _day(3),
          end: _day(4),
          isAllDay: true,
          color: const Color(0xFFE5484D)),
    ];

/// The gallery for kito_ui_calendar.
final calendarKit = KitEntry(
  title: 'Calendar',
  package: 'kito_ui_calendar',
  blurb: 'month, week and year pickers, slots, timelines and agendas',
  icon: Icons.calendar_month_rounded,
  category: KitCategory.data,
  isNew: true,
  sections: [
    KitSection('Month', Icons.calendar_view_month_rounded, [
      KitSample(
        title: 'Pick a day',
        subtitle: 'Swipe or tap the chevrons; the circle glides between days.',
        code: '''KitoMonthCalendar.single(
  selected: day,
  onChanged: (d) => setState(() => day = d),
)''',
        builder: (_) => const _SingleDay(),
      ),
      KitSample(
        title: 'Book a stay',
        subtitle:
            'A range with caps and one continuous band; past days blocked.',
        code: '''KitoMonthCalendar.range(
  selection: stay,
  onChanged: (s) => setState(() => stay = s),
  disablePastDates: true,
)
// stay.range → "12 – 18 Oct · 6 nights"''',
        builder: (_) => const _Stay(),
      ),
      KitSample(
        title: 'Several days',
        subtitle:
            'Wycliff N picks the chama’s meeting days; tap again to remove.',
        code: '''KitoMonthCalendar.multiple(
  selected: days,
  onChanged: (s) => setState(() => days = s),
  tint: const Color(0xFF21A86B),
)''',
        builder: (_) => const _Multiple(),
      ),
      KitSample(
        title: 'Event dots',
        subtitle: 'Up to three colours under each day with plans.',
        code: '''KitoMonthCalendar.single(
  selected: day,
  onChanged: pick,
  events: events,
)''',
        builder: (_) => _Picker(
            builder: (day, pick) => KitoMonthCalendar.single(
                selected: day, onChanged: pick, events: _week())),
      ),
      KitSample(
        title: 'Running heatmap',
        subtitle: 'Shade days by intensity, like a contribution graph.',
        code: '''KitoMonthCalendar.single(
  selected: day,
  onChanged: pick,
  heatmap: {for (final run in runs) run.date: run.km / 21},
  tint: const Color(0xFFF58C29),
)''',
        builder: (_) => _Picker(
          builder: (day, pick) => KitoMonthCalendar.single(
            selected: day,
            onChanged: pick,
            tint: const Color(0xFFF58C29),
            heatmap: {
              for (var i = -28; i <= 0; i++)
                if (i % 3 != 0) _day(i): ((i * 37) % 10).abs() / 10,
            },
          ),
        ),
      ),
      KitSample(
        title: 'Seats on the SGR',
        subtitle: 'The next 45 days only, with sold-out days struck through.',
        code: '''KitoMonthCalendar.single(
  selected: day,
  onChanged: pick,
  minDate: DateTime.now(),
  maxDate: DateTime.now().add(const Duration(days: 45)),
  isUnavailable: (d) => d.weekday == DateTime.friday,
)''',
        builder: (_) => _Picker(
          builder: (day, pick) => KitoMonthCalendar.single(
            selected: day,
            onChanged: pick,
            minDate: _today(),
            maxDate: _day(45),
            isUnavailable: (d) => d.weekday == DateTime.friday,
          ),
        ),
      ),
    ]),
    KitSection('Week and year', Icons.view_week_rounded, [
      KitSample(
        title: 'Week strip',
        subtitle: 'Swipe a week; the same weekday stays selected.',
        code: '''KitoWeekStrip(
  selected: day,
  onChanged: (d) => setState(() => day = d),
  events: classes,
)''',
        builder: (_) => _Picker(
            initial: _today(),
            builder: (day, pick) => KitoWeekStrip(
                selected: day ?? _today(), onChanged: pick, events: _week())),
      ),
      KitSample(
        title: 'Strip without the past',
        subtitle: 'No header, earlier days faded.',
        code: '''KitoWeekStrip(
  selected: day,
  onChanged: pick,
  disablePastDates: true,
  showsHeader: false,
  tint: const Color(0xFF8C5CF0),
)''',
        builder: (_) => _Picker(
            initial: _today(),
            builder: (day, pick) => KitoWeekStrip(
                selected: day ?? _today(),
                onChanged: pick,
                disablePastDates: true,
                showsHeader: false,
                tint: const Color(0xFF8C5CF0))),
      ),
      KitSample(
        title: 'Year overview',
        subtitle: 'Kenyan public holidays; tap a month to zoom in.',
        code: '''KitoYearOverview(
  selected: picked,
  onChanged: (d) => setState(() => picked = d),
  events: holidays,
)''',
        builder: (_) => _Picker(
            builder: (day, pick) => KitoYearOverview(
                selected: day, onChanged: pick, events: _holidays())),
      ),
    ]),
    KitSection('Booking', Icons.event_available_rounded, [
      KitSample(
        title: 'Barber slots',
        subtitle: 'Grouped by time of day; booked slots struck out.',
        code: '''final slots = const KitoCalendarSlotSchedule(
  opens: KitoCalendarClockTime(8, 30),
  closes: KitoCalendarClockTime(19),
  duration: 45,
  interval: 15,
).slotsOn(day, booked: bookings);

KitoTimeSlotPicker(slots: slots, selected: slot, onChanged: pickSlot)''',
        builder: (_) => const _Slots(),
      ),
      KitSample(
        title: 'Slots with end times',
        subtitle: 'Back-to-back hour slots; the past is greyed out today.',
        code: '''KitoTimeSlotPicker(
  slots: const KitoCalendarSlotSchedule(opens: KitoCalendarClockTime(9), duration: 60)
      .slotsOn(DateTime.now(), notBefore: DateTime.now()),
  selected: slot,
  onChanged: pickSlot,
  showsEndTime: true,
)''',
        builder: (_) => const _Slots(endTimes: true),
      ),
      KitSample(
        title: 'Date range field',
        subtitle: 'Opens a sheet with presets, a range calendar and Apply.',
        code: '''KitoDateRangeBar(
  range: stay,
  onChanged: (r) => setState(() => stay = r),
  title: 'Diani check-in – check-out',
)''',
        builder: (_) => const _RangeBar(),
      ),
      KitSample(
        title: 'Range chip with a holiday',
        subtitle: 'Compact style, days instead of nights, and a custom preset.',
        code: '''final mashujaa = KitoCalendarPreset(
  'Mashujaa weekend',
  icon: Icons.star_rounded,
  resolve: (today, weekend) => KitoCalendarRange(start: oct17, end: oct20),
);

KitoDateRangeBar(
  range: trip,
  onChanged: pickTrip,
  style: KitoDateRangeBarStyle.chip,
  unit: KitoCalendarRangeUnit.days,
  placeholder: 'Any week',
  presets: [mashujaa, KitoCalendarPreset.nextSevenDays],
)''',
        builder: (_) => const _RangeBar(chip: true),
      ),
    ]),
    KitSection('Schedule', Icons.view_timeline_rounded, [
      KitSample(
        title: 'Day timeline',
        subtitle: 'Overlaps side by side and a live now line.',
        code: '''SizedBox(
  height: 420,
  child: KitoDayTimeline(
    day: DateTime.now(),
    events: meetings,
    startHour: 7,
    endHour: 22,
    onEventTap: open,
  ),
)''',
        builder: (_) => SizedBox(
          height: 420,
          child: KitoDayTimeline(
              day: _today(), events: _week(), startHour: 7, endHour: 22),
        ),
      ),
      KitSample(
        title: 'Agenda',
        subtitle: 'Sticky day headers, multi-day trips on every day, and Now.',
        code: '''SizedBox(
  height: 420,
  child: KitoAgendaList(events: events, onEventTap: open),
)''',
        builder: (_) =>
            SizedBox(height: 420, child: KitoAgendaList(events: _week())),
      ),
      KitSample(
        title: 'Empty agenda',
        subtitle: 'Your own words when nothing is planned.',
        code: '''const KitoAgendaList(
  events: [],
  emptyTitle: 'Hakuna matata',
  emptyMessage: 'Nothing planned this week.',
)''',
        builder: (_) => const KitoAgendaList(
            events: [],
            emptyTitle: 'Hakuna matata',
            emptyMessage: 'Nothing planned this week.'),
      ),
    ]),
    KitSection('Locale', Icons.translate_rounded, [
      KitSample(
        title: 'Kiswahili',
        subtitle:
            'Month and weekday names from intl, weeks from Monday, 24-hour.',
        code: '''KitoCalendarScope(
  locale: const Locale('sw'),
  firstWeekday: DateTime.monday,
  use24HourFormat: true,
  child: KitoMonthCalendar.single(selected: day, onChanged: pick),
)''',
        builder: (_) => KitoCalendarScope(
          locale: const Locale('sw'),
          firstWeekday: DateTime.monday,
          use24HourFormat: true,
          child: _Picker(
              builder: (day, pick) =>
                  KitoMonthCalendar.single(selected: day, onChanged: pick)),
        ),
      ),
      KitSample(
        title: 'Sunday first',
        subtitle:
            'US English: weeks start on Sunday and ranges read "Oct 12 – 18".',
        code: '''KitoCalendarScope(
  locale: const Locale('en', 'US'),
  child: KitoMonthCalendar.range(selection: stay, onChanged: pick),
)''',
        builder: (_) => const KitoCalendarScope(
          locale: Locale('en', 'US'),
          child: _Stay(),
        ),
      ),
    ]),
  ],
);

List<KitoCalendarEvent> _holidays() {
  final y = DateTime.now().year;
  KitoCalendarEvent h(String title, int m, int d) => KitoCalendarEvent(
      title: title,
      start: DateTime(y, m, d),
      end: DateTime(y, m, d + 1),
      isAllDay: true,
      color: const Color(0xFFE5484D));
  return [
    h('New Year’s Day', 1, 1),
    h('Labour Day', 5, 1),
    h('Madaraka Day', 6, 1),
    h('Utamaduni Day', 10, 10),
    h('Mashujaa Day', 10, 20),
    h('Jamhuri Day', 12, 12),
    h('Christmas Day', 12, 25),
    h('Boxing Day', 12, 26),
  ];
}

class _Picker extends StatefulWidget {
  const _Picker({required this.builder, this.initial});

  final Widget Function(DateTime? day, ValueChanged<DateTime> pick) builder;
  final DateTime? initial;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late DateTime? _day = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_day, (d) => setState(() => _day = d));
}

class _SingleDay extends StatefulWidget {
  const _SingleDay();

  @override
  State<_SingleDay> createState() => _SingleDayState();
}

class _SingleDayState extends State<_SingleDay> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    return Column(children: [
      KitoMonthCalendar.single(
          selected: _day, onChanged: (d) => setState(() => _day = d)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Text(
            _day == null ? 'No day picked yet' : config.fullDate(_day!),
            style: theme.typography.label,
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _day =
              _day == null ? _today().add(const Duration(days: 40)) : null),
          child: Text(_day == null ? 'In 40 days' : 'Clear'),
        ),
      ]),
    ]);
  }
}

class _Stay extends StatefulWidget {
  const _Stay();

  @override
  State<_Stay> createState() => _StayState();
}

class _StayState extends State<_Stay> {
  var _stay = KitoCalendarRangeSelection();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    final range = _stay.range;
    return Column(children: [
      KitoMonthCalendar.range(
        selection: _stay,
        onChanged: (s) => setState(() => _stay = s),
        disablePastDates: true,
      ),
      const SizedBox(height: 8),
      Text(
        range != null
            ? config.formatRange(range)
            : _stay.isAwaitingEnd
                ? 'Now pick check-out'
                : 'Pick check-in',
        style: theme.typography.bodyEmphasized,
      ),
    ]);
  }
}

class _Multiple extends StatefulWidget {
  const _Multiple();

  @override
  State<_Multiple> createState() => _MultipleState();
}

class _MultipleState extends State<_Multiple> {
  Set<DateTime> _days = {};

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(children: [
      KitoMonthCalendar.multiple(
        selected: _days,
        onChanged: (s) => setState(() => _days = s),
        tint: const Color(0xFF21A86B),
      ),
      const SizedBox(height: 8),
      Text(
        _days.isEmpty
            ? 'Tap the meeting days'
            : '${_days.length} meeting${_days.length == 1 ? '' : 's'} picked',
        style: theme.typography.label,
      ),
    ]);
  }
}

class _Slots extends StatefulWidget {
  const _Slots({this.endTimes = false});

  final bool endTimes;

  @override
  State<_Slots> createState() => _SlotsState();
}

class _SlotsState extends State<_Slots> {
  KitoCalendarTimeSlot? _slot;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = widget.endTimes ? now : _day(1);
    final slots = widget.endTimes
        ? const KitoCalendarSlotSchedule(
                opens: KitoCalendarClockTime(9), duration: 60)
            .slotsOn(day, notBefore: now)
        : const KitoCalendarSlotSchedule(
            opens: KitoCalendarClockTime(8, 30),
            closes: KitoCalendarClockTime(19),
            duration: 45,
            interval: 15,
          ).slotsOn(day, booked: [
            DateTimeRange(start: _day(1, 10), end: _day(1, 11, 15)),
            DateTimeRange(start: _day(1, 17), end: _day(1, 19)),
          ]);
    return KitoTimeSlotPicker(
      slots: slots,
      selected: _slot,
      onChanged: (s) => setState(() => _slot = s),
      showsEndTime: widget.endTimes,
    );
  }
}

class _RangeBar extends StatefulWidget {
  const _RangeBar({this.chip = false});

  final bool chip;

  @override
  State<_RangeBar> createState() => _RangeBarState();
}

class _RangeBarState extends State<_RangeBar> {
  KitoCalendarRange? _range;

  @override
  Widget build(BuildContext context) {
    if (!widget.chip) {
      return KitoDateRangeBar(
        range: _range,
        onChanged: (r) => setState(() => _range = r),
        title: 'Diani check-in – check-out',
      );
    }
    final y = DateTime.now().year;
    final mashujaa = KitoCalendarPreset(
      'Mashujaa weekend',
      icon: Icons.star_rounded,
      resolve: (today, weekend) {
        var start = DateTime(y, 10, 17);
        if (start.isBefore(today)) start = DateTime(y + 1, 10, 17);
        return KitoCalendarRange(
            start: start, end: start.add(const Duration(days: 3)));
      },
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: KitoDateRangeBar(
        range: _range,
        onChanged: (r) => setState(() => _range = r),
        style: KitoDateRangeBarStyle.chip,
        unit: KitoCalendarRangeUnit.days,
        placeholder: 'Any week',
        presets: [mashujaa, KitoCalendarPreset.nextSevenDays],
      ),
    );
  }
}
