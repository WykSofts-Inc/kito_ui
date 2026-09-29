// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

/// One plotted value: a label along the category axis ("Mon", "Q3", "Nairobi") and its value.
@immutable
class KitoChartPoint {
  /// Creates a point. [color] overrides the palette for this point only, e.g. to call out an
  /// outlier bar or give a pie slice its brand colour.
  const KitoChartPoint(this.label, this.value, {this.color});

  /// The category label.
  final String label;

  /// The value.
  final double value;

  /// This point's own colour, or null to use the series or palette colour.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is KitoChartPoint &&
      other.label == label &&
      other.value == value &&
      other.color == color;

  @override
  int get hashCode => Object.hash(label, value, color);

  @override
  String toString() => 'KitoChartPoint($label, $value)';
}

/// A named run of points: one line on a line chart, one colour of bar on a bar chart.
///
/// Series on the same chart are matched by position, so the first point of every series shares
/// the first label.
@immutable
class KitoChartSeries {
  /// Creates a series.
  const KitoChartSeries({required this.name, required this.points, this.color});

  /// A series from bare values, labelled by [labels] (or 1, 2, 3… when left out).
  factory KitoChartSeries.values(String name, List<double> values,
          {List<String>? labels, Color? color}) =>
      KitoChartSeries(
        name: name,
        color: color,
        points: [
          for (var i = 0; i < values.length; i++)
            KitoChartPoint(
                labels != null && i < labels.length ? labels[i] : '${i + 1}',
                values[i]),
        ],
      );

  /// Shown in legends, callouts and screen-reader summaries.
  final String name;

  /// The values, in category order.
  final List<KitoChartPoint> points;

  /// The series colour, or null to take the next palette colour.
  final Color? color;

  /// Just the values.
  List<double> get values => [for (final p in points) p.value];

  @override
  bool operator ==(Object other) =>
      other is KitoChartSeries &&
      other.name == name &&
      other.color == color &&
      _listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(name, color, Object.hashAll(points));
}

/// A straight guide across the plot at a fixed value: a goal, a limit, an average.
@immutable
class KitoChartReferenceLine {
  /// Creates a guide.
  const KitoChartReferenceLine(this.label, this.value,
      {this.color, this.dashed = true});

  /// Drawn in a small pill at the end of the line.
  final String label;

  /// Where the line sits on the value axis.
  final double value;

  /// The line colour; the chart theme's axis colour when null.
  final Color? color;

  /// Dashed (the default) or solid.
  final bool dashed;

  @override
  bool operator ==(Object other) =>
      other is KitoChartReferenceLine &&
      other.label == label &&
      other.value == value &&
      other.color == color &&
      other.dashed == dashed;

  @override
  int get hashCode => Object.hash(label, value, color, dashed);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
