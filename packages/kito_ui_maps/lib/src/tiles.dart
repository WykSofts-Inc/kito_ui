// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Where a `KitoMap` gets its tiles. OpenStreetMap by default, no API key needed.
///
/// OpenStreetMap's tile servers are free but have a
/// [usage policy](https://operations.osmfoundation.org/policies/tiles/): pass your app's own
/// package name as [userAgentPackageName], keep the attribution visible, and use a commercial
/// provider (with [KitoMapTiles.custom]) for heavy traffic.
@immutable
class KitoMapTiles {
  /// OpenStreetMap's standard tiles.
  const KitoMapTiles.openStreetMap({
    this.userAgentPackageName = 'com.wyksoftsinc.kito_ui',
    this.darkensInDarkMode = true,
    this.tileProvider,
  })  : urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains = const [],
        attribution = '© OpenStreetMap contributors',
        maxNativeZoom = 19;

  /// Any XYZ tile server: `https://{s}.example.com/{z}/{x}/{y}.png`.
  const KitoMapTiles.custom({
    required String this.urlTemplate,
    this.attribution,
    this.subdomains = const [],
    this.maxNativeZoom = 19,
    this.userAgentPackageName = 'com.wyksoftsinc.kito_ui',
    this.darkensInDarkMode = false,
    this.tileProvider,
  });

  /// No tiles: a plain themed background with a faint grid. For tests, previews and offline
  /// screens; nothing touches the network.
  const KitoMapTiles.none()
      : urlTemplate = null,
        attribution = null,
        subdomains = const [],
        maxNativeZoom = 19,
        userAgentPackageName = '',
        darkensInDarkMode = false,
        tileProvider = null;

  /// The XYZ template, or null for [KitoMapTiles.none].
  final String? urlTemplate;

  /// The credit shown in the corner.
  final String? attribution;

  /// Values for `{s}`.
  final List<String> subdomains;

  /// The deepest zoom the server has; deeper zooms scale these tiles up.
  final int maxNativeZoom;

  /// Sent in the User-Agent header, as tile policies ask: your app's package name.
  final String userAgentPackageName;

  /// Inverts and hue-rotates the tiles when the theme is dark.
  final bool darkensInDarkMode;

  /// Your own tile provider (caching, auth headers, a fake one in tests).
  final TileProvider? tileProvider;

  /// True for [KitoMapTiles.none].
  bool get isNone => urlTemplate == null;

  /// The flutter_map layer, or null for [KitoMapTiles.none].
  Widget? buildLayer({required bool dark}) {
    if (urlTemplate == null) return null;
    final layer = TileLayer(
      urlTemplate: urlTemplate,
      subdomains: subdomains,
      maxNativeZoom: maxNativeZoom,
      userAgentPackageName: userAgentPackageName,
      tileProvider: tileProvider,
      tileBuilder: dark && darkensInDarkMode ? darkModeTileBuilder : null,
    );
    return layer;
  }
}
