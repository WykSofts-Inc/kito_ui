// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'geometry.dart';

/// The shapes a [KitoMapPin] can take.
enum KitoMapPinKind {
  /// A small dot with a white ring.
  dot,

  /// A round badge with an icon.
  icon,

  /// A capsule with text and a tail, like a price on a stays map.
  bubble,

  /// A round photo or initials with a pointer.
  avatar,

  /// The classic map pin with an icon inside.
  teardrop,

  /// A live-location dot with a pulsing halo, for riders and couriers.
  pulse,
}

/// How a pin looks.
@immutable
class KitoMapPinStyle {
  const KitoMapPinStyle._(this.kind, {this.text, this.icon, this.image});

  /// A small dot with a white ring.
  static const KitoMapPinStyle dot = KitoMapPinStyle._(KitoMapPinKind.dot);

  /// The classic pin with the pin's icon inside.
  static const KitoMapPinStyle teardrop =
      KitoMapPinStyle._(KitoMapPinKind.teardrop);

  /// A pulsing live-location dot.
  static const KitoMapPinStyle pulse = KitoMapPinStyle._(KitoMapPinKind.pulse);

  /// A round badge with [icon].
  const KitoMapPinStyle.icon(IconData icon)
      : this._(KitoMapPinKind.icon, icon: icon);

  /// A capsule with [text]: "KES 4,500".
  const KitoMapPinStyle.bubble(String text)
      : this._(KitoMapPinKind.bubble, text: text);

  /// A round [image], or [initials] when there's none.
  const KitoMapPinStyle.avatar(String initials, {ImageProvider? image})
      : this._(KitoMapPinKind.avatar, text: initials, image: image);

  /// The shape.
  final KitoMapPinKind kind;

  /// The bubble text or avatar initials.
  final String? text;

  /// The icon of an [KitoMapPinKind.icon] pin.
  final IconData? icon;

  /// The avatar photo.
  final ImageProvider? image;

  /// Whether the pin's tip (bottom centre) sits on the point, rather than its centre.
  bool get anchorsAtBottom =>
      kind == KitoMapPinKind.bubble ||
      kind == KitoMapPinKind.avatar ||
      kind == KitoMapPinKind.teardrop;

  @override
  bool operator ==(Object other) =>
      other is KitoMapPinStyle &&
      other.kind == kind &&
      other.text == text &&
      other.icon == icon &&
      other.image == image;

  @override
  int get hashCode => Object.hash(kind, text, icon, image);
}

/// A place on the map.
///
/// ```dart
/// const KitoMapPin(
///   id: 'java',
///   point: LatLng(-1.2890, 36.7820),
///   title: 'Java House',
///   subtitle: 'Coffee · 0.8 km',
///   style: KitoMapPinStyle.bubble('KES 650'),
/// )
/// ```
@immutable
class KitoMapPin {
  /// Creates a pin.
  const KitoMapPin({
    required this.id,
    required this.point,
    required this.title,
    this.subtitle,
    this.style = KitoMapPinStyle.teardrop,
    this.tint,
    this.badge,
    this.icon,
    this.heading,
  });

  /// A stable id.
  final String id;

  /// Where it is.
  final LatLng point;

  /// "Java House".
  final String title;

  /// "Coffee · 0.8 km".
  final String? subtitle;

  /// How it looks.
  final KitoMapPinStyle style;

  /// Its colour; the theme's primary when null.
  final Color? tint;

  /// A small label on the corner: "4.8", "2".
  final String? badge;

  /// The glyph inside teardrop and pulse pins.
  final IconData? icon;

  /// Direction of travel in degrees (0 is north). Drawn as a cone on pulse pins.
  final double? heading;

  /// What screen readers hear.
  String get semanticLabel => [
        title,
        if (style.kind == KitoMapPinKind.bubble && style.text != null)
          style.text!,
        if (subtitle != null) subtitle!,
        if (badge != null) 'badge $badge',
      ].join(', ');

