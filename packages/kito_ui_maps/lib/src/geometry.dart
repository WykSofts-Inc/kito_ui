// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Distances, bearings and projections on the sphere. Pure, so it's unit tested.
abstract final class KitoMapGeometry {
  /// The mean Earth radius in metres.
  static const double earthRadius = 6371008.8;

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;

  /// Great-circle distance in metres.
  static double distance(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  /// The initial bearing from [a] to [b] in degrees, 0 is north, clockwise.
  static double bearing(LatLng a, LatLng b) {
    final l1 = _rad(a.latitude), l2 = _rad(b.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) -
        math.sin(l1) * math.cos(l2) * math.cos(dLon);
    return normalizedDegrees(_deg(math.atan2(y, x)));
  }

  /// [degrees] in 0..<360.
  static double normalizedDegrees(double degrees) {
    final d = degrees % 360;
    return d < 0 ? d + 360 : d;
  }

  /// A straight blend between two points; fine for the short hops of a route.
  static LatLng interpolate(LatLng a, LatLng b, double fraction) {
    final t = fraction.clamp(0.0, 1.0);
    return LatLng(a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t);
  }

  /// The length of a path in metres.
  static double length(List<LatLng> path) {
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += distance(path[i - 1], path[i]);
    }
    return total;
  }

  /// The point [fraction] of the way along [path] and the bearing there.
  static ({LatLng point, double bearing}) along(
      List<LatLng> path, double fraction) {
    if (path.isEmpty) return (point: const LatLng(0, 0), bearing: 0);
    if (path.length == 1) return (point: path.first, bearing: 0);
    final target = length(path) * fraction.clamp(0.0, 1.0);
    var walked = 0.0;
    for (var i = 1; i < path.length; i++) {
      final seg = distance(path[i - 1], path[i]);
      if (walked + seg >= target || i == path.length - 1) {
        final t = seg == 0 ? 0.0 : (target - walked) / seg;
        return (
          point: interpolate(path[i - 1], path[i], t),
          bearing: bearing(path[i - 1], path[i]),
        );
      }
      walked += seg;
    }
    return (point: path.last, bearing: 0);
  }

  /// [path] cut at [fraction]: the part already travelled and what's left. Both include the
  /// cut point, so they meet.
  static ({List<LatLng> travelled, List<LatLng> remaining}) split(
      List<LatLng> path, double fraction) {
    if (path.length < 2) return (travelled: path, remaining: path);
    final f = fraction.clamp(0.0, 1.0);
    final target = length(path) * f;
    var walked = 0.0;
    for (var i = 1; i < path.length; i++) {
      final seg = distance(path[i - 1], path[i]);
      if (walked + seg >= target) {
        final cut = interpolate(
            path[i - 1], path[i], seg == 0 ? 0 : (target - walked) / seg);
        return (
          travelled: [...path.sublist(0, i), cut],
          remaining: [cut, ...path.sublist(i)],
        );
      }
      walked += seg;
    }
    return (travelled: path, remaining: [path.last]);
  }

  /// A ring of points [radius] metres around [center], for drawing a radius as a polygon.
  static List<LatLng> circle(LatLng center, double radius,
      {int segments = 64}) {
    final d = radius / earthRadius;
    final lat = _rad(center.latitude), lon = _rad(center.longitude);
    return [
      for (var i = 0; i <= segments; i++)
        () {
          final b = 2 * math.pi * i / segments;
          final lat2 = math.asin(math.sin(lat) * math.cos(d) +
              math.cos(lat) * math.sin(d) * math.cos(b));
          final lon2 = lon +
              math.atan2(math.sin(b) * math.sin(d) * math.cos(lat),
                  math.cos(d) - math.sin(lat) * math.sin(lat2));
          return LatLng(_deg(lat2), _deg(lon2));
        }(),
    ];
  }

  /// Web Mercator pixel coordinates of [point] at [zoom] with 256-pixel tiles.
  static ({double x, double y}) project(LatLng point, double zoom) {
    final scale = 256 * math.pow(2, zoom).toDouble();
    final lat = point.latitude.clamp(-85.05112878, 85.05112878);
    final s = math.sin(_rad(lat));
    return (
      x: (point.longitude + 180) / 360 * scale,
      y: (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale,
    );
  }

  /// The average of [points], or null when there are none.
  static LatLng? centroid(Iterable<LatLng> points) {
    var n = 0;
    var lat = 0.0, lon = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lon += p.longitude;
      n++;
    }
    return n == 0 ? null : LatLng(lat / n, lon / n);
  }
}

/// Glanceable distances and times: "850 m", "1.2 km", "12 min", "1 h 5 min".
abstract final class KitoMapFormat {
  /// "45 m", "850 m", "1.2 km", "12 km"; or feet and miles when [imperial].
  static String distance(double meters, {bool imperial = false}) {
    final m = math.max(meters, 0.0);
    if (imperial) {
      final feet = m * 3.28084;
      if (feet < 1000) return '${(feet / 10).round() * 10} ft';
      final miles = m / 1609.344;
      return miles < 9.95 ? '${_one(miles)} mi' : '${miles.round()} mi';
    }
    if (m < 100) return '${(m / 5).round() * 5} m';
    if (m < 995) return '${(m / 10).round() * 10} m';
    final km = m / 1000;
    return km < 9.95 ? '${_one(km)} km' : '${km.round()} km';
  }

  /// A travel time rounded up to the minute: "1 min", "12 min", "1 h", "1 h 5 min".
  static String duration(Duration d) {
    final minutes = math.max(1, (d.inSeconds / 60).ceil());
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60, rest = minutes % 60;
    return rest == 0 ? '$h h' : '$h h $rest min';
  }

  /// "1.2 km · 12 min".
  static String summary(double meters, Duration d, {bool imperial = false}) =>
      '${distance(meters, imperial: imperial)} · ${duration(d)}';

  static String _one(double v) {
    final tenths = (v * 10).round();
    return '${tenths ~/ 10}.${tenths % 10}';
  }
}
