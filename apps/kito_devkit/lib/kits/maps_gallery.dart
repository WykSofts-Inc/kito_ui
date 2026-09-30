// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_maps/kito_ui_maps.dart';

import '../catalog/catalog.dart';

const _tiles = KitoMapTiles.openStreetMap(
    userAgentPackageName: 'com.wyksoftsinc.kito_devkit');

const _cafes = [
  KitoMapPin(
    id: 'java',
    point: LatLng(-1.2649, 36.8047),
    title: 'Java House, Sarit Centre',
    subtitle: 'Coffee · Westlands',
    style: KitoMapPinStyle.bubble('KES 650'),
  ),
  KitoMapPin(
    id: 'artcaffe',
    point: LatLng(-1.2673, 36.8110),
    title: 'Artcaffé, The Oval',
    subtitle: 'Bakery · Westlands',
    style: KitoMapPinStyle.bubble('KES 780'),
  ),
  KitoMapPin(
    id: 'connect',
    point: LatLng(-1.2610, 36.8030),
    title: 'Connect Coffee',
    subtitle: 'Roastery · Westgate',
    style: KitoMapPinStyle.bubble('KES 520'),
    badge: '4.9',
  ),
  KitoMapPin(
    id: 'spring',
    point: LatLng(-1.2702, 36.8062),
    title: 'Spring Valley Coffee',
    subtitle: 'Garden café · Westlands',
    style: KitoMapPinStyle.bubble('KES 600'),
  ),
];

const _styles = [
  KitoMapPin(
    id: 'dot',
    point: LatLng(-1.2833, 36.8219),
    title: 'Kenyatta Avenue stop',
    style: KitoMapPinStyle.dot,
    tint: Color(0xFF2F80ED),
  ),
  KitoMapPin(
    id: 'icon',
    point: LatLng(-1.2887, 36.8233),
    title: 'KICC',
    style: KitoMapPinStyle.icon(Icons.account_balance_rounded),
    tint: Color(0xFF8C5CF0),
  ),
  KitoMapPin(
    id: 'bubble',
    point: LatLng(-1.2805, 36.8150),
    title: 'Sankara Nairobi',
    style: KitoMapPinStyle.bubble('KES 18,500'),
  ),
  KitoMapPin(
    id: 'avatar',
    point: LatLng(-1.2920, 36.8140),
    title: 'Amina',
    subtitle: 'Sharing her location',
    style: KitoMapPinStyle.avatar('AW'),
    tint: Color(0xFFD13D6B),
  ),
  KitoMapPin(
    id: 'teardrop',
    point: LatLng(-1.2864, 36.8290),
    title: 'Nairobi Railway Museum',
    icon: Icons.train_rounded,
    tint: Color(0xFFE5484D),
  ),
  KitoMapPin(
    id: 'pulse',
    point: LatLng(-1.2950, 36.8250),
    title: 'Otieno, your rider',
    style: KitoMapPinStyle.pulse,
    icon: Icons.two_wheeler_rounded,
    heading: 320,
    tint: Color(0xFF21A86B),
  ),
];

/// A made-up but plausible boda ride from Kilimani to the CBD.
const _ride = [
  LatLng(-1.2921, 36.7856),
  LatLng(-1.2905, 36.7902),
  LatLng(-1.2896, 36.7968),
  LatLng(-1.2880, 36.8031),
  LatLng(-1.2869, 36.8092),
  LatLng(-1.2861, 36.8140),
  LatLng(-1.2848, 36.8190),
  LatLng(-1.2833, 36.8219),
];

List<KitoMapPin> _kiosks() {
  final r = math.Random(7);
  const names = ['M-Pesa agent', 'Kiosk', 'Duka', 'Chemist', 'Mama mboga'];
  return [
    for (var i = 0; i < 60; i++)
      KitoMapPin(
        id: 'k$i',
        point: LatLng(-1.2864 + (r.nextDouble() - 0.5) * 0.06,
            36.8172 + (r.nextDouble() - 0.5) * 0.08),
        title: '${names[i % names.length]} ${i + 1}',
        style: KitoMapPinStyle.dot,
        tint: i % names.length == 0 ? const Color(0xFF2FB24C) : null,
      ),
  ];
}

