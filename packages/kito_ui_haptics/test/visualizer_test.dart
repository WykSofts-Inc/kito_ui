// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_haptics/kito_ui_haptics.dart';

const ms = Duration(milliseconds: 1);

Widget host(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false,
        Locale? locale}) =>
    MaterialApp(
      home: Builder(builder: (context) {
        Widget body = Directionality(
            textDirection: direction,
            child: Scaffold(
                body: Center(child: SizedBox(width: 320, child: child))));
        if (locale != null) {
          body = Localizations.override(
              context: context, locale: locale, child: body);
        }
        return MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: body,
        );
      }),
    );

void main() {
  group('maths', () {
    test('the envelope widens taps and follows buzzes', () {
      final p = KitoHapticPattern('P', [
        KitoHapticEvent.tap(ms * 100, intensity: 0.8),
        KitoHapticEvent.hold(ms * 400, duration: ms * 200, intensity: 0.5),
      ]);
      expect(KitoHapticVisualizer.envelope(p, ms * 100), closeTo(0.8, 1e-9));
      expect(KitoHapticVisualizer.envelope(p, ms * 130), greaterThan(0.3));
      expect(KitoHapticVisualizer.envelope(p, ms * 500), 0.5);
      expect(KitoHapticVisualizer.envelope(p, ms * 300), lessThan(0.01));
    });

    test('sharpness of the loudest event', () {
      final p = KitoHapticPattern('P', [
        KitoHapticEvent.hold(Duration.zero,
            duration: ms * 500, intensity: 0.3, sharpness: 0.1),
        KitoHapticEvent.tap(ms * 200, intensity: 1, sharpness: 0.9),
      ]);
      expect(KitoHapticVisualizer.sharpnessAt(p, ms * 200), 0.9);
      expect(KitoHapticVisualizer.sharpnessAt(p, ms * 400), 0.1);
      expect(
          KitoHapticVisualizer.sharpnessAt(
              KitoHapticPattern('E', const []), Duration.zero),
          0.5);
    });

    test('beats light up under the playhead, then fade', () {
      final tap = KitoHapticEvent.tap(ms * 100);
      expect(KitoHapticVisualizer.litAmount(tap, null), 0);
      expect(KitoHapticVisualizer.litAmount(tap, ms * 50), 0);
      expect(KitoHapticVisualizer.litAmount(tap, ms * 120), 1);
      expect(KitoHapticVisualizer.litAmount(tap, ms * 265), closeTo(0.5, 1e-9));
      expect(KitoHapticVisualizer.litAmount(tap, ms * 800), 0);
    });

    test('the timeline has breathing room and a minimum', () {
      expect(KitoHapticVisualizer.timelineLength(KitoHapticPattern.knock),
          greaterThan(KitoHapticPattern.knock.duration));
      expect(
          KitoHapticVisualizer.timelineLength(KitoHapticPattern('E', const [])),
          ms * 100);
    });
  });

  testWidgets('draws every preset in both styles, LTR and RTL', (tester) async {
    for (final p in KitoHapticPattern.presets) {
      for (final style in KitoHapticVisualizerStyle.values) {
        for (final dir in TextDirection.values) {
          await tester.pumpWidget(host(
              KitoHapticVisualizer(p, style: style, playedAt: DateTime.now()),
              direction: dir));
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('describes the pattern to screen readers, localised',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester
        .pumpWidget(host(KitoHapticVisualizer(KitoHapticPattern.heartbeat)));
    expect(
      tester.getSemantics(find.byType(KitoHapticVisualizer)),
      matchesSemantics(
          label: 'Heartbeat haptic pattern', value: '4 beats over 1.0 seconds'),
    );
    await tester.pumpWidget(host(KitoHapticVisualizer(KitoHapticPattern.knock),
        locale: const Locale('sw')));
    expect(tester.getSemantics(find.byType(KitoHapticVisualizer)).label,
        'Mtetemo wa Knock');
    handle.dispose();
  });

  testWidgets('the playhead animates only while it is on screen',
      (tester) async {
    await tester
        .pumpWidget(host(KitoHapticVisualizer(KitoHapticPattern.knock)));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(host(KitoHapticVisualizer(KitoHapticPattern.knock,
        playedAt: DateTime.now())));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    // Stops once the playhead has passed the end.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, 0);

    // An old playedAt draws no playhead and doesn't tick.
    await tester.pumpWidget(host(KitoHapticVisualizer(KitoHapticPattern.knock,
        playedAt: DateTime.now().subtract(const Duration(seconds: 10)))));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('keeps its height and fills the width', (tester) async {
    await tester.pumpWidget(host(
        KitoHapticVisualizer(KitoHapticPattern.rumble, height: 90),
        reduceMotion: true));
    expect(
        tester.getSize(find.byType(KitoHapticVisualizer)), const Size(320, 90));
  });
}
