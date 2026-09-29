// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'appearance.dart';
import 'center.dart';
import 'toast.dart';
import 'view.dart';

/// Draws a [KitoToastCenter]'s toasts above everything in [child] — pushed pages, dialogs and
/// bottom sheets included — by hosting them in its own [Overlay] layer above the navigator.
///
/// Put it in `MaterialApp.builder` so it wraps the navigator:
///
/// ```dart
/// final toasts = KitoToastCenter();
///
/// MaterialApp(
///   builder: (context, child) => KitoToastHost(center: toasts, child: child!),
/// );
/// ```
///
/// Touches outside the toasts fall straight through to the app.
class KitoToastHost extends StatefulWidget {
  /// Hosts [center]'s toasts over [child]. Leave [center] out and the host makes its own; find
  /// it with [KitoToastHost.of] or `context.kitoToasts`.
  const KitoToastHost({
    super.key,
    this.center,
    this.appearance = const KitoToastAppearance(),
    required this.child,
  });

  /// The toasts to draw.
  final KitoToastCenter? center;

  /// Styling for every toast.
  final KitoToastAppearance appearance;

  /// Usually the navigator.
  final Widget child;

  /// The nearest host's center, or null.
  static KitoToastCenter? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_KitoToastScope>()?.center;

  /// The nearest host's center; throws when there's no host above [context].
  static KitoToastCenter of(BuildContext context) {
    final center = maybeOf(context);
    assert(center != null,
        'No KitoToastHost above this widget. Add one in MaterialApp.builder.');
    return center!;
  }

  @override
  State<KitoToastHost> createState() => _KitoToastHostState();
}

/// Shortcut to the nearest [KitoToastHost]'s center.
extension KitoToastContext on BuildContext {
  /// `KitoToastHost.of(this)`.
  KitoToastCenter get kitoToasts => KitoToastHost.of(this);
}

class _KitoToastScope extends InheritedWidget {
  const _KitoToastScope({required this.center, required super.child});
  final KitoToastCenter center;

  @override
  bool updateShouldNotify(_KitoToastScope old) => old.center != center;
}

class _KitoToastHostState extends State<KitoToastHost> {
  final OverlayPortalController _portal = OverlayPortalController();
  KitoToastCenter? _own;

  KitoToastCenter get _center => widget.center ?? (_own ??= KitoToastCenter());

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _KitoToastScope(
      center: _center,
      child: Overlay.wrap(
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) =>
              _KitoToastLayer(center: _center, appearance: widget.appearance),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Item {
  _Item(this.toast);
  KitoToast toast;
  bool leaving = false;
  double offset = 0;
  double scale = 1;
  double opacity = 1;
  Object get id => toast.id;
}

class _KitoToastLayer extends StatefulWidget {
  const _KitoToastLayer({required this.center, required this.appearance});
  final KitoToastCenter center;
  final KitoToastAppearance appearance;

  @override
  State<_KitoToastLayer> createState() => _KitoToastLayerState();
}

class _KitoToastLayerState extends State<_KitoToastLayer> {
  List<_Item> _items = [];
  final Map<Object, double> _heights = {};

  @override
  void initState() {
    super.initState();
    widget.center.addListener(_sync);
    _sync(rebuild: false);
  }

  @override
  void didUpdateWidget(_KitoToastLayer old) {
    super.didUpdateWidget(old);
    if (old.center != widget.center) {
      old.center.removeListener(_sync);
      widget.center.addListener(_sync);
      _sync(rebuild: false);
    }
  }

  @override
  void dispose() {
    widget.center.removeListener(_sync);
    super.dispose();
  }

  void _sync({bool rebuild = true}) {
    final visible = widget.center.visible;
    final byId = {for (final i in _items) i.id: i};
    final ids = {for (final t in visible) t.id};
    _Item reuse(KitoToast t) {
      final existing = byId[t.id];
      if (existing == null) return _Item(t);
      return existing
        ..toast = t
        ..leaving = false;
    }

    final next = <_Item>[
      for (final t in visible) reuse(t),
      for (final i in _items)
        if (!ids.contains(i.id)) i..leaving = true,
    ];
    if (rebuild) {
      setState(() => _items = next);
    } else {
      _items = next;
    }
  }

  void _removed(Object id) {
    if (!mounted) return;
    setState(() {
      _items.removeWhere((i) => i.id == id && i.leaving);
      _heights.remove(id);
    });
  }

  void _measured(Object id, double height) {
    if (!mounted || _heights[id] == height) return;
    setState(() => _heights[id] = height);
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center;
    final isTop = center.position == KitoToastPosition.top;
    final expanded = center.isStackExpanded;
    final direction = isTop ? 1.0 : -1.0;
    final visible = [
      for (final i in _items)
        if (!i.leaving) i
    ];

    // Where each visible toast sits relative to the front one.
    var running = 0.0;
    for (var index = 0; index < visible.length; index++) {
      final item = visible[index];
      if (expanded) {
        item.offset = direction * running;
        item.scale = 1;
        item.opacity = 1;
      } else {
        item.offset = direction * (index < 2 ? index : 2) * 10.0;
        item.scale = 1 - (index < 3 ? index : 3) * 0.05;
        item.opacity = index < 3 ? 1 : 0;
      }
      running += (_heights[item.id] ?? 64) + 8;
    }

    final children = <Widget>[
      if (expanded)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => center.isStackExpanded = false,
          ),
        ),
      // Painted back to front: leaving toasts, then the oldest, then the newest on top.
      for (final item in _items.where((i) => i.leaving)) _slot(item, -1),
      for (var index = visible.length - 1; index >= 0; index--)
        _slot(visible[index], index),
    ];

    return Stack(clipBehavior: Clip.none, children: children);
  }

