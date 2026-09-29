// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'data.dart';
import 'legend.dart';
import 'scale.dart';
import 'theme.dart';

/// How a bar chart with several series arranges them.
enum KitoBarLayout {
  /// Side by side within each category.
  grouped,

  /// On top of each other, so the bar's length is the category total.
  stacked,
}

/// One drawn bar, for hit-testing and tests.
@immutable
class KitoBarRect {
  /// Creates a bar.
  const KitoBarRect(this.group, this.series, this.rect, this.value);

  /// The category index.
  final int group;

  /// The series index.
  final int series;

  /// Where it's drawn, fully grown.
  final Rect rect;

  /// Its value.
  final double value;
}

/// A bar chart: vertical or horizontal, one series or several grouped or stacked.
///
/// Bars grow in one after another with a gentle spring, and animate to new values when the
/// data changes. Tap a category to highlight it (the others dim and its values show); each
/// category is also a button for screen readers. Right-to-left layouts put the first category
/// and the value axis on the right, and horizontal bars grow from the right.
///
/// ```dart
/// KitoBarChart(
///   series: [
///     KitoChartSeries.values('Sales', [42, 58, 35, 71],
///         labels: ['Q1', 'Q2', 'Q3', 'Q4']),
///   ],
///   showsValues: true,
/// )
/// ```
class KitoBarChart extends StatefulWidget {
  /// Creates a bar chart.
  const KitoBarChart({
    super.key,
    required this.series,
    this.layout = KitoBarLayout.grouped,
    this.direction = Axis.vertical,
    this.height,
    this.cornerRadius = 6,
    this.maxBarThickness = 36,
    this.showsValueAxis = true,
    this.showsValues = false,
    this.showLegend = true,
    this.referenceLines = const [],
    this.valueFormatter = KitoChartFormat.compact,
    this.selectedIndex,
    this.onSelectionChanged,
    this.animatesIn = true,
    this.tint,
    this.semanticLabel,
  });

  /// The series, matched by position: bar 2 of every series is the same category.
  final List<KitoChartSeries> series;

  /// Grouped or stacked, when there's more than one series.
  final KitoBarLayout layout;

  /// [Axis.vertical] bars rise from the bottom; [Axis.horizontal] bars run along the reading
  /// direction, with category labels at the start.
  final Axis direction;

  /// The plot's height. Null picks 220 for vertical charts, and 40 per category for
  /// horizontal ones.
  final double? height;

  /// The rounding on each bar's end.
  final double cornerRadius;

  /// The widest a bar gets, however much room there is.
  final double maxBarThickness;

  /// Shows value labels and gridlines.
  final bool showsValueAxis;

  /// Shows each bar's value at its end.
  final bool showsValues;

  /// Shows a legend when there's more than one series.
  final bool showLegend;

  /// Guides across the value axis.
  final List<KitoChartReferenceLine> referenceLines;

  /// Formats axis and value labels.
  final KitoChartValueFormatter valueFormatter;

  /// The highlighted category. The chart keeps its own selection after taps; changing this
  /// moves it.
  final int? selectedIndex;

  /// Called when a tap selects a category, or with null when it's deselected.
  final ValueChanged<int?>? onSelectionChanged;

  /// Grows the bars in when the chart appears.
  final bool animatesIn;

  /// Colours the first series, overriding its own colour and the palette.
  final Color? tint;

  /// Replaces the generated screen-reader summary.
  final String? semanticLabel;

  @override
  State<KitoBarChart> createState() => _KitoBarChartState();
}

