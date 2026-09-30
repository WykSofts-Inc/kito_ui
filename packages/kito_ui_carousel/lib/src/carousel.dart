// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'logic.dart';

/// How a [KitoCarousel]'s neighbours look as they move.
enum KitoCarouselEffect {
  /// Flat.
  none,

  /// Neighbours shrink and dim a little.
  scale,

  /// Neighbours tilt on their bottom edge and drop, like cards in a hand.
  rotate,

  /// Each item's content drifts against the scroll, like a window onto a wider scene.
  parallax,

  /// Neighbours swing round in 3D to face the centre.
  coverFlow,

  /// Neighbours fade away.
  fade,

  /// Upcoming items wait stacked behind the current one and slide out as you swipe.
  stack,
}

/// Drives a [KitoCarousel] from outside and reports where it is.
///
/// Listen to it for page changes; [position] is fractional while it moves, which is what the
/// liquid page indicators follow.
class KitoCarouselController extends ChangeNotifier {
  /// Creates a controller starting on [initialPage].
  KitoCarouselController({this.initialPage = 0});

  /// The page a carousel starts on when it attaches.
  final int initialPage;

  _KitoCarouselState? _state;
  final ValueNotifier<double> _progress = ValueNotifier(0);

  /// How far auto-play is through the current page, 0–1.
  ValueListenable<double> get autoPlayProgress => _progress;

  /// The number of pages, once attached.
  int get count => _state?.widget.itemCount ?? 0;

  /// The settled page.
  int get page => _state?._realPage ?? initialPage;

  /// The fractional page, wrapped into `0..count` when looping.
  double get position {
    final s = _state;
    if (s == null || s.widget.itemCount == 0) return initialPage.toDouble();
    final v = s._pos.value;
    final n = s.widget.itemCount;
    return s.widget.loops ? v - (v / n).floorToDouble() * n : v;
  }

  /// Moves to the next page (wrapping when looping).
  void next({bool animate = true}) => _state?._step(1, animate: animate);

  /// Moves to the previous page.
  void previous({bool animate = true}) => _state?._step(-1, animate: animate);

  /// Glides to [page], the short way round when looping.
  void animateToPage(int page) => _state?._goTo(page, animate: true);

  /// Jumps to [page].
  void jumpToPage(int page) => _state?._goTo(page, animate: false);

  /// Holds or releases auto-play, e.g. while the carousel is off screen.
  void holdAutoPlay(bool hold) => _state?._holdExternal(hold);

  void _changed() => notifyListeners();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }
}

/// A snapping carousel with neighbour effects, looping and auto-play.
///
/// ```dart
/// KitoCarousel(
///   itemCount: lodges.length,
///   itemBuilder: (context, i) => LodgeCard(lodges[i]),
///   effect: KitoCarouselEffect.coverFlow,
///   peek: 40,
///   loops: true,
///   autoPlay: const Duration(seconds: 4),
///   controller: carousel,
/// )
/// ```
///
/// Swipes snap with a spring and a selection click; a flick moves one page. Auto-play pauses
/// while a finger is down and for screen readers, and stops under Reduce Motion, which also
/// turns effects off. Screen readers hear "Page 3 of 8" and can swipe up and down to change
/// page. In right-to-left layouts the next page sits to the left.
class KitoCarousel extends StatefulWidget {
  /// Creates a carousel.
  const KitoCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onPageChanged,
    this.effect = KitoCarouselEffect.scale,
    this.peek = 32,
    this.spacing = 12,
    this.height = 220,
    this.loops = false,
    this.autoPlay,
    this.semanticLabel = 'Carousel',
  });

  /// How many items.
  final int itemCount;

  /// Builds item `index`; it's sized to the page.
  final IndexedWidgetBuilder itemBuilder;

  /// Drives the carousel from outside.
  final KitoCarouselController? controller;

  /// Called with the new page after a swipe, a tap on an indicator or auto-play.
  final ValueChanged<int>? onPageChanged;

  /// How neighbours look.
  final KitoCarouselEffect effect;

  /// How much of each neighbour shows; 0 gives full-width pages.
  final double peek;

  /// The gap between pages.
  final double spacing;

  /// The carousel's height.
  final double height;

  /// Swipes past the end come back round to the start, forever.
  final bool loops;

  /// Advances every interval; null turns auto-play off.
  final Duration? autoPlay;

  /// What screen readers call it.
  final String semanticLabel;

  @override
  State<KitoCarousel> createState() => _KitoCarouselState();
}