  Widget _slot(_Item item, int index) {
    final center = widget.center;
    final theme = context.kito;
    final insets = MediaQuery.paddingOf(context);
    final isTop = center.position == KitoToastPosition.top;
    final layout = item.toast.layout;
    final edge = widget.appearance.edgeSpacing;
    final double base = switch (layout) {
      KitoToastLayout.banner => 0,
      KitoToastLayout.island when isTop =>
        insets.top > 24 ? 11 : insets.top + edge,
      _ => (isTop ? insets.top : insets.bottom) + edge,
    };
    final double side = switch (layout) {
      KitoToastLayout.banner => 0,
      KitoToastLayout.pill => theme.spacing.lg,
      KitoToastLayout.island => 14,
      _ => theme.spacing.md,
    };
    final count = center.visible.length;
    final front = index == 0;
    final stackAction = count > 1 && front
        ? {
            CustomSemanticsAction(
                label: center.isStackExpanded
                    ? 'Collapse notifications'
                    : 'Show all $count notifications'): center.toggleStack,
          }
        : const <CustomSemanticsAction, VoidCallback>{};

    return AnimatedPositioned(
      key: ValueKey(item.id),
      duration: KitoMotion.of(context, theme.motion.slow),
      curve: theme.motion.spring,
      left: side + insets.left * (layout == KitoToastLayout.banner ? 0 : 1),
      right: side + insets.right * (layout == KitoToastLayout.banner ? 0 : 1),
      top: isTop ? base + item.offset : null,
      bottom: isTop ? null : base - item.offset,
      child: IgnorePointer(
        ignoring: item.leaving || (!center.isStackExpanded && index > 0),
        child: Semantics(
          customSemanticsActions: stackAction,
          child: _ToastSlot(
            key: ValueKey(item.id),
            toast: item.toast,
            leaving: item.leaving,
            isTop: isTop,
            scale: item.scale,
            opacity: item.opacity,
            appearance: widget.appearance,
            center: center,
            topInset:
                layout == KitoToastLayout.banner && isTop ? insets.top : 0,
            bottomInset:
                layout == KitoToastLayout.banner && !isTop ? insets.bottom : 0,
            onRemoved: () => _removed(item.id),
            onMeasured: (h) => _measured(item.id, h),
            onTap: () {
              if (center.visible.length > 1) {
                center.toggleStack();
              } else {
                item.toast.onTap?.call();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ToastSlot extends StatefulWidget {
  const _ToastSlot({
    super.key,
    required this.toast,
    required this.leaving,
    required this.isTop,
    required this.scale,
    required this.opacity,
    required this.appearance,
    required this.center,
    required this.topInset,
    required this.bottomInset,
    required this.onRemoved,
    required this.onMeasured,
    required this.onTap,
  });

  final KitoToast toast;
  final bool leaving;
  final bool isTop;
  final double scale;
  final double opacity;
  final KitoToastAppearance appearance;
  final KitoToastCenter center;
  final double topInset;
  final double bottomInset;
  final VoidCallback onRemoved;
  final ValueChanged<double> onMeasured;
  final VoidCallback onTap;

  @override
  State<_ToastSlot> createState() => _ToastSlotState();
}

class _ToastSlotState extends State<_ToastSlot> with TickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _snap = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  double _drag = 0;
  double _raw = 0;
  bool _holding = false;
  bool _hovering = false;
  Animation<double>? _snapBack;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_presence.status == AnimationStatus.dismissed && !widget.leaving) {
      _presence.duration = context.reduceMotion
          ? const Duration(milliseconds: 150)
          : const Duration(milliseconds: 420);
      _presence.forward();
    }
  }

  @override
  void didUpdateWidget(_ToastSlot old) {
    super.didUpdateWidget(old);
    if (widget.leaving && !old.leaving) {
      _release();
      _presence.duration = context.reduceMotion
          ? const Duration(milliseconds: 150)
          : const Duration(milliseconds: 260);
      _presence.reverse().whenCompleteOrCancel(() {
        if (_presence.status == AnimationStatus.dismissed) widget.onRemoved();
      });
    } else if (!widget.leaving && old.leaving) {
      _presence.forward();
    }
  }

  @override
  void dispose() {
    _release();
    if (_hovering) {
      _hovering = false;
      widget.center.resume();
    }
    _presence.dispose();
    _snap.dispose();
    super.dispose();
  }

  void _hold() {
    if (_holding) return;
    _holding = true;
    widget.center.pause();
  }

  void _release() {
    if (!_holding) return;
    _holding = false;
    widget.center.resume();
  }

  void _onDragStart(DragStartDetails _) {
    _snap.stop();
    _hold();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _raw += d.delta.dy;
      _drag = _raw * 0.6; // rubber band: the toast lags the finger
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final flung = velocity.abs() > 700;
    _release();
    if (_raw.abs() > 50 || flung) {
      widget.center.dismiss(widget.toast.id);
      return;
    }
    final from = _drag;
    _raw = 0;
    if (context.reduceMotion) {
      setState(() => _drag = 0);
      return;
    }
    _snapBack = Tween(begin: from, end: 0.0)
        .animate(CurvedAnimation(parent: _snap, curve: const KitoSpringCurve()))
      ..addListener(() => setState(() => _drag = _snapBack!.value));
    _snap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    final toast = widget.toast;
    final center = widget.center;
    final island = toast.layout == KitoToastLayout.island;
    final anchor = widget.isTop ? Alignment.bottomCenter : Alignment.topCenter;

    Widget view = KitoToastView(
      toast: toast,
      appearance: widget.appearance,
      remaining: center.remainingFor(toast.id),
      paused: center.isPaused,
      topInset: widget.topInset,
      bottomInset: widget.bottomInset,
      onDismiss: () => center.dismiss(toast.id),
    );

    view = AnimatedScale(
      scale: widget.scale,
      alignment: anchor,
      duration: KitoMotion.of(context, const Duration(milliseconds: 380)),
      curve: context.kito.motion.spring,
      child: AnimatedOpacity(
        opacity: widget.opacity,
        duration: KitoMotion.of(context, const Duration(milliseconds: 200)),
        child: view,
      ),
    );

    // Entrance: slide in from the edge (the island grows out of the top); exit: shrink and fade.
    final presence = _presence;
    view = AnimatedBuilder(
      animation: presence,
      child: view,
      builder: (context, child) {
        final t = presence.value;
        if (reduce) return Opacity(opacity: t, child: child);
        if (widget.leaving) {
          return Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          );
        }
        final eased = const KitoSpringCurve(damping: 0.78).transform(t);
        final fade = Curves.easeOut.transform(t);
        if (island && widget.isTop) {
          return Opacity(
            opacity: fade,
            child: Transform.scale(
                scale: 0.3 + 0.7 * eased,
                alignment: Alignment.topCenter,
                child: child),
          );
        }
        return Opacity(
          opacity: fade,
          child: FractionalTranslation(
            translation: Offset(0, (widget.isTop ? -1 : 1) * (1 - eased)),
            child: child,
          ),
        );
      },
    );

    return _SizeReporter(
      onHeight: widget.onMeasured,
      child: MouseRegion(
        onEnter: (_) {
          if (_hovering) return;
          _hovering = true;
          center.pause();
        },
        onExit: (_) {
          if (!_hovering) return;
          _hovering = false;
          center.resume();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: widget.onTap,
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          onVerticalDragCancel: _release,
          child: Transform.translate(
            offset: Offset(0, _drag),
            child: Opacity(
              opacity: 1 - (_drag.abs() / 120).clamp(0.0, 0.6),
              child: RepaintBoundary(child: view),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onHeight, required super.child});
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onHeight);

  @override
  void updateRenderObject(
          BuildContext context, _RenderSizeReporter renderObject) =>
      renderObject.onHeight = onHeight;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onHeight);
  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    SchedulerBinding.instance.addPostFrameCallback((_) => onHeight(h));
  }
}
