// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A height a Kito sheet can rest at.
@immutable
class KitoSheetDetent {
  const KitoSheetDetent._(this._kind, [this.value = 0]);

  /// Exactly as tall as the sheet's content (grabber and header included).
  static const fit = KitoSheetDetent._(_DetentKind.fit);

  /// Nearly the full screen, stopping just below the status bar.
  static const large = KitoSheetDetent._(_DetentKind.large);

  /// Half the screen.
  static const medium = KitoSheetDetent.fraction(0.5);

  /// A fraction of the screen's height, 0.05–1.
  const KitoSheetDetent.fraction(double fraction)
      : this._(_DetentKind.fraction, fraction);

  /// A fixed height in logical pixels.
  const KitoSheetDetent.height(double height)
      : this._(_DetentKind.height, height);

  final _DetentKind _kind;

  /// The fraction or height; 0 for [fit] and [large].
  final double value;

  @override
  bool operator ==(Object other) =>
      other is KitoSheetDetent && other._kind == _kind && other.value == value;

  @override
  int get hashCode => Object.hash(_kind, value);

  @override
  String toString() => switch (_kind) {
        _DetentKind.fit => 'KitoSheetDetent.fit',
        _DetentKind.large => 'KitoSheetDetent.large',
        _DetentKind.fraction => 'KitoSheetDetent.fraction($value)',
        _DetentKind.height => 'KitoSheetDetent.height($value)',
      };
}

enum _DetentKind { fit, fraction, height, large }

/// How a Kito sheet sits on screen.
enum KitoSheetStyle {
  /// Full width, rounded top corners, running under the home indicator.
  attached,

  /// A card inset from the edges and the bottom, rounded all round.
  floating,

  /// Attached, on frosted glass that blurs what's behind it.
  glass,
}

/// How a Kito sheet treats its content.
enum KitoSheetContentMode {
  /// The content keeps its natural height and the whole sheet is draggable. Best for short
  /// content such as a confirmation or a picker.
  fitted,

  /// The content is a scroll view (a `ListView`, a `CustomScrollView`…) that scrolls inside
  /// the sheet. The sheet drags from the grabber and header, or when the content is pulled
  /// down while scrolled to its top (and pushed up while the sheet isn't at its tallest).
  scrollable,
}

/// Everything about how a Kito sheet looks and behaves.
@immutable
class KitoSheetConfiguration {
  /// Creates a configuration; the defaults give a fitted, attached sheet with a grabber.
  const KitoSheetConfiguration({
    List<KitoSheetDetent> detents = const [KitoSheetDetent.fit],
    this.initialDetent = 0,
    this.style = KitoSheetStyle.attached,
    this.showsGrabber = true,
    this.dismissesOnBackdropTap = true,
    this.dismissesOnDrag = true,
    this.backdropOpacity = 0.4,
    this.blursBackdrop = false,
    this.cornerRadius = 32,
    this.background,
    this.contentMode = KitoSheetContentMode.fitted,
    this.semanticLabel = 'Sheet',
    this.dismissLabel = 'Dismiss',
  }) : _detents = detents;

  /// Scrollable content with the given detents.
  const KitoSheetConfiguration.scrollable({
    List<KitoSheetDetent> detents = const [
      KitoSheetDetent.fraction(0.55),
      KitoSheetDetent.large,
    ],
    this.initialDetent = 0,
    this.style = KitoSheetStyle.attached,
    this.showsGrabber = true,
    this.dismissesOnBackdropTap = true,
    this.dismissesOnDrag = true,
    this.backdropOpacity = 0.4,
    this.blursBackdrop = false,
    this.cornerRadius = 32,
    this.background,
    this.semanticLabel = 'Sheet',
    this.dismissLabel = 'Dismiss',
  })  : _detents = detents,
        contentMode = KitoSheetContentMode.scrollable;

  final List<KitoSheetDetent> _detents;

  /// The heights the sheet rests at, in any order. Never empty: an empty list means
  /// `[KitoSheetDetent.fit]`.
  List<KitoSheetDetent> get detents =>
      _detents.isEmpty ? const [KitoSheetDetent.fit] : _detents;