class _KitoCarouselState extends State<KitoCarousel>
    with TickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(
      vsync: this, value: _initialVirtual().toDouble());
  late final KitoCarouselController _controller =
      widget.controller ?? KitoCarouselController();
  late int _virtual = _initialVirtual();
  late final KitoCarouselAutoPlayClock _clock =
      KitoCarouselAutoPlayClock(widget.autoPlay ?? Duration.zero);
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  int _window = 0;
  int _pointers = 0;
  int _dragStart = 0;

  int _initialVirtual() {
    final n = widget.itemCount;
    if (n == 0) return 0;
    final start = (widget.controller?.initialPage ?? 0).clamp(0, n - 1);
    return widget.loops && n > 1 ? n * 1000 + start : start;
  }

  int get _realPage => KitoCarouselLoopMath.wrap(_virtual, widget.itemCount);

  bool get _looping => widget.loops && widget.itemCount > 1;

  @override
  void initState() {
    super.initState();
    _controller._state = this;
    _pos.addListener(_onMove);
    _window = _pos.value.round();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoPlay();
  }

  @override
  void didUpdateWidget(KitoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      widget.controller!._state = this;
    }
    if (widget.itemCount != oldWidget.itemCount ||
        widget.loops != oldWidget.loops) {
      final real =
          widget.itemCount == 0 ? 0 : _realPage.clamp(0, widget.itemCount - 1);
      _virtual = _looping ? widget.itemCount * 1000 + real : real;
      _pos.value = _virtual.toDouble();
    }
    _clock.interval = widget.autoPlay ?? Duration.zero;
    _syncAutoPlay();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _pos.dispose();
    if (_controller._state == this) _controller._state = null;
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onMove() {
    final w = _pos.value.round();
    if (w != _window) setState(() => _window = w);
    _controller._changed();
  }

  bool get _autoPlayWanted =>
      widget.autoPlay != null &&
      widget.autoPlay! > Duration.zero &&
      widget.itemCount > 1 &&
      !context.reduceMotion;

  void _syncAutoPlay() {
    if (MediaQuery.maybeAccessibleNavigationOf(context) ?? false) {
      _clock.pause(KitoCarouselPauseReason.accessibility);
    } else {
      _clock.resume(KitoCarouselPauseReason.accessibility);
    }
    if (_autoPlayWanted && _ticker == null) {
      _lastTick = Duration.zero;
      _ticker = createTicker(_onTick)..start();
    } else if (!_autoPlayWanted && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      _controller._progress.value = 0;
    }
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    if (_clock.tick(delta)) {
      if (!_looping && _realPage == widget.itemCount - 1) {
        _goTo(0, animate: true, restart: false);
      } else {
        _step(1, animate: true, restart: false);
      }
    }
    _controller._progress.value = _clock.progress;
  }

  void _holdExternal(bool hold) => hold
      ? _clock.pause(KitoCarouselPauseReason.external)
      : _clock.resume(KitoCarouselPauseReason.external);

  void _settle(int virtual) {
    final before = _realPage;
    _virtual = virtual;
    if (_realPage != before) {
      HapticFeedback.selectionClick();
      widget.onPageChanged?.call(_realPage);
      setState(() {});
    }
    _controller._changed();
  }

  void _animateTo(int virtual, {double velocity = 0, bool spring = false}) {
    final target = virtual.toDouble();
    if (context.reduceMotion && !spring) {
      _pos.value = target;
      _settle(virtual);
      return;
    }
    final future = spring
        ? _pos.animateWith(SpringSimulation(
            SpringDescription.withDampingRatio(
                mass: 1, stiffness: 240, ratio: 0.86),
            _pos.value,
            target,
            velocity,
            tolerance: const Tolerance(distance: 0.001, velocity: 0.01)))
        : _pos.animateTo(target,
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic);
    future.whenCompleteOrCancel(() {
      if (!mounted) return;
      if ((_pos.value - target).abs() < 0.01) {
        _pos.value = target;
        _settle(virtual);
      }
    });
  }

  void _step(int by, {required bool animate, bool restart = true}) {
    final n = widget.itemCount;
    if (n == 0) return;
    final target = _looping ? _virtual + by : (_virtual + by).clamp(0, n - 1);
    if (restart) _clock.restart();
    if (animate) {
      _animateTo(target);
    } else {
      _pos.value = target.toDouble();
      _settle(target);
    }
  }

  void _goTo(int page, {required bool animate, bool restart = true}) {
    final n = widget.itemCount;
    if (n == 0) return;
    final real = page.clamp(0, n - 1);
    final target = _looping
        ? KitoCarouselLoopMath.nearestVirtual(real, _virtual, n)
        : real;
    if (restart) _clock.restart();
    if (animate) {
      _animateTo(target);
    } else {
      _pos.stop();
      _pos.value = target.toDouble();
      _settle(target);
    }
  }

  // Drags.

  double _stride = 1;
  bool _rtl = false;

  void _dragStarted(DragStartDetails _) {
    _pos.stop();
    _dragStart = _pos.value.round();
    _clock.pause(KitoCarouselPauseReason.touch);
  }

  void _dragUpdated(DragUpdateDetails d) {
    var delta = -d.delta.dx * (_rtl ? -1 : 1) / _stride;
    final v = _pos.value;
    if (!_looping) {
      final max = (widget.itemCount - 1).toDouble();
      if ((v < 0 && delta < 0) || (v > max && delta > 0)) delta *= 0.3;
    }
    _pos.value = v + delta;
  }

  void _dragEnded(DragEndDetails d) {
    if (_pointers == 0) _clock.resume(KitoCarouselPauseReason.touch);
    final velocity = -(d.primaryVelocity ?? 0) * (_rtl ? -1 : 1) / _stride;
    var target = (_pos.value + velocity * 0.15).round();
    if (velocity.abs() > 0.6 && target == _dragStart) {
      target = _dragStart + velocity.sign.toInt();
    }
    target = target.clamp(_dragStart - 1, _dragStart + 1);
    if (!_looping) target = target.clamp(0, math.max(widget.itemCount - 1, 0));
    _clock.restart();
    _animateTo(target, velocity: velocity, spring: true);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.itemCount;
    _rtl = context.isRtl;
    final effect =
        context.reduceMotion ? KitoCarouselEffect.none : widget.effect;
    if (n == 0) return SizedBox(height: widget.height);

    return LayoutBuilder(builder: (context, constraints) {
      final width =
          constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
      final side = widget.peek > 0 ? widget.peek + widget.spacing : 0.0;
      final pageWidth = math.max(width - side * 2, 1.0);
      _stride = pageWidth + widget.spacing;
      final reach = effect == KitoCarouselEffect.stack ? 4 : 2;
      var from = _window - reach, to = _window + reach;
      if (!_looping) {
        from = math.max(from, 0);
        to = math.min(to, n - 1);
      }
      final virtuals = [for (var v = from; v <= to; v++) v];

      final flow = Flow(
        clipBehavior: Clip.none,
        delegate: _CarouselFlowDelegate(
          position: _pos,
          virtuals: virtuals,
          pageWidth: pageWidth,
          stride: _stride,
          height: widget.height,
          effect: effect,
          rtl: _rtl,
        ),
        children: [
          for (final v in virtuals)
            KeyedSubtree(
              key: ValueKey(v),
              child: ExcludeSemantics(
                excluding: v != _virtual,
                child: _EffectChild(
                  position: _pos,
                  virtual: v,
                  parallax: effect == KitoCarouselEffect.parallax,
                  pageWidth: pageWidth,
                  rtl: _rtl,
                  child: widget.itemBuilder(
                      context, KitoCarouselLoopMath.wrap(v, n)),
                ),
              ),
            ),
        ],
      );

      return Semantics(
        container: true,
        label: widget.semanticLabel,
        value: 'Page ${_realPage + 1} of $n',
        increasedValue:
            'Page ${KitoCarouselLoopMath.step(_realPage, 1, n, wraps: _looping) + 1} of $n',
        decreasedValue:
            'Page ${KitoCarouselLoopMath.step(_realPage, -1, n, wraps: _looping) + 1} of $n',
        onIncrease: () => _step(1, animate: true),
        onDecrease: () => _step(-1, animate: true),
        child: Listener(
          onPointerDown: (_) {
            _pointers++;
            _clock.pause(KitoCarouselPauseReason.touch);
          },
          onPointerUp: (_) => _pointerGone(),
          onPointerCancel: (_) => _pointerGone(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _dragStarted,
            onHorizontalDragUpdate: _dragUpdated,
            onHorizontalDragEnd: _dragEnded,
            child: SizedBox(
              height: widget.height,
              width: width,
              child: flow,
            ),
          ),
        ),
      );
    });
  }

  void _pointerGone() {
    _pointers = math.max(0, _pointers - 1);
    if (_pointers == 0) _clock.resume(KitoCarouselPauseReason.touch);
  }
}

