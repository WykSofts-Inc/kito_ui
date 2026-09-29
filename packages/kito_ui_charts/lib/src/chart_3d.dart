// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'data.dart';
import 'legend.dart';
import 'math.dart';
import 'scale.dart';
import 'theme.dart';

/// Bars drawn as lit blocks with a top and a side, in an oblique projection. Pure painting:
/// no 3D engine, so it's cheap enough for a dashboard card.
///
/// Drag sideways to turn the blocks between a side-on and a top-down view. Tap a bar to
/// highlight it. The side faces point toward the end of the reading direction, so the chart
/// mirrors in right-to-left layouts.
///
/// ```dart
/// KitoBar3DChart(points: const [
///   KitoChartPoint('Nairobi', 420),
///   KitoChartPoint('Mombasa', 260),
///   KitoChartPoint('Kisumu', 180),
/// ])
/// ```
class KitoBar3DChart extends StatefulWidget {
  /// Creates a faux-3D bar chart.
  const KitoBar3DChart({
    super.key,
    required this.points,
    this.height = 240,
    this.depth = 16,
    this.angle = 38,
    this.turnable = true,
    this.showsValues = true,
    this.valueFormatter = KitoChartFormat.compact,
    this.selectedIndex,
    this.onSelectionChanged,
    this.animatesIn = true,
    this.tint,
    this.semanticLabel,
  });

  /// One block per point; a point's own colour wins over [tint] and the palette.
  final List<KitoChartPoint> points;

  /// The chart's height.
  final double height;

  /// How deep each block is, in logical pixels.
  final double depth;

  /// The viewing angle in degrees: near 0 looks from the side, near 90 from above.
  final double angle;

  /// Lets a sideways drag turn the view between 12° and 78°.
  final bool turnable;

  /// Shows each block's value above it.
  final bool showsValues;

  /// Formats values.
  final KitoChartValueFormatter valueFormatter;

  /// The highlighted block.
  final int? selectedIndex;

  /// Called when a tap selects a block, or with null when it's deselected.
  final ValueChanged<int?>? onSelectionChanged;

  /// Raises the blocks when the chart appears.
  final bool animatesIn;

  /// One colour for every block (a point's own colour still wins). Null uses the palette by
  /// position.
  final Color? tint;

  /// Replaces the generated screen-reader summary.
  final String? semanticLabel;

  @override
  State<KitoBar3DChart> createState() => _KitoBar3DChartState();
}

class _KitoBar3DChartState extends State<KitoBar3DChart>
    with TickerProviderStateMixin {
  late final ChartMotion _motion = ChartMotion(this,
      duration: const Duration(milliseconds: 700), values: [_values]);
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250), value: 1);
  late double _angle = widget.angle;
  bool _started = false;
  int? _selected;
  int? _previous;

  List<double> get _values => [for (final p in widget.points) p.value];

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
  void didUpdateWidget(KitoBar3DChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motion.update([_values],
        animate: !context.reduceMotion,
        duration: KitoChartTheme.of(context).animationDuration);
    if (widget.angle != oldWidget.angle) _angle = widget.angle;
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

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final chart = KitoChartTheme.of(context);
    final rtl = context.isRtl;
    final textScaler = MediaQuery.textScalerOf(context);
    final colors = [
      for (var i = 0; i < widget.points.length; i++)
        widget.points[i].color ?? widget.tint ?? chart.colorAt(i)
    ];
    final summary = widget.points.isEmpty
        ? '3D bar chart, no data'
        : '3D bar chart, ${widget.points.length} bars';

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? summary,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = Size(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
              widget.height);
          return AnimatedBuilder(
            animation: Listenable.merge([_motion.listenable, _fade]),
            builder: (context, _) {
              final geometry = _Bar3DGeometry.compute(
                values: _motion.current.first,
                size: size,
                depth: widget.depth,
                angle: _angle,
                rtl: rtl,
                labelHeight: measureChartLabel('0', chart.labelStyle!,
                        textScaler: textScaler)
                    .height,
                valuePad: widget.showsValues ? 18 : 4,
              );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: widget.turnable
                    ? (d) => setState(() => _angle =
                        (_angle + d.delta.dx * (rtl ? 0.4 : -0.4))
                            .clamp(12.0, 78.0))
                    : null,
                child: Stack(children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _Bar3DPainter(
                        geometry: geometry,
                        points: widget.points,
                        colors: colors,
                        chart: chart,
                        floor: theme.colors.surfaceMuted,
                        strong: theme.colors.onSurface,
                        reveal: widget.animatesIn ? _motion.reveal.value : 1,
                        spring: theme.motion.spring,
                        selected: _selected,
                        previous: _previous,
                        fade: _fade.value,
                        showsValues: widget.showsValues,
                        formatter: widget.valueFormatter,
                        textScaler: textScaler,
                      ),
                    ),
                  ),
                  for (var i = 0; i < geometry.bands.length; i++)
                    Positioned.fromRect(
                      rect: geometry.bands[i],
                      child: Semantics(
                        button: true,
                        selected: _selected == i,
                        label: '${widget.points[i].label}, '
                            '${widget.valueFormatter(widget.points[i].value)}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _setSelected(_selected == i ? null : i),
                        ),
                      ),
                    ),
                ]),
              );
            },
          );
        }),
      ),
    );
  }
}