  /// Which of [detents] the sheet opens at.
  final int initialDetent;

  /// Attached, floating or glass.
  final KitoSheetStyle style;

  /// Draws the small capsule at the top.
  final bool showsGrabber;

  /// Tap outside to dismiss.
  final bool dismissesOnBackdropTap;

  /// Drag down past the lowest detent (or fling down) to dismiss.
  final bool dismissesOnDrag;

  /// How dark the screen behind gets, 0–1.
  final double backdropOpacity;

  /// Blurs what's behind while the sheet is up.
  final bool blursBackdrop;

  /// The sheet's corner radius.
  final double cornerRadius;

  /// The sheet's fill; the theme's surface colour when null.
  final Color? background;

  /// Fitted (default) or scrollable content.
  final KitoSheetContentMode contentMode;

  /// What screen readers call the sheet.
  final String semanticLabel;

  /// The screen-reader label of the backdrop that dismisses the sheet.
  final String dismissLabel;

  /// A copy with some fields replaced.
  KitoSheetConfiguration copyWith({
    List<KitoSheetDetent>? detents,
    int? initialDetent,
    KitoSheetStyle? style,
    bool? showsGrabber,
    bool? dismissesOnBackdropTap,
    bool? dismissesOnDrag,
    double? backdropOpacity,
    bool? blursBackdrop,
    double? cornerRadius,
    Color? background,
    KitoSheetContentMode? contentMode,
    String? semanticLabel,
    String? dismissLabel,
  }) =>
      KitoSheetConfiguration(
        detents: detents ?? _detents,
        initialDetent: initialDetent ?? this.initialDetent,
        style: style ?? this.style,
        showsGrabber: showsGrabber ?? this.showsGrabber,
        dismissesOnBackdropTap:
            dismissesOnBackdropTap ?? this.dismissesOnBackdropTap,
        dismissesOnDrag: dismissesOnDrag ?? this.dismissesOnDrag,
        backdropOpacity: backdropOpacity ?? this.backdropOpacity,
        blursBackdrop: blursBackdrop ?? this.blursBackdrop,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        background: background ?? this.background,
        contentMode: contentMode ?? this.contentMode,
        semanticLabel: semanticLabel ?? this.semanticLabel,
        dismissLabel: dismissLabel ?? this.dismissLabel,
      );
}

/// The maths behind a Kito sheet's drag, public so it's easy to reason about and test.
abstract final class KitoSheetMath {
  /// The room the grabber takes: 10 above, 5 tall, 6 below.
  static const double grabberExtent = 21;

  /// The shortest a sheet ever gets.
  static const double minHeight = 60;

  /// A detent's height. [content] is the measured header plus content; `fit` adds the
  /// grabber's room and a little breathing space. Results are clamped between [minHeight]
  /// and the large height (the screen minus the top inset and 10).
  static double resolve(
    KitoSheetDetent detent, {
    required double content,
    required double screen,
    required double topInset,
    required bool grabber,
  }) {
    final largest = screen - topInset - 10;
    final value = switch (detent._kind) {
      _DetentKind.fit => content + (grabber ? grabberExtent : 0) + 8,
      _DetentKind.fraction => screen * detent.value.clamp(0.05, 1.0),
      _DetentKind.height => detent.value,
      _DetentKind.large => largest,
    };
    return math.min(math.max(value, minHeight), largest);
  }

  /// Dragging up past the tallest detent gets harder the further you go: [overshoot] is how
  /// far past, and the result how far the sheet actually grows (never more than 12% of
  /// [limit]).
  static double rubberBand(double overshoot, double limit) {
    if (overshoot <= 0) return overshoot;
    final k = limit * 0.12;
    return k * (1 - 1 / (overshoot / k + 1));
  }