class _KitoBarChartState extends State<KitoBarChart>
    with TickerProviderStateMixin {
  late final ChartMotion _motion = ChartMotion(this,
      duration: const Duration(milliseconds: 700),
      values: [for (final s in widget.series) s.values]);
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250), value: 1);
  bool _started = false;
  int? _selected;
  int? _previous;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion.start(
        animate: widget.animatesIn && !context.reduceMotion,
        duration: KitoChartTheme.of(context).animationDuration);
  }

  @override
  void didUpdateWidget(KitoBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motion.update([for (final s in widget.series) s.values],
        animate: !context.reduceMotion,
        duration: KitoChartTheme.of(context).animationDuration);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _setSelected(widget.selectedIndex, notify: false);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _fade.dispose();
    super.dispose();
  }

  int get _count =>
      widget.series.fold(0, (m, s) => math.max(m, s.points.length));

  void _setSelected(int? index, {bool notify = true}) {
    if (index == _selected) return;
    setState(() {
      _previous = _selected;
      _selected = index;
    });
    if (context.reduceMotion) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
    if (notify) {
      HapticFeedback.selectionClick();
      widget.onSelectionChanged?.call(index);
    }
  }

  void _toggle(int index) => _setSelected(_selected == index ? null : index);

  Color _color(KitoChartTheme chart, int s) {
    if (s == 0 && widget.tint != null) return widget.tint!;
    return widget.series[s].color ?? chart.colorAt(s);
  }

  String _label(int group) {
    for (final s in widget.series) {
      if (group < s.points.length) return s.points[group].label;
    }
    return '';
  }

  String _groupText(int group) {
    final parts = [
      for (final s in widget.series)
        if (group < s.points.length)
          widget.series.length > 1
              ? '${s.name} ${widget.valueFormatter(s.points[group].value)}'
              : widget.valueFormatter(s.points[group].value),
    ];
    return '${_label(group)}, ${parts.join(', ')}';
  }

  String _summary() {
    final n = _count;
    if (n == 0) return 'Bar chart, no data';
    final kind =
        widget.layout == KitoBarLayout.stacked && widget.series.length > 1
            ? 'Stacked bar chart'
            : 'Bar chart';
    final many =
        widget.series.length > 1 ? ', ${widget.series.length} series' : '';
    return '$kind, $n categories$many';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final chart = KitoChartTheme.of(context);
    final rtl = context.isRtl;
    final textScaler = MediaQuery.textScalerOf(context);
    final colors = [
      for (var s = 0; s < widget.series.length; s++) _color(chart, s)
    ];
    final horizontal = widget.direction == Axis.horizontal;
    final height =
        widget.height ?? (horizontal ? math.max(_count, 1) * 40.0 + 28 : 220.0);

    final plot = SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320, height);
        return AnimatedBuilder(
          animation: Listenable.merge([_motion.listenable, _fade]),
          builder: (context, _) {
            final geometry = _BarGeometry.compute(
              widget: widget,
              values: _motion.current,
              size: size,
              rtl: rtl,
              labelStyle: chart.labelStyle!,
              textScaler: textScaler,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BarPainter(
                      geometry: geometry,
                      widget: widget,
                      colors: colors,
                      chart: chart,
                      surface: theme.colors.surface,
                      strong: theme.colors.onSurface,
                      reveal: _motion.reveal.value,
                      spring: theme.motion.spring,
                      selected: _selected,
                      previous: _previous,
                      fade: _fade.value,
                      rtl: rtl,
                      textScaler: textScaler,
                    ),
                  ),
                ),
                for (var g = 0; g < geometry.count; g++)
                  Positioned.fromRect(
                    rect: geometry.bands[g],
                    child: Semantics(
                      button: true,
                      selected: _selected == g,
                      label: _groupText(g),
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggle(g),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      }),
    );

    final body = Semantics(
      container: true,
      label: widget.semanticLabel ?? _summary(),
      child: plot,
    );
    if (!widget.showLegend || widget.series.length < 2) return body;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        SizedBox(height: theme.spacing.sm),
        KitoChartLegend(entries: [
          for (var s = 0; s < widget.series.length; s++)
            KitoChartLegendEntry(widget.series[s].name, colors[s]),
        ]),
      ],
    );
  }
}

class _BarGeometry {
  _BarGeometry({
    required this.plot,
    required this.labels,
    required this.bands,
    required this.bars,
    required this.domain,
    required this.ticks,
    required this.value,
    required this.horizontal,
  });