class _Bar3DGeometry {
  _Bar3DGeometry(
      this.fronts, this.bands, this.offset, this.baseline, this.plot);

  factory _Bar3DGeometry.compute({
    required List<double> values,
    required Size size,
    required double depth,
    required double angle,
    required bool rtl,
    required double labelHeight,
    required double valuePad,
  }) {
    final radians = angle * math.pi / 180;
    final offset = Offset(
        depth * math.cos(radians) * (rtl ? -1 : 1), -depth * math.sin(radians));
    final plot = Rect.fromLTRB(
      8 + (rtl ? offset.dx.abs() : 0),
      valuePad + offset.dy.abs(),
      size.width - 8 - (rtl ? 0 : offset.dx.abs()),
      size.height - labelHeight - 10,
    );
    final n = values.length;
    final maxValue = values.fold<double>(0, (m, v) => math.max(m, v));
    final scale =
        KitoChartScale(0, maxValue <= 0 ? 1 : maxValue, plot.bottom, plot.top);
    final band = n == 0 ? plot.width : plot.width / n;
    final width = math.min(band * 0.58, 56.0);
    final fronts = <Rect>[];
    final bands = <Rect>[];
    for (var i = 0; i < n; i++) {
      final center =
          rtl ? plot.right - (i + 0.5) * band : plot.left + (i + 0.5) * band;
      final top = scale(math.max(values[i], 0));
      fronts.add(Rect.fromLTRB(center - width / 2,
          math.min(top, plot.bottom - 1), center + width / 2, plot.bottom));
      bands.add(Rect.fromLTWH(center - band / 2, 0, band, size.height));
    }
    return _Bar3DGeometry(fronts, bands, offset, plot.bottom, plot);
  }

  final List<Rect> fronts;
  final List<Rect> bands;
  final Offset offset;
  final double baseline;
  final Rect plot;
}

class _Bar3DPainter extends CustomPainter {
  _Bar3DPainter({
    required this.geometry,
    required this.points,
    required this.colors,
    required this.chart,
    required this.floor,
    required this.strong,
    required this.reveal,
    required this.spring,
    required this.selected,
    required this.previous,
    required this.fade,
    required this.showsValues,
    required this.formatter,
    required this.textScaler,
  });

  final _Bar3DGeometry geometry;
  final List<KitoChartPoint> points;
  final List<Color> colors;
  final KitoChartTheme chart;
  final Color floor;
  final Color strong;
  final double reveal;
  final Curve spring;
  final int? selected;
  final int? previous;
  final double fade;
  final bool showsValues;
  final KitoChartValueFormatter formatter;
  final TextScaler textScaler;

  double _opacity(int? sel, int i) => sel == null || sel == i ? 1 : 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    final d = geometry.offset;
    final plot = geometry.plot;
    final base = geometry.baseline;

    // The floor the blocks stand on.
    final floorPath = Path()
      ..moveTo(plot.left - 4, base)
      ..lineTo(plot.right + 4, base)
      ..lineTo(plot.right + 4 + d.dx, base + d.dy)
      ..lineTo(plot.left - 4 + d.dx, base + d.dy)
      ..close();
    canvas.drawPath(floorPath, Paint()..color = floor);

