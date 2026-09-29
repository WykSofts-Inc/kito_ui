// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'data.dart';
import 'legend.dart';
import 'line_style.dart';
import 'math.dart';
import 'scale.dart';
import 'theme.dart';

/// A line or area chart with one or more series.
///
/// Drag across it to scrub: a guide follows the finger with a callout of every series' value
/// at that point (tap to pin one). Screen readers get a summary, and can swipe up and down to
/// step through the points. In right-to-left layouts time runs from the right, the value axis
/// sits on the right, and scrubbing still tracks the finger.
///
/// ```dart
/// KitoLineChart(
///   series: [
///     KitoChartSeries.values('M-Pesa', [120, 200, 150, 260, 240],
///         labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']),
///   ],
///   style: const KitoLineChartStyle(
///     area: KitoLineAreaFill.gradient(),
///     points: KitoLinePointStyle.hollow,
///     showsLabels: true,
///   ),
/// )
/// ```
class KitoLineChart extends StatefulWidget {
  /// Creates a line chart.
  const KitoLineChart({
    super.key,
    required this.series,
    this.style = const KitoLineChartStyle(),
    this.height = 200,
    this.valueFormatter = KitoChartFormat.compact,
    this.showLegend = true,
    this.scrubbable = true,
    this.onSelectionChanged,
    this.tint,
    this.semanticLabel,
  });

  /// The lines, matched by position: point 3 of every series shares one label.
  final List<KitoChartSeries> series;

  /// How it looks.
  final KitoLineChartStyle style;

  /// The plot's height; the legend, when shown, goes below it.
  final double height;

  /// Formats the value axis, value labels and the scrub callout.
  final KitoChartValueFormatter valueFormatter;

  /// Shows a legend when there's more than one series.
  final bool showLegend;

  /// Lets a drag or tap pick a point.
  final bool scrubbable;

  /// Called with the scrubbed point's index, and null when the finger lifts.
  final ValueChanged<int?>? onSelectionChanged;

  /// Colours the first series (overriding its own colour and the palette).
  final Color? tint;

  /// Replaces the generated screen-reader summary.
  final String? semanticLabel;

  @override
  State<KitoLineChart> createState() => _KitoLineChartState();
}

