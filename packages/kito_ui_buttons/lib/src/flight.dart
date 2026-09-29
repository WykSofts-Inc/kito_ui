// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'button_motion.dart';

/// One item in the air, from [start] to [end] in the flight layer's coordinates.
@immutable
class KitoFlight {
  /// Creates a flight description.
  const KitoFlight({
    required this.id,
    required this.target,
    required this.start,
    required this.end,
    required this.size,
    required this.arcHeight,
    required this.builder,
    this.onLanded,
  });

  /// Unique within its controller.
  final int id;

  /// The anchor id it is flying to.
  final Object target;

  /// Where it starts, measured from the layer's physical top-left (also in RTL).
  final Offset start;

  /// Where it lands.
  final Offset end;

  /// Its size at take-off.
  final Size size;

  /// How far above the higher end point the arc peaks.
  final double arcHeight;

  /// Builds what flies (usually the product image).
  final WidgetBuilder builder;

  /// Called when it lands.
  final VoidCallback? onLanded;
}

/// Coordinates "fly to target" animations: a product image arcing from an Add to cart button
/// into the cart icon, a heart flying to a favourites tab, and so on.
///
/// 1. Put a [KitoFlightLayer] with this controller around a screen.
/// 2. Mark targets with [KitoFlightAnchor] (or give [KitoBadgeButton] a `flightAnchor`).
/// 3. Fly: `controller.fly(from: 'product-1', to: 'cart', builder: (_) => image)`, or give a
///    button a `flight:` and it launches one for you.
///
/// Listen to it (it's a [ChangeNotifier]) or read [landings] to react to arrivals.
class KitoFlightController extends ChangeNotifier {
  /// Creates a controller.
  KitoFlightController({this.motion = KitoButtonMotion.standard});

  /// Flight duration and curve.
  KitoButtonMotion motion;

  /// When true, flights land immediately without drawing an arc. Set automatically by
  /// [KitoFlightLayer] from the Reduce Motion setting.
  bool reducesMotion = false;

  final List<KitoFlight> _flights = [];
  final Map<Object, int> _landings = {};
  final Map<Object, BuildContext> _anchors = {};
  BuildContext? _layer;
  int _nextId = 0;

  /// The flights currently in the air.
  List<KitoFlight> get flights => List.unmodifiable(_flights);

  /// How many flights have landed on [target]; use it to drive badge bounces.
  int landings(Object target) => _landings[target] ?? 0;

  /// True while a [KitoFlightLayer] is showing this controller's flights.
  bool get isAttached => _layer != null;

  /// The anchor [id]'s rectangle in the layer, if it is laid out. Measured from the physical
  /// top-left, in every text direction.
  Rect? frameOf(Object id) {
    final anchor = _anchors[id];
    return anchor == null ? null : _rectOf(anchor);
  }

  Rect? _rectOf(BuildContext context) {
    final layer = _layer;
    if (layer == null || !context.mounted || !layer.mounted) return null;
    final box = context.findRenderObject();
    final layerBox = layer.findRenderObject();
    if (box is! RenderBox ||
        layerBox is! RenderBox ||
        !box.hasSize ||
        !box.attached ||
        !layerBox.attached) {
      return null;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: layerBox);
    return origin & box.size;
  }

  /// Flies from the centre of anchor [from] to the centre of anchor [to]. Returns false when
  /// either isn't laid out or no layer is attached.
  bool fly({
    required Object from,
    required Object to,
    required WidgetBuilder builder,
    Size size = const Size.square(44),
    double arcHeight = 120,
    VoidCallback? onLanded,
  }) {
    final start = frameOf(from);
    if (start == null) return false;
    return flyFromPoint(start.center,
        to: to,
        builder: builder,
        size: size,
        arcHeight: arcHeight,
        onLanded: onLanded);
  }

  /// Flies from the widget that owns [source] (a button's own context, say) to anchor [to].
  bool flyFrom(
    BuildContext source, {
    required Object to,
    required WidgetBuilder builder,
    Size size = const Size.square(44),
    double arcHeight = 120,
    VoidCallback? onLanded,
  }) {
    final start = _rectOf(source);
    if (start == null) return false;
    return flyFromPoint(start.center,
        to: to,
        builder: builder,
        size: size,
        arcHeight: arcHeight,
        onLanded: onLanded);
  }

  /// Flies from [start] (layer coordinates, from the physical top-left) to anchor [to].
  bool flyFromPoint(
    Offset start, {
    required Object to,
    required WidgetBuilder builder,
    Size size = const Size.square(44),
    double arcHeight = 120,
    VoidCallback? onLanded,
  }) {
    final end = frameOf(to);
    if (end == null) return false;
    final flight = KitoFlight(
      id: _nextId++,
      target: to,
      start: start,
      end: end.center,
      size: size,
      arcHeight: arcHeight,
      builder: builder,
      onLanded: onLanded,
    );
    if (reducesMotion) {
      _land(flight);
      return true;
    }
    _flights.add(flight);
    notifyListeners();
    return true;
  }

  void _land(KitoFlight flight) {
    _flights.removeWhere((f) => f.id == flight.id);
    _landings[flight.target] = landings(flight.target) + 1;
    notifyListeners();
    flight.onLanded?.call();
  }

