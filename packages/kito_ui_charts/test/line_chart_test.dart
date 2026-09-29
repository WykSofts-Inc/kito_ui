// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_charts/kito_ui_charts.dart';

import 'helpers.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

Widget _chart({
  ValueChanged<int?>? onSelect,
  KitoLineChartStyle style = const KitoLineChartStyle(),
  List<KitoChartSeries>? series,
}) =>
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: KitoLineChart(
          series: series ??
              [
                KitoChartSeries.values('Sales', [120, 200, 150, 260, 240],
                    labels: _days),
              ],
          style: style,
          onSelectionChanged: onSelect,
        ),
      ),
    );

void main() {
  testWidgets('summarises itself for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(testApp(_chart()));
    await tester.pumpAndSettle();
    expect(
        find.bySemanticsLabel('Line chart, 5 points, from Mon 120 to Fri 240'),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('scrubbing reports the nearest point and shows a callout',
      (tester) async {
    final picks = <int?>[];
    await tester.pumpWidget(testApp(_chart(onSelect: picks.add)));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(KitoLineChart));
    final gesture =
        await tester.startGesture(rect.centerRight - const Offset(4, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    expect(picks.last, 4);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('240'), findsOneWidget);
    await gesture.moveTo(rect.centerLeft + const Offset(60, 0));
    await tester.pump();
    expect(picks.last, 0);
    expect(find.text('Mon'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(picks.last, isNull);
  });

  testWidgets(
      'in RTL time runs from the right and scrubbing follows the finger',
      (tester) async {
    final picks = <int?>[];
    await tester.pumpWidget(
        testApp(_chart(onSelect: picks.add), direction: TextDirection.rtl));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(KitoLineChart));
    final gesture =
        await tester.startGesture(rect.centerRight - const Offset(50, 0));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveTo(rect.centerRight - const Offset(8, 0));
    await tester.pump();
    expect(picks.last, 0, reason: 'the right edge is the first point in RTL');
    await gesture.moveTo(rect.centerLeft + const Offset(8, 0));
    await tester.pump();
    expect(picks.last, 4);
    await gesture.up();
  });

  testWidgets('a tap pins the callout until tapped again', (tester) async {
    final picks = <int?>[];
    await tester.pumpWidget(testApp(_chart(onSelect: picks.add)));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(KitoLineChart));
    await tester.tapAt(rect.centerRight - const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(picks.last, 4);
    expect(find.text('Fri'), findsOneWidget);
    await tester.tapAt(rect.centerRight - const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(picks.last, isNull);
  });

  testWidgets('screen readers step through points', (tester) async {
    final semantics = tester.ensureSemantics();
    final picks = <int?>[];
    await tester.pumpWidget(testApp(_chart(onSelect: picks.add)));
    await tester.pumpAndSettle();
    final node =
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Line chart')));
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(picks.last, 0);
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(picks.last, 1);
    expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Line chart'))).value,
        'Tue: 200');
    semantics.dispose();
  });

  testWidgets('multiple series get a legend and a multi-row callout',
      (tester) async {
    await tester.pumpWidget(testApp(_chart(series: [
      KitoChartSeries.values('Nairobi', [1, 2, 3], labels: _days),
      KitoChartSeries.values('Mombasa', [3, 2, 1], labels: _days),
    ])));
    await tester.pumpAndSettle();
    expect(find.byType(KitoChartLegend), findsOneWidget);
    final rect = tester.getRect(find.byType(CustomPaint).last);
    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();
    expect(find.text('Nairobi'), findsNWidgets(2));
    expect(find.text('Mombasa'), findsNWidgets(2));
  });

  testWidgets('reduce motion skips the reveal and the live pulse',
      (tester) async {
    await tester.pumpWidget(testApp(
        _chart(
            style:
                const KitoLineChartStyle(points: KitoLinePointStyle.lastPoint)),
        reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the live point pulses with motion on', (tester) async {
    await tester.pumpWidget(testApp(_chart(
        style:
            const KitoLineChartStyle(points: KitoLinePointStyle.lastPoint))));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('every style paints in both directions', (tester) async {
    for (final direction in TextDirection.values) {
      for (final interpolation in KitoLineInterpolation.values) {
        for (final points in KitoLinePointStyle.values) {
          await tester.pumpWidget(testApp(
              _chart(
                  style: KitoLineChartStyle(
                interpolation: interpolation,
                points: points,
                area: const KitoLineAreaFill.gradient(),
                dash: const [6, 3],
                glows: true,
                strokeGradient: const [Colors.teal, Colors.purple],
                showsLabels: true,
                showsValues: true,
                includesZero: true,
                referenceLines: const [KitoChartReferenceLine('Goal', 250)],
              )),
              direction: direction));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('changing data morphs, and empty data is safe', (tester) async {
    await tester.pumpWidget(testApp(_chart()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(testApp(_chart(series: [
      KitoChartSeries.values('Sales', [10, 20, 30, 40, 50], labels: _days)
    ])));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await tester.pumpWidget(testApp(_chart(series: const [])));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('sparklines colour by trend and describe it', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(testApp(const Scaffold(
      body: Column(children: [
        SizedBox(
            width: 90, child: KitoSparkline([1, 3, 2, 5], trendColors: true)),
        SizedBox(width: 90, child: KitoSparkline([5, 3], trendColors: true)),
      ]),
    )));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Trend up, from 1 to 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Trend down, from 5 to 3'), findsOneWidget);
    expect(tester.getSize(find.byType(KitoSparkline).first).height, 36);
    semantics.dispose();
  });
}
