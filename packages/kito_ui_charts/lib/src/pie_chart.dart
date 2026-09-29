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
import 'math.dart';
import 'scale.dart';
import 'theme.dart';

/// A pie, or a donut when [holeFraction] is above zero.
///
/// Slices sweep in from the top. Tap a slice (or its legend entry) to pull it out: the others
/// dim and the hole shows its label, share and value in place of [center]. Every slice, its
/// legend swatch and the selection use the same colour: the point's own `color`, or the
/// palette by position. Slices run counter-clockwise in right-to-left layouts.
///
/// ```dart
/// KitoPieChart(
///   points: const [
///     KitoChartPoint('Rent', 45000),
///     KitoChartPoint('Food', 18000),
///     KitoChartPoint('Matatu', 6500),
///   ],
///   holeFraction: 0.62,
///   center: const Text('KSh 69.5k'),
/// )
/// ```
class KitoPieChart extends StatefulWidget {
  /// Creates a pie or donut chart.
  const KitoPieChart({
    super.key,
    required this.points,
    this.holeFraction = 0,
    this.center,
    this.size,
    this.gapDegrees = 0,
    this.showLegend = true,
    this.legendShowsShare = true,
    this.valueFormatter = KitoChartFormat.compact,
    this.shareFormatter = KitoChartFormat.percent,
    this.selectedIndex,
    this.onSelectionChanged,
    this.animatesIn = true,
    this.semanticLabel,
  });

  /// One slice per point, in order from the top.
  final List<KitoChartPoint> points;

  /// 0 draws a pie; 0.5–0.8 draws a donut with that much of the radius hollow.
  final double holeFraction;

  /// Shown in the hole while no slice is selected, e.g. the total.
  final Widget? center;

  /// The diameter. Null fills the width, up to 240.
  final double? size;

  /// A gap between slices, in degrees.
  final double gapDegrees;

  /// Shows a tappable legend below.
  final bool showLegend;

  /// Adds each slice's share to its legend entry.
  final bool legendShowsShare;

  /// Formats values in the selection readout.
  final KitoChartValueFormatter valueFormatter;

  /// Formats a 0–1 share; `42%` by default.
  final KitoChartValueFormatter shareFormatter;

  /// The pulled-out slice. The chart keeps its own selection after taps; changing this moves
  /// it.
  final int? selectedIndex;

  /// Called when a tap selects a slice, or with null when it's deselected.
  final ValueChanged<int?>? onSelectionChanged;

  /// Sweeps the slices in when the chart appears.
  final bool animatesIn;

  /// Replaces the generated screen-reader summary.
  final String? semanticLabel;

  @override
  State<KitoPieChart> createState() => _KitoPieChartState();
}

