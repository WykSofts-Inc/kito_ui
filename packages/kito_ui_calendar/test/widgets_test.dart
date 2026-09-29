// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_calendar/kito_ui_calendar.dart';

import 'helpers.dart';

final _now = DateTime(2026, 9, 29, 10, 30);

Widget app(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false,
        bool scroll = true}) =>
    testApp(
      KitoCalendarScope(
        locale: const Locale('en', 'GB'),
        now: () => _now,
        use24HourFormat: true,
        child: Scaffold(
          body: scroll
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(12), child: child)
              : child,
        ),
      ),
      direction: direction,
      reduceMotion: reduceMotion,
    );

Finder label(String pattern) => find.bySemanticsLabel(RegExp(pattern));

KitoCalendarEvent at(String title, int day, int h, int m, int h2, int m2,
        {Color color = Colors.blue, String? location}) =>
    KitoCalendarEvent(
      title: title,
      start: DateTime(2026, 9, day, h, m),
      end: DateTime(2026, 9, day, h2, m2),
      color: color,
      location: location,
    );

void main() {
  group('KitoWeekStrip', () {
    Widget strip(
            {required DateTime selected,
            required ValueChanged<DateTime> onChanged}) =>
        KitoWeekStrip(
          selected: selected,
          onChanged: onChanged,
          events: [at('Yoga', 30, 7, 0, 8, 0)],
        );

    testWidgets('taps select, swipes keep the weekday', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        var selected = DateTime(2026, 9, 29);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app(
            StatefulBuilder(
                builder: (context, setState) => strip(
                    selected: selected,
                    onChanged: (d) => setState(() => selected = d))),
            direction: direction));
        await tester.pumpAndSettle();
        expect(find.text('September 2026'), findsOneWidget);
        expect(
            tester.getSemantics(label('30 September 2026')).value, '1 event');
        await tester.tap(label('Thursday, 1 October 2026'));
        await tester.pumpAndSettle();
        expect(selected, DateTime(2026, 10, 1));
        expect(find.text('October 2026'), findsOneWidget);
        // Swipe forward a week: the same weekday stays selected.
        await tester.fling(
            find.byType(PageView),
            direction == TextDirection.ltr
                ? const Offset(-300, 0)
                : const Offset(300, 0),
            1000);
        await tester.pumpAndSettle();
        expect(selected, DateTime(2026, 10, 8), reason: direction.name);
        // Today comes back.
        await tester.tap(find.bySemanticsLabel('Today'));
        await tester.pumpAndSettle();
        expect(selected, DateTime(2026, 9, 29));
      }
      semantics.dispose();
    });

    testWidgets('past days can be blocked', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(KitoWeekStrip(
          selected: DateTime(2026, 9, 29),
          onChanged: (_) {},
          disablePastDates: true)));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(label('28 September 2026')),
          isSemantics(isButton: true, isEnabled: false, hasEnabledState: true));
      semantics.dispose();
    });
  });

  group('KitoYearOverview', () {
    testWidgets('zooms into a month and picks a day', (tester) async {
      final semantics = tester.ensureSemantics();
      DateTime? picked;
      await tester.pumpWidget(app(StatefulBuilder(
        builder: (context, setState) => KitoYearOverview(
          selected: picked,
          onChanged: (d) => setState(() => picked = d),
          events: [
            KitoCalendarEvent(
                title: 'Mashujaa Day',
                start: DateTime(2026, 10, 20),
                end: DateTime(2026, 10, 21),
                isAllDay: true),
          ],
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('October 2026')).value,
          '1 day with events');
      await tester.tap(find.bySemanticsLabel('October 2026'));
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
      await tester.tap(label('Tuesday, 20 October 2026'));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 10, 20));
      expect(find.text('Mashujaa Day'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back to 2026'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next year'));
      await tester.pumpAndSettle();
      expect(find.text('2027'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('KitoTimeSlotPicker', () {
    final day = DateTime(2026, 9, 30);
    final slots = const KitoCalendarSlotSchedule(
      opens: KitoCalendarClockTime(9),
      closes: KitoCalendarClockTime(19),
      duration: 60,
    ).slotsOn(day, booked: [
      DateTimeRange(
          start: DateTime(2026, 9, 30, 17), end: DateTime(2026, 9, 30, 19)),
    ]);

    testWidgets('groups, counts and picks', (tester) async {
      final semantics = tester.ensureSemantics();
      KitoCalendarTimeSlot? picked;
      await tester.pumpWidget(app(StatefulBuilder(
        builder: (context, setState) => KitoTimeSlotPicker(
          slots: slots,
          selected: picked,
          onChanged: (s) => setState(() => picked = s),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('3 open'), findsOneWidget);
      expect(find.text('5 open'), findsOneWidget);
      expect(find.text('Fully booked'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('14:00 to 15:00'));
      await tester.pumpAndSettle();
      expect(picked?.start, DateTime(2026, 9, 30, 14));
      expect(
          tester.getSemantics(find.bySemanticsLabel('14:00 to 15:00')),
          isSemantics(
              isButton: true,
              isSelected: true,
              isEnabled: true,
              hasEnabledState: true));
      await tester.tap(find.bySemanticsLabel('17:00 to 18:00'),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(picked?.start, DateTime(2026, 9, 30, 14), reason: 'booked');
      expect(tester.getSemantics(find.bySemanticsLabel('17:00 to 18:00')).value,
          'Unavailable');
      await tester.tap(find.bySemanticsLabel('14:00 to 15:00'));
      await tester.pumpAndSettle();
      expect(picked, isNull, reason: 'tap again to clear');
      semantics.dispose();
    });

    testWidgets('an empty day says so', (tester) async {
      await tester.pumpWidget(app(KitoTimeSlotPicker(
          slots: const [], selected: null, onChanged: (_) {})));
      await tester.pumpAndSettle();
      expect(find.text('No times on this day'), findsOneWidget);
    });
  });

  group('KitoDayTimeline', () {
    final events = [
      at('Standup', 29, 9, 0, 9, 30, location: 'Kilimani'),
      at('Design review', 29, 11, 0, 12, 30),
      at('Lunch with Amina', 29, 12, 0, 13, 0, color: Colors.orange),
      KitoCalendarEvent(
          title: 'Mashujaa prep',
          start: DateTime(2026, 9, 29),
          end: DateTime(2026, 9, 30),
          isAllDay: true),
    ];

    testWidgets('places overlaps side by side and shows now', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        KitoCalendarEvent? tapped;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app(
            SizedBox(
              height: 500,
              child: KitoDayTimeline(
                  day: _now, events: events, onEventTap: (e) => tapped = e),
            ),
            direction: direction,
            scroll: false));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.bySemanticsLabel('Now, 10:30'), findsOneWidget);
        expect(find.bySemanticsLabel('Mashujaa prep, all day'), findsOneWidget);
        final review = tester.getRect(label('^Design review'));
        final lunch = tester.getRect(label('^Lunch with Amina'));
        expect(review.width, closeTo(lunch.width, 1));
        if (direction == TextDirection.ltr) {
          expect(review.left, lessThan(lunch.left));
        } else {
          expect(review.left, greaterThan(lunch.left));
        }
        await tester.tap(label('^Lunch with Amina'));
        expect(tapped?.title, 'Lunch with Amina');
      }
      semantics.dispose();
    });

    testWidgets('lays out in full inside a scroll view', (tester) async {
      await tester.pumpWidget(app(KitoDayTimeline(
          day: DateTime(2026, 9, 30),
          events: events,
          startHour: 8,
          endHour: 18,
          hourHeight: 40)));
      await tester.pumpAndSettle();
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.byType(KitoDayTimeline), findsOneWidget);
    });
  });

  group('KitoAgendaList', () {
    final events = [
      at('Airport pickup', 28, 7, 0, 8, 0),
      at('Standup', 29, 10, 0, 11, 0, location: 'Kilimani'),
      KitoCalendarEvent(
          title: 'Safari',
          start: DateTime(2026, 9, 30, 14),
          end: DateTime(2026, 10, 2, 11)),
    ];

    testWidgets('groups by day with relative headers', (tester) async {
      final semantics = tester.ensureSemantics();
      KitoCalendarEvent? tapped;
      await tester.pumpWidget(app(
          SizedBox(
              height: 600,
              child: KitoAgendaList(
                  events: events, onEventTap: (e) => tapped = e)),
          scroll: false));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('TOMORROW'), findsOneWidget);
      expect(label('^Today, Tuesday'), findsOneWidget);
      final standup =
          tester.getSemantics(label('^Standup, 10:00 to 11:00, Kilimani'));
      expect(standup.value, 'Happening now');
      expect(label('^Safari, 14:00 to Next day'), findsOneWidget);
      expect(label('^Safari, All day'), findsOneWidget);
      await tester.tap(label('^Standup'));
      expect(tapped?.title, 'Standup');
      semantics.dispose();
    });

    testWidgets('an empty agenda shows a message', (tester) async {
      await tester.pumpWidget(app(const KitoAgendaList(
          events: [],
          emptyTitle: 'Hakuna matata',
          emptyMessage: 'Nothing planned this week.')));
      await tester.pumpAndSettle();
      expect(find.text('Hakuna matata'), findsOneWidget);
    });
  });

  group('KitoDateRangeBar', () {
    testWidgets('opens a sheet, applies a preset and clears', (tester) async {
      final semantics = tester.ensureSemantics();
      KitoCalendarRange? range;
      await tester.pumpWidget(app(StatefulBuilder(
        builder: (context, setState) => KitoDateRangeBar(
          range: range,
          onChanged: (r) => setState(() => range = r),
          title: 'Check-in – Check-out',
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Add dates'), findsOneWidget);
      await tester.tap(find.byType(KitoDateRangeBar));
      await tester.pumpAndSettle();
      expect(find.text('Pick the first day'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next 7 days'));
      await tester.pumpAndSettle();
      expect(find.text('29 Sept – 5 Oct · 6 nights'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Apply'));
      await tester.pumpAndSettle();
      expect(
          range,
          KitoCalendarRange(
              start: DateTime(2026, 9, 29), end: DateTime(2026, 10, 5)));
      expect(find.text('29 Sept – 5 Oct · 6 nights'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear dates'));
      await tester.pumpAndSettle();
      expect(range, isNull);
      semantics.dispose();
    });

    testWidgets('picks days in the sheet; chip style reads out',
        (tester) async {
      final semantics = tester.ensureSemantics();
      KitoCalendarRange? range;
      await tester.pumpWidget(app(StatefulBuilder(
        builder: (context, setState) => KitoDateRangeBar(
          range: range,
          onChanged: (r) => setState(() => range = r),
          style: KitoDateRangeBarStyle.chip,
          unit: KitoCalendarRangeUnit.days,
          presets: const [],
        ),
      )));
      await tester.pumpAndSettle();
      expect(
          tester.getSemantics(find.bySemanticsLabel('Dates')),
          isSemantics(
              isButton: true,
              label: 'Dates',
              value: 'Add dates',
              hint: 'Opens the date picker'));
      await tester.tap(find.byType(KitoDateRangeBar));
      await tester.pumpAndSettle();
      await tester
          .tap(label('Thursday, 1 October 2026|Wednesday, 30 September 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Now pick the last day'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(label('Saturday, 3 October 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Apply'));
      await tester.pumpAndSettle();
      expect(range?.dayCount, 4);
      semantics.dispose();
    });
  });
}