  /// The sheet's height mid-drag. Down ([drag] > 0) shrinks it one-for-one; up grows it
  /// one-for-one to [tallest], then rubber-bands.
  static double visibleHeight(
      {required double current,
      required double tallest,
      required double drag}) {
    if (drag >= 0) return math.max(current - drag, 0);
    final up = -drag;
    final room = math.max(tallest - current, 0.0);
    return current +
        math.min(up, room) +
        rubberBand(math.max(up - room, 0), tallest);
  }

  /// The index of the height in [heights] closest to [height].
  static int nearestDetent(double height, List<double> heights) {
    var best = 0;
    for (var i = 1; i < heights.length; i++) {
      if ((heights[i] - height).abs() < (heights[best] - height).abs()) {
        best = i;
      }
    }
    return best;
  }

  /// Where a released drag goes: the index of the detent to settle at, or null to dismiss.
  ///
  /// [visible] is the height at release and [velocity] the finger's vertical speed in
  /// pixels per second (positive is downward); a fling carries the sheet about a fifth of a
  /// second further. It dismisses when [dismissible] and the projected height falls below
  /// 55% of the lowest detent.
  static int? settle({
    required List<double> heights,
    required double visible,
    required double velocity,
    required bool dismissible,
  }) {
    final projected = visible - velocity * 0.2;
    final lowest = heights.reduce(math.min);
    if (dismissible && projected < lowest * 0.55) return null;
    return nearestDetent(projected, heights);
  }
}

/// Lets content inside a Kito sheet move or close it. Get it with [KitoSheetController.of].
abstract class KitoSheetController {
  /// The detents the sheet was shown with.
  List<KitoSheetDetent> get detents;

  /// The detent the sheet rests at (or is heading to).
  int get detentIndex;

  /// Animates to `detents[index]`.
  void snapTo(int index);

  /// Closes the sheet, completing `showKitoSheet`'s future with [result].
  void dismiss([Object? result]);

  /// The controller of the nearest enclosing sheet, or null outside one.
  static KitoSheetController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KitoSheetScope>()?.controller;

  /// The controller of the nearest enclosing sheet.
  static KitoSheetController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'KitoSheetController.of: no Kito sheet here.');
    return controller!;
  }
}

class _KitoSheetScope extends InheritedWidget {
  const _KitoSheetScope(
      {required this.controller, required this.index, required super.child});

  final KitoSheetController controller;
  final int index;

  @override
  bool updateShouldNotify(_KitoSheetScope oldWidget) =>
      oldWidget.index != index || oldWidget.controller != controller;
}

/// Shows a custom bottom sheet: detents you drag between, rubber-banding past the top,
/// drag-down, tap-outside and Escape to dismiss, and attached, floating or glass styles.
///
/// [builder] is the content. With [KitoSheetContentMode.scrollable] it should return a scroll
/// view; the sheet's scroll controller is its primary one, so a plain `ListView` picks it up.
/// [headerBuilder] is an optional fixed header (a title, a search field) above the content;
/// it never scrolls, and in scrollable mode it's the part you drag, with the grabber.
///
/// The future completes with whatever the sheet is dismissed with.
///
/// ```dart
/// final colour = await showKitoSheet<Color>(
///   context: context,
///   configuration: const KitoSheetConfiguration(
///     detents: [KitoSheetDetent.fit, KitoSheetDetent.large],
///     style: KitoSheetStyle.floating,
///   ),
///   builder: (context) => ColourPicker(
///     onPicked: (c) => KitoSheetController.of(context).dismiss(c),
///   ),
/// );
/// ```
Future<T?> showKitoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  WidgetBuilder? headerBuilder,
  KitoSheetConfiguration configuration = const KitoSheetConfiguration(),
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final reduce = KitoMotion.reduced(context);
  return navigator.push(KitoSheetRoute<T>(
    builder: builder,
    headerBuilder: headerBuilder,
    configuration: configuration,
    reduceMotion: reduce,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    settings: routeSettings,
  ));
}