/// Positions, transforms and orders the visible pages.
class _CarouselFlowDelegate extends FlowDelegate {
  _CarouselFlowDelegate({
    required this.position,
    required this.virtuals,
    required this.pageWidth,
    required this.stride,
    required this.height,
    required this.effect,
    required this.rtl,
  }) : super(repaint: position);

  final Animation<double> position;
  final List<int> virtuals;
  final double pageWidth;
  final double stride;
  final double height;
  final KitoCarouselEffect effect;
  final bool rtl;

  @override
  Size getSize(BoxConstraints constraints) =>
      Size(constraints.maxWidth, height);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(Size(pageWidth, height));

  @override
  void paintChildren(FlowPaintingContext context) {
    final pos = position.value;
    final dir = rtl ? -1.0 : 1.0;
    final order = [for (var i = 0; i < context.childCount; i++) i];
    double rel(int i) => virtuals[i] - pos;
    if (effect == KitoCarouselEffect.stack) {
      order.sort((a, b) => rel(b).compareTo(rel(a)));
    } else {
      order.sort((a, b) => rel(b).abs().compareTo(rel(a).abs()));
    }
    final left = (context.size.width - pageWidth) / 2;
    for (final i in order) {
      final p = rel(i);
      final d = math.min(p.abs(), 1.0);
      var scale = 1.0, opacity = 1.0, rotateZ = 0.0, rotateY = 0.0;
      var dx = 0.0, dy = 0.0;
      var pivot = Offset(pageWidth / 2, height / 2);
      switch (effect) {
        case KitoCarouselEffect.none:
          break;
        case KitoCarouselEffect.parallax:
          scale = 1 - 0.05 * d;
        case KitoCarouselEffect.scale:
          scale = 1 - 0.12 * d;
          opacity = 1 - 0.25 * d;
        case KitoCarouselEffect.rotate:
          rotateZ = p.clamp(-1.5, 1.5) * 9 * math.pi / 180 * dir;
          dy = 22 * d;
          scale = 1 - 0.05 * d;
          pivot = Offset(pageWidth / 2, height);
        case KitoCarouselEffect.coverFlow:
          rotateY = -p.clamp(-1.0, 1.0) * 52 * math.pi / 180 * dir;
          scale = 1 - 0.16 * d;
          dx = -p.clamp(-1.2, 1.2) * pageWidth * 0.14;
          opacity = 1 - 0.15 * d;
        case KitoCarouselEffect.fade:
          opacity = 1 - 0.7 * d;
          scale = 1 - 0.06 * d;
        case KitoCarouselEffect.stack:
          if (p > 0) {
            final depth = math.min(p, 3.0);
            dx = -depth * stride + depth * 22;
            scale = 1 - 0.07 * depth;
            opacity = p > 2.6 ? ((3.4 - p) / 0.8).clamp(0.0, 1.0) : 1;
            pivot = Offset(pageWidth, height / 2);
          } else {
            scale = 1 - 0.08 * d;
            rotateZ = p.clamp(-2.0, 2.0) * 6 * math.pi / 180 * dir;
            opacity = 1 - 0.35 * d;
          }
      }
      if (opacity <= 0.001) continue;
      final x = left + (p * stride + dx) * dir;
      final m = Matrix4.translationValues(x, dy, 0)
        ..translateByDouble(pivot.dx, pivot.dy, 0, 1);
      if (rotateY != 0) {
        m
          ..setEntry(3, 2, 0.0011)
          ..rotateY(rotateY);
      }
      if (rotateZ != 0) m.rotateZ(rotateZ);
      m
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
      context.paintChild(i, transform: m, opacity: opacity.clamp(0.0, 1.0));
    }
  }