    // Draw away from the side faces, so a block's side hides behind its neighbour.
    final order = [for (var i = 0; i < geometry.fronts.length; i++) i];
    order.sort((a, b) => d.dx >= 0
        ? geometry.fronts[a].left.compareTo(geometry.fronts[b].left)
        : geometry.fronts[b].left.compareTo(geometry.fronts[a].left));

    for (final i in order) {
      final full = geometry.fronts[i];
      final t = spring
          .transform(staggeredChartProgress(reveal, i, geometry.fronts.length));
      final top = base - (base - full.top) * t;
      final front =
          Rect.fromLTRB(full.left, math.min(top, base), full.right, base);
      final opacity =
          lerpDouble(_opacity(previous, i), _opacity(selected, i), fade)!;
      final color = colors[i % colors.length];
      Color tone(double amount) =>
          shadeChartColor(color, amount).withValues(alpha: opacity);

      // Soft contact shadow on the floor.
      canvas.drawPath(
          Path()
            ..moveTo(front.left, base)
            ..lineTo(front.right, base)
            ..lineTo(front.right + d.dx * 1.6, base + d.dy * 0.2)
            ..lineTo(front.left + d.dx * 1.6, base + d.dy * 0.2)
            ..close(),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.12 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

      final sideX = d.dx >= 0 ? front.right : front.left;
      final side = Path()
        ..moveTo(sideX, front.top)
        ..lineTo(sideX + d.dx, front.top + d.dy)
        ..lineTo(sideX + d.dx, base + d.dy)
        ..lineTo(sideX, base)
        ..close();
      canvas.drawPath(side, Paint()..color = tone(-0.16));

      final lid = Path()
        ..moveTo(front.left, front.top)
        ..lineTo(front.right, front.top)
        ..lineTo(front.right + d.dx, front.top + d.dy)
        ..lineTo(front.left + d.dx, front.top + d.dy)
        ..close();
      canvas.drawPath(lid, Paint()..color = tone(0.14));

      canvas.drawRect(
          front,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [tone(0.04), tone(-0.06)],
            ).createShader(front));

      final labelStyle = chart.labelStyle!.copyWith(
          color: selected == i ? strong : chart.labelColor,
          fontWeight: selected == i ? FontWeight.w700 : null);
      paintChartLabel(canvas, points[i].label, labelStyle,
          Offset(front.center.dx + d.dx / 2, base + 6),
          alignment: Alignment.topCenter,
          textScaler: textScaler,
          maxWidth: math.max(geometry.bands[i].width + 6, 1));
      if ((showsValues || selected == i) && t > 0.6) {
        final alpha = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
        paintChartLabel(
          canvas,
          formatter(points[i].value),
          chart.labelStyle!.copyWith(
              color: strong.withValues(alpha: alpha * opacity),
              fontWeight: FontWeight.w700),
          Offset(front.center.dx + d.dx / 2, front.top + d.dy - 3),
          alignment: Alignment.bottomCenter,
          textScaler: textScaler,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Bar3DPainter old) => true;
}

/// A tilted pie or donut with depth: lit side walls, a visible inner wall through the hole,
/// and slices that lift out when selected. Pure painting, no 3D engine.
///
/// Drag sideways to spin it (it keeps turning briefly after a flick, unless Reduce Motion is
/// on). Tap a slice or its legend entry to select it. Slices run counter-clockwise in
/// right-to-left layouts.
///
/// ```dart
/// KitoPie3DChart(
///   points: const [
///     KitoChartPoint('Safaricom', 64),
///     KitoChartPoint('Airtel', 31),
///     KitoChartPoint('Telkom', 5),
///   ],
///   holeFraction: 0.45,
/// )
/// ```
class KitoPie3DChart extends StatefulWidget {
  /// Creates a faux-3D pie or donut.
  const KitoPie3DChart({
    super.key,
    required this.points,
    this.holeFraction = 0,
    this.tilt = 0.52,
    this.depth = 22,
    this.size,
    this.spinnable = true,
    this.showLegend = true,
    this.shareFormatter = KitoChartFormat.percent,
    this.selectedIndex,
    this.onSelectionChanged,
    this.animatesIn = true,
    this.semanticLabel,
  });

  /// One slice per point.
  final List<KitoChartPoint> points;

  /// 0 for a pie, up to about 0.8 for a donut.
  final double holeFraction;

  /// How squashed the disc looks: 1 is straight down, 0.3 is nearly edge-on.
  final double tilt;

  /// The wall height, in logical pixels.
  final double depth;

  /// The disc's width. Null fills the width, up to 280.
  final double? size;

  /// Lets a sideways drag spin the disc.
  final bool spinnable;

  /// Shows a tappable legend below.
  final bool showLegend;

  /// Formats a 0–1 share for the legend and screen readers.
  final KitoChartValueFormatter shareFormatter;

  /// The lifted slice.
  final int? selectedIndex;

  /// Called when a tap selects a slice, or with null when it's deselected.
  final ValueChanged<int?>? onSelectionChanged;

  /// Raises and sweeps the disc in when it appears.
  final bool animatesIn;

  /// Replaces the generated screen-reader summary.
  final String? semanticLabel;

  @override
  State<KitoPie3DChart> createState() => _KitoPie3DChartState();
}

class _KitoPie3DChartState extends State<KitoPie3DChart>
    with TickerProviderStateMixin {
  late final ChartMotion _motion = ChartMotion(this,
      duration: const Duration(milliseconds: 800), values: [_values]);
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  late final AnimationController _spin =
      AnimationController.unbounded(vsync: this);
  bool _started = false;
  int? _selected;
  int? _previous;

  List<double> get _values => [for (final p in widget.points) p.value];

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
  void didUpdateWidget(KitoPie3DChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motion.update([_values],
        animate: !context.reduceMotion,
        duration: KitoChartTheme.of(context).animationDuration);
    if (_selected != null && _selected! >= widget.points.length) {
      _selected = _previous = null;
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _setSelected(widget.selectedIndex, notify: false);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _pop.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _setSelected(int? index, {bool notify = true}) {
    if (index == _selected) return;
    setState(() {
      _previous = _selected;
      _selected = index;
    });
    if (context.reduceMotion) {
      _pop.value = 1;
    } else {
      _pop.forward(from: 0);
    }
    if (notify) {
      HapticFeedback.selectionClick();
      widget.onSelectionChanged?.call(index);
    }
  }

  void _toggle(int i) => _setSelected(_selected == i ? null : i);

  double get _total =>
      widget.points.fold(0, (sum, p) => sum + math.max(p.value, 0));

  String _share(int i) => _total <= 0
      ? ''
      : widget.shareFormatter(math.max(widget.points[i].value, 0) / _total);

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final chart = KitoChartTheme.of(context);
    final rtl = context.isRtl;
    final colors = [
      for (var i = 0; i < widget.points.length; i++)
        widget.points[i].color ?? chart.colorAt(i)
    ];
    final tilt = widget.tilt.clamp(0.25, 1.0);
    final hole = widget.holeFraction.clamp(0.0, 0.85);
    final summary = widget.points.isEmpty || _total <= 0
        ? '3D pie chart, no data'
        : '3D pie chart, ${widget.points.length} slices: ${[
            for (var i = 0; i < widget.points.length; i++)
              '${widget.points[i].label} ${_share(i)}'
          ].join(', ')}';

    return LayoutBuilder(builder: (context, constraints) {
      final available =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
      final width = math.min(widget.size ?? 280.0, available);
      final rx = width / 2 - 12;
      final height = rx * 2 * tilt + widget.depth + 28;
      final disc = SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: Listenable.merge([_motion.listenable, _pop, _spin]),
          builder: (context, _) {
            final reveal = widget.animatesIn
                ? Curves.easeOutCubic.transform(_motion.reveal.value)
                : 1.0;
            final slices = KitoChartMath.pieSlices(_motion.current.first,
                startAngle: -math.pi / 2 + _spin.value, clockwise: !rtl);
            final center = Offset(width / 2, 14 + rx * tilt);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart:
                  widget.spinnable ? (_) => _spin.stop() : null,
              onHorizontalDragUpdate: widget.spinnable
                  ? (d) => _spin.value -= d.delta.dx / rx
                  : null,
              onHorizontalDragEnd: widget.spinnable
                  ? (d) {
                      if (context.reduceMotion) return;
                      final v = -d.velocity.pixelsPerSecond.dx / rx;
                      _spin.animateWith(
                          FrictionSimulation(0.12, _spin.value, v));
                    }
                  : null,
              onTapUp: (d) {
                final local = d.localPosition - center;
                final flat = Offset(local.dx, local.dy / tilt);
                final i = KitoChartMath.pieSliceAt(flat, Offset.zero, slices,
                    outerRadius: rx + 6, innerRadius: rx * hole);
                if (i != null) _toggle(i);
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: _Pie3DPainter(
                  slices: slices,
                  colors: colors,
                  center: center,
                  rx: rx,
                  tilt: tilt,
                  depth: widget.depth * (0.2 + 0.8 * reveal),
                  hole: hole,
                  reveal: reveal,
                  selected: _selected,
                  previous: _previous,
                  pop: theme.motion.spring.transform(_pop.value),
                  shadow: theme.brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.18),
                ),
              ),
            );
          },
        ),
      );
      final body = Semantics(
        container: true,
        label: widget.semanticLabel ?? summary,
        value: _selected == null
            ? null
            : '${widget.points[_selected!].label}, ${_share(_selected!)}',
        child: ExcludeSemantics(child: Center(child: disc)),
      );
      if (!widget.showLegend) return body;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          SizedBox(height: theme.spacing.md),
          KitoChartLegend(
            alignment: WrapAlignment.center,
            highlighted: _selected,
            onTap: _toggle,
            entries: [
              for (var i = 0; i < widget.points.length; i++)
                KitoChartLegendEntry(widget.points[i].label, colors[i],
                    value: _share(i)),
            ],
          ),
        ],
      );
    });
  }
}

