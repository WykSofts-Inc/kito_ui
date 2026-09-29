// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An illustration's signature movement.
enum KitoEmptyStateMotion {
  /// Drifts gently up and down.
  float,

  /// Swings from the top, like a bell.
  swing,

  /// A short shake every couple of seconds, like a "no".
  shake,

  /// Bounces on the spot, with a squash on landing.
  bounce,

  /// Beats like a heart.
  beat,

  /// Circles slowly, like a magnifier scanning.
  sweep,

  /// Tilts from side to side, like something rocking.
  rock,
}

/// A code-drawn illustration: a glossy gradient tile with an icon, floating satellite chips,
/// twinkling sparkles and a dashed orbit, all moving with a [motion]. No image assets.
///
/// Use a preset (`KitoEmptyStateIllustration.inbox`, `.search`, `.offline`…) or make your own.
@immutable
class KitoEmptyStateIllustration {
  /// Creates an illustration.
  const KitoEmptyStateIllustration({
    required this.name,
    required this.icon,
    this.satellites = const [],
    this.colors = const [],
    this.motion = KitoEmptyStateMotion.float,
    this.badge,
  });

  /// Read by screen readers, e.g. "Empty inbox".
  final String name;

  /// The icon on the tile.
  final IconData icon;

  /// Small icons in chips floating around the tile (up to four are drawn).
  final List<IconData> satellites;

  /// The tile's gradient; empty uses the theme's primary colour.
  final List<Color> colors;

  /// How the tile moves.
  final KitoEmptyStateMotion motion;

  /// A small icon in a bubble on the tile's corner, e.g. an exclamation mark.
  final IconData? badge;

  /// The same illustration in other colours.
  KitoEmptyStateIllustration tinted(List<Color> colors) =>
      copyWith(colors: colors);

  /// A copy with some fields replaced.
  KitoEmptyStateIllustration copyWith({
    String? name,
    IconData? icon,
    List<IconData>? satellites,
    List<Color>? colors,
    KitoEmptyStateMotion? motion,
    IconData? badge,
  }) =>
      KitoEmptyStateIllustration(
        name: name ?? this.name,
        icon: icon ?? this.icon,
        satellites: satellites ?? this.satellites,
        colors: colors ?? this.colors,
        motion: motion ?? this.motion,
        badge: badge ?? this.badge,
      );

  /// Nothing in the inbox.
  static const inbox = KitoEmptyStateIllustration(
    name: 'Empty inbox',
    icon: Icons.inbox_rounded,
    satellites: [
      Icons.mail_rounded,
      Icons.send_rounded,
      Icons.description_rounded
    ],
    colors: [Color(0xFF5C6BFF), Color(0xFF8C54FA)],
  );

  /// No search results.
  static const search = KitoEmptyStateIllustration(
    name: 'Nothing found',
    icon: Icons.search_rounded,
    satellites: [
      Icons.question_mark_rounded,
      Icons.insert_drive_file_rounded,
      Icons.sell_rounded
    ],
    colors: [Color(0xFF14B8C7), Color(0xFF2E73F2)],
    motion: KitoEmptyStateMotion.sweep,
  );

  /// No connection.
  static const offline = KitoEmptyStateIllustration(
    name: 'Offline',
    icon: Icons.wifi_off_rounded,
    satellites: [
      Icons.cloud_rounded,
      Icons.cell_tower_rounded,
      Icons.cloud_off_rounded
    ],
    colors: [Color(0xFF6B7894), Color(0xFF38425C)],
    motion: KitoEmptyStateMotion.rock,
    badge: Icons.priority_high_rounded,
  );

  /// An empty cart.
  static const cart = KitoEmptyStateIllustration(
    name: 'Empty cart',
    icon: Icons.shopping_cart_rounded,
    satellites: [
      Icons.shopping_bag_rounded,
      Icons.sell_rounded,
      Icons.card_giftcard_rounded
    ],
    colors: [Color(0xFFFF8C33), Color(0xFFFF4D73)],
    motion: KitoEmptyStateMotion.rock,
  );

  /// No notifications.
  static const notifications = KitoEmptyStateIllustration(
    name: 'No notifications',
    icon: Icons.notifications_rounded,
    satellites: [
      Icons.bedtime_rounded,
      Icons.check_rounded,
      Icons.auto_awesome_rounded
    ],
    colors: [Color(0xFFFFB826), Color(0xFFFF7A33)],
    motion: KitoEmptyStateMotion.swing,
  );

