// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The colour roles every Kito widget draws with.
@immutable
class KitoColors {
  /// Creates a colour set.
  const KitoColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceMuted,
    required this.border,
    required this.danger,
    required this.success,
    required this.warning,
  });

  /// The main brand colour: filled buttons, selection, focus.
  final Color primary;

  /// Text and icons drawn on [primary].
  final Color onPrimary;

  /// A second accent.
  final Color secondary;

  /// Text and icons drawn on [secondary].
  final Color onSecondary;

  /// The screen behind everything.
  final Color background;

  /// Text and icons on [background].
  final Color onBackground;

  /// Cards, sheets and fields.
  final Color surface;

  /// Text and icons on [surface].
  final Color onSurface;

  /// A quieter surface: tracks, skeletons, inactive chips.
  final Color surfaceMuted;

  /// Hairlines and outlines.
  final Color border;

  /// Errors and destructive actions.
  final Color danger;

  /// Confirmations.
  final Color success;

  /// Cautions.
  final Color warning;

  /// Black primary on white — the Kito default.
  static const light = KitoColors(
    primary: Color(0xFF0B0B0F),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF5B5BD6),
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF6F6F8),
    onBackground: Color(0xFF0B0B0F),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF16161D),
    surfaceMuted: Color(0xFFEDEDF1),
    border: Color(0x1F0B0B0F),
    danger: Color(0xFFE5484D),
    success: Color(0xFF30A46C),
    warning: Color(0xFFF5A524),
  );

  /// White primary on near-black.
  static const dark = KitoColors(
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF0B0B0F),
    secondary: Color(0xFF8E8EF7),
    onSecondary: Color(0xFF0B0B0F),
    background: Color(0xFF0B0B0F),
    onBackground: Color(0xFFF4F4F6),
    surface: Color(0xFF16161D),
    onSurface: Color(0xFFF4F4F6),
    surfaceMuted: Color(0xFF22222B),
    border: Color(0x24FFFFFF),
    danger: Color(0xFFFF6369),
    success: Color(0xFF3DD68C),
    warning: Color(0xFFFFB224),
  );

  /// Electric teal and violet on deep navy, the DevKit look.
  static const neon = KitoColors(
    primary: Color(0xFF00E5D4),
    onPrimary: Color(0xFF041014),
    secondary: Color(0xFFA855F7),
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFF070B14),
    onBackground: Color(0xFFEAF6FF),
    surface: Color(0xFF111827),
    onSurface: Color(0xFFEAF6FF),
    surfaceMuted: Color(0xFF1B2436),
    border: Color(0x2600E5D4),
    danger: Color(0xFFFF5C7A),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
  );

  /// A copy with some roles replaced.
  KitoColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceMuted,
    Color? border,
    Color? danger,
    Color? success,
    Color? warning,
  }) =>
      KitoColors(
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        secondary: secondary ?? this.secondary,
        onSecondary: onSecondary ?? this.onSecondary,
        background: background ?? this.background,
        onBackground: onBackground ?? this.onBackground,
        surface: surface ?? this.surface,
        onSurface: onSurface ?? this.onSurface,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        border: border ?? this.border,
        danger: danger ?? this.danger,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  /// Blends two colour sets, for animated theme changes.
  static KitoColors lerp(KitoColors a, KitoColors b, double t) => KitoColors(
        primary: Color.lerp(a.primary, b.primary, t)!,
        onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
        secondary: Color.lerp(a.secondary, b.secondary, t)!,
        onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t)!,
        background: Color.lerp(a.background, b.background, t)!,
        onBackground: Color.lerp(a.onBackground, b.onBackground, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
        surfaceMuted: Color.lerp(a.surfaceMuted, b.surfaceMuted, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        danger: Color.lerp(a.danger, b.danger, t)!,
        success: Color.lerp(a.success, b.success, t)!,
        warning: Color.lerp(a.warning, b.warning, t)!,
      );
}

/// Spacing steps, in logical pixels.
@immutable
class KitoSpacing {
  /// Creates a spacing scale.
  const KitoSpacing({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
  });

  /// 2 by default.
  final double xxs;

  /// 4 by default.
  final double xs;

  /// 8 by default.
  final double sm;

  /// 12 by default.
  final double md;

  /// 16 by default.
  final double lg;

  /// 24 by default.
  final double xl;

  /// 32 by default.
  final double xxl;

  /// Blends two scales.
  static KitoSpacing lerp(KitoSpacing a, KitoSpacing b, double t) =>
      KitoSpacing(
        xxs: lerpDouble(a.xxs, b.xxs, t)!,
        xs: lerpDouble(a.xs, b.xs, t)!,
        sm: lerpDouble(a.sm, b.sm, t)!,
        md: lerpDouble(a.md, b.md, t)!,
        lg: lerpDouble(a.lg, b.lg, t)!,
        xl: lerpDouble(a.xl, b.xl, t)!,
        xxl: lerpDouble(a.xxl, b.xxl, t)!,
      );
}

/// Corner radii.
@immutable
class KitoRadii {
  /// Creates a radius scale.
  const KitoRadii({
    this.sm = 6,
    this.md = 10,
    this.lg = 16,
    this.xl = 24,
    this.pill = 999,
  });

  /// 6 by default.
  final double sm;

  /// 10 by default.
  final double md;

  /// 16 by default.
  final double lg;

  /// 24 by default.
  final double xl;

  /// Fully rounded ends.
  final double pill;

  /// Blends two radius scales.
  static KitoRadii lerp(KitoRadii a, KitoRadii b, double t) => KitoRadii(
        sm: lerpDouble(a.sm, b.sm, t)!,
        md: lerpDouble(a.md, b.md, t)!,
        lg: lerpDouble(a.lg, b.lg, t)!,
        xl: lerpDouble(a.xl, b.xl, t)!,
        pill: lerpDouble(a.pill, b.pill, t)!,
      );
}

/// Text styles. Colours are left unset so they follow the surrounding
/// `DefaultTextStyle`; sizes scale with the system text size.
@immutable
class KitoTypography {
  /// Creates a type scale.
  const KitoTypography({
    this.display = const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5),
    this.title =
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
    this.headline =
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
    this.body =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
    this.bodyEmphasized =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    this.label =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
    this.caption =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
    this.button =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
  });

  /// Big screen titles.
  final TextStyle display;

  /// Section and sheet titles.
  final TextStyle title;

  /// Row titles and emphasised lines.
  final TextStyle headline;

  /// Running text.
  final TextStyle body;

  /// Running text, stronger.
  final TextStyle bodyEmphasized;

  /// Field labels and chips.
  final TextStyle label;

  /// Small print.
  final TextStyle caption;

  /// Button titles.
  final TextStyle button;

  /// Blends two type scales.
  static KitoTypography lerp(KitoTypography a, KitoTypography b, double t) =>
      KitoTypography(
        display: TextStyle.lerp(a.display, b.display, t)!,
        title: TextStyle.lerp(a.title, b.title, t)!,
        headline: TextStyle.lerp(a.headline, b.headline, t)!,
        body: TextStyle.lerp(a.body, b.body, t)!,
        bodyEmphasized: TextStyle.lerp(a.bodyEmphasized, b.bodyEmphasized, t)!,
        label: TextStyle.lerp(a.label, b.label, t)!,
        caption: TextStyle.lerp(a.caption, b.caption, t)!,
        button: TextStyle.lerp(a.button, b.button, t)!,
      );
}

