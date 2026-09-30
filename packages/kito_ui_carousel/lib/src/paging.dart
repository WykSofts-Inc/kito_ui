// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

// MARK: - Paged list

/// Full-screen vertical paging, Reels-style: one item per screen, a haptic on each snap, and the
/// leaving page easing back as the next slides up. Your builder learns whether its page is the
/// active one, so a video can play only while it's on screen.
///
/// ```dart
/// KitoPagedList(
///   itemCount: clips.length,
///   itemBuilder: (context, i, isActive) => ClipView(clips[i], playing: isActive),
///   onPageChanged: (i) => setState(() => index = i),
/// )
/// ```
class KitoPagedList extends StatefulWidget {
  /// Creates a paged list.
  const KitoPagedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.initialPage = 0,
    this.onPageChanged,
    this.tint,
  });

  /// How many pages.
  final int itemCount;

  /// Builds page `index`, and whether it's the one on screen.
  final Widget Function(BuildContext context, int index, bool isActive)
      itemBuilder;

  /// Moves the list from outside; one is made for you when null.
  final PageController? controller;

  /// The page it opens on, without a [controller].
  final int initialPage;

  /// Called with the page that settles on screen.
  final ValueChanged<int>? onPageChanged;

  /// The colour behind pages while they load; the theme's `onBackground` when null.
  final Color? tint;

  @override
  State<KitoPagedList> createState() => _KitoPagedListState();
}

class _KitoPagedListState extends State<KitoPagedList> {
  late PageController _controller =
      widget.controller ?? PageController(initialPage: widget.initialPage);
  late int _active = widget.controller?.initialPage ?? widget.initialPage;

  @override
  void didUpdateWidget(KitoPagedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ??
          PageController(initialPage: _active.clamp(0, widget.itemCount));
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _changed(int page) {
    HapticFeedback.selectionClick();
    setState(() => _active = page);
    widget.onPageChanged?.call(page);
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    final n = widget.itemCount;
    return ColoredBox(
      color: widget.tint ?? kito.colors.onBackground,
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: n,
        onPageChanged: _changed,
        itemBuilder: (context, i) => Semantics(
          container: true,
          value: '${i + 1} of $n',
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              var d = 0.0;
              if (_controller.hasClients &&
                  _controller.position.hasContentDimensions) {
                d = ((_controller.page ?? _active.toDouble()) - i)
                    .clamp(-1.0, 1.0);
              } else {
                d = (_active - i).clamp(-1, 1).toDouble();
              }
              final a = d.abs();
              Widget page = Opacity(
                opacity: 1 - a * 0.35,
                child: Transform.scale(
                    scale: reduce ? 1 : 1 - a * 0.08, child: child),
              );
              if (!reduce && a > 0.01) {
                page = ImageFiltered(
                  imageFilter:
                      ui.ImageFilter.blur(sigmaX: a * 4, sigmaY: a * 4),
                  child: page,
                );
              }
              return page;
            },
            child:
                ClipRect(child: widget.itemBuilder(context, i, i == _active)),
          ),
        ),
      ),
    );
  }
}

// MARK: - Snap grid

/// A horizontally paging grid, App Store style: items fill [rows] rows, a column snaps to the
/// leading edge after each swipe, and the next column peeks in.
///
/// ```dart
/// KitoSnapGrid(
///   itemCount: dishes.length,
///   rows: 3,
///   itemBuilder: (context, i) => DishRow(dishes[i]),
/// )
/// ```
class KitoSnapGrid extends StatefulWidget {
  /// Creates a snap grid.
  const KitoSnapGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.rows = 3,
    this.columnsPerPage = 1,
    this.rowHeight = 64,
    this.spacing = 12,
    this.peek = 28,
    this.tint,
    this.padding,
  });

  /// How many items; they fill top to bottom, then along.
  final int itemCount;

  /// Builds item `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// Rows per column.
  final int rows;

  /// Columns visible at once.
  final int columnsPerPage;

  /// One row's height.
  final double rowHeight;

  /// The gap between rows and columns.
  final double spacing;

  /// How much of the next column shows.
  final double peek;

  /// The hairline colour between rows; the theme border when null.
  final Color? tint;

  /// The inset at the leading edge; the theme's large spacing when null.
  final double? padding;

  @override
  State<KitoSnapGrid> createState() => _KitoSnapGridState();
}