  /// Something went wrong.
  static const error = KitoEmptyStateIllustration(
    name: 'Something went wrong',
    icon: Icons.warning_rounded,
    satellites: [
      Icons.bolt_rounded,
      Icons.build_rounded,
      Icons.refresh_rounded
    ],
    colors: [Color(0xFFFF5259), Color(0xFFFF8C40)],
    motion: KitoEmptyStateMotion.shake,
  );

  /// All done.
  static const success = KitoEmptyStateIllustration(
    name: 'All done',
    icon: Icons.verified_rounded,
    satellites: [
      Icons.star_rounded,
      Icons.thumb_up_rounded,
      Icons.celebration_rounded
    ],
    colors: [Color(0xFF21C780), Color(0xFF1A9EBF)],
    motion: KitoEmptyStateMotion.bounce,
  );

  /// Location off or unknown.
  static const location = KitoEmptyStateIllustration(
    name: 'Location off',
    icon: Icons.location_on_rounded,
    satellites: [
      Icons.map_rounded,
      Icons.near_me_rounded,
      Icons.directions_car_rounded
    ],
    colors: [Color(0xFFF2476B), Color(0xFFC740D9)],
    motion: KitoEmptyStateMotion.bounce,
  );

  /// No photos.
  static const photos = KitoEmptyStateIllustration(
    name: 'No photos',
    icon: Icons.photo_library_rounded,
    satellites: [
      Icons.photo_camera_rounded,
      Icons.auto_awesome_rounded,
      Icons.favorite_rounded
    ],
    colors: [Color(0xFFB359FF), Color(0xFFFF619E)],
  );

  /// No favourites.
  static const favourites = KitoEmptyStateIllustration(
    name: 'No favourites',
    icon: Icons.favorite_rounded,
    satellites: [
      Icons.star_rounded,
      Icons.bookmark_rounded,
      Icons.auto_awesome_rounded
    ],
    colors: [Color(0xFFFF4D80), Color(0xFFFF7359)],
    motion: KitoEmptyStateMotion.beat,
  );

  /// No messages.
  static const messages = KitoEmptyStateIllustration(
    name: 'No messages',
    icon: Icons.forum_rounded,
    satellites: [
      Icons.sentiment_satisfied_rounded,
      Icons.send_rounded,
      Icons.call_rounded
    ],
    colors: [Color(0xFF33BF73), Color(0xFF1F94E6)],
  );

  /// Nothing scheduled.
  static const calendar = KitoEmptyStateIllustration(
    name: 'Nothing scheduled',
    icon: Icons.calendar_month_rounded,
    satellites: [
      Icons.schedule_rounded,
      Icons.wb_sunny_rounded,
      Icons.coffee_rounded
    ],
    colors: [Color(0xFFFA5C4D), Color(0xFFF29933)],
    motion: KitoEmptyStateMotion.rock,
  );

  /// No transactions.
  static const wallet = KitoEmptyStateIllustration(
    name: 'No transactions',
    icon: Icons.credit_card_rounded,
    satellites: [
      Icons.payments_rounded,
      Icons.swap_horiz_rounded,
      Icons.trending_up_rounded
    ],
    colors: [Color(0xFF1A1A24), Color(0xFF524D6B)],
  );

  /// No downloads.
  static const downloads = KitoEmptyStateIllustration(
    name: 'No downloads',
    icon: Icons.download_rounded,
    satellites: [
      Icons.music_note_rounded,
      Icons.movie_rounded,
      Icons.menu_book_rounded
    ],
    colors: [Color(0xFF338CFF), Color(0xFF59D9F2)],
    motion: KitoEmptyStateMotion.bounce,
  );

  /// Locked or signed out.
  static const locked = KitoEmptyStateIllustration(
    name: 'Locked',
    icon: Icons.lock_rounded,
    satellites: [Icons.key_rounded, Icons.face_rounded, Icons.shield_rounded],
    colors: [Color(0xFF594DF2), Color(0xFF2699F2)],
    motion: KitoEmptyStateMotion.shake,
  );

  /// Every preset, for pickers and galleries.
  static const presets = [
    inbox,
    search,
    offline,
    cart,
    notifications,
    error,
    success,
    location,
    photos,
    favourites,
    messages,
    calendar,
    wallet,
    downloads,
    locked,
  ];

