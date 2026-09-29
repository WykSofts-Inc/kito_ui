// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_charts/kito_ui_charts.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'helpers.dart';

const _quarters = ['Q1', 'Q2', 'Q3', 'Q4'];

Widget _bars({
  KitoBarLayout layout = KitoBarLayout.grouped,
  Axis direction = Axis.vertical,
  ValueChanged<int?>? onSelect,
  int series = 1,
}) =>
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: KitoBarChart(
          layout: layout,
          direction: direction,
          onSelectionChanged: onSelect,
          showsValues: true,
          referenceLines: const [KitoChartReferenceLine('Target', 50)],
          series: [
            KitoChartSeries.values('Tea', [42, 58, 35, 71], labels: _quarters),
            if (series > 1)
              KitoChartSeries.values('Coffee', [20, -10, 30, 25],
                  labels: _quarters),
          ],
        ),
      ),
    );

const _spending = [
  KitoChartPoint('Rent', 45000),
  KitoChartPoint('Food', 18000),
  KitoChartPoint('Matatu', 6500, color: Color(0xFF7C4DFF)),
  KitoChartPoint('Airtime', 500),
];

void main() {
  group('KitoBarChart', () {
    testWidgets('each category is a button for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      final picks = <int?>[];
      await tester.pumpWidget(testApp(_bars(onSelect: picks.add, series: 2)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bar chart, 4 categories, 2 series'),
          findsOneWidget);
      final q2 = find.bySemanticsLabel('Q2, Tea 58, Coffee -10');
      expect(q2, findsOneWidget);
      await tester.tap(q2);
      await tester.pumpAndSettle();
      expect(picks, [1]);
      expect(
          tester.getSemantics(q2),
          isSemantics(
              isButton: true,
              isSelected: true,
              label: 'Q2, Tea 58, Coffee -10'));
      await tester.tap(q2);
      await tester.pumpAndSettle();
      expect(picks, [1, null]);
      semantics.dispose();
    });

    testWidgets('the first category sits at the start edge', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(testApp(_bars(), direction: direction));
        await tester.pumpAndSettle();
        final q1 = tester.getCenter(find.bySemanticsLabel('Q1, 42'));
        final q4 = tester.getCenter(find.bySemanticsLabel('Q4, 71'));
        if (direction == TextDirection.ltr) {
          expect(q1.dx, lessThan(q4.dx));
        } else {
          expect(q1.dx, greaterThan(q4.dx));
        }
      }
      semantics.dispose();
    });

    testWidgets('horizontal bars stack categories top to bottom',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(testApp(_bars(direction: Axis.horizontal)));
      await tester.pumpAndSettle();
      final q1 = tester.getCenter(find.bySemanticsLabel('Q1, 42'));
      final q4 = tester.getCenter(find.bySemanticsLabel('Q4, 71'));
      expect(q1.dy, lessThan(q4.dy));
      expect(tester.getSize(find.byType(KitoBarChart)).height, 4 * 40 + 28);
      semantics.dispose();
    });

    testWidgets('stacked, grouped and horizontal paint in both directions',
        (tester) async {
      for (final direction in TextDirection.values) {
        for (final layout in KitoBarLayout.values) {
          for (final axis in Axis.values) {
            await tester.pumpWidget(testApp(
                _bars(layout: layout, direction: axis, series: 2),
                direction: direction));
            await tester.pump(const Duration(milliseconds: 200));
            await tester.tap(find.byType(KitoBarChart), warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('bars grow in, and not under reduce motion', (tester) async {
      await tester.pumpWidget(testApp(_bars()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      await tester.pumpWidget(testApp(const SizedBox()));
      await tester.pumpWidget(testApp(_bars(), reduceMotion: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('KitoPieChart', () {
    Widget pie({double hole = 0, ValueChanged<int?>? onSelect}) => Scaffold(
          body: Center(
            child: KitoPieChart(
              points: _spending,
              holeFraction: hole,
              gapDegrees: hole > 0 ? 2 : 0,
              center: const Text('KSh 70k'),
              onSelectionChanged: onSelect,
            ),
          ),
        );

    testWidgets('summarises slices and shows the centre content',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(testApp(pie(hole: 0.6)));
      await tester.pumpAndSettle();
      expect(
          find.bySemanticsLabel(
              'Donut chart, 4 slices: Rent 64%, Food 26%, Matatu 9%, Airtime 1%'),
          findsOneWidget);
      expect(find.text('KSh 70k'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a legend tap selects a slice and the hole shows it',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final picks = <int?>[];
      await tester.pumpWidget(testApp(pie(hole: 0.6, onSelect: picks.add)));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Food, 26%'));
      await tester.pumpAndSettle();
      expect(picks, [1]);
      expect(find.text('KSh 70k'), findsNothing);
      expect(find.text('26%'), findsOneWidget);
      expect(find.text('18k'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Food, 26%')),
          isSemantics(isButton: true, isSelected: true, label: 'Food, 26%'));
      semantics.dispose();
    });

    testWidgets('tapping a slice selects it, clockwise in LTR', (tester) async {
      final picks = <int?>[];
      await tester.pumpWidget(testApp(pie(onSelect: picks.add)));
      await tester.pumpAndSettle();
      final pieRect = tester.getRect(find.byType(CustomPaint).first);
      // Rent is 64%: it covers the right side and the bottom from the top.
      await tester.tapAt(pieRect.center + const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(picks.last, 0);
      // The small slices sit just left of the top.
      await tester.tapAt(pieRect.center + const Offset(-20, -80));
      await tester.pumpAndSettle();
      expect(picks.last, 2);
    });

    testWidgets('slices run counter-clockwise in RTL', (tester) async {
      final picks = <int?>[];
      await tester.pumpWidget(
          testApp(pie(onSelect: picks.add), direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      final pieRect = tester.getRect(find.byType(CustomPaint).first);
      await tester.tapAt(pieRect.center + const Offset(-60, 0));
      await tester.pumpAndSettle();
      expect(picks.last, 0);
      await tester.tapAt(pieRect.center + const Offset(20, -80));
      await tester.pumpAndSettle();
      expect(picks.last, 2);
    });

    testWidgets('legend uses each point\'s own colour', (tester) async {
      await tester.pumpWidget(testApp(pie()));
      await tester.pumpAndSettle();
      final legend =
          tester.widget<KitoChartLegend>(find.byType(KitoChartLegend));
      expect(legend.entries[2].color, const Color(0xFF7C4DFF));
      expect(legend.entries[0].color, KitoChartTheme.defaultPalette[0]);
    });

    testWidgets('reduce motion draws it at once', (tester) async {
      await tester.pumpWidget(testApp(pie(), reduceMotion: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('faux 3D', () {
    testWidgets('3D bars select on tap and turn on drag', (tester) async {
      final semantics = tester.ensureSemantics();
      final picks = <int?>[];
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(testApp(
            Scaffold(
              body: KitoBar3DChart(
                onSelectionChanged: picks.add,
                points: const [
                  KitoChartPoint('Nairobi', 420),
                  KitoChartPoint('Mombasa', 260),
                  KitoChartPoint('Kisumu', 180),
                ],
              ),
            ),
            direction: direction));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Mombasa, 260'));
        await tester.pump();
        await tester.drag(find.byType(KitoBar3DChart), const Offset(80, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(picks, [1, 1]);
      semantics.dispose();
    });

    testWidgets('3D pie spins, selects from the legend, and reads out',
        (tester) async {
      final semantics = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(testApp(
            const Scaffold(
              body: SingleChildScrollView(
                child: KitoPie3DChart(
                  holeFraction: 0.45,
                  points: [
                    KitoChartPoint('Safaricom', 64),
                    KitoChartPoint('Airtel', 31),
                    KitoChartPoint('Telkom', 5),
                  ],
                ),
              ),
            ),
            direction: direction));
        await tester.pumpAndSettle();
        expect(
            find.bySemanticsLabel(
                '3D pie chart, 3 slices: Safaricom 64%, Airtel 31%, Telkom 5%'),
            findsOneWidget);
        await tester.fling(
            find.byType(KitoPie3DChart), const Offset(120, 0), 800);
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Airtel, 31%'));
        await tester.pumpAndSettle();
        expect(
            tester
                .getSemantics(find.bySemanticsLabel(RegExp('^3D pie chart')))
                .value,
            'Airtel, 31%');
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    });
  });

  group('theme and legend', () {
    testWidgets('a scope retints charts and legends are 44 tall when tappable',
        (tester) async {
      final semantics = tester.ensureSemantics();
      late KitoChartTheme resolved;
      await tester.pumpWidget(testApp(KitoChartThemeScope(
        theme: const KitoChartTheme(
            palette: [Colors.teal, Colors.amber], showGridlines: false),
        child: Builder(builder: (context) {
          resolved = KitoChartTheme.of(context);
          return Scaffold(
            body: KitoChartLegend(
              onTap: (_) {},
              entries: const [KitoChartLegendEntry('Tea', Colors.teal)],
            ),
          );
        }),
      )));
      expect(resolved.colorAt(0), Colors.teal);
      expect(resolved.colorAt(3), Colors.amber, reason: 'wraps around');
      expect(resolved.showGridlines, isFalse);
      expect(resolved.gridlineColor, isNotNull);
      expect(tester.getSize(find.bySemanticsLabel('Tea')).height,
          greaterThanOrEqualTo(44));
      semantics.dispose();
    });

    testWidgets('the neon theme gets the neon palette', (tester) async {
      late KitoChartTheme resolved;
      await tester.pumpWidget(MaterialApp(
        theme: KitoTheme.neon.toThemeData(),
        home: Builder(builder: (context) {
          resolved = KitoChartTheme.of(context);
          return const SizedBox();
        }),
      ));
      expect(resolved.palette, KitoChartTheme.neonPalette);
    });
  });
}
