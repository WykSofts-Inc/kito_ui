// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_maps/kito_ui_maps.dart';

import 'helpers.dart';

final _pins = [
  const KitoMapPin(
      id: 'java',
      point: LatLng(-1.2890, 36.7820),
      title: 'Java House',
      subtitle: 'Coffee',
      style: KitoMapPinStyle.bubble('KES 650')),
  const KitoMapPin(
      id: 'mall',
      point: LatLng(-1.2630, 36.8030),
      title: 'Sarit Centre',
      style: KitoMapPinStyle.icon(Icons.shopping_bag_rounded)),
  const KitoMapPin(
      id: 'home',
      point: LatLng(-1.2921, 36.7856),
      title: 'Home',
      icon: Icons.home_rounded),
  const KitoMapPin(
      id: 'amina',
      point: LatLng(-1.2800, 36.8100),
      title: 'Amina',
      style: KitoMapPinStyle.avatar('AW')),
  const KitoMapPin(
      id: 'dot',
      point: LatLng(-1.2750, 36.8000),
      title: 'Stop',
      style: KitoMapPinStyle.dot),
  const KitoMapPin(
      id: 'rider',
      point: LatLng(-1.2860, 36.7950),
      title: 'Otieno',
      style: KitoMapPinStyle.pulse,
      icon: Icons.two_wheeler_rounded,
      heading: 45),
];

void main() {
  setUpAll(() => KitoMap.debugTilesOverride = const KitoMapTiles.none());

  testWidgets('map draws pins, routes and the puck, and taps pins',
      (tester) async {
    KitoMapPin? tapped;
    String? selected;
    await tester.pumpWidget(testApp(StatefulBuilder(
      builder: (context, setState) => Scaffold(
        body: KitoMap(
          pins: _pins,
          selectedPinId: selected,
          onPinTap: (p) => setState(() {
            tapped = p;
            selected = p.id;
          }),
          routes: const [
            KitoMapRoute(
                points: [LatLng(-1.2921, 36.7856), LatLng(-1.2890, 36.7820)],
                progress: 0.4),
          ],
          userLocation: const LatLng(-1.2921, 36.7856),
          userAccuracy: 40,
          userHeading: 30,
          placeCardBuilder: (pin) => KitoMapPlaceCard.fromPin(pin,
              rating: 4.6, distance: '850 m', tags: const ['Open now']),
        ),
      ),
    )));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KitoMapPinView), findsNWidgets(_pins.length));
    expect(find.byType(KitoMapPulse), findsNWidgets(2));
    expect(find.text('KES 650'), findsOneWidget);
    await tester.tap(find.text('KES 650'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped?.id, 'java');
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Java House'), findsOneWidget);
  });

  testWidgets('controls zoom, fit and locate', (tester) async {
    final controller = KitoMapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(testApp(Scaffold(
      body: KitoMap(
        pins: _pins,
        controller: controller,
        initialCenter: const LatLng(-1.2864, 36.8172),
        initialZoom: 13,
        userLocation: const LatLng(-1.2921, 36.7856),
      ),
    )));
    await tester.pump();
    expect(controller.camera?.zoom, 13);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.camera?.zoom, closeTo(14, 1e-6));
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.camera?.zoom, closeTo(13, 1e-6));
    await tester.tap(find.byTooltip('Show my location'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.camera!.center.latitude, closeTo(-1.2921, 1e-4));
    expect(controller.camera!.zoom, closeTo(16, 1e-6));
    await tester.tap(find.byTooltip('Show all places'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.camera!.zoom, lessThan(16));
    controller.animateTo(const LatLng(-1.3192, 36.9278), zoom: 12);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.camera!.center.longitude, closeTo(36.9278, 1e-4));
  });

  testWidgets('clusters collapse close pins and open on tap', (tester) async {
    final controller = KitoMapController();
    addTearDown(controller.dispose);
    final crowd = [
      for (var i = 0; i < 6; i++)
        KitoMapPin(
            id: 'c$i',
            point: LatLng(-1.2864 + i * 0.0003, 36.8172),
            title: 'Kiosk $i',
            style: KitoMapPinStyle.dot),
    ];
    await tester.pumpWidget(testApp(Scaffold(
      body: KitoMap(
        pins: crowd,
        controller: controller,
        initialCenter: const LatLng(-1.2864, 36.8172),
        initialZoom: 11,
        clusterer: const KitoMapClusterer(),
        showsControls: false,
      ),
    )));
    await tester.pump();
    expect(find.byType(KitoMapClusterView), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    await tester.tap(find.byType(KitoMapClusterView));
    await tester.pumpAndSettle();
    expect(controller.camera!.zoom, greaterThan(15));
    expect(find.byType(KitoMapClusterView), findsNothing);
    expect(find.byType(KitoMapPinView), findsNWidgets(6));
  });

  testWidgets('place card actions and pieces build RTL with reduce motion',
      (tester) async {
    var directions = 0;
    await tester.pumpWidget(testApp(
      Scaffold(
        body: ListView(children: [
          KitoMapPlaceCard(
            title: 'Carnivore',
            subtitle: 'Restaurant · Langata',
            rating: 4.4,
            reviewCount: 1200,
            distance: '6.1 km',
            actions: [
              KitoMapPlaceAction(
                  icon: Icons.directions_rounded,
                  label: 'Directions',
                  isPrimary: true,
                  onPressed: () => directions++),
              KitoMapPlaceAction(
                  icon: Icons.call_rounded, label: 'Call', onPressed: () {}),
            ],
            onClose: () {},
          ),
          const KitoMapClusterView(count: 120),
          const KitoMapControls(),
          for (final p in _pins)
            SizedBox(height: 80, child: KitoMapPinView(pin: p, selected: true)),
        ]),
      ),
      direction: TextDirection.rtl,
      reduceMotion: true,
    ));
    await tester.pump();
    expect(find.text('99+'), findsOneWidget);
    expect(find.text(' (1200)'), findsOneWidget);
    await tester.tap(find.text('Directions'));
    expect(directions, 1);
    expect(find.byTooltip('Call'), findsOneWidget);
  });

  testWidgets('the real tile layer is used without the override',
      (tester) async {
    KitoMap.debugTilesOverride = null;
    addTearDown(() => KitoMap.debugTilesOverride = const KitoMapTiles.none());
    const tiles = KitoMapTiles.openStreetMap(userAgentPackageName: 'test');
    expect(tiles.buildLayer(dark: false), isNotNull);
    expect(const KitoMapTiles.none().buildLayer(dark: false), isNull);
    expect(tiles.attribution, contains('OpenStreetMap'));
  });
}