/// The route behind [showKitoSheet], for pushing a Kito sheet yourself (for example with a
/// `Navigator` in a nested flow).
class KitoSheetRoute<T> extends PopupRoute<T> {
  /// Creates a sheet route.
  KitoSheetRoute({
    required this.builder,
    this.headerBuilder,
    this.configuration = const KitoSheetConfiguration(),
    this.reduceMotion = false,
    this.capturedThemes,
    super.settings,
  });

  /// The content.
  final WidgetBuilder builder;

  /// An optional fixed header.
  final WidgetBuilder? headerBuilder;

  /// How the sheet looks and behaves.
  final KitoSheetConfiguration configuration;

  /// Fades instead of sliding.
  final bool reduceMotion;

  /// Themes captured from where the sheet was shown.
  final CapturedThemes? capturedThemes;

  @override
  Color? get barrierColor => null;

  /// Escape and the back button close the sheet when a tap outside would.
  @override
  bool get barrierDismissible => configuration.dismissesOnBackdropTap;

  @override
  String? get barrierLabel => configuration.dismissLabel;

  /// The sheet draws its own backdrop, which fades as you drag.
  @override
  Widget buildModalBarrier() => const SizedBox.shrink();

  @override
  Duration get transitionDuration => reduceMotion
      ? const Duration(milliseconds: 200)
      : const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => reduceMotion
      ? const Duration(milliseconds: 180)
      : const Duration(milliseconds: 280);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final frame = _KitoSheetFrame<T>(route: this);
    return capturedThemes?.wrap(frame) ?? frame;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      child;
}

/// Coordinates a drag on scrollable content with the sheet: while [pulling], the content
/// ignores the finger and the sheet moves instead.
class _PullLink {
  bool pulling = false;
  bool suppressBallistic = false;
}

class _SheetPullPhysics extends ScrollPhysics {
  const _SheetPullPhysics(this.link, {super.parent});

  final _PullLink link;

  @override
  _SheetPullPhysics applyTo(ScrollPhysics? ancestor) =>
      _SheetPullPhysics(link, parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (link.pulling) return 0;
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((link.pulling || link.suppressBallistic) && !position.outOfRange) {
      return null;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class _KitoSheetFrame<T> extends StatefulWidget {
  const _KitoSheetFrame({super.key, required this.route});

  final KitoSheetRoute<T> route;

  @override
  State<_KitoSheetFrame<T>> createState() => _KitoSheetFrameState<T>();
}

class _KitoSheetFrameState<T> extends State<_KitoSheetFrame<T>>
    with SingleTickerProviderStateMixin
    implements KitoSheetController {
  /// For attached sheets the fill runs this far below the screen, so a springy entrance or
  /// a rubber-band never shows a gap under the sheet.
  static const double _underflow = 48;

  late final AnimationController _settle =
      AnimationController.unbounded(vsync: this)
        ..addListener(() => setState(() {}))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            if (mounted) setState(() => _settling = false);
          }
        });

  late int _index;
  double _drag = 0;
  bool _settling = false;
  bool _dismissing = false;
  double _contentHeight = 0;
  double _headerHeight = 0;
  double? _scrollExtent;
  List<double> _heights = const [];

  final _link = _PullLink();
  final ScrollController _scroll = ScrollController();
  bool _atTop = true;
  int? _pointer;
  VelocityTracker? _tracker;
  Offset _pending = Offset.zero;
  bool _decided = false;
  bool _horizontal = false;

  KitoSheetConfiguration get _config => widget.route.configuration;
  bool get _scrollable =>
      _config.contentMode == KitoSheetContentMode.scrollable;

  @override
  void initState() {
    super.initState();
    _index = _config.initialDetent.clamp(0, _config.detents.length - 1);
  }

