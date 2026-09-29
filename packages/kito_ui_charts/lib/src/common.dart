// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Turns a value into the text shown on axes, callouts and value labels.
typedef KitoChartValueFormatter = String Function(double value);

/// The entrance and data-change animation every chart shares: a 0→1 [reveal] when the chart
/// first appears, and a [morph] from the old values to the new ones when the data changes
/// shape-for-shape (same number of series and points). Anything else re-reveals.
class ChartMotion {
  /// Creates the controllers on [vsync].
  ChartMotion(TickerProvider vsync,
      {required Duration duration, required List<List<double>> values})
      : reveal = AnimationController(vsync: vsync, duration: duration),
        morph = AnimationController(vsync: vsync, duration: duration),
        _from = values,
        _to = values;

  /// The entrance, 0 → 1.
  final AnimationController reveal;

  /// Old values → new values, 0 → 1.
  final AnimationController morph;

  List<List<double>> _from;
  List<List<double>> _to;

  /// Repaints on either animation.
  Listenable get listenable => Listenable.merge([reveal, morph]);

  /// Plays the entrance, or jumps to the end when [animate] is false.
  void start({required bool animate, required Duration duration}) {
    reveal.duration = duration;
    morph.value = 1;
    if (animate) {
      reveal.forward(from: 0);
    } else {
      reveal.value = 1;
    }
  }

  /// Moves to [next], morphing when the shape matches and [animate] is true.
  void update(List<List<double>> next,
      {required bool animate, required Duration duration}) {
    if (_sameValues(next, _to)) return;
    final sameShape = next.length == _to.length &&
        [for (var i = 0; i < next.length; i++) next[i].length == _to[i].length]
            .every((same) => same);
    if (sameShape) {
      _from = current;
      _to = next;
      morph.duration = duration;
      if (animate) {
        morph.forward(from: 0);
      } else {
        morph.value = 1;
      }
    } else {
      _from = next;
      _to = next;
      start(animate: animate, duration: duration);
    }
  }

  /// The values to draw right now.
  List<List<double>> get current {
    final t = Curves.easeInOutCubic.transform(morph.value);
    if (t >= 1) return _to;
    return [
      for (var s = 0; s < _to.length; s++)
        [
          for (var i = 0; i < _to[s].length; i++)
            lerpDouble(_from[s][i], _to[s][i], t)!
        ]
    ];
  }

  /// Stops both controllers.
  void dispose() {
    reveal.dispose();
    morph.dispose();
  }

  static bool _sameValues(List<List<double>> a, List<List<double>> b) {
    if (a.length != b.length) return false;
    for (var s = 0; s < a.length; s++) {
      if (a[s].length != b[s].length) return false;
      for (var i = 0; i < a[s].length; i++) {
        if (a[s][i] != b[s][i]) return false;
      }
    }
    return true;
  }
}

/// Lays out [text] and paints it with its [alignment] point at [anchor]; returns where it went.
Rect paintChartLabel(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset anchor, {
  Alignment alignment = Alignment.center,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
  Color? background,
  EdgeInsets padding = EdgeInsets.zero,
  double? maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  final size = Size(
      painter.width + padding.horizontal, painter.height + padding.vertical);
  final topLeft = anchor - alignment.alongSize(size);
  final rect = topLeft & size;
  if (background != null) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
        Paint()..color = background);
  }
  painter.paint(canvas, topLeft + Offset(padding.left, padding.top));
  painter.dispose();
  return rect;
}

/// The size [text] takes in [style].
Size measureChartLabel(String text, TextStyle style,
    {TextScaler textScaler = TextScaler.noScaling}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

/// [source] cut into dashes of `pattern[0]` on, `pattern[1]` off, and so on.
Path dashChartPath(Path source, List<double> pattern) {
  if (pattern.isEmpty || pattern.every((d) => d <= 0)) return source;
  final out = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var index = 0;
    var draw = true;
    while (distance < metric.length) {
      final length = math.max(pattern[index % pattern.length], 0.5);
      if (draw) {
        out.addPath(
            metric.extractPath(distance, distance + length), Offset.zero);
      }
      distance += length;
      draw = !draw;
      index++;
    }
  }
  return out;
}

/// [color] made lighter (positive [amount]) or darker (negative), in HSL.
Color shadeChartColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// The staggered progress of item [index] of [count] at overall progress [t]: items start one
/// after another, each taking [span] of the timeline.
double staggeredChartProgress(double t, int index, int count,
    {double span = 0.6}) {
  if (count <= 1) return t;
  final start = (1 - span) * index / (count - 1);
  return ((t - start) / span).clamp(0.0, 1.0);
}