  factory _BarGeometry.compute({
    required KitoBarChart widget,
    required List<List<double>> values,
    required Size size,
    required bool rtl,
    required TextStyle labelStyle,
    required TextScaler textScaler,
  }) {
    final horizontal = widget.direction == Axis.horizontal;
    final stacked = widget.layout == KitoBarLayout.stacked && values.length > 1;
    final count = values.fold(0, (m, v) => math.max(m, v.length));
    final labels = [
      for (var g = 0; g < count; g++)
        () {
          for (final s in widget.series) {
            if (g < s.points.length) return s.points[g].label;
          }
          return '';
        }(),
    ];

    // Value domain, always including zero so bars have a baseline.
    var lo = 0.0, hi = 0.0;
    for (var g = 0; g < count; g++) {
      var pos = 0.0, neg = 0.0;
      for (final v in values) {
        if (g >= v.length) continue;
        if (stacked) {
          if (v[g] >= 0) {
            pos += v[g];
          } else {
            neg += v[g];
          }
        } else {
          hi = math.max(hi, v[g]);
          lo = math.min(lo, v[g]);
        }
      }
      if (stacked) {
        hi = math.max(hi, pos);
        lo = math.min(lo, neg);
      }
    }
    for (final line in widget.referenceLines) {
      hi = math.max(hi, line.value);
      lo = math.min(lo, line.value);
    }
    if (hi == lo) hi = lo + 1;
    final step = KitoChartTicks.niceStep(lo, hi);
    final domain = KitoChartTicks.niceDomain(lo, hi);
    final ticks = widget.showsValueAxis
        ? KitoChartTicks.nice(domain.$1, domain.$2, step: step)
        : const <double>[];

    final labelHeight =
        measureChartLabel('0', labelStyle, textScaler: textScaler).height;
    var tickWidth = 0.0;
    for (final t in ticks) {
      tickWidth = math.max(
          tickWidth,
          measureChartLabel(widget.valueFormatter(t), labelStyle,
                  textScaler: textScaler)
              .width);
    }
    final valuePad = widget.showsValues ? labelHeight + 4 : 4.0;

    late Rect plot;
    if (horizontal) {
      var labelWidth = 0.0;
      for (final l in labels) {
        labelWidth = math.max(labelWidth,
            measureChartLabel(l, labelStyle, textScaler: textScaler).width);
      }
      labelWidth = math.min(labelWidth, size.width * 0.35) + 10;
      final endPad = widget.showsValues
          ? math.max(tickWidth / 2, 36.0)
          : math.max(tickWidth / 2, 8.0);
      final bottom = widget.showsValueAxis ? labelHeight + 8 : 2.0;
      plot = rtl
          ? Rect.fromLTRB(
              endPad, 2, size.width - labelWidth, size.height - bottom)
          : Rect.fromLTRB(
              labelWidth, 2, size.width - endPad, size.height - bottom);
    } else {
      final start = widget.showsValueAxis ? tickWidth + 10 : 4.0;
      final top = math.max(valuePad, labelHeight / 2 + 2);
      final bottom = labelHeight + 8;
      plot = rtl
          ? Rect.fromLTRB(4, top, size.width - start, size.height - bottom)
          : Rect.fromLTRB(start, top, size.width - 4, size.height - bottom);
    }
    if (plot.width < 1 || plot.height < 1) {
      plot = Rect.fromLTWH(plot.left, plot.top, math.max(plot.width, 1),
          math.max(plot.height, 1));
    }

    final value = horizontal
        ? (rtl
            ? KitoChartScale(domain.$1, domain.$2, plot.right, plot.left)
            : KitoChartScale(domain.$1, domain.$2, plot.left, plot.right))
        : KitoChartScale(domain.$1, domain.$2, plot.bottom, plot.top);

    final bands = <Rect>[];
    final bars = <KitoBarRect>[];
    final along = horizontal ? plot.height : plot.width;
    final band = count == 0 ? along : along / count;
    final area = band * 0.7;
    final m = values.length;
    for (var g = 0; g < count; g++) {
      final Rect bandRect;
      if (horizontal) {
        bandRect = Rect.fromLTWH(0, plot.top + g * band, size.width, band);
      } else {
        final left = rtl ? plot.right - (g + 1) * band : plot.left + g * band;
        bandRect = Rect.fromLTWH(left, 0, band, size.height);
      }
      bands.add(bandRect);
      final center = horizontal
          ? plot.top + (g + 0.5) * band
          : (rtl
              ? plot.right - (g + 0.5) * band
              : plot.left + (g + 0.5) * band);
      if (stacked) {
        final thickness = math.min(area, widget.maxBarThickness);
        var pos = 0.0, neg = 0.0;
        for (var s = 0; s < m; s++) {
          if (g >= values[s].length) continue;
          final v = values[s][g];
          final from = v >= 0 ? pos : neg;
          final to = from + v;
          if (v >= 0) {
            pos = to;
          } else {
            neg = to;
          }
          bars.add(KitoBarRect(g, s,
              _rect(horizontal, center, thickness, value(from), value(to)), v));
        }
      } else {
        const gap = 3.0;
        final thickness = math.min(
            (area - gap * (m - 1)) / math.max(m, 1), widget.maxBarThickness);
        final total = thickness * m + gap * (m - 1);
        for (var s = 0; s < m; s++) {
          if (g >= values[s].length) continue;
          final offset = -total / 2 + s * (thickness + gap) + thickness / 2;
          // Series run with the reading direction inside a group.
          final c =
              horizontal ? center + offset : center + (rtl ? -offset : offset);
          bars.add(KitoBarRect(
              g,
              s,
              _rect(horizontal, c, thickness, value(0), value(values[s][g])),
              values[s][g]));
        }
      }
    }
    return _BarGeometry(
      plot: plot,
      labels: labels,
      bands: bands,
      bars: bars,
      domain: domain,
      ticks: ticks,
      value: value,
      horizontal: horizontal,
    );
  }