class _Pie3DPainter extends CustomPainter {
  _Pie3DPainter({
    required this.slices,
    required this.colors,
    required this.center,
    required this.rx,
    required this.tilt,
    required this.depth,
    required this.hole,
    required this.reveal,
    required this.selected,
    required this.previous,
    required this.pop,
    required this.shadow,
  });

  final List<KitoPieSlice> slices;
  final List<Color> colors;
  final Offset center;
  final double rx;
  final double tilt;
  final double depth;
  final double hole;
  final double reveal;
  final int? selected;
  final int? previous;
  final double pop;
  final Color shadow;

  Offset _at(Offset c, double r, double a, [double drop = 0]) =>
      Offset(c.dx + r * math.cos(a), c.dy + r * tilt * math.sin(a) + drop);

  /// [a]…[b] (a < b) clipped to where sin is positive (front) or negative (back).
  static List<(double, double)> _visible(double a, double b, bool front) {
    final out = <(double, double)>[];
    final base = (a / math.pi).floor() - 1;
    for (var k = base; k <= (b / math.pi).ceil() + 1; k++) {
      final isFront = k.isEven;
      if (isFront != front) continue;
      final s = math.max(a, k * math.pi), e = math.min(b, (k + 1) * math.pi);
      if (e > s) out.add((s, e));
    }
    return out;
  }