Widget _frame(Widget map) => SizedBox(
      width: double.infinity,
      height: 440,
      child: map,
    );

/// The gallery for kito_ui_maps.
final mapsKit = KitEntry(
  title: 'Maps',
  package: 'kito_ui_maps',
  blurb: 'OpenStreetMap pins, clusters, routes, a live puck and place cards',
  icon: Icons.map_rounded,
  category: KitCategory.device,
  isNew: true,
  sections: [
    KitSection('Maps', Icons.map_rounded, [
      KitSample(
        title: 'Coffee in Westlands',
        subtitle: 'Price pins; tap one and its card rises from the bottom.',
        code: '''KitoMap(
  tiles: const KitoMapTiles.openStreetMap(
      userAgentPackageName: 'com.example.app'),
  pins: cafes,
  selectedPinId: selected?.id,
  onPinTap: (pin) => setState(() => selected = pin),
  onMapTap: (_) => setState(() => selected = null),
  placeCardBuilder: (pin) => KitoMapPlaceCard.fromPin(pin,
      rating: 4.6, distance: '850 m', actions: [...]),
)''',
        builder: (_) => _frame(const _Cafes()),
      ),
      KitSample(
        title: 'Six pin styles',
        subtitle:
            'Dot, icon, price bubble, avatar, teardrop and a pulsing rider.',
        code: '''const KitoMapPin(
  id: 'rider',
  point: LatLng(-1.2950, 36.8250),
  title: 'Otieno, your rider',
  style: KitoMapPinStyle.pulse,
  icon: Icons.two_wheeler_rounded,
  heading: 320,
)
// also .dot, .icon(…), .bubble('KES 18,500'), .avatar('AW'), .teardrop''',
        builder: (_) => _frame(const _Styles()),
      ),
      KitSample(
        title: 'Clusters',
        subtitle: '60 shops around the CBD; zoom or tap a bubble to split it.',
        code: '''KitoMap(
  pins: kiosks,
  clusterer: const KitoMapClusterer(cellSize: 64),
)''',
        builder: (_) => _frame(KitoMap(
          tiles: _tiles,
          pins: _kiosks(),
          clusterer: const KitoMapClusterer(),
          initialCenter: const LatLng(-1.2864, 36.8172),
          initialZoom: 12.5,
          borderRadius: BorderRadius.circular(20),
        )),
      ),
    ]),
    KitSection('Routes', Icons.route_rounded, [
      KitSample(
        title: 'Boda on the way',
        subtitle: 'The travelled part fades as the rider moves, with an ETA.',
        code:
            '''final (:point, :bearing) = KitoMapGeometry.along(ride, progress);

KitoMap(
  routes: [KitoMapRoute(points: ride, progress: progress)],
  pins: [
    KitoMapPin(
      id: 'rider',
      point: point,
      heading: bearing,
      title: 'Otieno',
      style: KitoMapPinStyle.pulse,
      icon: Icons.two_wheeler_rounded,
    ),
  ],
)''',
        builder: (_) => _frame(const _Ride()),
      ),
      KitSample(
        title: 'Walk, then ride',
        subtitle: 'A dashed walking leg to the stage, then the matatu route.',
        code: '''routes: [
  KitoMapRoute(points: walk, dashed: true, color: Colors.green, width: 4),
  KitoMapRoute(points: matatu),
]''',
        builder: (_) => _frame(KitoMap(
          tiles: _tiles,
          borderRadius: BorderRadius.circular(20),
          routes: [
            KitoMapRoute(
                points: _ride.sublist(0, 3),
                dashed: true,
                width: 4,
                color: const Color(0xFF21A86B)),
            KitoMapRoute(points: _ride.sublist(2)),
          ],
          pins: const [
            KitoMapPin(
                id: 'stage',
                point: LatLng(-1.2896, 36.7968),
                title: 'Adams Arcade stage',
                style: KitoMapPinStyle.icon(Icons.directions_bus_rounded),
                tint: Color(0xFFF5A524)),
          ],
          userLocation: _ride.first,
        )),
      ),
    ]),
    KitSection('Location', Icons.my_location_rounded, [
      KitSample(
        title: 'You are here',
        subtitle: 'A pulsing puck with heading and accuracy; tap locate.',
        code: '''KitoMap(
  userLocation: here,
  userHeading: 40,
  userAccuracy: 60,
  pins: nearby,
)''',
        builder: (_) => _frame(KitoMap(
          tiles: _tiles,
          borderRadius: BorderRadius.circular(20),
          userLocation: const LatLng(-1.2986, 36.7627),
          userHeading: 40,
          userAccuracy: 60,
          pins: const [
            KitoMapPin(
                id: 'junction',
                point: LatLng(-1.2983, 36.7621),
                title: 'The Junction Mall',
                style: KitoMapPinStyle.icon(Icons.shopping_bag_rounded),
                tint: Color(0xFF8C5CF0)),
            KitoMapPin(
                id: 'prestige',
                point: LatLng(-1.2991, 36.7836),
                title: 'Prestige Plaza',
                style: KitoMapPinStyle.icon(Icons.local_movies_rounded),
                tint: Color(0xFFE5484D)),
          ],
        )),
      ),
    ]),
    KitSection('Pieces', Icons.widgets_rounded, [
      KitSample(
        title: 'Place card',
        subtitle: 'Rating, distance, tags and actions, for your own sheets.',
        code: '''KitoMapPlaceCard(
  title: 'Carnivore',
  subtitle: 'Nyama choma · Langata',
  rating: 4.4,
  reviewCount: 1200,
  distance: '6.1 km',
  tags: const ['Open now', 'Parking'],
  actions: [
    KitoMapPlaceAction(icon: Icons.directions_rounded, label: 'Directions',
        isPrimary: true, onPressed: go),
    KitoMapPlaceAction(icon: Icons.call_rounded, label: 'Call', onPressed: call),
  ],
)''',
        builder: (_) => KitoMapPlaceCard(
          title: 'Carnivore',
          subtitle: 'Nyama choma · Langata',
          icon: Icons.restaurant_rounded,
          rating: 4.4,
          reviewCount: 1200,
          distance: '6.1 km',
          tags: const ['Open now', 'Parking', 'Live music Fri'],
          tint: const Color(0xFFE5484D),
          actions: [
            KitoMapPlaceAction(
                icon: Icons.directions_rounded,
                label: 'Directions',
                isPrimary: true,
                onPressed: () {}),
            KitoMapPlaceAction(
                icon: Icons.call_rounded, label: 'Call', onPressed: () {}),
            KitoMapPlaceAction(
                icon: Icons.bookmark_add_rounded,
                label: 'Save',
                onPressed: () {}),
          ],
          onClose: () {},
        ),
      ),
      KitSample(
        title: 'Pins up close',
        subtitle: 'Tap to select; each style springs up by its own amount.',
        code: '''KitoMapPinView(pin: pin, selected: selected, onTap: toggle)''',
        builder: (_) => const _PinShelf(),
      ),
      KitSample(
        title: 'Map controls',
        subtitle: 'Zoom, locate and fit, for maps of your own.',
        code: '''KitoMapControls(
  onZoomIn: () => controller.zoomBy(1),
  onZoomOut: () => controller.zoomBy(-1),
  onLocate: locate,
  onFitAll: () => controller.fitPoints(points),
  isFollowingUser: following,
)''',
        builder: (_) => const _Controls(),
      ),
    ]),
  ],
);

