// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:latlong2/latlong.dart';

import 'chrome.dart';
import 'geometry.dart';
import 'markers.dart';
import 'models.dart';
import 'tiles.dart';

/// Nairobi's CBD, where a map with nothing to show opens.
const LatLng kitoMapNairobi = LatLng(-1.2864, 36.8172);

/// Moves a [KitoMap]'s camera from outside, with an eased glide (a jump under Reduce Motion).
///
/// ```dart
/// final controller = KitoMapController();
/// controller.animateTo(const LatLng(-1.2921, 36.8219), zoom: 15);
/// controller.fitPoints(route.points);
/// ```
class KitoMapController {
  /// Creates a controller. Dispose it with the screen.
  KitoMapController();

  final MapController _map = MapController();
  _KitoMapState? _state;

  /// The underlying flutter_map controller, for anything the kit doesn't wrap.
  MapController get mapController => _map;

  /// The camera, once the map has been laid out.
  MapCamera? get camera => _state == null ? null : _map.camera;

  /// Glides to [center], and to [zoom] when given.
  void animateTo(LatLng center, {double? zoom}) =>
      _state?._glide(center, zoom ?? _map.camera.zoom);

  /// Zooms in (positive) or out (negative) around the centre.
  void zoomBy(double delta) {
    if (_state == null) return;
    final c = _map.camera;
    _state!._glide(c.center, c.zoom + delta);
  }

  /// Frames [points] with [padding] around them.
  void fitPoints(List<LatLng> points,
      {EdgeInsets padding = const EdgeInsets.all(64), double maxZoom = 17}) {
    if (_state == null || points.isEmpty) return;
    if (points.length == 1) {
      animateTo(points.first, zoom: math.min(maxZoom, 16));
      return;
    }
    final target = CameraFit.coordinates(
            coordinates: points, padding: padding, maxZoom: maxZoom)
        .fit(_map.camera);
    _state!._glide(target.center, target.zoom);
  }

  /// Releases the controller.
  void dispose() => _map.dispose();
}

/// A themed OpenStreetMap map (via flutter_map) with Kito pins, clusters, routes, a
/// user-location puck, controls and a place card for the selected pin.
///
/// ```dart
/// KitoMap(
///   pins: cafes,
///   selectedPinId: selected?.id,
///   onPinTap: (pin) => setState(() => selected = pin),
///   onMapTap: (_) => setState(() => selected = null),
///   clusterer: const KitoMapClusterer(),
///   routes: [KitoMapRoute(points: ride)],
///   userLocation: here,
///   tiles: const KitoMapTiles.openStreetMap(userAgentPackageName: 'com.example.app'),
///   placeCardBuilder: (pin) => KitoMapPlaceCard.fromPin(pin),
/// )
/// ```
class KitoMap extends StatefulWidget {
  /// Creates a map.
  const KitoMap({
    super.key,
    this.pins = const [],
    this.selectedPinId,
    this.onPinTap,
    this.onMapTap,
    this.routes = const [],
    this.userLocation,
    this.userHeading,
    this.userAccuracy,
    this.initialCenter,
    this.initialZoom = 14,
    this.controller,
    this.tiles = const KitoMapTiles.openStreetMap(),
    this.clusterer,
    this.showsControls = true,
    this.placeCardBuilder,
    this.layers = const [],
    this.minZoom = 3,
    this.maxZoom = 19,
    this.interactive = true,
    this.borderRadius,
    this.tint,
  });

  /// Replaces every map's [tiles] — set it to `KitoMapTiles.none()` in widget tests so no map
  /// touches the network.
  static KitoMapTiles? debugTilesOverride;

  /// The places.
  final List<KitoMapPin> pins;

  /// The pin drawn selected (and never clustered).
  final String? selectedPinId;

  /// Called when a pin is tapped.
  final ValueChanged<KitoMapPin>? onPinTap;

  /// Called when the map itself is tapped.
  final ValueChanged<LatLng>? onMapTap;

  /// Lines to draw under the pins.
  final List<KitoMapRoute> routes;