  @override
  bool operator ==(Object other) =>
      other is KitoEmptyStateIllustration &&
      other.name == name &&
      other.icon == icon &&
      other.motion == motion &&
      other.badge == badge &&
      _listEquals(other.satellites, satellites) &&
      _listEquals(other.colors, colors);

  @override
  int get hashCode => Object.hash(name, icon, motion, badge,
      Object.hashAll(satellites), Object.hashAll(colors));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Where an illustration's tile is at a moment: offsets are fractions of the illustration's
/// size, rotation is in degrees, and [squash] below 1 flattens it on landing.
@immutable
class KitoEmptyStatePose {
  /// Creates a pose.
  const KitoEmptyStatePose(
      {this.x = 0,
      this.y = 0,
      this.rotation = 0,
      this.scale = 1,
      this.squash = 1});

  /// Horizontal offset, as a fraction of the size.
  final double x;

  /// Vertical offset, as a fraction of the size (negative is up).
  final double y;

  /// Degrees, clockwise.
  final double rotation;

  /// Uniform scale.
  final double scale;

  /// Vertical squash; 1 is none.
  final double squash;

  /// The pose [seconds] into [motion]'s loop.
  static KitoEmptyStatePose at(double seconds, KitoEmptyStateMotion motion) {
    final t = seconds;
    switch (motion) {
      case KitoEmptyStateMotion.float:
        return KitoEmptyStatePose(
            y: math.sin(t * 1.6) * 0.03, rotation: math.sin(t * 0.8) * 2);
      case KitoEmptyStateMotion.swing:
        // A swing burst, then rest, every 2.4 s.
        final local = t % 2.4;
        final damp = local < 1.2 ? math.exp(-local * 2.6) : 0.0;
        return KitoEmptyStatePose(
            y: math.sin(t * 1.6) * 0.012,
            rotation: math.sin(local * 14) * 16 * damp);
      case KitoEmptyStateMotion.shake:
        final local = t % 2.2;
        final active = local < 0.5 ? math.sin(local / 0.5 * math.pi) : 0.0;
        return KitoEmptyStatePose(
            x: math.sin(local * 48) * 0.025 * active,
            rotation: math.sin(local * 48) * 3 * active);
      case KitoEmptyStateMotion.bounce:
        final local = (t % 1.3) / 1.3;
        final height = math.max(0.0, math.sin(local * math.pi));
        final landing = local > 0.9 || local < 0.06 ? 0.9 : 1.0;
        return KitoEmptyStatePose(y: -height * 0.06, squash: landing);
      case KitoEmptyStateMotion.beat:
        final local = (t % 1.1) / 1.1;
        final lub = math.exp(-math.pow((local - 0.12) / 0.06, 2));
        final dub = 0.6 * math.exp(-math.pow((local - 0.32) / 0.06, 2));
        return KitoEmptyStatePose(scale: 1 + 0.08 * math.min(lub + dub, 1));
      case KitoEmptyStateMotion.sweep:
        return KitoEmptyStatePose(
            x: math.cos(t * 1.4) * 0.04,
            y: math.sin(t * 1.4) * 0.03,
            rotation: math.sin(t * 1.4) * 6);
      case KitoEmptyStateMotion.rock:
        return KitoEmptyStatePose(
            y: (math.sin(t * 1.5)).abs() * -0.015,
            rotation: math.sin(t * 1.5) * 6);
    }
  }

  /// Where satellite [index] sits, as a unit offset from the centre: spread around the tile.
  static Offset satellite(int index) {
    const angles = [-150.0, -35.0, 25.0, 160.0, -95.0];
    final angle = angles[index % angles.length] * math.pi / 180;
    final radius = index.isEven ? 0.4 : 0.44;
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  /// Each satellite bobs on its own phase, so they never move in lockstep.
  static double bob(int index, double seconds) =>
      math.sin(seconds * (1.1 + index * 0.23) + index * 1.7) * 0.025;

  /// Sparkles twinkle in turn: 0 hidden, 1 fully lit.
  static double twinkle(int index, double seconds) {
    final local = ((seconds + index * 0.7) % 2.8) / 2.8;
    return math.max(0, math.sin(local * math.pi * 2));
  }

  @override
  bool operator ==(Object other) =>
      other is KitoEmptyStatePose &&
      other.x == x &&
      other.y == y &&
      other.rotation == rotation &&
      other.scale == scale &&
      other.squash == squash;

  @override
  int get hashCode => Object.hash(x, y, rotation, scale, squash);
}