  @override
  bool shouldRepaint(_CarouselFlowDelegate old) =>
      old.position != position ||
      old.virtuals != virtuals ||
      old.pageWidth != pageWidth ||
      old.effect != effect ||
      old.rtl != rtl;

  @override
  bool shouldRelayout(_CarouselFlowDelegate old) =>
      old.pageWidth != pageWidth || old.height != height;
}

/// One page; with [parallax] its content drifts against the scroll.
class _EffectChild extends StatelessWidget {
  const _EffectChild({
    required this.position,
    required this.virtual,
    required this.parallax,
    required this.pageWidth,
    required this.rtl,
    required this.child,
  });

  final Animation<double> position;
  final int virtual;
  final bool parallax;
  final double pageWidth;
  final bool rtl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!parallax) return RepaintBoundary(child: child);
    final radius = BorderRadius.circular(context.kito.radii.lg);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedBuilder(
          animation: position,
          builder: (context, child) {
            final p = (virtual - position.value).clamp(-1.5, 1.5);
            final shift = -p * pageWidth * 0.18 * (rtl ? -1 : 1);
            return Transform.translate(
              offset: Offset(shift, 0),
              child: Transform.scale(scale: 1.4, child: child),
            );
          },
          child: child,
        ),
      ),
    );
  }
}