  /// Where the user is; draws the puck.
  final LatLng? userLocation;

  /// The user's heading in degrees, for the puck's cone.
  final double? userHeading;

  /// The location's accuracy in metres, drawn as a pale circle.
  final double? userAccuracy;

  /// Where the map opens. When null it frames the pins, or the user, or Nairobi.
  final LatLng? initialCenter;

  /// The opening zoom when [initialCenter] is set or there's one place.
  final double initialZoom;

  /// Moves the camera from outside.
  final KitoMapController? controller;

  /// Where the tiles come from.
  final KitoMapTiles tiles;

  /// Groups nearby pins when set.
  final KitoMapClusterer? clusterer;

  /// Shows zoom, locate and fit buttons.
  final bool showsControls;

  /// The card shown at the bottom for the selected pin.
  final Widget Function(KitoMapPin pin)? placeCardBuilder;

  /// More flutter_map layers, drawn above the routes and below the pins.
  final List<Widget> layers;

  /// The farthest out the map zooms.
  final double minZoom;

  /// The farthest in the map zooms.
  final double maxZoom;

  /// Lets people pan and zoom.
  final bool interactive;

  /// Rounds the map's corners.
  final BorderRadius? borderRadius;

  /// The accent for routes and controls; the theme's secondary when null.
  final Color? tint;

  @override
  State<KitoMap> createState() => _KitoMapState();
}

