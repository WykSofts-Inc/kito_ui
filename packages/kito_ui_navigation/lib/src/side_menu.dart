// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Which side a [KitoSideMenu] opens from. Directional: [start] is the left in left-to-right
/// layouts and the right in right-to-left ones.
enum KitoSideMenuEdge {
  /// The leading edge.
  start,

  /// The trailing edge.
  end,
}

/// How the drawer and the screen move when a [KitoSideMenu] opens.
enum KitoSideMenuStyle {
  /// The drawer slides in and pushes the screen aside with it.
  push,

  /// The drawer slides over the screen, which dims and stays put.
  overlay,

  /// The drawer waits underneath; the screen slides away to reveal it.
  reveal,

  /// The screen shrinks into a rounded card and slides aside, the drawer behind it.
  scale,

  /// The screen swings away in perspective.
  rotate3D,

  /// The drawer is a rounded card inset from the edges, over a softened screen.
  floating;

  /// Styles that draw the drawer behind the screen, on a full-screen background.
  bool get drawerIsBehind =>
      this == reveal || this == scale || this == rotate3D;
}

/// Opens and closes a [KitoSideMenu], and reports how open it is while it moves.
class KitoSideMenuController extends ChangeNotifier {
  /// Creates a controller.
  KitoSideMenuController({bool isOpen = false})
      : _isOpen = isOpen,
        _progress = ValueNotifier(isOpen ? 1 : 0);

  bool _isOpen;
  final ValueNotifier<double> _progress;

  /// Whether the menu is open (or opening).
  bool get isOpen => _isOpen;

  set isOpen(bool value) {
    if (value == _isOpen) return;
    _isOpen = value;
    notifyListeners();
  }

  /// How open the drawer looks, 0–1, following drags and animations.
  ValueListenable<double> get progress => _progress;

  /// Opens the menu.
  void open() => isOpen = true;

  /// Closes the menu.
  void close() => isOpen = false;

  /// Opens a closed menu and closes an open one.
  void toggle() => isOpen = !_isOpen;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }
}

/// The side menu's drag maths, public so it's easy to reason about and test.
abstract final class KitoSideMenuMath {
  /// How open the drawer looks, 0–1, from its resting state and a drag along the opening
  /// direction (positive opens).
  static double progress(
      {required bool isOpen,
      required double translation,
      required double width}) {
    if (width <= 0) return isOpen ? 1 : 0;
    return ((isOpen ? 1 : 0) + translation / width).clamp(0.0, 1.0);
  }

  /// Where a released drag settles: open past halfway, counting a fling. [velocity] is in
  /// pixels per second along the opening direction.
  static bool settlesOpen(
      {required double progress,
      required double velocity,
      required double width}) {
    if (width <= 0) return progress > 0.5;
    if (velocity.abs() > 700) return velocity > 0;
    return progress + velocity * 0.2 / width > 0.5;
  }

  /// +1 when the drawer sits on the physical left (so opening drags go right), −1 otherwise.
  static double openingSign(KitoSideMenuEdge edge, TextDirection direction) =>
      (edge == KitoSideMenuEdge.start) == (direction == TextDirection.ltr)
          ? 1
          : -1;
}

/// A swipeable side menu around [child]: drag it open or closed, or drive it with a
/// [KitoSideMenuController]. It closes on a tap on the screen, a swipe back, Escape or the
/// accessibility dismiss action. The drawer opens from the start edge by default, so it
/// comes from the right in right-to-left layouts.
///
/// ```dart
/// KitoSideMenu(
///   controller: menu,
///   style: KitoSideMenuStyle.scale,
///   background: const KitoBackground.gradient(KitoGradient.ocean),
///   foreground: Colors.white,
///   menu: const DrawerContent(),
///   child: const HomeScreen(),
/// )
/// ```
class KitoSideMenu extends StatefulWidget {
  /// Creates a side menu.
  const KitoSideMenu({
    super.key,
    required this.controller,
    required this.menu,
    required this.child,
    this.width = 300,
    this.style = KitoSideMenuStyle.push,
    this.edge = KitoSideMenuEdge.start,
    this.background,
    this.foreground,
    this.edgeDragWidth,
    this.semanticLabel = 'Menu',
    this.closeLabel = 'Close menu',
  });

  /// Opens and closes it.
  final KitoSideMenuController controller;

  /// The drawer's content.
  final Widget menu;

  /// The screen.
  final Widget child;

  /// The drawer's width.
  final double width;

  /// How the drawer and screen move.
  final KitoSideMenuStyle style;

  /// Which side it opens from.
  final KitoSideMenuEdge edge;

  /// What the drawer sits on; the theme's surface when null. With the behind styles it fills
  /// the whole screen, so a colour or gradient reads best.
  final KitoBackground? background;

