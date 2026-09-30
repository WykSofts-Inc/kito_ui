// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_maps/kito_ui_maps.dart';

const _cbd = LatLng(-1.2864, 36.8172);
const _westlands = LatLng(-1.2676, 36.8108);
const _jkia = LatLng(-1.3192, 36.9278);

void main() {
  group('geometry', () {
    test('distance and bearing', () {
      final d = KitoMapGeometry.distance(_cbd, _westlands);
      expect(d, closeTo(2200, 100));
      expect(KitoMapGeometry.distance(_cbd, _jkia), closeTo(12800, 400));
      expect(KitoMapGeometry.bearing(const LatLng(0, 0), const LatLng(1, 0)),
          closeTo(0, 1e-9));
      expect(KitoMapGeometry.bearing(const LatLng(0, 0), const LatLng(0, 1)),
          closeTo(90, 1e-9));
      expect(KitoMapGeometry.normalizedDegrees(-90), 270);
    });

    test('along and split a path', () {
      const path = [LatLng(0, 0), LatLng(0, 1), LatLng(0, 2)];
      final mid = KitoMapGeometry.along(path, 0.5);
      expect(mid.point.longitude, closeTo(1, 1e-6));
      expect(mid.bearing, closeTo(90, 1e-6));
      final parts = KitoMapGeometry.split(path, 0.25);
      expect(parts.travelled.last.longitude, closeTo(0.5, 1e-6));
      expect(parts.remaining.first, parts.travelled.last);
      expect(parts.remaining.last, path.last);
      expect(KitoMapGeometry.length(path),
          closeTo(2 * KitoMapGeometry.distance(path[0], path[1]), 1e-6));
    });

    test('circle and centroid', () {
      final ring = KitoMapGeometry.circle(_cbd, 500, segments: 16);
      expect(ring.length, 17);
      for (final p in ring) {
        expect(KitoMapGeometry.distance(_cbd, p), closeTo(500, 1));
      }
      expect(KitoMapGeometry.centroid(const [LatLng(0, 0), LatLng(2, 4)]),
          const LatLng(1, 2));
      expect(KitoMapGeometry.centroid(const []), isNull);
    });

    test('web mercator projection', () {
      final p = KitoMapGeometry.project(const LatLng(0, 0), 0);
      expect(p.x, 128);
      expect(p.y, closeTo(128, 1e-9));
      final q = KitoMapGeometry.project(const LatLng(0, 180), 1);
      expect(q.x, 512);
    });
  });

  test('format', () {
    expect(KitoMapFormat.distance(42), '40 m');
    expect(KitoMapFormat.distance(853), '850 m');
    expect(KitoMapFormat.distance(1234), '1.2 km');
    expect(KitoMapFormat.distance(12800), '13 km');
    expect(KitoMapFormat.distance(100, imperial: true), '330 ft');
    expect(KitoMapFormat.duration(const Duration(seconds: 20)), '1 min');
    expect(KitoMapFormat.duration(const Duration(minutes: 60)), '1 h');
    expect(KitoMapFormat.duration(const Duration(minutes: 65)), '1 h 5 min');
    expect(KitoMapFormat.summary(1234, const Duration(minutes: 12)),
        '1.2 km · 12 min');
  });

  group('clusterer', () {
    final pins = [
      for (var i = 0; i < 5; i++)
        KitoMapPin(
            id: 'p$i',
            point: LatLng(-1.2864 + i * 0.0002, 36.8172),
            title: 'Pin $i'),
      const KitoMapPin(id: 'far', point: _jkia, title: 'JKIA'),
    ];

    test('groups close pins at low zoom', () {
      final c = const KitoMapClusterer().clusters(pins, zoom: 12);
      expect(c.where((x) => x.isCluster).single.count, 5);
      expect(c.where((x) => !x.isCluster).single.pins.single.id, 'far');
    });

    test('keeps the selected pin out and stops clustering when zoomed in', () {
      final c = const KitoMapClusterer().clusters(pins, zoom: 12, keep: 'p2');
      expect(c.where((x) => x.isCluster).single.count, 4);
      expect(c.any((x) => x.id == 'p2'), isTrue);
      expect(const KitoMapClusterer().clusters(pins, zoom: 18).length, 6);
    });

    test('respects the minimum size', () {
      final c = const KitoMapClusterer(minimumClusterSize: 6)
          .clusters(pins, zoom: 12);
      expect(c.every((x) => !x.isCluster), isTrue);
    });
  });

  test('pins and routes', () {
    const pin = KitoMapPin(
        id: 'java',
        point: _westlands,
        title: 'Java House',
        subtitle: 'Coffee',
        style: KitoMapPinStyle.bubble('KES 650'),
        badge: '4.8');
    expect(pin.semanticLabel, 'Java House, KES 650, Coffee, badge 4.8');
    expect(pin.style.anchorsAtBottom, isTrue);
    expect(KitoMapPinStyle.pulse.anchorsAtBottom, isFalse);
    expect(pin.copyWith(heading: 90).heading, 90);
    expect(pin, pin.copyWith());
    expect(const KitoMapRoute(points: [_cbd, _westlands]).length,
        closeTo(2200, 100));
    final size = KitoMapPinView.markerSize(pin);
    expect(size.width, greaterThan(60));
  });
}
