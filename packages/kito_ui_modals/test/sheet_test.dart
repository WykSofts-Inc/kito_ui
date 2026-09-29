// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_modals/kito_ui_modals.dart';

import 'helpers.dart';

void main() {
  group('KitoSheetMath', () {
    test('detents resolve and clamp to the screen', () {
      double r(KitoSheetDetent d,
              {double content = 0,
              double screen = 874,
              double top = 62,
              bool grabber = true}) =>
          KitoSheetMath.resolve(d,
              content: content,
              screen: screen,
              topInset: top,
              grabber: grabber);
      expect(r(KitoSheetDetent.fit, content: 300), 329);
      expect(r(KitoSheetDetent.fit, content: 300, grabber: false), 308);
      expect(r(const KitoSheetDetent.fraction(0.5), screen: 800, top: 0), 400);
      expect(r(const KitoSheetDetent.height(240), screen: 800, top: 0), 240);
      expect(r(KitoSheetDetent.large), 802);
      expect(r(const KitoSheetDetent.height(5000)), 802,
          reason: 'never taller than large');
      expect(r(const KitoSheetDetent.height(10)), 60, reason: 'never a sliver');
      expect(r(const KitoSheetDetent.fraction(0)), 60);
    });

    test('dragging down shrinks one for one', () {
      expect(KitoSheetMath.visibleHeight(current: 400, tallest: 800, drag: 120),
          280);
      expect(KitoSheetMath.visibleHeight(current: 400, tallest: 800, drag: 900),
          0);
    });

    test('dragging up grows freely, then rubber-bands', () {
      expect(
          KitoSheetMath.visibleHeight(current: 400, tallest: 800, drag: -200),
          600);
      final past =
          KitoSheetMath.visibleHeight(current: 800, tallest: 800, drag: -300);
      expect(past, greaterThan(800));
      expect(past, lessThan(800 + 800 * 0.12));
      expect(KitoSheetMath.rubberBand(0, 800), 0);
      expect(KitoSheetMath.rubberBand(10000, 800), lessThan(96));
    });

    test('the nearest detent wins', () {
      expect(KitoSheetMath.nearestDetent(520, [300, 500, 800]), 1);
      expect(KitoSheetMath.nearestDetent(10, [300, 500, 800]), 0);
      expect(KitoSheetMath.nearestDetent(2000, [300, 500, 800]), 2);
    });

    test('settling counts the fling and dismisses low enough', () {
      final heights = [300.0, 800.0];
      expect(
          KitoSheetMath.settle(
              heights: heights, visible: 500, velocity: 0, dismissible: true),
          0);
      expect(
          KitoSheetMath.settle(
              heights: heights,
              visible: 500,
              velocity: -2000,
              dismissible: true),
          1,
          reason: 'an upward fling carries it to the top');
      expect(
          KitoSheetMath.settle(
              heights: heights, visible: 150, velocity: 0, dismissible: true),
          isNull);
      expect(
          KitoSheetMath.settle(
              heights: heights, visible: 150, velocity: 0, dismissible: false),
          0);
      expect(
          KitoSheetMath.settle(
              heights: heights,
              visible: 290,
              velocity: 1500,
              dismissible: true),
          isNull,
          reason: 'a downward fling dismisses');
    });
  });

  group('KitoSheetConfiguration', () {
    test('empty detents fall back to fit', () {
      expect(const KitoSheetConfiguration(detents: []).detents,
          [KitoSheetDetent.fit]);
    });

    test('defaults to fitted; scrollable sets the mode', () {
      expect(const KitoSheetConfiguration().contentMode,
          KitoSheetContentMode.fitted);
      const scrollable =
          KitoSheetConfiguration.scrollable(detents: [KitoSheetDetent.large]);
      expect(scrollable.contentMode, KitoSheetContentMode.scrollable);
      expect(scrollable.detents, [KitoSheetDetent.large]);
      expect(scrollable.copyWith(style: KitoSheetStyle.glass).contentMode,
          KitoSheetContentMode.scrollable);
    });

    test('detents compare by value', () {
      expect(const KitoSheetDetent.fraction(0.5), KitoSheetDetent.medium);
      expect(const KitoSheetDetent.height(200),
          isNot(const KitoSheetDetent.fraction(200)));
      expect(KitoSheetDetent.fit.toString(), 'KitoSheetDetent.fit');
    });
  });

  group('showKitoSheet', () {
    testWidgets('shows content and a tap outside dismisses', (tester) async {
      Future<String?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoSheet<String>(
              context: context,
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      expect(find.text('Body'), findsOneWidget);
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('fit sizes the sheet to its content', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      // 200 content + 21 grabber + 8, so the sheet top sits at 600 - 229.
      expect(
          tester.getTopLeft(find.text('Body')).dy, closeTo(600 - 229 + 21, 1));
    });

    testWidgets('backdrop taps can be turned off', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration:
                  const KitoSheetConfiguration(dismissesOnBackdropTap: false),
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('dragging down dismisses; a short drag springs back',
        (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      final before = tester.getTopLeft(find.text('Body')).dy;
      await tester.drag(find.text('Body'), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Body')).dy, closeTo(before, 1));

      await tester.drag(find.text('Body'), const Offset(0, 180));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('drag to dismiss can be turned off', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration:
                  const KitoSheetConfiguration(dismissesOnDrag: false),
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      await tester.drag(find.text('Body'), const Offset(0, 190));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('dragging up moves to a taller detent', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration: const KitoSheetConfiguration(detents: [
                KitoSheetDetent.height(250),
                KitoSheetDetent.large,
              ]),
              builder: (_) =>
                  const SizedBox(height: 100, child: Text('Body'))));
      expect(
          tester.getTopLeft(find.text('Body')).dy, closeTo(600 - 250 + 21, 1));
      await tester.drag(find.text('Body'), const Offset(0, -250));
      await tester.pumpAndSettle();
      // large = 600 - 0 - 10.
      expect(tester.getTopLeft(find.text('Body')).dy, closeTo(10 + 21, 1));
    });

    testWidgets('content can close the sheet with a result and snap it',
        (tester) async {
      Future<int?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoSheet<int>(
              context: context,
              configuration: const KitoSheetConfiguration(detents: [
                KitoSheetDetent.height(200),
                KitoSheetDetent.height(400),
              ]),
              builder: (context) => Column(children: [
                    TextButton(
                        onPressed: () =>
                            KitoSheetController.of(context).snapTo(1),
                        child: const Text('Grow')),
                    TextButton(
                        onPressed: () =>
                            KitoSheetController.of(context).dismiss(7),
                        child: const Text('Pick')),
                  ])));
      final low = tester.getTopLeft(find.text('Grow')).dy;
      await tester.tap(find.text('Grow'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Grow')).dy, closeTo(low - 200, 1));
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(await result, 7);
    });

    testWidgets('Escape dismisses', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('scrollable content pulls the sheet down from its top',
        (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration: const KitoSheetConfiguration.scrollable(
                  detents: [KitoSheetDetent.height(400)]),
              headerBuilder: (_) =>
                  const SizedBox(height: 40, child: Text('Header')),
              builder: (_) => ListView(children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 50, child: Text('Row $i')),
                  ])));
      expect(find.text('Row 0'), findsOneWidget);

      // Scrolling up scrolls the list, not the sheet.
      final header = tester.getTopLeft(find.text('Header')).dy;
      await tester.drag(find.text('Row 2'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Header')).dy, closeTo(header, 1));
      expect(find.text('Row 0'), findsNothing);

      // Back to the top, then a pull down closes the sheet.
      await tester.drag(find.text('Row 6'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Row 0'), findsOneWidget);
      await tester.drag(find.text('Row 1'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Header'), findsNothing);
    });

    testWidgets('scrollable sheets drag from the header', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration: const KitoSheetConfiguration.scrollable(
                  detents: [KitoSheetDetent.height(400)]),
              headerBuilder: (_) =>
                  const SizedBox(height: 40, child: Text('Header')),
              builder: (_) => ListView(children: const [Text('Row')])));
      await tester.drag(find.text('Header'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Header'), findsNothing);
    });

    testWidgets('pushing up at a low detent grows the sheet first',
        (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration: const KitoSheetConfiguration.scrollable(detents: [
                KitoSheetDetent.height(250),
                KitoSheetDetent.large,
              ]),
              headerBuilder: (_) =>
                  const SizedBox(height: 40, child: Text('Header')),
              builder: (_) => ListView(children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 50, child: Text('Row $i')),
                  ])));
      final before = tester.getTopLeft(find.text('Header')).dy;
      await tester.drag(find.text('Row 0'), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Header')).dy, lessThan(before - 200));
      expect(find.text('Row 0'), findsOneWidget,
          reason: 'the sheet moved, not the list');
    });

    testWidgets('floating and glass styles render', (tester) async {
      for (final style in KitoSheetStyle.values) {
        await pumpLauncher(
            tester,
            (context) => showKitoSheet<void>(
                context: context,
                configuration:
                    KitoSheetConfiguration(style: style, blursBackdrop: true),
                builder: (_) =>
                    SizedBox(height: 120, child: Text(style.name))));
        expect(find.text(style.name), findsOneWidget);
        if (style == KitoSheetStyle.floating) {
          expect(tester.getTopLeft(find.text(style.name)).dx,
              greaterThanOrEqualTo(10));
        }
        await tester.tapAt(const Offset(400, 10));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('reduce motion fades rather than slides', (tester) async {
      await tester.pumpWidget(testApp(
          Builder(
              builder: (context) => TextButton(
                  onPressed: () => showKitoSheet<void>(
                      context: context,
                      builder: (_) =>
                          const SizedBox(height: 200, child: Text('Body'))),
                  child: const Text('Open'))),
          reduceMotion: true));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-way through, the sheet is already in its resting place.
      expect(
          tester.getTopLeft(find.text('Body')).dy, closeTo(600 - 229 + 21, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('announces itself and a dismiss button', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLauncher(
          tester,
          (context) => showKitoSheet<void>(
              context: context,
              configuration:
                  const KitoSheetConfiguration(semanticLabel: 'Filters'),
              builder: (_) =>
                  const SizedBox(height: 200, child: Text('Body'))));
      expect(find.bySemanticsLabel('Filters'), findsOneWidget);
      expect(
          tester.getSemantics(find.bySemanticsLabel('Dismiss')),
          matchesSemantics(
              label: 'Dismiss', isButton: true, hasTapAction: true));
      semantics.dispose();
    });
  });
}