  /// A copy with some fields replaced.
  KitoMapPin copyWith({LatLng? point, double? heading, String? subtitle}) =>
      KitoMapPin(
        id: id,
        point: point ?? this.point,
        title: title,
        subtitle: subtitle ?? this.subtitle,
        style: style,
        tint: tint,
        badge: badge,
        icon: icon,
        heading: heading ?? this.heading,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoMapPin &&
      other.id == id &&
      other.point == point &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.style == style &&
      other.tint == tint &&
      other.badge == badge &&
      other.heading == heading;

  @override
  int get hashCode =>
      Object.hash(id, point, title, subtitle, style, tint, badge, heading);
}

/// A line on the map: a route, a trail, a delivery path.
@immutable
class KitoMapRoute {
  /// Creates a route.
  const KitoMapRoute({
    required this.points,
    this.color,
    this.width = 6,
    this.dashed = false,
    this.showsEnds = true,
    this.progress,
  });

  /// The path, in order.
  final List<LatLng> points;

  /// The line colour; the theme's secondary when null.
  final Color? color;

  /// The line width.
  final double width;

  /// Dashes instead of a solid line — for walking legs or planned routes.
  final bool dashed;

  /// Draws a start dot and an end ring.
  final bool showsEnds;

  /// 0–1: the part already travelled is drawn faded. Null draws it all the same.
  final double? progress;

  /// The length in metres.
  double get length => KitoMapGeometry.length(points);
}

/// Pins grouped for one zoom level: one pin, or several drawn as a count bubble.
@immutable
class KitoMapCluster {
  /// Creates a cluster.
  KitoMapCluster(List<KitoMapPin> pins)
      : pins = List.unmodifiable(pins),
        point = KitoMapGeometry.centroid(pins.map((p) => p.point)) ??
            const LatLng(0, 0);

  /// The pins inside.
  final List<KitoMapPin> pins;

  /// The average position.
  final LatLng point;

  /// How many pins.
  int get count => pins.length;

  /// True for more than one pin.
  bool get isCluster => pins.length > 1;

  /// A stable id: the pin's id, or the cluster's first pin and its size.
  String get id =>
      isCluster ? 'cluster-${pins.first.id}-$count' : pins.first.id;
}

/// Groups pins that would overlap at a zoom level into clusters, on a grid of [cellSize]
/// screen pixels. Above [maximumZoom] nothing clusters.
@immutable
class KitoMapClusterer {
  /// Creates a clusterer.
  const KitoMapClusterer({
    this.cellSize = 64,
    this.minimumClusterSize = 2,
    this.maximumZoom = 17,
  });

  /// The grid size in logical pixels.
  final double cellSize;

  /// Groups smaller than this stay as single pins.
  final int minimumClusterSize;

  /// The zoom at and above which every pin shows on its own.
  final double maximumZoom;

  /// The clusters for [pins] at [zoom]. [keep] (e.g. the selected pin) never clusters.
  List<KitoMapCluster> clusters(List<KitoMapPin> pins,
      {required double zoom, String? keep}) {
    if (zoom >= maximumZoom) {
      return [
        for (final p in pins) KitoMapCluster([p])
      ];
    }
    final cells = <(int, int), List<KitoMapPin>>{};
    final out = <KitoMapCluster>[];
    for (final p in pins) {
      if (p.id == keep) {
        out.add(KitoMapCluster([p]));
        continue;
      }
      final px = KitoMapGeometry.project(p.point, zoom);
      final key = ((px.x / cellSize).floor(), (px.y / cellSize).floor());
      (cells[key] ??= []).add(p);
    }
    for (final group in cells.values) {
      if (group.length >= math.max(minimumClusterSize, 2)) {
        out.add(KitoMapCluster(group));
      } else {
        out.addAll(group.map((p) => KitoMapCluster([p])));
      }
    }
    return out;
  }
}
