// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_haptics/kito_ui_haptics.dart';

const ms = Duration(milliseconds: 1);

/// Records each platform haptic with the fake-clock time it fired at.
class Recorder {
  Recorder(this.tester) : start = tester.binding.clock.now() {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add((
          tester.binding.clock.now().difference(start),
          (call.arguments as String?)
                  ?.replaceFirst('HapticFeedbackType.', '') ??
              'vibrate'
        ));
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  final WidgetTester tester;
  final DateTime start;
  final calls = <(Duration, String)>[];

  Future<void> advance(Duration d,
      {Duration step = const Duration(milliseconds: 10)}) async {
    var left = d;
    while (left > Duration.zero) {
      final s = left < step ? left : step;
      await tester.pump(s);
      left -= s;
    }
  }

  List<String> get kinds => [for (final c in calls) c.$2];
}

void main() {
  tearDown(() {
    KitoHaptics.stop();
    KitoHaptics.isEnabled = true;
  });

  group('events', () {
    test('taps clamp and decay', () {
      final tap = KitoHapticEvent.tap(-ms * 5, intensity: 3, sharpness: -1);
      expect(tap.at, Duration.zero);
      expect(tap.intensity, 1);
      expect(tap.sharpness, 0);
      expect(tap.length, KitoHapticEvent.transientLength);
      expect(tap.intensityAt(Duration.zero), 1);
      expect(tap.intensityAt(ms * 20), closeTo(0.5, 1e-9));
      expect(tap.intensityAt(ms * 50), 0);
    });

    test('holds ramp and have a minimum length', () {
      final ramp = KitoHapticEvent.hold(ms * 100,
          duration: ms * 200, intensity: 0.2, endIntensity: 1);
      expect(ramp.end, ms * 300);
      expect(ramp.intensityAt(ms * 50), 0);
      expect(ramp.intensityAt(ms * 200), closeTo(0.6, 1e-9));
      expect(ramp.intensityAt(ms * 300), closeTo(1, 1e-9));
      final steady = KitoHapticEvent.hold(Duration.zero,
          duration: ms * 100, intensity: 0.4);
      expect(steady.intensityAt(ms * 70), 0.4);
      expect(
          KitoHapticEvent.hold(Duration.zero, duration: Duration.zero).length,
          ms * 10);
    });

    test('equality and shifting', () {
      final a = KitoHapticEvent.tap(ms * 10, intensity: 0.5);
      expect(a, KitoHapticEvent.tap(ms * 10, intensity: 0.5));
      final moved = a.shifted(ms * 90, factor: 0.5);
      expect(moved.at, ms * 100);
      expect(moved.intensity, 0.25);
    });
  });

  group('patterns', () {
    test('events sort and the duration is the last end', () {
      final p = KitoHapticPattern('P', [
        KitoHapticEvent.tap(ms * 300),
        KitoHapticEvent.hold(Duration.zero, duration: ms * 500),
      ]);
      expect(p.events.first.isTransient, isFalse);
      expect(p.duration, ms * 500);
      expect(p.intensityAt(ms * 300), 1);
      expect(() => p.events.add(KitoHapticEvent.tap(Duration.zero)),
          throwsUnsupportedError);
    });

    test('samples, repeats and scaling', () {
      final p = KitoHapticPattern.knock;
      final s = p.samples(50);
      expect(s, hasLength(50));
      expect(s.first, 1);
      expect(KitoHapticPattern('Empty', const []).samples(3), [0, 0, 0]);

      final twice = p.repeated(2, gap: ms * 100);
      expect(twice.events, hasLength(4));
      expect(twice.events[2].at, p.duration + ms * 100);
      expect(p.repeated(1), p);

      final soft = p.scaled(0.5);
      expect(soft.events.first.intensity, 0.5);
      expect(soft.name, p.name);
    });

    test('presets are distinct and non-empty', () {
      expect(KitoHapticPattern.presets, hasLength(9));
      expect(
          KitoHapticPattern.presets.map((p) => p.name).toSet(), hasLength(9));
      for (final p in KitoHapticPattern.presets) {
        expect(p.events, isNotEmpty);
        expect(p.duration, greaterThan(Duration.zero));
      }
      expect(KitoHapticPattern.ticksOf(0, ms * 50).events, hasLength(1));
      expect(KitoHapticPattern.ticksOf(12, ms * 50).duration,
          ms * 550 + KitoHapticEvent.transientLength);
    });

    test('impacts: one per tap, one per interval through a buzz', () {
      final p = KitoHapticPattern('Mix', [
        KitoHapticEvent.tap(Duration.zero, intensity: 1, sharpness: 0.3),
        KitoHapticEvent.hold(ms * 100, duration: ms * 300, intensity: 0.5),
      ]);
      final impacts = p.impacts(buzzInterval: ms * 100);
      expect(impacts.map((i) => i.at),
          [Duration.zero, ms * 100, ms * 200, ms * 300]);
      expect(impacts.first.style, KitoHapticImpactStyle.heavy);
      expect(impacts[1].style, KitoHapticImpactStyle.medium);

      // A fade to nothing drops its faintest steps.
      final fade = KitoHapticPattern.rampDown.impacts();
      expect(fade.every((i) => i.intensity > 0.02), isTrue);
      final times = fade.map((i) => i.at).toList();
      expect(times, [...times]..sort());
    });

    test('impact styles follow strength and crispness', () {
      expect(KitoHapticImpactStyle.forEvent(0.5, 1),
          KitoHapticImpactStyle.selection);
      expect(KitoHapticImpactStyle.forEvent(0.2, 0.2),
          KitoHapticImpactStyle.light);
      expect(KitoHapticImpactStyle.forEvent(0.6, 0.5),
          KitoHapticImpactStyle.medium);
      expect(KitoHapticImpactStyle.forEvent(0.9, 0.9),
          KitoHapticImpactStyle.heavy);
    });
  });

  group('playing', () {
    testWidgets('plays each impact at its moment', (tester) async {
      final rec = Recorder(tester);
      var finished = false;
      KitoHaptics.play(KitoHapticPattern.heartbeat)
          .then((_) => finished = true);
      expect(KitoHaptics.isPlaying, isTrue);
      expect(rec.calls, hasLength(1), reason: 'the first beat fires at once');
      await rec.advance(ms * 1000);
      expect(rec.calls.map((c) => c.$1.inMilliseconds), [0, 140, 800, 940]);
      expect(rec.kinds,
          ['heavyImpact', 'mediumImpact', 'heavyImpact', 'mediumImpact']);
      expect(finished, isTrue);
      expect(KitoHaptics.isPlaying, isFalse);
    });

    testWidgets('stop cancels the rest, and a new pattern replaces the old',
        (tester) async {
      final rec = Recorder(tester);
      KitoHaptics.play(KitoHapticPattern.ticks);
      await rec.advance(ms * 100);
      final before = rec.calls.length;
      KitoHaptics.stop();
      await rec.advance(ms * 600);
      expect(rec.calls.length, before);

      KitoHaptics.play(KitoHapticPattern.heartbeat);
      await rec.advance(ms * 100);
      KitoHaptics.play(KitoHapticPattern.knock);
      await rec.advance(ms * 1000);
      // Heartbeat's first beat, then knock's two — nothing more from the heartbeat.
      expect(rec.calls.length, before + 3);
    });

    testWidgets('the switch silences everything', (tester) async {
      final rec = Recorder(tester);
      KitoHaptics.isEnabled = false;
      await KitoHaptics.success();
      await KitoHaptics.selection();
      await KitoHaptics.impact();
      KitoHaptics.play(KitoHapticPattern.rumble);
      await rec.advance(ms * 1000);
      expect(rec.calls, isEmpty);
    });

    testWidgets('semantic haptics', (tester) async {
      final rec = Recorder(tester);
      KitoHaptics.success();
      await rec.advance(ms * 300);
      expect(rec.kinds, ['lightImpact', 'mediumImpact']);
      rec.calls.clear();
      KitoHaptics.warning();
      await rec.advance(ms * 300);
      expect(rec.kinds, ['mediumImpact', 'mediumImpact']);
      rec.calls.clear();
      KitoHaptics.error();
      await rec.advance(ms * 300);
      expect(rec.kinds, ['heavyImpact', 'heavyImpact', 'heavyImpact']);
      rec.calls.clear();
      await KitoHaptics.selection();
      await KitoHaptics.impact(KitoHapticImpactStyle.light);
      await KitoHaptics.impact(KitoHapticImpactStyle.vibrate);
      expect(rec.kinds, ['selectionClick', 'lightImpact', 'vibrate']);
    });
  });

  group('on change', () {
    testWidgets('fires when the value changes, not on first build',
        (tester) async {
      final rec = Recorder(tester);
      Widget build(int v, {bool Function(int, int)? when}) =>
          KitoHapticOnChange<int>(
              value: v, when: when, child: const SizedBox());
      await tester.pumpWidget(build(0));
      expect(rec.calls, isEmpty);
      await tester.pumpWidget(build(1));
      expect(rec.kinds, ['selectionClick']);
      await tester.pumpWidget(build(1));
      expect(rec.calls, hasLength(1));
      await tester.pumpWidget(build(0, when: (a, b) => b > a));
      expect(rec.calls, hasLength(1), reason: 'filtered out');
    });

    testWidgets('plays a pattern or a haptic', (tester) async {
      final rec = Recorder(tester);
      await tester.pumpWidget(KitoHapticOnChange(
          value: false,
          pattern: KitoHapticPattern.knock,
          child: const SizedBox()));
      await tester.pumpWidget(KitoHapticOnChange(
          value: true,
          pattern: KitoHapticPattern.knock,
          child: const SizedBox()));
      await rec.advance(ms * 300);
      expect(rec.calls, hasLength(2));
      await tester.pumpWidget(const KitoHapticOnChange(
          value: false, haptic: KitoHaptics.error, child: SizedBox()));
      await rec.advance(ms * 300);
      expect(rec.calls, hasLength(5));
    });
  });
}
