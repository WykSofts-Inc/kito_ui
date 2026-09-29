// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_calendar/kito_ui_calendar.dart';

import 'helpers.dart';

final _now = DateTime(2026, 9, 29, 10, 30);

Widget calendarApp(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false}) =>
    testApp(
      KitoCalendarScope(
        locale: const Locale('en', 'GB'),
        now: () => _now,
        child: Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(12), child: child)),
      ),
      direction: direction,
      reduceMotion: reduceMotion,
    );

Finder day(String pattern) => find.bySemanticsLabel(RegExp(pattern));

class _Single extends StatefulWidget {
  const _Single({this.onMonth, this.disablePast = false});
  final ValueChanged<DateTime>? onMonth;
  final bool disablePast;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  DateTime? selected;

  @override
  Widget build(BuildContext context) => Column(children: [
        KitoMonthCalendar.single(
          selected: selected,
          onChanged: (d) => setState(() => selected = d),
          onMonthChanged: widget.onMonth,
          disablePastDates: widget.disablePast,
          events: [
            KitoCalendarEvent(
                title: 'Chama',
                start: DateTime(2026, 9, 30, 18),
                end: DateTime(2026, 9, 30, 20)),
            KitoCalendarEvent(
                title: 'Gym',
                color: Colors.green,
                start: DateTime(2026, 9, 30, 6),
                end: DateTime(2026, 9, 30, 7)),
          ],
          heatmap: {DateTime(2026, 9, 2): 0.5},
        ),
        TextButton(
            onPressed: () => setState(() => selected = DateTime(2026, 12, 25)),
            child: const Text('Christmas')),
        Text('picked ${selected?.day}'),
      ]);
}

void main() {
  testWidgets('single selection, events and today', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(calendarApp(const _Single()));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    final today = tester.getSemantics(day('29 September 2026'));
    expect(today.value, 'Today');
    expect(tester.getSemantics(day('30 September 2026')).value, '2 events');
    expect(tester.getSemantics(day(' 2 September 2026')).value,
        'Activity 50 percent');
    await tester.tap(day('15 September 2026'));
    await tester.pumpAndSettle();
    expect(find.text('picked 15'), findsOneWidget);
    expect(
        tester.getSemantics(day('15 September 2026')),
        isSemantics(
            isButton: true,
            isSelected: true,
            value: 'Selected',
            isEnabled: true));
    semantics.dispose();
  });

  testWidgets('pages with the chevrons and comes back with Today',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final months = <DateTime>[];
    await tester.pumpWidget(calendarApp(_Single(onMonth: months.add)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Today'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(months, [DateTime(2026, 10)]);
    await tester.tap(find.bySemanticsLabel('Today'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('setting the selection from outside pages to it', (tester) async {
    await tester.pumpWidget(calendarApp(const _Single()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Christmas'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
  });

  testWidgets('past days are disabled when asked', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(calendarApp(const _Single(disablePast: true)));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(day('10 September 2026')),
        isSemantics(isButton: true, isEnabled: false, hasEnabledState: true));
    await tester.tap(day('10 September 2026'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('picked null'), findsOneWidget);
    expect(find.bySemanticsLabel('Previous month'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Previous month')),
        isSemantics(isButton: true, isEnabled: false, hasEnabledState: true),
        reason: 'no months before this one');
    semantics.dispose();
  });

  testWidgets('range selection with caps and a band', (tester) async {
    final semantics = tester.ensureSemantics();
    var range = KitoCalendarRangeSelection();
    await tester.pumpWidget(calendarApp(StatefulBuilder(
      builder: (context, setState) => KitoMonthCalendar.range(
        selection: range,
        onChanged: (s) => setState(() => range = s),
        isUnavailable: (d) => d.day == 20,
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(day('12 October|12 September 2026'));
    await tester.pumpAndSettle();
    expect(range.start, DateTime(2026, 9, 12));
    await tester.tap(day('18 September 2026'));
    await tester.pumpAndSettle();
    expect(range.range?.nights, 6);
    expect(tester.getSemantics(day('12 September 2026')).value, 'Start date');
    expect(tester.getSemantics(day('18 September 2026')).value, 'End date');
    expect(tester.getSemantics(day('15 September 2026')).value,
        'In selected range');
    expect(tester.getSemantics(day('20 September 2026')).value, 'Unavailable');
    semantics.dispose();
  });

  testWidgets('multiple selection toggles days', (tester) async {
    final semantics = tester.ensureSemantics();
    var days = <DateTime>{};
    await tester.pumpWidget(calendarApp(StatefulBuilder(
      builder: (context, setState) => KitoMonthCalendar.multiple(
        selected: days,
        onChanged: (s) => setState(() => days = s),
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(day(' 3 September 2026'));
    await tester.pump();
    await tester.tap(day(' 5 September 2026'));
    await tester.pumpAndSettle();
    expect(days, {DateTime(2026, 9, 3), DateTime(2026, 9, 5)});
    await tester.tap(day(' 3 September 2026'));
    await tester.pumpAndSettle();
    expect(days, {DateTime(2026, 9, 5)});
    semantics.dispose();
  });

  testWidgets('the grid runs from the right in RTL', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final direction in TextDirection.values) {
      await tester
          .pumpWidget(calendarApp(const _Single(), direction: direction));
      await tester.pumpAndSettle();
      final first = tester.getCenter(day('Tuesday.* 1 September 2026'));
      final second = tester.getCenter(day('Wednesday.* 2 September 2026'));
      if (direction == TextDirection.ltr) {
        expect(first.dx, lessThan(second.dx));
      } else {
        expect(first.dx, greaterThan(second.dx));
      }
    }
    semantics.dispose();
  });

  testWidgets('swiping changes month in both directions', (tester) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(const SizedBox());
      await tester
          .pumpWidget(calendarApp(const _Single(), direction: direction));
      await tester.pumpAndSettle();
      final offset = direction == TextDirection.ltr
          ? const Offset(-300, 0)
          : const Offset(300, 0);
      await tester.fling(find.byType(PageView), offset, 1000);
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget, reason: direction.name);
    }
  });

  testWidgets('first weekday follows the locale or the override',
      (tester) async {
    await tester.pumpWidget(testApp(KitoCalendarScope(
      locale: const Locale('en', 'US'),
      now: () => _now,
      child: Scaffold(
        body: KitoMonthCalendar.single(selected: null, onChanged: (_) {}),
      ),
    )));
    await tester.pumpAndSettle();
    final header = tester.widget<Row>(find.descendant(
        of: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'CalendarWeekdayHeader'),
        matching: find.byType(Row)));
    final first = (header.children.first as Expanded).child as Text;
    expect(first.data, 'S');
    await tester.pumpWidget(testApp(KitoCalendarScope(
      locale: const Locale('en', 'US'),
      now: () => _now,
      firstWeekday: DateTime.monday,
      child: Scaffold(
        body: KitoMonthCalendar.single(selected: null, onChanged: (_) {}),
      ),
    )));
    await tester.pumpAndSettle();
    final monday = tester.widget<Row>(find.descendant(
        of: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'CalendarWeekdayHeader'),
        matching: find.byType(Row)));
    expect(((monday.children.first as Expanded).child as Text).data, 'M');
  });

  testWidgets('reduce motion settles at once', (tester) async {
    await tester.pumpWidget(calendarApp(const _Single(), reduceMotion: true));
    await tester.pump();
    await tester.tap(find.text('15').first);
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
