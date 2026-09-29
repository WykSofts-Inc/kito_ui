// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'data.dart';
import 'line_style.dart';

/// One pie or donut slice, in radians on screen (0 points right, angles grow clockwise).
@immutable
class KitoPieSlice {
  /// Creates a slice.
  const KitoPieSlice(
      {required this.index,
      required this.startAngle,
      required this.sweepAngle,
      required this.fraction});

  /// The point this slice draws.
  final int index;

  /// Where the slice starts.
  final double startAngle;

  /// How far it runs; negative runs counter-clockwise (right-to-left layouts).
  final double sweepAngle;

  /// Its share of the total, 0–1.
  final double fraction;

  /// The angle through the middle of the slice.
  double get midAngle => startAngle + sweepAngle / 2;
}

/// The pure geometry behind the charts, kept out of the widgets so it can be tested and reused.
abstract final class KitoChartMath {
  /// The value range a line chart plots: every series, stretched to include each reference
  /// line and, when asked, zero. Never empty.
  static (double, double) lineDomain(
    List<KitoChartSeries> series, {
    List<KitoChartReferenceLine> referenceLines = const [],
    bool includesZero = false,
  }) {
    var lower = double.infinity, upper = double.negativeInfinity;
    for (final s in series) {
      for (final p in s.points) {
        lower = math.min(lower, p.value);
        upper = math.max(upper, p.value);
      }
    }
    for (final line in referenceLines) {
      lower = math.min(lower, line.value);
      upper = math.max(upper, line.value);
    }
    if (includesZero) {
      lower = math.min(lower, 0);
      upper = math.max(upper, 0);
    }
    if (!lower.isFinite || !upper.isFinite) return (0, 1);
    return lower == upper ? (lower - 1, upper + 1) : (lower, upper);
  }

  /// The line through [points] joined by [interpolation].
  static Path linePath(
      List<Offset> points, KitoLineInterpolation interpolation) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      switch (interpolation) {
        case KitoLineInterpolation.linear:
          path.lineTo(current.dx, current.dy);
        case KitoLineInterpolation.smooth:
          final midX = (previous.dx + current.dx) / 2;
          path.cubicTo(
              midX, previous.dy, midX, current.dy, current.dx, current.dy);
        case KitoLineInterpolation.catmullRom:
          final before = points[math.max(i - 2, 0)];
          final after = points[math.min(i + 1, points.length - 1)];
          path.cubicTo(
            previous.dx + (current.dx - before.dx) / 6,
            previous.dy + (current.dy - before.dy) / 6,
            current.dx - (after.dx - previous.dx) / 6,
            current.dy - (after.dy - previous.dy) / 6,
            current.dx,
            current.dy,
          );
        case KitoLineInterpolation.stepped:
          path
            ..lineTo(current.dx, previous.dy)
            ..lineTo(current.dx, current.dy);
      }
    }
    return path;
  }

  /// The line closed down to [baselineY], for an area fill.
  static Path areaPath(List<Offset> points, KitoLineInterpolation interpolation,
      double baselineY) {
    if (points.length < 2) return Path();
    return linePath(points, interpolation)
      ..lineTo(points.last.dx, baselineY)
      ..lineTo(points.first.dx, baselineY)
      ..close();
  }

  /// Which of [count] evenly spaced labels across [width] get drawn: all of them when they fit
  /// [minSpacing] apart, otherwise every nth, always keeping the last so the latest period is
  /// labelled.
  static List<int> labelIndices(int count, double width,
      {double minSpacing = 34}) {
    if (count <= 0) return const [];
    if (count == 1 || width <= 0) return const [0];
    final spacing = width / (count - 1);
    final stride = math.max((minSpacing / spacing).ceil(), 1);
    final indices = [for (var i = 0; i < count; i += stride) i];
    if (indices.last != count - 1) {
      if ((count - 1 - indices.last) * spacing < minSpacing &&
          indices.length > 1) {
        indices.removeLast();
      }
      indices.add(count - 1);
    }
    return indices;
  }

  /// The x of point [index] of [count] spread across [plot]: from the left edge, or from the
  /// right when [rtl], so time runs with the reading direction.
  static double indexX(int index, int count, Rect plot, {bool rtl = false}) {
    final t = count <= 1 ? 0.5 : index / (count - 1);
    return rtl ? plot.right - t * plot.width : plot.left + t * plot.width;
  }

  /// The point nearest [dx] (a physical, left-to-right position) on a [count]-point axis
  /// across [plot], mirrored when [rtl].
  static int nearestIndex(double dx, int count, Rect plot, {bool rtl = false}) {
    if (count <= 1 || plot.width <= 0) return 0;
    var t = ((dx - plot.left) / plot.width).clamp(0.0, 1.0);
    if (rtl) t = 1 - t;
    return (t * (count - 1)).round().clamp(0, count - 1);
  }

  /// The slices for [values], starting at [startAngle] (the top by default) and running
  /// clockwise, or counter-clockwise when [clockwise] is false. Negative values count as zero.
  static List<KitoPieSlice> pieSlices(List<double> values,
      {double startAngle = -math.pi / 2, bool clockwise = true}) {
    final total = values.fold<double>(0, (sum, v) => sum + math.max(v, 0));
    if (total <= 0) return const [];
    final direction = clockwise ? 1.0 : -1.0;
    var angle = startAngle;
    return [
      for (var i = 0; i < values.length; i++)
        () {
          final fraction = math.max(values[i], 0) / total;
          final sweep = fraction * 2 * math.pi * direction;
          final slice = KitoPieSlice(
              index: i,
              startAngle: angle,
              sweepAngle: sweep,
              fraction: fraction);
          angle += sweep;
          return slice;
        }(),
    ];
  }

  /// The index of the slice under [position], or null outside the ring between
  /// [innerRadius] and [outerRadius] around [center].
  static int? pieSliceAt(
      Offset position, Offset center, List<KitoPieSlice> slices,
      {required double outerRadius, double innerRadius = 0}) {
    final delta = position - center;
    final distance = delta.distance;
    if (distance > outerRadius || distance < innerRadius) return null;
    final angle = math.atan2(delta.dy, delta.dx);
    for (final slice in slices) {
      if (slice.sweepAngle == 0) continue;
      var offset = (angle - slice.startAngle) * slice.sweepAngle.sign;
      offset %= 2 * math.pi;
      if (offset <= slice.sweepAngle.abs()) return slice.index;
    }
    return null;
  }
}