  /// A point on the arc [t] (0–1) of the way from [start] to [end]: a quadratic curve whose
  /// control point sits [arcHeight] above the higher end.
  static Offset arcPoint(Offset start, Offset end, double arcHeight, double t) {
    final control = Offset((start.dx + end.dx) / 2,
        (start.dy < end.dy ? start.dy : end.dy) - arcHeight);
    final u = 1 - t;
    return start * (u * u) + control * (2 * u * t) + end * (t * t);
  }

  void _attach(BuildContext layer) => _layer = layer;

  void _detach(BuildContext layer) {
    if (_layer == layer) _layer = null;
  }

  void _register(Object id, BuildContext anchor) => _anchors[id] = anchor;

  void _unregister(Object id, BuildContext anchor) {
    if (_anchors[id] == anchor) _anchors.remove(id);
  }
}

/// Hosts in-flight items above [child]. Put one around a screen that contains every anchor.
class KitoFlightLayer extends StatefulWidget {
  /// Creates a layer.
  const KitoFlightLayer(
      {super.key, required this.controller, required this.child});

  /// The controller whose flights are drawn here.
  final KitoFlightController controller;

  /// The screen.
  final Widget child;

  /// The controller of the nearest layer, if any.
  static KitoFlightController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_KitoFlightScope>()
      ?.controller;

  @override
  State<KitoFlightLayer> createState() => _KitoFlightLayerState();
}

class _KitoFlightLayerState extends State<KitoFlightLayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(KitoFlightLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller
        ..removeListener(_changed)
        .._detach(context);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller
      ..removeListener(_changed)
      .._detach(context);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller
      ..reducesMotion = context.reduceMotion
      .._attach(context);
    return _KitoFlightScope(
      controller: controller,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          for (final flight in controller.flights)
            _FlightView(
                key: ValueKey(flight.id),
                flight: flight,
                controller: controller),
        ],
      ),
    );
  }
}

class _KitoFlightScope extends InheritedWidget {
  const _KitoFlightScope({required this.controller, required super.child});
  final KitoFlightController controller;

  @override
  bool updateShouldNotify(_KitoFlightScope oldWidget) =>
      controller != oldWidget.controller;
}

class _FlightView extends StatefulWidget {
  const _FlightView(
      {super.key, required this.flight, required this.controller});
  final KitoFlight flight;
  final KitoFlightController controller;

  @override
  State<_FlightView> createState() => _FlightViewState();
}

class _FlightViewState extends State<_FlightView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: widget.controller.motion.flightDuration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller._land(widget.flight);
      }
    })
    ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flight;
    final curve = widget.controller.motion.flightCurve;
    return AnimatedBuilder(
      animation: _controller,
      child: SizedBox.fromSize(size: f.size, child: f.builder(context)),
      builder: (context, child) {
        final t = curve.transform(_controller.value);
        final p = KitoFlightController.arcPoint(f.start, f.end, f.arcHeight, t);
        final scale = 1 - 0.75 * t;
        final opacity = (1 - ((t - 0.7) / 0.3).clamp(0.0, 1.0));
        return Positioned(
          left: p.dx - f.size.width / 2,
          top: p.dy - f.size.height / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Registers [child] as a flight source or target under [id] in the nearest [KitoFlightLayer].
class KitoFlightAnchor extends StatefulWidget {
  /// Creates an anchor.
  const KitoFlightAnchor({super.key, required this.id, required this.child});

  /// The name flights use to find this widget (`'cart'`, `'product-1'`).
  final Object id;

  /// What is anchored.
  final Widget child;

  @override
  State<KitoFlightAnchor> createState() => _KitoFlightAnchorState();
}

class _KitoFlightAnchorState extends State<KitoFlightAnchor> {
  KitoFlightController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = KitoFlightLayer.maybeOf(context);
    if (next != _controller) {
      _controller?._unregister(widget.id, context);
      _controller = next?.._register(widget.id, context);
    }
  }

  @override
  void didUpdateWidget(KitoFlightAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _controller
        ?.._unregister(oldWidget.id, context)
        .._register(widget.id, context);
    }
  }

  @override
  void dispose() {
    _controller?._unregister(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// What a button flies to its target when tapped (or, for [KitoAddToCartButton], when the item
/// lands).
@immutable
class KitoFlightRequest {
  /// Creates a request.
  const KitoFlightRequest({
    required this.to,
    required this.builder,
    this.size = const Size.square(44),
    this.arcHeight = 120,
    this.controller,
  });

  /// The target anchor id.
  final Object to;

  /// Builds what flies.
  final WidgetBuilder builder;

  /// Size at take-off.
  final Size size;

  /// Arc peak height.
  final double arcHeight;

  /// The controller to fly with; the nearest [KitoFlightLayer]'s when null.
  final KitoFlightController? controller;

  /// Launches the flight from [source]. Returns false if nothing could fly.
  bool launch(BuildContext source) {
    final c = controller ?? KitoFlightLayer.maybeOf(source);
    if (c == null) return false;
    return c.flyFrom(source,
        to: to, builder: builder, size: size, arcHeight: arcHeight);
  }
}