class _KitoMapState extends State<KitoMap> with SingleTickerProviderStateMixin {
  KitoMapController? _own;
  late final AnimationController _move = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650))
    ..addListener(_step)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && _ready) {
        final z = _controller._map.camera.zoom;
        if (z != _zoom) _update(() => _zoom = z);
      }
    });
  LatLng? _from, _to;
  double _fromZoom = 0, _toZoom = 0;
  double _zoom = 14;
  bool _ready = false;
  bool _following = false;

  KitoMapController get _controller =>
      widget.controller ?? (_own ??= KitoMapController());

  @override
  void initState() {
    super.initState();
    _controller._state = this;
    _zoom = widget.initialZoom;
  }

  @override
  void didUpdateWidget(KitoMap old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      _controller._state = this;
    }
  }

  @override
  void dispose() {
    _move.dispose();
    if (_controller._state == this) _controller._state = null;
    _own?.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(change);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(change);
      });
    }
  }

  void _glide(LatLng to, double zoom) {
    if (!_ready) return;
    final z = zoom.clamp(widget.minZoom, widget.maxZoom).toDouble();
    if (context.reduceMotion) {
      _controller._map.move(to, z);
      if (z != _zoom) _update(() => _zoom = z);
      return;
    }
    final cam = _controller._map.camera;
    _from = cam.center;
    _fromZoom = cam.zoom;
    _to = to;
    _toZoom = z;
    _move.forward(from: 0);
  }

  void _step() {
    if (_from == null || _to == null) return;
    final t = Curves.easeInOutCubic.transform(_move.value);
    // Zoom out a touch mid-flight on long hops, like a camera flying over.
    final hop = KitoMapGeometry.distance(_from!, _to!);
    final dip = hop > 3000 ? math.sin(t * math.pi) * 0.8 : 0.0;
    _controller._map.move(
      KitoMapGeometry.interpolate(_from!, _to!, t),
      _fromZoom + (_toZoom - _fromZoom) * t - dip,
    );
  }

  List<LatLng> get _allPoints => [
        for (final p in widget.pins) p.point,
        if (widget.userLocation != null) widget.userLocation!,
      ];

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final dark = theme.brightness == Brightness.dark;
    final tiles = KitoMap.debugTilesOverride ?? widget.tiles;
    final accent = widget.tint ?? theme.colors.secondary;
    final points = _allPoints;
    final fitOnOpen = widget.initialCenter == null && widget.pins.length > 1;
    final center = widget.initialCenter ??
        KitoMapGeometry.centroid(widget.pins.map((p) => p.point)) ??
        widget.userLocation ??
        kitoMapNairobi;

    final selected =
        widget.pins.where((p) => p.id == widget.selectedPinId).firstOrNull;
    final clusters = widget.clusterer == null
        ? [
            for (final p in widget.pins) KitoMapCluster([p])
          ]
        : widget.clusterer!
            .clusters(widget.pins, zoom: _zoom, keep: widget.selectedPinId);
    // The selected pin draws last, on top.
    clusters.sort((a, b) => (a.pins.first.id == widget.selectedPinId ? 1 : 0)
        .compareTo(b.pins.first.id == widget.selectedPinId ? 1 : 0));
    final scaler = MediaQuery.textScalerOf(context);

    final map = FlutterMap(
      mapController: _controller._map,
      options: MapOptions(
        initialCenter: center,
        initialZoom: widget.initialZoom,
        initialCameraFit: fitOnOpen
            ? CameraFit.coordinates(
                coordinates: [for (final p in widget.pins) p.point],
                padding: const EdgeInsets.fromLTRB(56, 72, 72, 56),
                maxZoom: 16)
            : null,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        backgroundColor:
            dark ? const Color(0xFF1B1F27) : const Color(0xFFEFEDE8),
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
        onMapReady: () {
          _ready = true;
          final z = _controller._map.camera.zoom;
          if (z != _zoom) _update(() => _zoom = z);
        },
        onTap: widget.onMapTap == null ? null : (_, p) => widget.onMapTap!(p),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _following) _update(() => _following = false);
          if (widget.clusterer != null && (camera.zoom - _zoom).abs() >= 0.1) {
            _update(() => _zoom = camera.zoom);
          }
        },
      ),
      children: [
        tiles.buildLayer(dark: dark) ?? _PaperLayer(dark: dark),
        if (widget.userLocation != null && (widget.userAccuracy ?? 0) > 0)
          CircleLayer(circles: [
            CircleMarker(
              point: widget.userLocation!,
              radius: widget.userAccuracy!,
              useRadiusInMeter: true,
              color: kitoMapUserBlue.withValues(alpha: 0.12),
              borderColor: kitoMapUserBlue.withValues(alpha: 0.35),
              borderStrokeWidth: 1,
            ),
          ]),
        if (widget.routes.isNotEmpty)
          PolylineLayer(polylines: [
            for (final r in widget.routes) ..._polylines(r, accent, dark),
          ]),
        if (widget.routes.any((r) => r.showsEnds && r.points.length > 1))
          MarkerLayer(markers: [
            for (final r in widget.routes)
              if (r.showsEnds && r.points.length > 1) ...[
                Marker(
                  point: r.points.first,
                  width: 18,
                  height: 18,
                  child: _End(color: r.color ?? accent, start: true),
                ),
                Marker(
                  point: r.points.last,
                  width: 22,
                  height: 22,
                  child: _End(color: r.color ?? accent, start: false),
                ),
              ],
          ]),
        ...widget.layers,
        MarkerLayer(
          rotate: true,
          markers: [
            for (final c in clusters)
              if (c.isCluster)
                Marker(
                  key: ValueKey(c.id),
                  point: c.point,
                  width: KitoMapClusterView.diameter(c.count) + 12,
                  height: KitoMapClusterView.diameter(c.count) + 12,
                  child: KitoMapClusterView(
                    count: c.count,
                    tint: c.pins.first.tint,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _controller.fitPoints([for (final p in c.pins) p.point],
                          padding: const EdgeInsets.all(80));
                    },
                  ),
                )
              else
                _pinMarker(c.pins.first, scaler),
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 62,
                height: 62,
                child: Semantics(
                  label: 'Your location',
                  child: KitoMapPulse(heading: widget.userHeading),
                ),
              ),
          ],
        ),
      ],
    );

    final card = selected == null || widget.placeCardBuilder == null
        ? null
        : widget.placeCardBuilder!(selected);

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(children: [
        Positioned.fill(child: map),
        if (widget.showsControls)
          PositionedDirectional(
            top: theme.spacing.md,
            end: theme.spacing.md,
            child: SafeArea(
              child: KitoMapControls(
                tint: accent,
                onZoomIn: () => _controller.zoomBy(1),
                onZoomOut: () => _controller.zoomBy(-1),
                isFollowingUser: _following,
                onLocate: widget.userLocation == null
                    ? null
                    : () {
                        setState(() => _following = true);
                        _controller.animateTo(widget.userLocation!,
                            zoom: math.max(_controller._map.camera.zoom, 16));
                      },
                onFitAll: points.length < 2
                    ? null
                    : () => _controller.fitPoints(points,
                        padding: const EdgeInsets.fromLTRB(56, 72, 72, 56)),
              ),
            ),
          ),
        if (tiles.attribution != null)
          PositionedDirectional(
            start: theme.spacing.sm,
            bottom: theme.spacing.sm,
            child: _Attribution(text: tiles.attribution!),
          ),
        PositionedDirectional(
          start: theme.spacing.md,
          end: theme.spacing.md,
          bottom: theme.spacing.md,
          child: SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: KitoMotion.of(context, theme.motion.medium),
              switchInCurve: theme.motion.spring,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.6), end: Offset.zero)
                    .animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: card == null
                  ? const SizedBox.shrink()
                  : KeyedSubtree(key: ValueKey(selected!.id), child: card),
            ),
          ),
        ),
      ]),
    );
  }

  Marker _pinMarker(KitoMapPin pin, TextScaler scaler) {
    final size = KitoMapPinView.markerSize(pin, textScaler: scaler);
    return Marker(
      key: ValueKey(pin.id),
      point: pin.point,
      width: size.width,
      height: size.height,
      alignment:
          pin.style.anchorsAtBottom ? Alignment.topCenter : Alignment.center,
      child: KitoMapPinView(
        pin: pin,
        selected: pin.id == widget.selectedPinId,
        onTap: widget.onPinTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onPinTap!(pin);
              },
      ),
    );
  }

  List<Polyline> _polylines(KitoMapRoute r, Color accent, bool dark) {
    if (r.points.length < 2) return const [];
    final color = r.color ?? accent;
    final casing = dark ? const Color(0xFF0B0B0F) : Colors.white;
    final pattern = r.dashed
        ? StrokePattern.dashed(segments: [r.width * 2, r.width * 1.5])
        : const StrokePattern.solid();
    Polyline line(List<LatLng> pts, Color c) => Polyline(
          points: pts,
          color: c,
          strokeWidth: r.width,
          borderColor: casing,
          borderStrokeWidth: r.dashed ? 0 : 2,
          pattern: pattern,
        );
    if (r.progress == null) return [line(r.points, color)];
    final parts = KitoMapGeometry.split(r.points, r.progress!);
    return [
      if (parts.travelled.length > 1)
        line(parts.travelled, color.withValues(alpha: 0.35)),
      if (parts.remaining.length > 1) line(parts.remaining, color),
    ];
  }
}

class _End extends StatelessWidget {
  const _End({required this.color, required this.start});

  final Color color;
  final bool start;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: start ? Colors.white : color,
            shape: BoxShape.circle,
            border: Border.all(
                color: start ? color : Colors.white, width: start ? 4 : 4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
        ),
      );
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: theme.colors.onSurface.withValues(alpha: 0.7))),
    );
  }
}

/// A faint street-grid backdrop used when there are no tiles.
class _PaperLayer extends StatelessWidget {
  const _PaperLayer({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(
          origin: camera.pixelOrigin,
          color: dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.origin, required this.color});

  final Offset origin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 48.0;
    final thin = Paint()
      ..color = color
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = color
      ..strokeWidth = 5;
    final dx = -(origin.dx % step);
    final dy = -(origin.dy % step);
    var i = (origin.dx / step).floor();
    for (var x = dx; x < size.width; x += step, i++) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), i % 4 == 0 ? thick : thin);
    }
    var j = (origin.dy / step).floor();
    for (var y = dy; y < size.height; y += step, j++) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), j % 4 == 0 ? thick : thin);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.origin != origin || old.color != color;
}
