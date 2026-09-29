// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_loaders/kito_ui_loaders.dart';

void main() {
  group('strings', () {
    tearDown(() => KitoLoaderStrings.provider = null);

    test('every language has every key', () {
      final en = KitoLoaderStrings.bundled['en']!.keys.toSet();
      for (final lang in KitoLoaderStrings.bundled.values) {
        expect(lang.keys.toSet(), en);
      }
    });

    test('lookup, fallback and provider', () {
      expect(
          KitoLoaderStrings.lookup('loading', const Locale('sw')), 'Inapakia');
      expect(KitoLoaderStrings.lookup('typing', const Locale('fr')),
          'En train d’écrire');
      expect(
          KitoLoaderStrings.lookup('loading', const Locale('ja')), 'Loading');
      KitoLoaderStrings.provider = (k, l) => k == 'loading' ? 'Hold on' : null;
      expect(
          KitoLoaderStrings.lookup('loading', const Locale('en')), 'Hold on');
      expect(KitoLoaderStrings.lookup('typing', const Locale('en')), 'Typing');
    });
  });

  group('timing maths', () {
    test('the spinner turns once per period', () {
      const period = Duration(milliseconds: 800);
      expect(KitoLoaderSpinner.angleAt(0, period), 0);
      expect(KitoLoaderSpinner.angleAt(0.4, period), closeTo(math.pi, 1e-9));
      expect(KitoLoaderSpinner.angleAt(0.8, period), closeTo(0, 1e-9));
    });

    test('dots take turns', () {
      for (var t = 0.0; t < 1.5; t += 0.05) {
        for (var i = 0; i < 3; i++) {
          expect(KitoLoaderDots.intensity(t, i), inInclusiveRange(0, 1));
        }
      }
      // At 1/8 of the cycle only the first dot is lit.
      expect(KitoLoaderDots.intensity(0.125, 0), greaterThan(0.8));
      expect(KitoLoaderDots.intensity(0.125, 1), 0);
    });

    test('bars stay between a quarter and full height', () {
      for (var t = 0.0; t < 2; t += 0.03) {
        for (var i = 0; i < 5; i++) {
          expect(KitoLoaderBars.heightAt(t, i), inInclusiveRange(0.25, 1.0001));
        }
      }
    });

    test('wave, ripple and orbit phases', () {
      expect(KitoLoaderWave.liftAt(0, 0), 0);
      expect(KitoLoaderWave.liftAt(0, 1), lessThan(0));
      expect(KitoLoaderRipple.phaseAt(0, 1, 3), closeTo(1 / 3, 1e-9));
      expect(KitoLoaderRipple.phaseAt(1.4, 0, 3), closeTo(0, 1e-9));
      expect(KitoLoaderOrbit.angleAt(0.75), closeTo(math.pi, 1e-9));
    });

    test('typing dots hop one after another, then rest', () {
      expect(KitoLoaderTypingIndicator.lift(0, 0), 0);
      expect(KitoLoaderTypingIndicator.lift(0.216, 0), closeTo(1, 1e-6));
      expect(KitoLoaderTypingIndicator.lift(0.216, 2), 0);
      expect(KitoLoaderTypingIndicator.lift(1.15, 0), 0);
      expect(KitoLoaderTypingIndicator.lift(1.15, 1), 0);
    });

    test('the ECG spikes at the R wave and the heart goes lub-dub', () {
      final peak = List.generate(1000, (i) => i / 1000).reduce((a, b) =>
          KitoLoaderHeartbeat.ecg(a) > KitoLoaderHeartbeat.ecg(b) ? a : b);
      expect(peak, closeTo(0.38, 0.01));
      expect(KitoLoaderHeartbeat.ecg(0.9).abs(), lessThan(0.01));
      expect(KitoLoaderHeartbeat.pulse(0.1), closeTo(1, 0.01));
      expect(KitoLoaderHeartbeat.pulse(0.3), closeTo(0.6, 0.02));
      expect(KitoLoaderHeartbeat.pulse(0.8), lessThan(0.01));
    });
  });

  group('morph', () {
    test('forms have the right corners and radii', () {
      expect(KitoLoaderMorphForm.circle.vertices, isEmpty);
      expect(KitoLoaderMorphForm.triangle.vertices, hasLength(3));
      expect(KitoLoaderMorphForm.star.vertices, hasLength(10));
      expect(KitoLoaderMorphForm.circle.radiusAt(1.2), 1);
      // A flat-topped square touches the unit circle at its corners.
      expect(
          KitoLoaderMorphForm.square.radiusAt(-math.pi / 4), closeTo(1, 1e-6));
      expect(
          KitoLoaderMorphForm.square.radiusAt(0), closeTo(math.sqrt1_2, 1e-6));
    });

    test('each step holds, then flows', () {
      final hold = KitoLoaderMorph.step(0.2, 0.9, 5);
      expect(hold.index, 0);
      expect(hold.progress, 0);
      final mid = KitoLoaderMorph.step(0.9 * 1.675, 0.9, 5);
      expect(mid.index, 1);
      expect(mid.progress, closeTo(0.5, 0.01));
      expect(KitoLoaderMorph.step(0.9 * 5.1, 0.9, 5).index, 0);
      expect(KitoLoaderMorph.step(1, 0.9, 0).index, 0);
    });

    test('blended radius sits between the two forms', () {
      const a = KitoLoaderMorphForm.circle, b = KitoLoaderMorphForm.square;
      final r = KitoLoaderMorph.radius(a, b, 0.5, 0, softness: 0);
      expect(r, closeTo((1 + math.sqrt1_2) / 2, 1e-6));
    });
  });

  group('progress maths', () {
    test('indeterminate segments stay on the track', () {
      for (var p = 0.0; p <= 1; p += 0.01) {
        for (var i = 0; i < 2; i++) {
          final s = KitoLoaderLinearProgress.segment(p, i);
          expect(s.start, inInclusiveRange(0, 1));
          expect(s.end, inInclusiveRange(0, 1));
          expect(s.start, lessThanOrEqualTo(s.end + 1e-9));
        }
      }
      expect(KitoLoaderLinearProgress.segment(0.2, 1), (start: 0.0, end: 0.0));
    });

    test('percent text rounds down and clamps', () {
      expect(KitoLoaderProgressRing.percentText(0.426), '42%');
      expect(KitoLoaderProgressRing.percentText(1.4), '100%');
      expect(KitoLoaderProgressRing.percentText(-1), '0%');
    });

    test('steps clamp and fill', () {
      expect(KitoLoaderStepProgress.clampedStep(-2, 4), 0);
      expect(KitoLoaderStepProgress.clampedStep(9, 4), 4);
      expect(KitoLoaderStepProgress.segmentFill(0, 2, 0.3), 1);
      expect(KitoLoaderStepProgress.segmentFill(2, 2, 0.3), 0.3);
      expect(KitoLoaderStepProgress.segmentFill(3, 2, 0.3), 0);
    });

    test('pull maths', () {
      expect(KitoLoaderPullToRefresh.progress(40, 80), 0.5);
      expect(KitoLoaderPullToRefresh.progress(200, 80), 1);
      expect(KitoLoaderPullToRefresh.progress(10, 0), 1);
      expect(KitoLoaderPullToRefresh.indicatorOffset(0), -44);
      expect(KitoLoaderPullToRefresh.indicatorOffset(100), 16);
    });
  });

  group('skeletons', () {
    test('line widths are stable and hand-set looking', () {
      final values = [
        for (var r = 0; r < 20; r++)
          KitoLoaderSkeletonTemplate.lineFraction(r, 0)
      ];
      for (final v in values) {
        expect(v, inInclusiveRange(0.55, 1));
      }
      expect(values.toSet().length, greaterThan(10));
      expect(KitoLoaderSkeletonTemplate.lineFraction(3, 1),
          KitoLoaderSkeletonTemplate.lineFraction(3, 1));
    });

    test('shimmer band starts and ends off the edges', () {
      expect(KitoLoaderShimmer.offset(0, 300, 100), -100);
      expect(KitoLoaderShimmer.offset(1, 300, 100), 400);
    });

    test('redaction matrix is identity at 0 and flat at 1', () {
      final id = KitoLoaderRedacted.redactionMatrix(Colors.red, 0);
      expect(id, [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
      final flat =
          KitoLoaderRedacted.redactionMatrix(const Color(0xFF808080), 1);
      expect(flat[0], 0);
      expect(flat[4], closeTo(128, 0.5));
      expect(flat[18], 1);
    });
  });

  test('loader styles compare by value', () {
    const a = KitoLoaderStyle(kind: KitoLoaderKind.orbit, size: 30);
    expect(a, const KitoLoaderStyle(kind: KitoLoaderKind.orbit, size: 30));
    expect(a.copyWith(size: 40).size, 40);
    expect(a.copyWith(size: 40).kind, KitoLoaderKind.orbit);
    expect(a.hashCode, a.copyWith().hashCode);
  });
}
