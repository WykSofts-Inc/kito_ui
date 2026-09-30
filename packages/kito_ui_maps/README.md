# kito_ui_maps

Themed maps for Flutter on [flutter_map](https://pub.dev/packages/flutter_map) with
OpenStreetMap tiles — no API key. Pins in six styles, clustering, routes with travelled
progress, a pulsing user-location puck, zoom / locate / fit controls and a place card that
rises for the selected pin. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui);
follows `KitoTheme` (light, dark, neon), right-to-left layouts and Reduce Motion.

> **Opt-in native kit.** `kito_ui_maps` is *not* part of the `kito_ui` umbrella, so apps
> that don't show maps never pull in flutter_map or need network setup. Add it on its own.

## Install

```yaml
dependencies:
  kito_ui_maps: ^0.1.0
```

```dart
import 'package:kito_ui_maps/kito_ui_maps.dart';   // also exports latlong2's LatLng
```

## Platform setup

Tiles are downloaded over HTTPS, so the app needs network access:

- **Android** — add `<uses-permission android:name="android.permission.INTERNET"/>` to
  `android/app/src/main/AndroidManifest.xml` (Flutter's template only adds it for debug).
- **macOS** — add `com.apple.security.network.client` = `true` to both
  `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
- **iOS, web** — nothing to do.

### OpenStreetMap tile policy

OpenStreetMap's tile servers are free for light use under their
[tile usage policy](https://operations.osmfoundation.org/policies/tiles/): identify your app,
keep the attribution visible (the map shows "© OpenStreetMap contributors" in the corner), and
move to a commercial or self-hosted tile provider for heavy traffic.

```dart
const tiles = KitoMapTiles.openStreetMap(userAgentPackageName: 'com.example.myapp');

// Or any XYZ server:
const tiles = KitoMapTiles.custom(
  urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.png',
  attribution: '© Example Maps',
);
```

## Quick start

```dart
KitoMapPin? selected;

KitoMap(
  tiles: const KitoMapTiles.openStreetMap(userAgentPackageName: 'com.example.myapp'),
  pins: const [
    KitoMapPin(
      id: 'java',
      point: LatLng(-1.2890, 36.7820),
      title: 'Java House',
      subtitle: 'Coffee · Valley Arcade',
      style: KitoMapPinStyle.bubble('KES 650'),
    ),
  ],
  selectedPinId: selected?.id,
  onPinTap: (pin) => setState(() => selected = pin),
  onMapTap: (_) => setState(() => selected = null),
  placeCardBuilder: (pin) => KitoMapPlaceCard.fromPin(pin, rating: 4.6, distance: '850 m'),
)
```

With no `initialCenter` the map frames its pins; with nothing to show it opens on Nairobi.

## Pins

```dart
KitoMapPinStyle.dot                          // a small dot with a white ring
KitoMapPinStyle.icon(Icons.local_cafe)       // a round icon badge
KitoMapPinStyle.bubble('KES 4,500')          // a price capsule with a tail
KitoMapPinStyle.avatar('AW', image: photo)   // a face or initials with a pointer
KitoMapPinStyle.teardrop                     // the classic pin (uses `icon`)
KitoMapPinStyle.pulse                        // a live dot; `heading` draws a cone
```

Every pin can have a `tint`, a corner `badge` ("4.8") and a spoken label from its title,
price and subtitle. Selected pins spring up. `KitoMapPinView` and `KitoMapClusterView` also
work in your own flutter_map `MarkerLayer`s.

## Clusters, routes and the user

```dart
KitoMap(
  pins: matatuStops,
  clusterer: const KitoMapClusterer(cellSize: 64, maximumZoom: 17),
  routes: [
    KitoMapRoute(points: ride, progress: 0.4),       // travelled part fades
    KitoMapRoute(points: walk, dashed: true, color: Colors.green),
  ],
  userLocation: here,
  userHeading: 30,
  userAccuracy: 25,                                   // metres
)
```

Tapping a cluster zooms to fit it. The selected pin never clusters.

## Moving the camera

```dart
final controller = KitoMapController();

KitoMap(controller: controller, pins: pins);

controller.animateTo(const LatLng(-1.3192, 36.9278), zoom: 14);   // JKIA
controller.fitPoints(route);
controller.zoomBy(1);
controller.mapController;   // flutter_map's own controller for anything else
```

Glides ease in and out (and pull back a little on long hops); Reduce Motion jumps instead.
Add your own flutter_map layers (polygons, overlays) with `layers:`.

## Geometry

```dart
KitoMapGeometry.distance(a, b);           // metres
KitoMapGeometry.bearing(a, b);            // degrees from north
KitoMapGeometry.along(route, 0.5);        // point and bearing halfway
KitoMapGeometry.split(route, 0.3);        // travelled and remaining
KitoMapGeometry.circle(center, 500);      // a ring for a radius
KitoMapFormat.summary(1234, const Duration(minutes: 12));  // "1.2 km · 12 min"
```

## Testing

Widget tests must not download tiles. Switch every map to a plain themed backdrop:

```dart
setUpAll(() => KitoMap.debugTilesOverride = const KitoMapTiles.none());
```

or pass `tiles: const KitoMapTiles.none()` (or your own `tileProvider`) to a single map.

## License

MIT — see [LICENSE](LICENSE). Map data © OpenStreetMap contributors.