/// Durations and curves, so every kit moves the same way.
@immutable
class KitoMotion {
  /// Creates a motion set.
  const KitoMotion({
    this.fast = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 280),
    this.slow = const Duration(milliseconds: 450),
    this.standard = Curves.easeOutCubic,
    this.emphasized = Curves.easeInOutCubicEmphasized,
    this.spring = const KitoSpringCurve(),
  });

  /// Taps, toggles, small fades.
  final Duration fast;

  /// Most transitions.
  final Duration medium;

  /// Big, choreographed moves.
  final Duration slow;

  /// The everyday curve.
  final Curve standard;

  /// For entrances that should feel deliberate.
  final Curve emphasized;

  /// A gentle overshoot, like SwiftUI's default spring.
  final Curve spring;

  /// True when the user asked for less motion (Reduce Motion / animations off).
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when the user asked for less motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// A damped spring as a [Curve]: overshoots slightly, then settles at 1.
class KitoSpringCurve extends Curve {
  /// [damping] below 1 overshoots; higher is calmer.
  const KitoSpringCurve({this.damping = 0.72, this.stiffness = 10});

  /// The damping ratio (0 < damping < 1 for a bounce).
  final double damping;

  /// How quickly it oscillates.
  final double stiffness;

  @override
  double transformInternal(double t) {
    final d = damping.clamp(0.05, 0.99);
    final omega = stiffness;
    final wd = omega * math.sqrt(1 - d * d);
    final envelope = math.exp(-d * omega * t);
    return 1 -
        envelope * (math.cos(wd * t) + (d * omega / wd) * math.sin(wd * t));
  }
}