  Path _wall(Offset c, double r, double s, double e) {
    final path = Path()..moveTo(_at(c, r, s).dx, _at(c, r, s).dy);
    const steps = 24;
    for (var i = 1; i <= steps; i++) {
      final p = _at(c, r, s + (e - s) * i / steps);
      path.lineTo(p.dx, p.dy);
    }
    for (var i = steps; i >= 0; i--) {
      final p = _at(c, r, s + (e - s) * i / steps, depth);
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Path _top(Offset c, double outer, double inner, double s, double e) {
    const steps = 48;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final p = _at(c, outer, s + (e - s) * i / steps);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    if (inner > 0) {
      for (var i = steps; i >= 0; i--) {
        final p = _at(c, inner, s + (e - s) * i / steps);
        path.lineTo(p.dx, p.dy);
      }
    } else {
      path.lineTo(c.dx, c.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Ground shadow, with the hole left clear.
    final ground = center + Offset(0, depth + 4);
    final shadowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCenter(
          center: ground, width: rx * 2.05, height: rx * 2 * tilt * 1.05));
    if (hole > 0) {
      shadowPath.addOval(Rect.fromCenter(
          center: ground,
          width: rx * hole * 2.1,
          height: rx * hole * 2 * tilt * 1.1));
    }
    canvas.drawPath(
        shadowPath,
        Paint()
          ..color = shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    if (slices.isEmpty) return;

    final start = slices.first.startAngle;
    final inner = rx * hole;
    final parts = <(KitoPieSlice, double, double, double, double)>[];
    for (final slice in slices) {
      var a = start + (slice.startAngle - start) * reveal;
      var b = a + slice.sweepAngle * reveal;
      if (b < a) (a, b) = (b, a);
      if (b - a <= 0) continue;
      final amount = (slice.index == selected ? 1.0 : 0.0) * pop +
          (slice.index == previous ? 1.0 : 0.0) * (1 - pop);
      final lifted =
          selected == null ? 1.0 : (slice.index == selected ? 1.0 : 0.55);
      final before =
          previous == null ? 1.0 : (slice.index == previous ? 1.0 : 0.55);
      parts.add((
        slice,
        a,
        b,
        amount,
        lerpDouble(before, lifted, pop.clamp(0.0, 1.0))!
      ));
    }

    void drawSlice((KitoPieSlice, double, double, double, double) part,
        {required bool walls, required bool top}) {
      final (slice, a, b, amount, opacity) = part;
      final mid = (a + b) / 2;
      final c = center +
          Offset(math.cos(mid), math.sin(mid) * tilt) * (12 * amount) +
          Offset(0, -6 * amount);
      final color = colors[slice.index % colors.length];
      Color tone(double v) =>
          shadeChartColor(color, v).withValues(alpha: opacity);
      if (walls) {
        if (inner > 0) {
          for (final (s, e) in _visible(a, b, false)) {
            canvas.drawPath(
                _wall(c, inner, s, e), Paint()..color = tone(-0.22));
          }
        }
        for (final (s, e) in _visible(a, b, true)) {
          final wall = _wall(c, rx, s, e);
          canvas.drawPath(
              wall,
              Paint()
                ..shader = LinearGradient(colors: [
                  tone(-0.2),
                  tone(-0.08),
                  tone(-0.2),
                ]).createShader(Rect.fromLTRB(
                    c.dx - rx, c.dy, c.dx + rx, c.dy + rx * tilt + depth)));
        }
        if (amount > 0.01) {
          // Cut faces, visible once the slice lifts away from its neighbours.
          for (final angle in [a, b]) {
            final face = Path()
              ..moveTo(_at(c, inner, angle).dx, _at(c, inner, angle).dy)
              ..lineTo(_at(c, rx, angle).dx, _at(c, rx, angle).dy)
              ..lineTo(_at(c, rx, angle, depth).dx, _at(c, rx, angle, depth).dy)
              ..lineTo(_at(c, inner, angle, depth).dx,
                  _at(c, inner, angle, depth).dy)
              ..close();
            canvas.drawPath(face, Paint()..color = tone(-0.28));
          }
        }
      }
      if (top) {
        final path = _top(c, rx, inner, a, b);
        canvas.drawPath(
            path,
            Paint()
              ..shader = RadialGradient(
                center: const Alignment(-0.3, -0.6),
                radius: 1.1,
                colors: [tone(0.1), tone(0)],
              ).createShader(Rect.fromCenter(
                  center: c, width: rx * 2, height: rx * 2 * tilt)));
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8
              ..color = Colors.white.withValues(alpha: 0.25 * opacity));
      }
    }

    final flat = parts.where((p) => p.$4 <= 0.01).toList();
    final lifted = parts.where((p) => p.$4 > 0.01).toList()
      ..sort((x, y) =>
          math.sin((x.$2 + x.$3) / 2).compareTo(math.sin((y.$2 + y.$3) / 2)));
    for (final p in flat) {
      drawSlice(p, walls: true, top: false);
    }
    for (final p in flat) {
      drawSlice(p, walls: false, top: true);
    }
    for (final p in lifted) {
      drawSlice(p, walls: true, top: true);
    }
  }

  @override
  bool shouldRepaint(_Pie3DPainter old) => true;
}