  @override
  void dispose() {
    _settle.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // KitoSheetController

  @override
  List<KitoSheetDetent> get detents => _config.detents;

  @override
  int get detentIndex => _index;

  @override
  void snapTo(int index) {
    if (_heights.isEmpty) return;
    final target = index.clamp(0, _heights.length - 1);
    final from = _currentVisible();
    setState(() {
      _index = target;
      _drag = 0;
    });
    _animateTo(from, _heights[target], 0);
  }

  @override
  void dismiss([Object? result]) {
    if (_dismissing) return;
    _dismissing = true;
    final route = widget.route;
    final navigator = route.navigator;
    if (navigator == null) return;
    if (route.isCurrent) {
      navigator.pop(result as T?);
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }
  }

  // Heights

  double _resolvedCurrent() =>
      _heights.isEmpty ? 0 : _heights[math.min(_index, _heights.length - 1)];

  double _tallest() => _heights.isEmpty ? 0 : _heights.reduce(math.max);

  double _currentVisible() {
    if (_settling) return _settle.value;
    return KitoSheetMath.visibleHeight(
        current: _resolvedCurrent(), tallest: _tallest(), drag: _drag);
  }

  void _animateTo(double from, double to, double velocity) {
    _settling = true;
    if (context.reduceMotion) {
      _settle.value = from;
      _settle.animateTo(to,
          duration: const Duration(milliseconds: 220), curve: Curves.easeInOut);
      return;
    }
    const spring = SpringDescription(mass: 1, stiffness: 230, damping: 25.5);
    _settle.animateWith(SpringSimulation(spring, from, to, velocity));
  }

  // Drag

  void _dragStart() {
    if (_settling) {
      final value = _settle.value;
      _settle.stop();
      _settling = false;
      final current = _resolvedCurrent();
      final tallest = _tallest();
      _drag = value <= current
          ? current - value
          : -math.min(value - current, math.max(tallest - current, 0)) -
              math.max(value - tallest, 0);
    }
  }

  void _dragUpdate(double dy) {
    if (_dismissing) return;
    setState(() => _drag += dy);
  }

  void _dragEnd(double velocity) {
    if (_dismissing || _heights.isEmpty) return;
    final visible = _currentVisible();
    final target = KitoSheetMath.settle(
      heights: _heights,
      visible: visible,
      velocity: velocity,
      dismissible: _config.dismissesOnDrag,
    );
    if (target == null) {
      // Keep the drag so the exit slides on from where the finger let go.
      dismiss();
      return;
    }
    setState(() {
      _index = target;
      _drag = 0;
    });
    _animateTo(visible, _heights[target], -velocity);
  }

  // Scrollable content: pull the sheet from the content's top.

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _tracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _pending = Offset.zero;
    _decided = false;
    _horizontal = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _tracker?.addPosition(event.timeStamp, event.position);
    if (!_decided) {
      _pending += event.delta;
      if (_pending.distance < 6) return;
      _decided = true;
      _horizontal = _pending.dy.abs() < _pending.dx.abs();
      if (!_horizontal) _maybeStartPull(_pending.dy);
      return;
    }
    if (_horizontal) return;
    if (_link.pulling) {
      _applyPull(event.delta.dy);
    } else {
      _maybeStartPull(event.delta.dy);
    }
  }

  void _maybeStartPull(double dy) {
    if (!_atTop || dy == 0 || _dismissing) return;
    final canGrow = _currentVisible() < _tallest() - 0.5;
    if (dy > 0 || canGrow) {
      _link.pulling = true;
      _dragStart();
      _applyPull(dy);
    }
  }