class _KitoPieChartState extends State<KitoPieChart>
    with TickerProviderStateMixin {
  late final ChartMotion _motion = ChartMotion(this,
      duration: const Duration(milliseconds: 700), values: [_values]);
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380), value: 1);
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
  void didUpdateWidget(KitoPieChart oldWidget) {
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

  void _toggle(int index) => _setSelected(_selected == index ? null : index);

  double get _total =>
      widget.points.fold(0, (sum, p) => sum + math.max(p.value, 0));

  String _share(int i) => _total <= 0
      ? ''
      : widget.shareFormatter(math.max(widget.points[i].value, 0) / _total);

  String _summary() {
    if (widget.points.isEmpty || _total <= 0) {
      return '${widget.holeFraction > 0 ? 'Donut' : 'Pie'} chart, no data';
    }
    final parts = [
      for (var i = 0; i < widget.points.length; i++)
        '${widget.points[i].label} ${_share(i)}'
    ];
    return '${widget.holeFraction > 0 ? 'Donut' : 'Pie'} chart, '
        '${widget.points.length} slices: ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final chart = KitoChartTheme.of(context);
    final rtl = context.isRtl;
    final colors = [
      for (var i = 0; i < widget.points.length; i++)
        widget.points[i].color ?? chart.colorAt(i)
    ];
    final hole = widget.holeFraction.clamp(0.0, 0.92);

    return LayoutBuilder(builder: (context, constraints) {
      final available =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 240.0;
      final diameter = math.min(widget.size ?? 240.0, available);
      final pie = SizedBox.square(
        dimension: diameter,
        child: AnimatedBuilder(
          animation: Listenable.merge([_motion.listenable, _pop]),
          builder: (context, _) {
            final reveal = widget.animatesIn
                ? Curves.easeOutCubic.transform(_motion.reveal.value)
                : 1.0;
            final slices =
                KitoChartMath.pieSlices(_motion.current.first, clockwise: !rtl);
            final pop = theme.motion.spring.transform(_pop.value);
            final radius = diameter / 2 - 10;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final i = KitoChartMath.pieSliceAt(
                    d.localPosition, Offset(diameter / 2, diameter / 2), slices,
                    outerRadius: radius + 10, innerRadius: radius * hole);
                if (i != null) _toggle(i);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PiePainter(
                        slices: slices,
                        colors: colors,
                        hole: hole,
                        radius: radius,
                        reveal: reveal,
                        selected: _selected,
                        previous: _previous,
                        pop: pop,
                        gap: widget.gapDegrees * math.pi / 180,
                        rtl: rtl,
                        surface: theme.colors.surface,
                      ),
                    ),
                  ),
                  _centerContent(context,
                      radius * 2 * math.max(hole, 0.5) * 0.78, hole > 0),
                ],
              ),
            );
          },
        ),
      );
      final body = Semantics(
        container: true,
        label: widget.semanticLabel ?? _summary(),
        value: _selected == null
            ? null
            : '${widget.points[_selected!].label}, ${_share(_selected!)}, '
                '${widget.valueFormatter(widget.points[_selected!].value)}',
        child: ExcludeSemantics(child: Center(child: pie)),
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
                    value: widget.legendShowsShare ? _share(i) : null),
            ],
          ),
        ],
      );
    });
  }

  Widget _centerContent(BuildContext context, double width, bool donut) {
    final theme = context.kito;
    final selected = _selected;
    Widget child;
    if (selected != null && selected < widget.points.length) {
      final info = Column(
        key: ValueKey(selected),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.points[selected].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onSurface.withValues(alpha: 0.65))),
          Text(_share(selected),
              style: theme.typography.title.copyWith(
                  color: theme.colors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          if (donut)
            Text(widget.valueFormatter(widget.points[selected].value),
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onSurface.withValues(alpha: 0.65))),
        ],
      );
      child = donut
          ? info
          : KitoSurface(
              key: ValueKey(selected),
              radius: theme.radii.md,
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: info);
    } else if (donut && widget.center != null) {
      child = KeyedSubtree(
          key: const ValueKey('center'),
          child: DefaultTextStyle(
              style: theme.typography.headline
                  .copyWith(color: theme.colors.onSurface),
              textAlign: TextAlign.center,
              child: widget.center!));
    } else {
      child = const SizedBox.shrink(key: ValueKey('none'));
    }
    return IgnorePointer(
      child: SizedBox(
        width: math.max(width, 1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedSwitcher(
            duration: KitoMotion.of(context, theme.motion.medium),
            switchInCurve: theme.motion.spring,
            transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: child)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.slices,
    required this.colors,
    required this.hole,
    required this.radius,
    required this.reveal,
    required this.selected,
    required this.previous,
    required this.pop,
    required this.gap,
    required this.rtl,
    required this.surface,
  });

  final List<KitoPieSlice> slices;
  final List<Color> colors;
  final double hole;
  final double radius;
  final double reveal;
  final int? selected;
  final int? previous;
  final double pop;
  final double gap;
  final bool rtl;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (slices.isEmpty) {
      canvas.drawCircle(
          center,
          radius * (1 - hole / 2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * (1 - hole)
            ..color = surface.withValues(alpha: 0.5));
      return;
    }
    final start = slices.first.startAngle;
    final scale = 0.9 + 0.1 * reveal;
    final outer = radius * scale;
    final inner = outer * hole;
    for (final slice in slices) {
      final amount = (slice.index == selected ? 1.0 : 0.0) * pop +
          (slice.index == previous ? 1.0 : 0.0) * (1 - pop);
      final dim =
          selected == null ? 1.0 : (slice.index == selected ? 1.0 : 0.45);
      final dimBefore =
          previous == null ? 1.0 : (slice.index == previous ? 1.0 : 0.45);
      final opacity = lerpDouble(dimBefore, dim, pop.clamp(0.0, 1.0))!;
      var a = start + (slice.startAngle - start) * reveal;
      var sweep = slice.sweepAngle * reveal;
      if (gap > 0 && sweep.abs() > gap) {
        a += gap / 2 * sweep.sign;
        sweep -= gap * sweep.sign;
      }
      if (sweep == 0) continue;
      final mid = a + sweep / 2;
      final offset = Offset(math.cos(mid), math.sin(mid)) * (8 * amount);
      final c = center + offset;
      final path = _wedge(c, outer, inner, a, sweep);
      final color = colors[slice.index % colors.length];
      if (amount > 0.01) {
        canvas.drawShadow(
            path, Colors.black.withValues(alpha: 0.5 * amount), 4, false);
      }
      canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              colors: [
                shadeChartColor(color, 0.06).withValues(alpha: opacity),
                color.withValues(alpha: opacity),
              ],
              stops: [hole, 1],
            ).createShader(Rect.fromCircle(center: c, radius: outer)));
      if (gap <= 0 && slices.length > 1) {
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = surface);
      }
    }
  }

  static Path _wedge(
      Offset c, double outer, double inner, double start, double sweep) {
    final full = sweep.abs() >= 2 * math.pi - 1e-6;
    if (full) {
      final path = Path()..addOval(Rect.fromCircle(center: c, radius: outer));
      if (inner > 0) {
        path
          ..addOval(Rect.fromCircle(center: c, radius: inner))
          ..fillType = PathFillType.evenOdd;
      }
      return path;
    }
    final path = Path()
      ..moveTo(c.dx + inner * math.cos(start), c.dy + inner * math.sin(start))
      ..lineTo(c.dx + outer * math.cos(start), c.dy + outer * math.sin(start))
      ..arcTo(Rect.fromCircle(center: c, radius: outer), start, sweep, false);
    if (inner > 0) {
      path.arcTo(Rect.fromCircle(center: c, radius: inner), start + sweep,
          -sweep, false);
    } else {
      path.lineTo(c.dx, c.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_PiePainter old) => true;
}