  /// Text and icon colour inside the drawer; the theme's on-surface when null.
  final Color? foreground;

  /// When set, a closed menu only opens from drags starting this close to its edge.
  final double? edgeDragWidth;

  /// What screen readers call the drawer.
  final String semanticLabel;

  /// The screen-reader label of the screen while it's covered.
  final String closeLabel;

  @override
  State<KitoSideMenu> createState() => _KitoSideMenuState();
}

class _KitoSideMenuState extends State<KitoSideMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _p =
      AnimationController(vsync: this, value: widget.controller.isOpen ? 1 : 0)
        ..addListener(_report);
  bool _dragging = false;
  double _sign = 1;
  final FocusNode _drawerFocus = FocusNode(debugLabel: 'KitoSideMenu drawer');
  bool _wasOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    if (widget.controller.isOpen) _moveFocus();
  }

  @override
  void didUpdateWidget(KitoSideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _p.value = widget.controller.isOpen ? 1 : 0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _p.dispose();
    _drawerFocus.dispose();
    super.dispose();
  }

  void _report() {
    widget.controller._progress.value = _p.value;
  }

  void _sync({double velocity = 0}) {
    _moveFocus();
    if (_dragging) return;
    _animateTo(widget.controller.isOpen ? 1 : 0, velocity: velocity);
  }

  /// Moves keyboard focus into the drawer when it opens, and lets it go when it closes.
  void _moveFocus() {
    final open = widget.controller.isOpen;
    if (open == _wasOpen) return;
    _wasOpen = open;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.isOpen) {
        _drawerFocus.requestFocus();
      } else if (_drawerFocus.hasFocus) {
        _drawerFocus.unfocus();
      }
    });
  }

  void _animateTo(double target, {double velocity = 0}) {
    if (context.reduceMotion) {
      _p.animateTo(target,
          duration: const Duration(milliseconds: 220), curve: Curves.easeInOut);
      return;
    }
    const spring = SpringDescription(mass: 1, stiffness: 220, damping: 26);
    _p.animateWith(SpringSimulation(spring, _p.value, target, velocity));
  }

  void _dragStart(DragStartDetails details, Size size) {
    final limit = widget.edgeDragWidth;
    if (!widget.controller.isOpen && limit != null) {
      final x = details.localPosition.dx;
      final fromEdge = _sign > 0 ? x : size.width - x;
      if (fromEdge > limit) return;
    }
    _dragging = true;
    _p.stop();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _p.value =
        (_p.value + details.delta.dx * _sign / widget.width).clamp(0.0, 1.0);
  }

  void _dragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details.velocity.pixelsPerSecond.dx * _sign;
    final open = KitoSideMenuMath.settlesOpen(
        progress: _p.value, velocity: velocity, width: widget.width);
    widget.controller.isOpen = open;
    _animateTo(open ? 1 : 0, velocity: velocity / widget.width);
  }

  void _close() => widget.controller.close();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    _sign =
        KitoSideMenuMath.openingSign(widget.edge, Directionality.of(context));
    final background =
        widget.background ?? KitoBackground.color(theme.colors.surface);
    final foreground = widget.foreground ?? theme.colors.onSurface;

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      return Actions(
        actions: {DismissIntent: _CloseMenuAction(widget.controller)},
        child: GestureDetector(
          onHorizontalDragStart: (d) => _dragStart(d, size),
          onHorizontalDragUpdate: _dragUpdate,
          onHorizontalDragEnd: _dragEnd,
          onHorizontalDragCancel: () {
            if (_dragging) {
              _dragging = false;
              _sync();
            }
          },
          child: AnimatedBuilder(
            animation: _p,
            builder: (context, _) =>
                _layers(context, size, _p.value, background, foreground),
          ),
        ),
      );
    });
  }

  Widget _drawer(BuildContext context, double p, Color foreground) {
    final open = widget.controller.isOpen;
    final theme = context.kito;
    return Visibility(
      visible: p > 0 || open,
      maintainState: true,
      child: ExcludeFocus(
        excluding: !open,
        child: Focus(
          focusNode: _drawerFocus,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: widget.semanticLabel,
            onDismiss: open ? _close : null,
            child: IgnorePointer(
              ignoring: !open,
              child: SizedBox(
                width: widget.width,
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground),
                  child: DefaultTextStyle(
                    style: theme.typography.body.copyWith(color: foreground),
                    child: widget.menu,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pins [child] to the drawer's edge at full height.
  static Widget _edge(bool left, Widget child) => Positioned(
        top: 0,
        bottom: 0,
        left: left ? 0 : null,
        right: left ? null : 0,
        child: child,
      );

  Widget _layers(BuildContext context, Size size, double p,
      KitoBackground background, Color foreground) {
    final style = widget.style;
    final s = _sign;
    final open = widget.controller.isOpen;
    final left = s > 0;
    final edgeAlign = left ? Alignment.centerLeft : Alignment.centerRight;
    final reduce = context.reduceMotion;

    final dim = switch (style) {
      KitoSideMenuStyle.overlay || KitoSideMenuStyle.floating => 0.4,
      KitoSideMenuStyle.push => 0.2,
      _ => 0.08,
    };

    Widget screen = ExcludeFocus(
      excluding: open,
      child: ExcludeSemantics(
        excluding: open,
        child: AbsorbPointer(absorbing: open || p > 0.01, child: widget.child),
      ),
    );
    screen = Stack(fit: StackFit.expand, children: [
      screen,
      if (p > 0)
        Positioned.fill(
          child: Semantics(
            button: true,
            label: widget.closeLabel,
            onTap: _close,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _close,
              child: ColoredBox(color: Colors.black.withValues(alpha: dim * p)),
            ),
          ),
        ),
    ]);

    final radius = BorderRadius.circular(34 * p);
    final shadow = [
      BoxShadow(
          color: Colors.black.withValues(alpha: 0.3 * p),
          blurRadius: 30,
          offset: Offset(-s * 8, 0)),
    ];
    switch (style) {
      case KitoSideMenuStyle.push:
        screen = Transform.translate(
            offset: Offset(s * widget.width * p, 0), child: screen);
      case KitoSideMenuStyle.overlay:
        break;
      case KitoSideMenuStyle.floating:
        if (p > 0 && !reduce) {
          screen = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3 * p, sigmaY: 3 * p),
              child: screen);
        }
      case KitoSideMenuStyle.reveal:
        screen = Transform.translate(
          offset: Offset(s * widget.width * p, 0),
          child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: shadow), child: screen),
        );
      case KitoSideMenuStyle.scale:
        screen = Transform.translate(
          offset: Offset(s * widget.width * 0.9 * p, 0),
          child: Transform.scale(
            scale: 1 - 0.16 * p,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(borderRadius: radius, boxShadow: shadow),
              child: ClipRRect(borderRadius: radius, child: screen),
            ),
          ),
        );
      case KitoSideMenuStyle.rotate3D:
        final angle = reduce ? 0.0 : -s * 28 * math.pi / 180 * p;
        screen = Transform.translate(
          offset: Offset(s * widget.width * 0.95 * p, 0),
          child: Transform.scale(
            scale: 1 - 0.1 * p,
            child: Transform(
              alignment: edgeAlign,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: DecoratedBox(
                decoration:
                    BoxDecoration(borderRadius: radius, boxShadow: shadow),
                child: ClipRRect(borderRadius: radius, child: screen),
              ),
            ),
          ),
        );
    }

    final drawer = _drawer(context, p, foreground);
    final children = <Widget>[];
    if (style.drawerIsBehind) {
      children
        ..add(Positioned.fill(
            child: KitoSurface(
                background: background,
                radius: 0,
                child: const SizedBox.expand())))
        ..add(_edge(
          left,
          Opacity(
            opacity: style == KitoSideMenuStyle.reveal || reduce ? 1 : p,
            child: Transform.translate(
              offset: Offset(
                  style == KitoSideMenuStyle.reveal ? 0 : -s * 40 * (1 - p), 0),
              child: SafeArea(left: left, right: !left, child: drawer),
            ),
          ),
        ))
        ..add(screen);
    } else if (style == KitoSideMenuStyle.floating) {
      children
        ..add(screen)
        ..add(_edge(
          left,
          Transform.translate(
            offset: Offset(-s * (widget.width + 30) * (1 - p), 0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25 * p),
                          blurRadius: 30,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: KitoSurface(
                    background: background,
                    radius: 30,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(30), child: drawer),
                  ),
                ),
              ),
            ),
          ),
        ));
    } else {
      children
        ..add(screen)
        ..add(_edge(
          left,
          Transform.translate(
            offset: Offset(-s * widget.width * (1 - p), 0),
            child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: [
                if (style == KitoSideMenuStyle.overlay)
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2 * p),
                      blurRadius: 20),
              ]),
              child: KitoSurface(
                background: background,
                radius: 0,
                child: SafeArea(left: left, right: !left, child: drawer),
              ),
            ),
          ),
        ));
    }
    return ClipRect(child: Stack(fit: StackFit.expand, children: children));
  }
}

class _CloseMenuAction extends DismissAction {
  _CloseMenuAction(this.controller);

  final KitoSideMenuController controller;

  @override
  bool isEnabled(DismissIntent intent) => controller.isOpen;

  @override
  Object? invoke(DismissIntent intent) {
    controller.close();
    return null;
  }
}