  /// Moves the sheet with the finger; hands the finger back to the content once the sheet
  /// is back at rest (pushing up) or has reached its tallest detent.
  void _applyPull(double dy) {
    final room = math.max(_tallest() - _resolvedCurrent(), 0.0);
    var next = _drag + dy;
    if (next <= -room) {
      next = -room;
      _link.pulling = false;
    } else if (_drag > 0 && next <= 0 && room <= 0.5) {
      next = 0;
      _link.pulling = false;
    }
    if (_dismissing) return;
    setState(() => _drag = next);
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    final velocity = _tracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    _tracker = null;
    if (_link.pulling) {
      _link.pulling = false;
      _link.suppressBallistic = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _link.suppressBallistic = false);
      _dragEnd(velocity);
    } else if (_drag != 0 && !_settling) {
      _dragEnd(0);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    _atTop = notification.metrics.extentBefore <= 0.5;
    return false;
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final m = notification.metrics;
    _atTop = m.extentBefore <= 0.5;
    final extent = m.maxScrollExtent - m.minScrollExtent + m.viewportDimension;
    if (_scrollExtent == null || (extent - _scrollExtent!).abs() > 0.5) {
      _scrollExtent = extent;
      if (_config.detents.contains(KitoSheetDetent.fit)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
    return false;
  }

  void _measured(double height, {required bool header}) {
    final old = header ? _headerHeight : _contentHeight;
    if ((old - height).abs() < 0.5) return;
    if (header) {
      _headerHeight = height;
    } else {
      _contentHeight = height;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final media = MediaQuery.of(context);
    final route = widget.route;
    final reduce = route.reduceMotion || context.reduceMotion;
    final animation = CurvedAnimation(
      parent: route.animation!,
      curve: reduce ? Curves.easeOut : const KitoSpringCurve(damping: 0.86),
      reverseCurve: Curves.easeInCubic,
    );
    final floating = _config.style == KitoSheetStyle.floating;
    final bottomInset = media.padding.bottom;
    final keyboard = media.viewInsets.bottom;

    return LayoutBuilder(builder: (context, constraints) {
      final screen = constraints.maxHeight - keyboard;
      final measured = _scrollable
          ? _headerHeight + (_scrollExtent ?? screen)
          : _contentHeight;
      _heights = [
        for (final d in _config.detents)
          KitoSheetMath.resolve(d,
              content: measured,
              screen: screen,
              topInset: media.padding.top,
              grabber: _config.showsGrabber),
      ];
      final visible = _currentVisible();
      final current = _resolvedCurrent();
      final dragFade = current <= 0
          ? 0.0
          : (1 - (math.max(current - visible, 0) / current)).clamp(0.0, 1.0);

      return _KitoSheetScope(
        controller: this,
        index: _index,
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: route.animation!,
              builder: (context, child) {
                final t = route.animation!.value.clamp(0.0, 1.0);
                Widget dim = ColoredBox(
                    color: Colors.black.withValues(
                        alpha: _config.backdropOpacity * t * dragFade));
                if (_config.blursBackdrop) {
                  dim = BackdropFilter(
                      filter: ui.ImageFilter.blur(
                          sigmaX: 6 * t * dragFade, sigmaY: 6 * t * dragFade),
                      child: dim);
                }
                return dim;
              },
            ),
          ),
          Positioned.fill(
            child: Semantics(
              button: _config.dismissesOnBackdropTap,
              label:
                  _config.dismissesOnBackdropTap ? _config.dismissLabel : null,
              onTap: _config.dismissesOnBackdropTap ? dismiss : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: _config.dismissesOnBackdropTap ? dismiss : null,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final t = animation.value;
                final travel = visible +
                    (floating ? math.max(bottomInset, 10) : bottomInset) +
                    24;
                final dy = reduce ? 0.0 : travel * (1 - t);
                final opacity =
                    reduce ? route.animation!.value.clamp(0.0, 1.0) : 1.0;
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                      offset: Offset(0, floating ? dy : dy + _underflow),
                      child: child),
                );
              },
              child: _sheet(theme, visible, bottomInset, floating, screen),
            ),
          ),
        ]),
      );
    });
  }

  Widget _sheet(KitoTheme theme, double visible, double bottomInset,
      bool floating, double screen) {
    final r = Radius.circular(_config.cornerRadius);
    final radius =
        floating ? BorderRadius.all(r) : BorderRadius.vertical(top: r);
    final fill = _config.background ??
        (_config.style == KitoSheetStyle.glass
            ? theme.colors.surface.withValues(alpha: 0.72)
            : theme.colors.surface);
    final underflow = floating ? 0.0 : _underflow;
    final innerBottom = floating ? 0.0 : bottomInset + underflow;

    final grabber = _config.showsGrabber
        ? Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colors.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )
        : const SizedBox.shrink();

    final header = widget.route.headerBuilder;
    Widget body;
    if (_scrollable) {
      final top = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _dragStart(),
        onVerticalDragUpdate: (d) => _dragUpdate(d.delta.dy),
        onVerticalDragEnd: (d) => _dragEnd(d.velocity.pixelsPerSecond.dy),
        child: SizedBox(
          width: double.infinity,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            grabber,
            if (header != null)
              _Measure(
                onHeight: (h) => _measured(h, header: true),
                child: Builder(builder: header),
              ),
          ]),
        ),
      );
      final behavior = ScrollConfiguration.of(context);
      final content = ScrollConfiguration(
        behavior: behavior.copyWith(
            physics: _SheetPullPhysics(_link,
                parent: behavior.getScrollPhysics(context))),
        child: PrimaryScrollController(
          controller: _scroll,
          automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerEnd,
                onPointerCancel: _onPointerEnd,
                child: Builder(builder: widget.route.builder),
              ),
            ),
          ),
        ),
      );
      body = Column(children: [top, Expanded(child: content)]);
    } else {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _dragStart(),
        onVerticalDragUpdate: (d) => _dragUpdate(d.delta.dy),
        onVerticalDragEnd: (d) => _dragEnd(d.velocity.pixelsPerSecond.dy),
        child: Column(children: [
          grabber,
          Expanded(
            child: _TopMeasure(
              maxHeight: screen,
              onHeight: (h) => _measured(h, header: false),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (header != null) Builder(builder: header),
                Builder(builder: widget.route.builder),
              ]),
            ),
          ),
        ]),
      );
    }

    Widget sheet = Padding(
      padding: EdgeInsets.only(bottom: innerBottom),
      child: body,
    );
    sheet = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: sheet,
    );
    if (_config.style == KitoSheetStyle.glass) {
      sheet = BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: sheet);
    }
    sheet = ClipRRect(borderRadius: radius, child: sheet);
    if (fill.a > 0.01) {
      sheet = DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, -4)),
        ]),
        child: sheet,
      );
    }
    sheet = SizedBox(
      height: math.max(visible, 0) + innerBottom,
      width: double.infinity,
      child: sheet,
    );
    if (floating) {
      sheet = Padding(
        padding: EdgeInsets.only(
            left: 10, right: 10, bottom: math.max(bottomInset, 10)),
        child: sheet,
      );
    }
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: _config.semanticLabel,
      onDismiss: dismiss,
      child: sheet,
    );
  }
}

