// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_charts/kito_ui_charts.dart';

void main() {
  group('KitoChartTicks', () {
    test('rounds to human steps', () {
      expect(KitoChartTicks.nice(0, 137), [0, 50, 100]);
      expect(KitoChartTicks.nice(0, 1), [0, 0.2, 0.4, 0.6, 0.8, 1]);
      expect(KitoChartTicks.nice(170, 180), [170, 172, 174, 176, 178, 180]);
      expect(KitoChartTicks.niceStep(0, 4200), 1000);
    });

    test('widens a domain to whole steps', () {
      expect(KitoChartTicks.niceDomain(0, 137), (0, 150));
      expect(KitoChartTicks.niceDomain(-12, 40), (-20, 40));
      expect(KitoChartTicks.niceDomain(5, 5), (5, 6));
    });

    test('an empty or reversed range gives one tick', () {
      expect(KitoChartTicks.nice(3, 3), [3]);
    });
  });

  group('KitoChartScale', () {
    test('maps and inverts, including reversed ranges', () {
      const y = KitoChartScale(0, 100, 200, 0);
      expect(y(0), 200);
      expect(y(100), 0);
      expect(y(25), 150);
      expect(y.invert(150), 25);
      const flat = KitoChartScale(4, 4, 10, 20);
      expect(flat(4), 10);
    });
  });

  group('KitoChartFormat', () {
    test('compact', () {
      expect(KitoChartFormat.compact(950), '950');
      expect(KitoChartFormat.compact(1200), '1.2k');
      expect(KitoChartFormat.compact(45000), '45k');
      expect(KitoChartFormat.compact(3400000), '3.4M');
      expect(KitoChartFormat.compact(2e9), '2B');
      expect(KitoChartFormat.compact(-1500), '-1.5k');
      expect(KitoChartFormat.compact(12.5), '12.5');
    });

    test('plain and percent', () {
      expect(KitoChartFormat.plain(3), '3');
      expect(KitoChartFormat.plain(3.10), '3.1');
      expect(KitoChartFormat.percent(0.237), '24%');
    });
  });

  group('KitoChartMath.lineDomain', () {
    final series = [
      KitoChartSeries.values('a', [170, 175, 180])
    ];

    test('spans the data', () {
      expect(KitoChartMath.lineDomain(series), (170, 180));
    });

    test('stretches to reference lines and zero', () {
      expect(
          KitoChartMath.lineDomain(series,
              referenceLines: const [KitoChartReferenceLine('Goal', 200)]),
          (170, 200));
      expect(KitoChartMath.lineDomain(series, includesZero: true), (0, 180));
    });

    test('never collapses', () {
      expect(
          KitoChartMath.lineDomain([
            KitoChartSeries.values('a', [5, 5])
          ]),
          (4, 6));
      expect(KitoChartMath.lineDomain(const []), (0, 1));
    });
  });

  group('paths', () {
    const points = [Offset(0, 10), Offset(10, 0), Offset(20, 10)];

    test('every interpolation passes through the ends', () {
      for (final i in KitoLineInterpolation.values) {
        final bounds = KitoChartMath.linePath(points, i).getBounds();
        expect(bounds.left, 0, reason: i.name);
        expect(bounds.right, 20, reason: i.name);
      }
    });

    test('smooth never overshoots a peak; stepped holds values', () {
      final smooth =
          KitoChartMath.linePath(points, KitoLineInterpolation.smooth);
      expect(smooth.getBounds().top, closeTo(0, 0.01));
      final stepped =
          KitoChartMath.linePath(points, KitoLineInterpolation.stepped);
      final length =
          stepped.computeMetrics().fold<double>(0, (sum, m) => sum + m.length);
      expect(length, 40, reason: 'across, up, across, down');
      expect(stepped.getBounds(), const Rect.fromLTRB(0, 0, 20, 10));
    });

    test('area closes to the baseline', () {
      final area =
          KitoChartMath.areaPath(points, KitoLineInterpolation.linear, 30);
      expect(area.getBounds().bottom, 30);
      expect(area.contains(const Offset(10, 20)), isTrue);
      expect(
          KitoChartMath.areaPath(
                  const [Offset.zero], KitoLineInterpolation.linear, 30)
              .getBounds(),
          Rect.zero);
    });
  });

  group('labels and scrubbing', () {
    test('all labels when they fit', () {
      expect(KitoChartMath.labelIndices(5, 400), [0, 1, 2, 3, 4]);
    });

    test('thins crowded labels but keeps the last', () {
      final indices = KitoChartMath.labelIndices(30, 300);
      expect(indices.first, 0);
      expect(indices.last, 29);
      for (var i = 1; i < indices.length; i++) {
        expect((indices[i] - indices[i - 1]) * 300 / 29,
            greaterThanOrEqualTo(34 - 1e-9));
      }
    });

    test('time runs right to left in RTL', () {
      const plot = Rect.fromLTRB(0, 0, 100, 50);
      expect(KitoChartMath.indexX(0, 5, plot), 0);
      expect(KitoChartMath.indexX(0, 5, plot, rtl: true), 100);
      expect(KitoChartMath.indexX(4, 5, plot, rtl: true), 0);
      expect(KitoChartMath.indexX(0, 1, plot), 50);
    });

    test('the finger maps to the nearest point in both directions', () {
      const plot = Rect.fromLTRB(20, 0, 120, 50);
      expect(KitoChartMath.nearestIndex(20, 5, plot), 0);
      expect(KitoChartMath.nearestIndex(118, 5, plot), 4);
      expect(KitoChartMath.nearestIndex(46, 5, plot), 1);
      expect(KitoChartMath.nearestIndex(118, 5, plot, rtl: true), 0);
      expect(KitoChartMath.nearestIndex(20, 5, plot, rtl: true), 4);
      expect(KitoChartMath.nearestIndex(-500, 5, plot), 0);
    });
  });

  group('pie slices', () {
    test('share the circle', () {
      final slices = KitoChartMath.pieSlices([1, 1, 2]);
      expect(slices.map((s) => s.fraction), [0.25, 0.25, 0.5]);
      expect(slices.first.startAngle, -math.pi / 2);
      final total = slices.fold<double>(0, (t, s) => t + s.sweepAngle);
      expect(total, closeTo(2 * math.pi, 1e-9));
      expect(KitoChartMath.pieSlices([0, 0]), isEmpty);
      expect(KitoChartMath.pieSlices([-3, 1]).first.fraction, 0);
    });

    test('run counter-clockwise when asked', () {
      final slices = KitoChartMath.pieSlices([1, 1], clockwise: false);
      expect(slices.first.sweepAngle, -math.pi);
    });

    test('hit-test by angle and radius', () {
      const c = Offset(100, 100);
      final cw = KitoChartMath.pieSlices([1, 3]);
      // Top right is the first quarter, clockwise from the top.
      expect(
          KitoChartMath.pieSliceAt(const Offset(130, 70), c, cw,
              outerRadius: 80),
          0);
      expect(
          KitoChartMath.pieSliceAt(const Offset(70, 70), c, cw,
              outerRadius: 80),
          1);
      // Counter-clockwise, the first slice is top left.
      final ccw = KitoChartMath.pieSlices([1, 3], clockwise: false);
      expect(
          KitoChartMath.pieSliceAt(const Offset(70, 70), c, ccw,
              outerRadius: 80),
          0);
      // Outside the ring or in the hole.
      expect(
          KitoChartMath.pieSliceAt(const Offset(300, 300), c, cw,
              outerRadius: 80),
          isNull);
      expect(
          KitoChartMath.pieSliceAt(const Offset(102, 98), c, cw,
              outerRadius: 80, innerRadius: 40),
          isNull);
    });
  });

  test('series from values', () {
    final s = KitoChartSeries.values('Sales', [1, 2], labels: ['Jan']);
    expect(s.points.map((p) => p.label), ['Jan', '2']);
    expect(s.values, [1, 2]);
    expect(s, KitoChartSeries.values('Sales', [1, 2], labels: ['Jan']));
  });
}
