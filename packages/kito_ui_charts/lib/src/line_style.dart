// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

import 'data.dart';

/// How a line joins consecutive points.
enum KitoLineInterpolation {
  /// Straight segments.
  linear,

  /// Curves with flat tangents at each point: smooth, and never overshoots a peak.
  smooth,

  /// Catmull–Rom: the most natural curve through every point; can overshoot on sharp turns.
  catmullRom,

  /// Holds each value until the next point, like a price tier or a state that changes.
  stepped,
}

/// The marker drawn on each data point.
enum KitoLinePointStyle {
  /// No markers.
  none,

  /// A solid dot in the series colour.
  filled,

  /// A ring in the series colour with the surface showing through.
  hollow,

  /// A solid dot with a soft halo.
  halo,

  /// Only the latest point, with a pulsing halo: the "live value" look. The pulse stops under
  /// Reduce Motion.
  lastPoint,
}

/// What a line chart draws under each line.
@immutable
sealed class KitoLineAreaFill {
  /// Subclasses only; use [none], [KitoLineAreaFill.solid] or [KitoLineAreaFill.gradient].
  const KitoLineAreaFill();

  /// No fill.
  static const none = KitoLineAreaNone();

  /// A flat fill in the series colour at [opacity].
  const factory KitoLineAreaFill.solid({double opacity}) = KitoLineAreaSolid;

  /// The series colour at [opacity] under the line, fading to clear at the baseline.
  const factory KitoLineAreaFill.gradient({double opacity}) =
      KitoLineAreaGradient;
}

/// No area fill.
final class KitoLineAreaNone extends KitoLineAreaFill {
  /// Creates the empty fill; use [KitoLineAreaFill.none].
  const KitoLineAreaNone();
}

/// A flat area fill.
final class KitoLineAreaSolid extends KitoLineAreaFill {
  /// Creates a flat fill.
  const KitoLineAreaSolid({this.opacity = 0.2});

  /// 0–1.
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is KitoLineAreaSolid && other.opacity == opacity;

  @override
  int get hashCode => opacity.hashCode;
}

/// A fill that fades toward the baseline.
final class KitoLineAreaGradient extends KitoLineAreaFill {
  /// Creates a fading fill.
  const KitoLineAreaGradient({this.opacity = 0.35});

  /// The opacity right under the line, 0–1.
  final double opacity;

  @override
  bool operator ==(Object other) =>
      other is KitoLineAreaGradient && other.opacity == opacity;

  @override
  int get hashCode => opacity.hashCode;
}

/// Everything about how a line chart looks, independent of its data.
///
/// ```dart
/// const KitoLineChartStyle(
///   interpolation: KitoLineInterpolation.catmullRom,
///   points: KitoLinePointStyle.hollow,
///   area: KitoLineAreaFill.gradient(opacity: 0.35),
///   showsLabels: true,
///   referenceLines: [KitoChartReferenceLine('Goal', 250)],
/// )
/// ```
@immutable
class KitoLineChartStyle {
  /// Creates a style; the defaults draw a smooth line over a value axis.
  const KitoLineChartStyle({
    this.interpolation = KitoLineInterpolation.smooth,
    this.lineWidth = 2.5,
    this.dash = const [],
    this.points = KitoLinePointStyle.none,
    this.pointSize = 7,
    this.area = KitoLineAreaFill.none,
    this.strokeGradient,
    this.glows = false,
    this.showsValueAxis = true,
    this.showsLabels = false,
    this.showsValues = false,
    this.includesZero = false,
    this.referenceLines = const [],
    this.animatesIn = true,
  });

  /// How points are joined.
  final KitoLineInterpolation interpolation;

  /// Stroke width in logical pixels.
  final double lineWidth;

  /// Dash pattern (on, off, on, …); empty is solid.
  final List<double> dash;

  /// The marker on each point.
  final KitoLinePointStyle points;

  /// Marker diameter.
  final double pointSize;

  /// What's drawn under the line.
  final KitoLineAreaFill area;

  /// Colours every line with a gradient running along the time axis instead of its series
  /// colour.
  final List<Color>? strokeGradient;

  /// A soft glow in the line colour, for dark and neon designs.
  final bool glows;

  /// Value labels and gridlines along the start edge.
  final bool showsValueAxis;

  /// Each point's label along the bottom, thinned out when they'd collide.
  final bool showsLabels;

  /// Each point's value above it.
  final bool showsValues;

  /// Stretches the value axis to include zero, so the baseline doesn't float.
  final bool includesZero;

  /// Horizontal guides: goals, limits, averages.
  final List<KitoChartReferenceLine> referenceLines;

  /// Wipes the chart in from the start edge when it appears.
  final bool animatesIn;

  /// A compact, axis-free trend line with a soft fill and a live last point, for table rows
  /// and stat tiles.
  static const sparkline = KitoLineChartStyle(
    lineWidth: 2,
    points: KitoLinePointStyle.lastPoint,
    pointSize: 6,
    area: KitoLineAreaFill.gradient(opacity: 0.3),
    showsValueAxis: false,
  );

  /// A filled area chart down to zero.
  static const areaChart = KitoLineChartStyle(
    area: KitoLineAreaFill.gradient(opacity: 0.35),
    includesZero: true,
    showsLabels: true,
  );

  /// A copy with some properties replaced.
  KitoLineChartStyle copyWith({
    KitoLineInterpolation? interpolation,
    double? lineWidth,
    List<double>? dash,
    KitoLinePointStyle? points,
    double? pointSize,
    KitoLineAreaFill? area,
    List<Color>? strokeGradient,
    bool? glows,
    bool? showsValueAxis,
    bool? showsLabels,
    bool? showsValues,
    bool? includesZero,
    List<KitoChartReferenceLine>? referenceLines,
    bool? animatesIn,
  }) =>
      KitoLineChartStyle(
        interpolation: interpolation ?? this.interpolation,
        lineWidth: lineWidth ?? this.lineWidth,
        dash: dash ?? this.dash,
        points: points ?? this.points,
        pointSize: pointSize ?? this.pointSize,
        area: area ?? this.area,
        strokeGradient: strokeGradient ?? this.strokeGradient,
        glows: glows ?? this.glows,
        showsValueAxis: showsValueAxis ?? this.showsValueAxis,
        showsLabels: showsLabels ?? this.showsLabels,
        showsValues: showsValues ?? this.showsValues,
        includesZero: includesZero ?? this.includesZero,
        referenceLines: referenceLines ?? this.referenceLines,
        animatesIn: animatesIn ?? this.animatesIn,
      );
}