class _KitoSnapGridState extends State<KitoSnapGrid> {
  final _scroll = ScrollController();
  int _column = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _onScrollEnd(ScrollEndNotification n, double stride) {
    final c = (n.metrics.pixels / stride).round();
    if (c != _column) {
      _column = c;
      HapticFeedback.selectionClick();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final rows = math.max(widget.rows, 1);
    final perPage = math.max(widget.columnsPerPage, 1);
    final columns = (widget.itemCount / rows).ceil();
    final height = rows * widget.rowHeight + (rows - 1) * widget.spacing;
    final lead = widget.padding ?? kito.spacing.lg;
    final divider = widget.tint?.withValues(alpha: 0.4) ?? kito.colors.border;
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columnWidth = math.max(
            (width -
                    lead -
                    (kito.spacing.lg + widget.peek) -
                    (perPage - 1) * widget.spacing) /
                perPage,
            1.0);
        final stride = columnWidth + widget.spacing;
        final offset = _scroll.hasClients ? _scroll.offset : 0.0;
        return NotificationListener<ScrollEndNotification>(
          onNotification: (n) => _onScrollEnd(n, stride),
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: _SnapPhysics(stride: stride),
            padding: EdgeInsetsDirectional.only(
                start: lead, end: kito.spacing.lg + widget.peek),
            itemExtent: stride,
            itemCount: columns,
            itemBuilder: (context, c) {
              // Columns only partly on screen fade back, like the next one peeking in.
              final left = c * stride - offset;
              final right = left + columnWidth;
              final visible = width - lead;
              var outside = 0.0;
              if (left < -1) outside = (-left / stride).clamp(0.0, 1.0);
              if (right > visible + 1) {
                outside = ((right - visible) / stride).clamp(0.0, 1.0);
              }
              return Padding(
                padding: EdgeInsetsDirectional.only(end: widget.spacing),
                child: Opacity(
                  opacity: 1 - outside * 0.4,
                  child: Column(children: [
                    for (var r = 0; r < rows; r++) ...[
                      if (r > 0)
                        SizedBox(
                          height: widget.spacing,
                          child: c * rows + r < widget.itemCount
                              ? Center(
                                  child: Container(height: 0.5, color: divider))
                              : null,
                        ),
                      SizedBox(
                        height: widget.rowHeight,
                        width: columnWidth,
                        child: c * rows + r < widget.itemCount
                            ? Align(
                                alignment: AlignmentDirectional.centerStart,
                                child:
                                    widget.itemBuilder(context, c * rows + r),
                              )
                            : null,
                      ),
                    ],
                  ]),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Snaps a scroll to whole multiples of [stride].
class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.stride, super.parent});

  final double stride;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(stride: stride, parent: buildParent(ancestor));

  double _target(ScrollMetrics position, double velocity) {
    var page = position.pixels / stride;
    if (velocity < -toleranceFor(position).velocity) {
      page -= 0.5;
    } else if (velocity > toleranceFor(position).velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * stride)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _target(position, velocity);
    final tolerance = toleranceFor(position);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

// MARK: - Marquee

/// Which way a [KitoInfiniteMarquee] drifts.
enum KitoMarqueeDirection {
  /// Content moves towards the leading edge.
  leading,

  /// Content moves towards the trailing edge.
  trailing,
}

/// An endless, auto-scrolling strip of logos, tags or headlines. Press and hold to stop it.
/// With Reduce Motion on it becomes a plain horizontal scroll.
///
/// ```dart
/// KitoInfiniteMarquee(
///   itemCount: partners.length,
///   itemBuilder: (context, i) => PartnerLogo(partners[i]),
///   speed: 36,
/// )
/// ```
class KitoInfiniteMarquee extends StatefulWidget {
  /// Creates a marquee.
  const KitoInfiniteMarquee({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.speed = 40,
    this.spacing = 28,
    this.direction = KitoMarqueeDirection.leading,
    this.pausesOnPress = true,
    this.fadesEdges = true,
    this.tint,
  });

  /// How many items; they repeat to fill the strip.
  final int itemCount;

  /// Builds item `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// Logical pixels per second.
  final double speed;

  /// The gap between items, and between the end and the start again.
  final double spacing;

  /// Which way it drifts.
  final KitoMarqueeDirection direction;

  /// Hold to stop.
  final bool pausesOnPress;

  /// Softens the ends of the strip.
  final bool fadesEdges;

  /// The colour of small dots between items; none when null.
  final Color? tint;

  @override
  State<KitoInfiniteMarquee> createState() => _KitoInfiniteMarqueeState();
}

class _KitoInfiniteMarqueeState extends State<KitoInfiniteMarquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _travelled = 0;
  double _rowWidth = 0;
  bool _held = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KitoInfiniteMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _moving =>
      !context.reduceMotion && widget.speed > 0 && widget.itemCount > 0;

  void _sync() {
    if (_moving && !_held && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if ((!_moving || _held) && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final delta = elapsed - _last;
    _last = elapsed;
    setState(() => _travelled +=
        widget.speed * delta.inMicroseconds / Duration.microsecondsPerSecond);
  }

  void _setHeld(bool held) {
    if (!widget.pausesOnPress || held == _held) return;
    _held = held;
    _sync();
  }

  Widget _row(BuildContext context, {bool measure = false}) {
    final children = <Widget>[];
    for (var i = 0; i < widget.itemCount; i++) {
      if (i > 0) {
        children.add(
            SizedBox(width: widget.spacing / (widget.tint == null ? 1 : 2)));
        if (widget.tint case final t?) {
          children.add(Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
                color: t.withValues(alpha: 0.5), shape: BoxShape.circle),
          ));
          children.add(SizedBox(width: widget.spacing / 2));
        }
      }
      children.add(widget.itemBuilder(context, i));
    }
    final row = Row(mainAxisSize: MainAxisSize.min, children: children);
    if (!measure) return row;
    return _MeasureWidth(
      onWidth: (w) {
        if (w != _rowWidth) setState(() => _rowWidth = w);
      },
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    Widget strip;
    if (!_moving) {
      strip = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: kito.spacing.lg),
        child: _row(context),
      );
    } else {
      strip = LayoutBuilder(builder: (context, constraints) {
        final container = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cycle = _rowWidth + widget.spacing;
        final copies = cycle > widget.spacing
            ? math.max((container / cycle).ceil() + 1, 2)
            : 1;
        final shift = cycle > widget.spacing ? _travelled % cycle : 0.0;
        final dir = context.isRtl ? -1.0 : 1.0;
        final dx = widget.direction == KitoMarqueeDirection.leading
            ? -shift * dir
            : (shift - cycle) * dir;
        return ClipRect(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _setHeld(true),
            onPointerUp: (_) => _setHeld(false),
            onPointerCancel: (_) => _setHeld(false),
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var c = 0; c < copies; c++) ...[
                    if (c > 0) SizedBox(width: widget.spacing),
                    ExcludeSemantics(
                      excluding: c > 0,
                      child: _row(context, measure: c == 0),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        );
      });
    }
    if (widget.fadesEdges) {
      strip = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          stops: [0, 0.08, 0.92, 1],
        ).createShader(rect),
        child: strip,
      );
    }
    return strip;
  }
}

/// Reports its child's laid-out width after each layout.
class _MeasureWidth extends SingleChildRenderObjectWidget {
  const _MeasureWidth({required this.onWidth, super.child});

  final ValueChanged<double> onWidth;

  @override
  _RenderMeasureWidth createRenderObject(BuildContext context) =>
      _RenderMeasureWidth(onWidth);

  @override
  void updateRenderObject(
          BuildContext context, _RenderMeasureWidth renderObject) =>
      renderObject.onWidth = onWidth;
}

class _RenderMeasureWidth extends RenderProxyBox {
  _RenderMeasureWidth(this.onWidth);

  ValueChanged<double> onWidth;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final w = size.width;
    if (w != _reported) {
      _reported = w;
      SchedulerBinding.instance.addPostFrameCallback((_) => onWidth(w));
    }
  }
}
