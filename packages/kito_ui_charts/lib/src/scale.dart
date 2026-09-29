// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Maps a value range onto a pixel range. [rangeStart] may be larger than [rangeEnd]: a value
/// axis runs bottom to top, and a right-to-left category axis runs right to left.
@immutable
class KitoChartScale {
  /// Maps [domainMin] to [rangeStart] and [domainMax] to [rangeEnd].
  const KitoChartScale(
      this.domainMin, this.domainMax, this.rangeStart, this.rangeEnd);

  /// The value at [rangeStart].
  final double domainMin;

  /// The value at [rangeEnd].
  final double domainMax;

  /// The pixel for [domainMin].
  final double rangeStart;

  /// The pixel for [domainMax].
  final double rangeEnd;

  /// The pixel for [value].
  double call(double value) {
    final span = domainMax - domainMin;
    if (span == 0) return rangeStart;
    return rangeStart + (value - domainMin) / span * (rangeEnd - rangeStart);
  }

  /// The value at [pixel].
  double invert(double pixel) {
    final span = rangeEnd - rangeStart;
    if (span == 0) return domainMin;
    return domainMin + (pixel - rangeStart) / span * (domainMax - domainMin);
  }
}

/// Human-friendly axis ticks.
abstract final class KitoChartTicks {
  /// A step near `(max - min) / count`, rounded to 1, 2 or 5 × 10ⁿ, so labels read 0, 50, 100
  /// rather than 0, 37.4, 74.8.
  static double niceStep(double min, double max, {int count = 4}) {
    final span = max - min;
    if (span <= 0 || count <= 0) return 1;
    final raw = span / count;
    final magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final normalized = raw / magnitude;
    final nice = normalized < 1.5
        ? 1
        : normalized < 3
            ? 2
            : normalized < 7
                ? 5
                : 10;
    return nice * magnitude;
  }

  /// The ticks between [min] and [max], about [count] of them, on a [niceStep].
  ///
  /// Pass [step] to reuse the step from [niceDomain], so the ticks land on its ends.
  static List<double> nice(double min, double max,
      {int count = 4, double? step}) {
    if (max <= min || count <= 0) return [min];
    step ??= niceStep(min, max, count: count);
    final ticks = <double>[];
    var value = (min / step).floor() * step;
    final epsilon = step * 1e-9;
    while (value <= max + epsilon) {
      if (value >= min - epsilon) ticks.add(_clean(value, step));
      value += step;
    }
    return ticks;
  }

  /// [min]…[max] widened outward to whole [niceStep]s, so bars end under a gridline.
  static (double, double) niceDomain(double min, double max, {int count = 4}) {
    if (max <= min) return (min, min + 1);
    final step = niceStep(min, max, count: count);
    return (
      _clean((min / step).floor() * step, step),
      _clean((max / step).ceil() * step, step)
    );
  }

  static double _clean(double value, double step) {
    final decimals = step >= 1 ? 0 : (-math.log(step) / math.ln10).ceil();
    return double.parse(value.toStringAsFixed(decimals.clamp(0, 12)));
  }
}

/// Default number formats for axes, callouts and slices. Pass your own `valueFormatter` (for
/// example from `intl` or `kito_ui_formatting`) for currencies and locale digits.
abstract final class KitoChartFormat {
  /// 950, 1.2k, 3.4M, 1B: short enough for an axis.
  static String compact(double value) {
    final abs = value.abs();
    String trim(double v) {
      final s = v.toStringAsFixed(v.abs() >= 100 ? 0 : 1);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }

    if (abs >= 1e9) return '${trim(value / 1e9)}B';
    if (abs >= 1e6) return '${trim(value / 1e6)}M';
    if (abs >= 1e3) return '${trim(value / 1e3)}k';
    return plain(value);
  }

  /// Whole numbers without decimals, others with up to two.
  static String plain(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final s = value.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  /// A 0–1 fraction as a whole percentage: 0.237 → 24%.
  static String percent(double fraction) => '${(fraction * 100).round()}%';
}
