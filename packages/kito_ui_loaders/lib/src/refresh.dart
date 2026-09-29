// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'indicators.dart';
import 'loader_strings.dart';

/// A pull-to-refresh indicator: a ring that draws itself as you pull, an arrow that flips once
/// you've pulled far enough, then a spinning gradient ring while refreshing.
/// [KitoLoaderPullToRefresh] wires it up; use it alone to drive your own.
class KitoLoaderRefreshIndicator extends StatelessWidget {
  /// Creates an indicator; [pullProgress] is clamped to 0–1.
  const KitoLoaderRefreshIndicator({
    super.key,
    required this.pullProgress,
    required this.isRefreshing,
    this.size = 30,
    this.color,
  });

  /// How far the pull is towards triggering, 0–1.
  final double pullProgress;

  /// Spinning while the refresh runs.
  final bool isRefreshing;

  /// The ring's diameter.
  final double size;

  /// Colour; the theme's primary when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final tint = color ?? kito.colors.primary;
    final p = pullProgress.clamp(0.0, 1.0);
    final duration = KitoMotion.of(context, kito.motion.medium);
    return Semantics(
      container: true,
      liveRegion: isRefreshing,
      label: KitoLoaderStrings.of(
          context, isRefreshing ? 'refreshing' : 'pullToRefresh'),
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: isRefreshing ? 1 : 0.6 + 0.4 * p,
          duration: duration,
          curve: kito.motion.spring,
          child: AnimatedOpacity(
            opacity: isRefreshing ? 1 : math.min(p * 2, 1),
            duration: kito.motion.fast,
            child: Container(
              width: size + 14,
              height: size + 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kito.colors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, a) => ScaleTransition(
                    scale: a, child: FadeTransition(opacity: a, child: child)),
                child: isRefreshing
                    ? KitoLoaderGradientRing(
                        key: const ValueKey('refreshing'),
                        size: size,
                        strokeWidth: 3,
                        colors: [tint.withValues(alpha: 0), tint],
                      )
                    : SizedBox.square(
                        key: const ValueKey('pulling'),
                        dimension: size,
                        child: Stack(alignment: Alignment.center, children: [
                          Transform.rotate(
                            angle: (p * 120) * math.pi / 180,
                            child: CustomPaint(
                              size: Size.square(size),
                              painter: _TrimPainter(tint, p * 0.92),
                            ),
                          ),
                          Opacity(
                            opacity: 0.3 + 0.7 * p,
                            child: AnimatedRotation(
                              turns: p >= 1 ? 0.5 : 0,
                              duration: duration,
                              curve: kito.motion.spring,
                              child: Icon(Icons.arrow_downward_rounded,
                                  size: size * 0.5, color: tint),
                            ),
                          ),
                        ]),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrimPainter extends CustomPainter {
  _TrimPainter(this.color, this.fraction);
  final Color color;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    canvas.drawArc(
      (Offset.zero & size).deflate(1.5),
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TrimPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// Pull-to-refresh with [KitoLoaderRefreshIndicator] for any vertical scrollable [child]:
/// pull past [threshold] and [onRefresh] runs, holding the indicator open until it completes.
///
/// Works with bouncing (iOS) and clamping (Android) physics; give the scrollable
/// `AlwaysScrollableScrollPhysics` so short lists can be pulled too.
///
/// ```dart
/// KitoLoaderPullToRefresh(
///   onRefresh: () => feed.reload(),
///   child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: posts),
/// )
/// ```
class KitoLoaderPullToRefresh extends StatefulWidget {
  /// Creates a pull-to-refresh wrapper.
  const KitoLoaderPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.threshold = 80,
    this.color,
  });

  /// Runs when the pull passes [threshold].
  final Future<void> Function() onRefresh;

  /// The scrollable.
  final Widget child;

  /// How far to pull, in logical pixels.
  final double threshold;

  /// Indicator colour.
  final Color? color;

  /// How far the pull is towards triggering, 0–1.
  static double progress(double pull, double threshold) =>
      threshold <= 0 ? 1 : (pull / threshold).clamp(0.0, 1.0);

  /// The indicator follows the pull at 60% speed, starting tucked above the top edge.
  static double indicatorOffset(double pull) => -44 + math.max(pull, 0) * 0.6;

  @override
  State<KitoLoaderPullToRefresh> createState() =>
      _KitoLoaderPullToRefreshState();
}

class _KitoLoaderPullToRefreshState extends State<KitoLoaderPullToRefresh> {
  double _pull = 0;
  bool _refreshing = false;
  bool _armed = true;
  bool _dragging = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    var pull = _pull;
    if (n is ScrollStartNotification) {
      _dragging = n.dragDetails != null;
    } else if (n is ScrollUpdateNotification) {
      if (n.dragDetails == null && !_dragging) {
        // Ballistic: follow a bounce back, else let go.
        pull = math.max(n.metrics.minScrollExtent - n.metrics.pixels, 0);
      } else if (n.metrics.pixels < n.metrics.minScrollExtent) {
        pull = n.metrics.minScrollExtent - n.metrics.pixels;
      } else if (pull > 0 && (n.scrollDelta ?? 0) > 0) {
        pull = math.max(0, pull - n.scrollDelta!);
      }
    } else if (n is OverscrollNotification) {
      if (n.dragDetails != null && n.overscroll < 0) {
        pull += -n.overscroll * 0.5;
      }
    } else if (n is ScrollEndNotification) {
      _dragging = false;
      if (n.metrics.pixels >= n.metrics.minScrollExtent) pull = 0;
    }
    if (pull < 4) _armed = true;
    if (pull != _pull) setState(() => _pull = pull);
    if (_armed && !_refreshing && _pull >= widget.threshold) {
      _armed = false;
      _refresh();
    }
    return false;
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final offset =
        _refreshing ? 12.0 : KitoLoaderPullToRefresh.indicatorOffset(_pull);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          AnimatedPositioned(
            duration: _dragging
                ? Duration.zero
                : KitoMotion.of(context, kito.motion.medium),
            curve: kito.motion.standard,
            top: offset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: KitoLoaderRefreshIndicator(
                  pullProgress:
                      KitoLoaderPullToRefresh.progress(_pull, widget.threshold),
                  isRefreshing: _refreshing,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