/// Reports its child's height after each layout.
class _Measure extends SingleChildRenderObjectWidget {
  const _Measure({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasure(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasure renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}

/// Fills the space it's given, lays its child out at its natural height (up to a generous
/// cap) at the top, reports that height, and clips what doesn't fit — so a fitted sheet can
/// measure its content while it's shorter than it (mid-drag or mid-entrance).
class _TopMeasure extends SingleChildRenderObjectWidget {
  const _TopMeasure(
      {required this.onHeight, required this.maxHeight, super.child});

  final ValueChanged<double> onHeight;
  final double maxHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTopMeasure(onHeight, maxHeight);

  @override
  void updateRenderObject(
      BuildContext context, _RenderTopMeasure renderObject) {
    renderObject
      ..onHeight = onHeight
      ..maxHeight = maxHeight;
  }
}

class _RenderTopMeasure extends RenderProxyBox {
  _RenderTopMeasure(this.onHeight, this._maxHeight);

  ValueChanged<double> onHeight;

  double _maxHeight;
  set maxHeight(double value) {
    if (value == _maxHeight) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    child.layout(
        BoxConstraints(
            minWidth: size.width,
            maxWidth: size.width,
            maxHeight: math.max(_maxHeight, size.height)),
        parentUsesSize: true);
    onHeight(child.size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (child.size.height > size.height) {
      context.pushClipRect(needsCompositing, offset, Offset.zero & size,
          (context, offset) => context.paintChild(child, offset));
    } else {
      context.paintChild(child, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).contains(position)) return false;
    return super.hitTestChildren(result, position: position);
  }
}