class _KitoLineChartState extends State<KitoLineChart>
    with TickerProviderStateMixin {
  late final ChartMotion _motion = ChartMotion(this,
      duration: const Duration(milliseconds: 700), values: _values(widget));
  AnimationController? _pulse;
  bool _started = false;
  int? _scrub;
  int? _pinned;
  int? _lastShown;

  static List<List<double>> _values(KitoLineChart w) =>
      [for (final s in w.series) s.values];

  int get _count =>
      widget.series.fold(0, (m, s) => math.max(m, s.points.length));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = KitoChartTheme.of(context).animationDuration;
    if (!_started) {
      _started = true;
      _motion.start(
          animate: widget.style.animatesIn && !context.reduceMotion,
          duration: duration);
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(KitoLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motion.update(_values(widget),
        animate: !context.reduceMotion,
        duration: KitoChartTheme.of(context).animationDuration);
    if (_scrub != null && _scrub! >= _count) _scrub = _pinned = null;
    _syncPulse();
  }

  void _syncPulse() {
    final wants = widget.style.points == KitoLinePointStyle.lastPoint &&
        !context.reduceMotion;
    if (wants && _pulse == null) {
      _pulse = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
    } else if (!wants && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _pulse?.dispose();
    super.dispose();
  }

  void _select(int? index) {
    if (index == _scrub) return;
    if (index != null && _scrub != null) HapticFeedback.selectionClick();
    setState(() {
      _scrub = index;
      if (index != null) _lastShown = index;
    });
    widget.onSelectionChanged?.call(index);
  }

  Color _color(KitoChartTheme chart, int i) {
    if (i == 0 && widget.tint != null) return widget.tint!;
    return widget.series[i].color ?? chart.colorAt(i);
  }

  String _summary() {
    final first = widget.series.where((s) => s.points.isNotEmpty).firstOrNull;
    if (first == null) return 'Line chart, no data';
    final start = first.points.first, end = first.points.last;
    final many =
        widget.series.length > 1 ? '${widget.series.length} series, ' : '';
    return 'Line chart, $many${first.points.length} points, from '
        '${start.label} ${widget.valueFormatter(start.value)} to '
        '${end.label} ${widget.valueFormatter(end.value)}';
  }

  String? _selectionText(int? index) {
    if (index == null) return null;
    final label = widget.series
        .map((s) => index < s.points.length ? s.points[index].label : null)
        .nonNulls
        .firstOrNull;
    final values = [
      for (final s in widget.series)
        if (index < s.points.length)
          widget.series.length > 1
              ? '${s.name} ${widget.valueFormatter(s.points[index].value)}'
              : widget.valueFormatter(s.points[index].value)
    ];
    return '${label ?? ''}: ${values.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final chart = KitoChartTheme.of(context);
    final rtl = context.isRtl;
    final textScaler = MediaQuery.textScalerOf(context);
    final colors = [
      for (var i = 0; i < widget.series.length; i++) _color(chart, i)
    ];

    final plot = SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
            widget.height);
        return AnimatedBuilder(
          animation: Listenable.merge([_motion.listenable, _pulse]),
          builder: (context, _) {
            final geometry = _LineGeometry.compute(
              series: widget.series,
              values: _motion.current,
              style: widget.style,
              size: size,
              rtl: rtl,
              labelStyle: chart.labelStyle!,
              textScaler: textScaler,
              formatter: widget.valueFormatter,
            );
            final shown = _scrub ?? _lastShown;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragDown: widget.scrubbable
                  ? (d) => _select(geometry.indexAt(d.localPosition.dx))
                  : null,
              onHorizontalDragUpdate: widget.scrubbable
                  ? (d) => _select(geometry.indexAt(d.localPosition.dx))
                  : null,
              onHorizontalDragEnd:
                  widget.scrubbable ? (_) => _select(_pinned) : null,
              onHorizontalDragCancel:
                  widget.scrubbable ? () => _select(_pinned) : null,
              onTapUp: widget.scrubbable
                  ? (d) {
                      final i = geometry.indexAt(d.localPosition.dx);
                      _pinned = _pinned == i ? null : i;
                      _select(_pinned);
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LinePainter(
                        geometry: geometry,
                        style: widget.style,
                        colors: colors,
                        chart: chart,
                        surface: theme.colors.surface,
                        reveal: widget.style.animatesIn
                            ? Curves.easeOutCubic
                                .transform(_motion.reveal.value)
                            : 1,
                        pulse: _pulse?.value,
                        selected: _scrub,
                        rtl: rtl,
                        textScaler: textScaler,
                        formatter: widget.valueFormatter,
                      ),
                    ),
                  ),
                  if (shown != null && shown < geometry.count)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _scrub == null ? 0 : 1,
                          duration: KitoMotion.of(context, theme.motion.fast),
                          child: CustomSingleChildLayout(
                            delegate: _CalloutLayout(geometry.anchor(shown)),
                            child: _Callout(
                              label: geometry.labelAt(shown),
                              rows: [
                                for (var s = 0; s < widget.series.length; s++)
                                  if (shown < widget.series[s].points.length)
                                    (
                                      widget.series.length > 1
                                          ? widget.series[s].name
                                          : null,
                                      colors[s],
                                      widget.valueFormatter(
                                          widget.series[s].points[shown].value),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      }),
    );

    final count = _count;
    final semantic = Semantics(
      container: true,
      label: widget.semanticLabel ?? _summary(),
      value: _selectionText(_scrub),
      increasedValue: _scrub == null
          ? null
          : _selectionText(math.min(_scrub! + 1, count - 1)),
      decreasedValue:
          _scrub == null ? null : _selectionText(math.max(_scrub! - 1, 0)),
      onIncrease: widget.scrubbable && count > 0
          ? () => _select(math.min((_scrub ?? -1) + 1, count - 1))
          : null,
      onDecrease: widget.scrubbable && count > 0
          ? () => _select(math.max((_scrub ?? count) - 1, 0))
          : null,
      child: ExcludeSemantics(child: plot),
    );

    if (!widget.showLegend || widget.series.length < 2) return semantic;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        semantic,
        SizedBox(height: theme.spacing.sm),
        KitoChartLegend(entries: [
          for (var i = 0; i < widget.series.length; i++)
            KitoChartLegendEntry(widget.series[i].name, colors[i]),
        ]),
      ],
    );
  }
}

/// Where everything on a line chart goes, for the painter, the callout and hit-testing.
class _LineGeometry {
  _LineGeometry({
    required this.plot,
    required this.size,
    required this.domain,
    required this.ticks,
    required this.positions,
    required this.labels,
    required this.rtl,
    required this.axisWidth,
  });

  factory _LineGeometry.compute({
    required List<KitoChartSeries> series,
    required List<List<double>> values,
    required KitoLineChartStyle style,
    required Size size,
    required bool rtl,
    required TextStyle labelStyle,
    required TextScaler textScaler,
    required KitoChartValueFormatter formatter,
  }) {
    final domain = KitoChartMath.lineDomain(
      [
        for (var s = 0; s < values.length; s++)
          KitoChartSeries.values(series[s].name, values[s])
      ],
      referenceLines: style.referenceLines,
      includesZero: style.includesZero,
    );
    final ticks = style.showsValueAxis
        ? KitoChartTicks.nice(domain.$1, domain.$2)
        : const <double>[];
    var axisWidth = 0.0;
    for (final t in ticks) {
      axisWidth = math.max(
          axisWidth,
          measureChartLabel(formatter(t), labelStyle, textScaler: textScaler)
              .width);
    }
    final labelHeight =
        measureChartLabel('0', labelStyle, textScaler: textScaler).height;
    final markerPad = switch (style.points) {
      KitoLinePointStyle.none => style.lineWidth,
      KitoLinePointStyle.filled ||
      KitoLinePointStyle.hollow =>
        style.pointSize * 0.6,
      KitoLinePointStyle.halo ||
      KitoLinePointStyle.lastPoint =>
        style.pointSize * 1.3,
    };
    final startPad = style.showsValueAxis
        ? axisWidth + 10
        : (style.showsLabels ? 16.0 : markerPad);
    final endPad = math.max(style.showsLabels ? 16.0 : 8.0, markerPad);
    final top = style.showsValues
        ? labelHeight + 8
        : math.max(
            markerPad, style.referenceLines.isEmpty ? 2.0 : labelHeight + 4);
    final bottom =
        style.showsLabels ? labelHeight + 10 : math.max(markerPad, 2.0);
    final left = rtl ? endPad : startPad;
    final right = rtl ? startPad : endPad;
    final plot = Rect.fromLTRB(
        left,
        top,
        math.max(size.width - right, left + 1),
        math.max(size.height - bottom, top + 1));
    final y = KitoChartScale(domain.$1, domain.$2, plot.bottom, plot.top);
    final positions = [
      for (final v in values)
        [
          for (var i = 0; i < v.length; i++)
            Offset(KitoChartMath.indexX(i, v.length, plot, rtl: rtl), y(v[i]))
        ]
    ];
    var longest = const <String>[];
    for (final s in series) {
      if (s.points.length > longest.length) {
        longest = [for (final p in s.points) p.label];
      }
    }
    return _LineGeometry(
      plot: plot,
      size: size,
      domain: domain,
      ticks: ticks,
      positions: positions,
      labels: longest,
      rtl: rtl,
      axisWidth: axisWidth,
    );
  }

  final Rect plot;
  final Size size;
  final (double, double) domain;
  final List<double> ticks;
  final List<List<Offset>> positions;
  final List<String> labels;
  final bool rtl;
  final double axisWidth;

  int get count => labels.length;

  KitoChartScale get y =>
      KitoChartScale(domain.$1, domain.$2, plot.bottom, plot.top);

  int indexAt(double dx) =>
      KitoChartMath.nearestIndex(dx, count, plot, rtl: rtl);

  String labelAt(int i) => i < labels.length ? labels[i] : '';

  /// The highest point at [index] across the series, where the callout hangs.
  Offset anchor(int index) {
    var best =
        Offset(KitoChartMath.indexX(index, count, plot, rtl: rtl), plot.bottom);
    for (final series in positions) {
      if (index < series.length && series[index].dy < best.dy) {
        best = series[index];
      }
    }
    return best;
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.geometry,
    required this.style,
    required this.colors,
    required this.chart,
    required this.surface,
    required this.reveal,
    required this.pulse,
    required this.selected,
    required this.rtl,
    required this.textScaler,
    required this.formatter,
  });

  final _LineGeometry geometry;
  final KitoLineChartStyle style;
  final List<Color> colors;
  final KitoChartTheme chart;
  final Color surface;
  final double reveal;
  final double? pulse;
  final int? selected;
  final bool rtl;
  final TextScaler textScaler;
  final KitoChartValueFormatter formatter;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = geometry.plot;
    final y = geometry.y;
    final labelStyle = chart.labelStyle!.copyWith(color: chart.labelColor);

    // Value axis and gridlines.
    for (final tick in geometry.ticks) {
      final ty = y(tick);
      if (chart.showGridlines) {
        canvas.drawLine(
            Offset(plot.left, ty),
            Offset(plot.right, ty),
            Paint()
              ..color = chart.gridlineColor!
              ..strokeWidth = 1);
      }
      paintChartLabel(
        canvas,
        formatter(tick),
        labelStyle,
        Offset(rtl ? plot.right + 8 : plot.left - 8, ty),
        alignment: rtl ? Alignment.centerLeft : Alignment.centerRight,
        textScaler: textScaler,
      );
    }

    // Reference lines.
    for (final line in style.referenceLines) {
      final ly = y(line.value);
      final color = line.color ?? chart.axisColor!;
      final path = Path()
        ..moveTo(plot.left, ly)
        ..lineTo(plot.right, ly);
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
        Offset(rtl ? plot.left : plot.right, ly - 2),
        alignment: rtl ? Alignment.bottomLeft : Alignment.bottomRight,
        textScaler: textScaler,
        background: surface.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      );
    }

    // X labels.
    if (style.showsLabels && geometry.count > 0) {
      for (final i in KitoChartMath.labelIndices(geometry.count, plot.width)) {
        paintChartLabel(
          canvas,
          geometry.labels[i],
          labelStyle,
          Offset(KitoChartMath.indexX(i, geometry.count, plot, rtl: rtl),
              plot.bottom + 6),
          alignment: Alignment.topCenter,
          textScaler: textScaler,
        );
      }
    }

    // Series, wiped in from the start edge.
    canvas.save();
    final revealWidth = size.width * reveal;
    canvas.clipRect(rtl
        ? Rect.fromLTRB(
            size.width - revealWidth, -40, size.width, size.height + 40)
        : Rect.fromLTRB(0, -40, revealWidth, size.height + 40));
    final baseline =
        y(math.min(math.max(0, geometry.domain.$1), geometry.domain.$2));
    for (var s = 0; s < geometry.positions.length; s++) {
      _paintSeries(canvas, geometry.positions[s], colors[s], baseline, s);
    }
    canvas.restore();

    // Scrub guide.
    final index = selected;
    if (index != null && index < geometry.count) {
      final x = KitoChartMath.indexX(index, geometry.count, plot, rtl: rtl);
      canvas.drawPath(
          dashChartPath(
              Path()
                ..moveTo(x, plot.top)
                ..lineTo(x, plot.bottom),
              const [3, 3]),
          Paint()
            ..color = chart.axisColor!
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
      for (var s = 0; s < geometry.positions.length; s++) {
        final points = geometry.positions[s];
        if (index >= points.length) continue;
        canvas
          ..drawCircle(points[index], 7,
              Paint()..color = colors[s].withValues(alpha: 0.2))
          ..drawCircle(points[index], 5.5, Paint()..color = surface)
          ..drawCircle(points[index], 4, Paint()..color = colors[s]);
      }
    }
  }

  void _paintSeries(
      Canvas canvas, List<Offset> points, Color color, double baseline, int s) {
    if (points.isEmpty) return;
    final plot = geometry.plot;
    final line = KitoChartMath.linePath(points, style.interpolation);

    switch (style.area) {
      case KitoLineAreaNone():
        break;
      case KitoLineAreaSolid(:final opacity):
        canvas.drawPath(
            KitoChartMath.areaPath(points, style.interpolation, baseline),
            Paint()..color = color.withValues(alpha: opacity));
      case KitoLineAreaGradient(:final opacity):
        final top = points.map((p) => p.dy).reduce(math.min);
        canvas.drawPath(
          KitoChartMath.areaPath(points, style.interpolation, baseline),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0)
              ],
            ).createShader(Rect.fromLTRB(
                plot.left, top, plot.right, math.max(baseline, top + 1))),
        );
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final gradient = style.strokeGradient;
    if (gradient != null && gradient.length > 1) {
      stroke.shader = LinearGradient(
        begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
        end: rtl ? Alignment.centerLeft : Alignment.centerRight,
        colors: gradient,
      ).createShader(plot);
    } else {
      stroke.color = gradient?.firstOrNull ?? color;
    }
    final drawn = style.dash.isEmpty ? line : dashChartPath(line, style.dash);
    if (style.glows) {
      canvas.drawPath(
          drawn,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.lineWidth + 2
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.75)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    }
    canvas.drawPath(drawn, stroke);

    final r = style.pointSize / 2;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      switch (style.points) {
        case KitoLinePointStyle.none:
          break;
        case KitoLinePointStyle.filled:
          canvas.drawCircle(p, r, Paint()..color = color);
        case KitoLinePointStyle.hollow:
          final ring = math.max(style.pointSize * 0.28, 1.5);
          canvas
            ..drawCircle(p, r, Paint()..color = surface)
            ..drawCircle(
                p,
                r - ring / 2,
                Paint()
                  ..color = color
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = ring);
        case KitoLinePointStyle.halo:
          canvas
            ..drawCircle(
                p, r * 2.2, Paint()..color = color.withValues(alpha: 0.25))
            ..drawCircle(p, r, Paint()..color = color);
        case KitoLinePointStyle.lastPoint:
          if (i != points.length - 1) break;
          final t = pulse;
          if (t != null) {
            canvas.drawCircle(p, r * 2.6 * (0.4 + 0.6 * t),
                Paint()..color = color.withValues(alpha: 0.35 * (1 - t)));
          } else {
            canvas.drawCircle(
                p, r * 2, Paint()..color = color.withValues(alpha: 0.2));
          }
          canvas.drawCircle(p, r, Paint()..color = color);
      }
      if (style.showsValues && s < colors.length) {
        paintChartLabel(
          canvas,
          formatter(geometry.y.invert(p.dy)),
          chart.labelStyle!
              .copyWith(color: chart.labelColor, fontWeight: FontWeight.w600),
          Offset(p.dx, p.dy - math.max(r, style.lineWidth) - 3),
          alignment: Alignment.bottomCenter,
          textScaler: textScaler,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

class _CalloutLayout extends SingleChildLayoutDelegate {
  _CalloutLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints
          .loosen()
          .copyWith(maxWidth: math.min(constraints.maxWidth, 220));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double x = (anchor.dx - childSize.width / 2)
        .clamp(0.0, math.max(size.width - childSize.width, 0.0));
    var y = anchor.dy - childSize.height - 14;
    if (y < 0) y = math.min(anchor.dy + 14, size.height - childSize.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_CalloutLayout old) => old.anchor != anchor;
}

class _Callout extends StatelessWidget {
  const _Callout({required this.label, required this.rows});

  final String label;
  final List<(String?, Color, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);
    return KitoSurface(
      radius: theme.radii.md,
      elevation: 3,
      border: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: DefaultTextStyle(
        style: theme.typography.caption.copyWith(color: theme.colors.onSurface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: muted)),
            for (final (name, color, value) in rows)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted))),
                    const SizedBox(width: 8),
                  ],
                  Text(value,
                      style: (name == null
                              ? theme.typography.headline
                              : theme.typography.caption)
                          .copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colors.onSurface,
                              fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