class _Cafes extends StatefulWidget {
  const _Cafes();

  @override
  State<_Cafes> createState() => _CafesState();
}

class _CafesState extends State<_Cafes> {
  String? _selected;

  @override
  Widget build(BuildContext context) => KitoMap(
        tiles: _tiles,
        pins: _cafes,
        borderRadius: BorderRadius.circular(20),
        selectedPinId: _selected,
        onPinTap: (p) => setState(() => _selected = p.id),
        onMapTap: (_) => setState(() => _selected = null),
        placeCardBuilder: (pin) => KitoMapPlaceCard.fromPin(
          pin,
          rating: pin.badge != null ? 4.9 : 4.5,
          reviewCount: 312,
          distance: '850 m',
          tags: const ['Open now', 'Wi-Fi'],
          onClose: () => setState(() => _selected = null),
          actions: [
            KitoMapPlaceAction(
                icon: Icons.directions_walk_rounded,
                label: 'Directions',
                isPrimary: true,
                onPressed: () {}),
            KitoMapPlaceAction(
                icon: Icons.call_rounded, label: 'Call', onPressed: () {}),
          ],
        ),
      );
}

class _Styles extends StatefulWidget {
  const _Styles();

  @override
  State<_Styles> createState() => _StylesState();
}

class _StylesState extends State<_Styles> {
  String? _selected = 'bubble';