  static Rect _rect(
      bool horizontal, double center, double thickness, double a, double b) {
    return horizontal
        ? Rect.fromLTRB(math.min(a, b), center - thickness / 2, math.max(a, b),
            center + thickness / 2)
        : Rect.fromLTRB(center - thickness / 2, math.min(a, b),
            center + thickness / 2, math.max(a, b));
  }

  final Rect plot;
  final List<String> labels;
  final List<Rect> bands;
  final List<KitoBarRect> bars;
  final (double, double) domain;
  final List<double> ticks;
  final KitoChartScale value;
  final bool horizontal;

  int get count => labels.length;
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.geometry,
    required this.widget,
    required this.colors,
    required this.chart,
    required this.surface,
    required this.strong,
    required this.reveal,
    required this.spring,
    required this.selected,
    required this.previous,
    required this.fade,
    required this.rtl,
    required this.textScaler,
  });

  final _BarGeometry geometry;
  final KitoBarChart widget;
  final List<Color> colors;
  final KitoChartTheme chart;
  final Color surface;
  final Color strong;
  final double reveal;
  final Curve spring;
  final int? selected;
  final int? previous;
  final double fade;
  final bool rtl;
  final TextScaler textScaler;

  double _opacity(int? sel, int g) => sel == null || sel == g ? 1 : 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = geometry.plot;
    final horizontal = geometry.horizontal;
    final scale = geometry.value;
    final labelStyle = chart.labelStyle!.copyWith(color: chart.labelColor);
    final grid = Paint()
      ..color = chart.gridlineColor!
      ..strokeWidth = 1;

    for (final tick in geometry.ticks) {
      final p = scale(tick);
      if (horizontal) {
        if (chart.showGridlines) {
          canvas.drawLine(Offset(p, plot.top), Offset(p, plot.bottom), grid);
        }
        paintChartLabel(canvas, widget.valueFormatter(tick), labelStyle,
            Offset(p, plot.bottom + 6),
            alignment: Alignment.topCenter, textScaler: textScaler);
      } else {
        if (chart.showGridlines) {
          canvas.drawLine(Offset(plot.left, p), Offset(plot.right, p), grid);
        }
        paintChartLabel(canvas, widget.valueFormatter(tick), labelStyle,
            Offset(rtl ? plot.right + 8 : plot.left - 8, p),
            alignment: rtl ? Alignment.centerLeft : Alignment.centerRight,
            textScaler: textScaler);
      }
    }

    // Baseline at zero.
    final zero = scale(0);
    final axis = Paint()
      ..color = chart.axisColor!
      ..strokeWidth = 1;
    if (horizontal) {
      canvas.drawLine(Offset(zero, plot.top), Offset(zero, plot.bottom), axis);
    } else {
      canvas.drawLine(Offset(plot.left, zero), Offset(plot.right, zero), axis);
    }

    // Category labels.
    for (var g = 0; g < geometry.count; g++) {
      final band = geometry.bands[g];
      final style = labelStyle.copyWith(
          color: selected == g ? strong : null,
          fontWeight: selected == g ? FontWeight.w700 : null);
      if (horizontal) {
        paintChartLabel(canvas, geometry.labels[g], style,
            Offset(rtl ? plot.right + 10 : plot.left - 10, band.center.dy),
            alignment: rtl ? Alignment.centerLeft : Alignment.centerRight,
            textScaler: textScaler,
            maxWidth: math.max(size.width * 0.35, 1));
      } else {
        paintChartLabel(canvas, geometry.labels[g], style,
            Offset(band.center.dx, plot.bottom + 6),
            alignment: Alignment.topCenter,
            textScaler: textScaler,
            maxWidth: math.max(band.width + 8, 1));
      }
    }

    // Bars.
    final stacked = widget.layout == KitoBarLayout.stacked && colors.length > 1;
    final topOf = <int, int>{};
    for (var i = 0; i < geometry.bars.length; i++) {
      final bar = geometry.bars[i];
      if (bar.value == 0) continue;
      final key = bar.group * 2 + (bar.value >= 0 ? 0 : 1);
      topOf[key] = i;
    }
    for (var i = 0; i < geometry.bars.length; i++) {
      final bar = geometry.bars[i];
      final t = spring.transform(staggeredChartProgress(
          widget.animatesIn ? reveal : 1, bar.group, geometry.count));
      final grown = _grow(bar.rect, t, zero, horizontal, bar.value >= 0);
      if (grown.width <= 0 || grown.height <= 0) continue;
      final opacity = lerpDouble(
          _opacity(previous, bar.group), _opacity(selected, bar.group), fade)!;
      final color = _pointColor(bar).withValues(alpha: opacity);
      final isEnd =
          !stacked || topOf[bar.group * 2 + (bar.value >= 0 ? 0 : 1)] == i;
      final r = Radius.circular(isEnd
          ? math.min(widget.cornerRadius,
              (horizontal ? grown.height : grown.width) / 2)
          : 0);
      final positive = bar.value >= 0;
      final RRect rrect;
      if (horizontal) {
        final endIsRight = positive != rtl;
        rrect = RRect.fromRectAndCorners(grown,
            topRight: endIsRight ? r : Radius.zero,
            bottomRight: endIsRight ? r : Radius.zero,
            topLeft: endIsRight ? Radius.zero : r,
            bottomLeft: endIsRight ? Radius.zero : r);
      } else {
        rrect = RRect.fromRectAndCorners(grown,
            topLeft: positive ? r : Radius.zero,
            topRight: positive ? r : Radius.zero,
            bottomLeft: positive ? Radius.zero : r,
            bottomRight: positive ? Radius.zero : r);
      }
      final paint = Paint()
        ..shader = LinearGradient(
          begin: horizontal
              ? (rtl ? Alignment.centerRight : Alignment.centerLeft)
              : Alignment.bottomCenter,
          end: horizontal
              ? (rtl ? Alignment.centerLeft : Alignment.centerRight)
              : Alignment.topCenter,
          colors: [
            color,
            shadeChartColor(color, 0.08).withValues(alpha: opacity)
          ],
        ).createShader(grown);
      canvas.drawRRect(stacked ? rrect.deflate(0.5) : rrect, paint);

      final showValue =
          widget.showsValues || (selected == bar.group && !stacked);
      if (showValue && t > 0.6) {
        final text = widget.valueFormatter(bar.value);
        final labelOpacity = ((t - 0.6) / 0.4).clamp(0.0, 1.0) *
            (widget.showsValues ? opacity : 1);
        final style = labelStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: labelStyle.color!
                .withValues(alpha: labelStyle.color!.a * labelOpacity));
        if (stacked) {
          final inside = horizontal ? grown.width > 30 : grown.height > 18;
          if (inside) {
            paintChartLabel(
                canvas,
                text,
                style.copyWith(
                    color: _readableOn(color).withValues(alpha: labelOpacity)),
                grown.center,
                textScaler: textScaler);
          }
        } else if (horizontal) {
          final endRight = positive != rtl;
          paintChartLabel(
              canvas,
              text,
              style,
              Offset(
                  endRight ? grown.right + 6 : grown.left - 6, grown.center.dy),
              alignment:
                  endRight ? Alignment.centerLeft : Alignment.centerRight,
              textScaler: textScaler);
        } else {
          paintChartLabel(
              canvas,
              text,
              style,
              Offset(
                  grown.center.dx, positive ? grown.top - 3 : grown.bottom + 3),
              alignment:
                  positive ? Alignment.bottomCenter : Alignment.topCenter,
              textScaler: textScaler);
        }
      }
    }

    // Stacked totals on the selected category.
    if (stacked && selected != null && selected! < geometry.count) {
      final g = selected!;
      final group = geometry.bars.where((b) => b.group == g).toList();
      if (group.isNotEmpty) {
        final total = group.fold<double>(0, (sum, b) => sum + b.value);
        final bounds =
            group.map((b) => b.rect).reduce((a, b) => a.expandToInclude(b));
        final text = widget.valueFormatter(total);
        final style = labelStyle.copyWith(fontWeight: FontWeight.w700);
        if (horizontal) {
          paintChartLabel(
              canvas,
              text,
              style,
              Offset(
                  rtl ? bounds.left - 6 : bounds.right + 6, bounds.center.dy),
              alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
              textScaler: textScaler);
        } else {
          paintChartLabel(
              canvas, text, style, Offset(bounds.center.dx, bounds.top - 3),
              alignment: Alignment.bottomCenter, textScaler: textScaler);
        }
      }
    }

    // Reference lines.
    for (final line in widget.referenceLines) {
      final p = scale(line.value);
      final color = line.color ?? chart.axisColor!;
      final path = horizontal
          ? (Path()
            ..moveTo(p, plot.top)
            ..lineTo(p, plot.bottom))
          : (Path()
            ..moveTo(plot.left, p)
            ..lineTo(plot.right, p));
      canvas.drawPath(
          line.dashed ? dashChartPath(path, const [5, 4]) : path,
          Paint()
            ..color = color
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke);
      paintChartLabel(
        canvas,
        line.label,
        labelStyle.copyWith(color: color, fontWeight: FontWeight.w700),
        horizontal
            ? Offset(p, plot.top)
            : Offset(rtl ? plot.left : plot.right, p - 2),
        alignment: horizontal
            ? Alignment.topCenter
            : (rtl ? Alignment.bottomLeft : Alignment.bottomRight),
        textScaler: textScaler,
        background: surface.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      );
    }
  }

  Color _pointColor(KitoBarRect bar) {
    final points = widget.series[bar.series].points;
    final own = bar.group < points.length ? points[bar.group].color : null;
    return own ?? colors[bar.series];
  }

  static Color _readableOn(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
          ? Colors.white
          : Colors.black;

  static Rect _grow(
      Rect r, double t, double zero, bool horizontal, bool positive) {
    if (t == 1) return r;
    if (horizontal) {
      final left = zero + (r.left - zero) * t;
      final right = zero + (r.right - zero) * t;
      return Rect.fromLTRB(
          math.min(left, right), r.top, math.max(left, right), r.bottom);
    }
    final top = zero + (r.top - zero) * t;
    final bottom = zero + (r.bottom - zero) * t;
    return Rect.fromLTRB(
        r.left, math.min(top, bottom), r.right, math.max(top, bottom));
  }

  @override
  bool shouldRepaint(_BarPainter old) => true;
}
