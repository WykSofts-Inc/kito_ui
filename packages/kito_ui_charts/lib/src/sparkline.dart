// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'data.dart';
import 'line_chart.dart';
import 'line_style.dart';
import 'scale.dart';

/// A tiny, axis-free trend line for table rows, list tiles and stat cards.
///
/// With [trendColors] it goes green when the last value is at or above the first and red when
/// it's below, using the theme's success and danger colours.
///
/// ```dart
/// Row(children: [
///   const Text('SCOM'),
///   const Spacer(),
///   SizedBox(width: 80, child: KitoSparkline([27.1, 27.9, 27.4, 28.6, 29.2], trendColors: true)),
/// ])
/// ```
class KitoSparkline extends StatelessWidget {
  /// Creates a sparkline.
  const KitoSparkline(
    this.values, {
    super.key,
    this.height = 36,
    this.color,
    this.trendColors = false,
    this.style = KitoLineChartStyle.sparkline,
    this.scrubbable = false,
    this.valueFormatter = KitoChartFormat.compact,
    this.semanticLabel,
  });

  /// The values, oldest first.
  final List<double> values;

  /// Its height.
  final double height;

  /// The line colour; the palette's first colour when null.
  final Color? color;

  /// Green for up, red for down (overrides [color]).
  final bool trendColors;

  /// The line style; [KitoLineChartStyle.sparkline] by default.
  final KitoLineChartStyle style;

  /// Lets a drag show values, like a full chart.
  final bool scrubbable;

  /// Formats the callout and the summary.
  final KitoChartValueFormatter valueFormatter;

  /// Replaces the generated screen-reader summary ("Trend up from 120 to 260").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.kito.colors;
    final up = values.isEmpty || values.last >= values.first;
    final tint = trendColors ? (up ? colors.success : colors.danger) : color;
    final summary = values.isEmpty
        ? 'Trend, no data'
        : 'Trend ${values.last == values.first ? 'flat' : up ? 'up' : 'down'}, '
            'from ${valueFormatter(values.first)} to ${valueFormatter(values.last)}';
    return KitoLineChart(
      series: [KitoChartSeries.values('', values)],
      style: style,
      height: height,
      tint: tint,
      showLegend: false,
      scrubbable: scrubbable,
      valueFormatter: valueFormatter,
      semanticLabel: semanticLabel ?? summary,
    );
  }
}