  @override
  Widget build(BuildContext context) => KitoMap(
        tiles: _tiles,
        pins: _styles,
        borderRadius: BorderRadius.circular(20),
        selectedPinId: _selected,
        onPinTap: (p) => setState(() => _selected = p.id),
        onMapTap: (_) => setState(() => _selected = null),
      );
}

class _Ride extends StatefulWidget {
  const _Ride();

  @override
  State<_Ride> createState() => _RideState();
}

class _RideState extends State<_Ride> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final length = KitoMapGeometry.length(_ride);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = context.reduceMotion ? 0.45 : _c.value;
        final at = KitoMapGeometry.along(_ride, t);
        final left = length * (1 - t);
        return Stack(children: [
          Positioned.fill(
            child: KitoMap(
              tiles: _tiles,
              borderRadius: BorderRadius.circular(20),
              showsControls: false,
              initialCenter: const LatLng(-1.2878, 36.8040),
              initialZoom: 14,
              routes: [KitoMapRoute(points: _ride, progress: t)],
              pins: [
                KitoMapPin(
                  id: 'rider',
                  point: at.point,
                  heading: at.bearing,
                  title: 'Otieno, your rider',
                  style: KitoMapPinStyle.pulse,
                  icon: Icons.two_wheeler_rounded,
                  tint: const Color(0xFF21A86B),
                ),
                const KitoMapPin(
                    id: 'drop',
                    point: LatLng(-1.2833, 36.8219),
                    title: 'Hilton Nairobi',
                    icon: Icons.flag_rounded),
              ],
            ),
          ),
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Otieno is on the way',
                      style: theme.typography.label.copyWith(
                          color: theme.colors.onSurface,
                          fontWeight: FontWeight.w700)),
                  Text(
                      KitoMapFormat.summary(
                          left, Duration(seconds: (left / 6).round())),
                      style: theme.typography.caption.copyWith(
                          color:
                              theme.colors.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _PinShelf extends StatefulWidget {
  const _PinShelf();

  @override
  State<_PinShelf> createState() => _PinShelfState();
}

class _PinShelfState extends State<_PinShelf> {
  final _on = <String>{'bubble'};

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final p in _styles)
            SizedBox.fromSize(
              size: KitoMapPinView.markerSize(p) * 1.1,
              child: KitoMapPinView(
                pin: p,
                selected: _on.contains(p.id),
                onTap: () => setState(() =>
                    _on.contains(p.id) ? _on.remove(p.id) : _on.add(p.id)),
              ),
            ),
          const SizedBox(
              width: 76, height: 76, child: KitoMapClusterView(count: 24)),
        ],
      );
}

class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  bool _following = false;
  int _zoom = 14;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      KitoMapControls(
        onZoomIn: () => setState(() => _zoom = math.min(_zoom + 1, 19)),
        onZoomOut: () => setState(() => _zoom = math.max(_zoom - 1, 3)),
        onLocate: () => setState(() => _following = !_following),
        onFitAll: () => setState(() => _zoom = 12),
        isFollowingUser: _following,
      ),
      const SizedBox(width: 24),
      Text('Zoom $_zoom${_following ? '\nFollowing you' : ''}',
          style: theme.typography.bodyEmphasized
              .copyWith(color: theme.colors.onSurface)),
    ]);
  }
}
