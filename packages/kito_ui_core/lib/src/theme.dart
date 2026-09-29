// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Everything a Kito widget needs to look right: colours, spacing, radii, type and motion.
///
/// It's a [ThemeExtension], so add it to your [ThemeData] and every Kito widget below picks it
/// up; `KitoTheme.of(context)` falls back to [KitoTheme.light] or [KitoTheme.dark] (following the
/// platform brightness) when none is installed.
///
/// ```dart
/// MaterialApp(
///   theme: KitoTheme.light.toThemeData(),
///   darkTheme: KitoTheme.dark.toThemeData(),
/// )
/// ```
@immutable
class KitoTheme extends ThemeExtension<KitoTheme> {
  /// Creates a theme; anything left out uses the Kito defaults.
  const KitoTheme({
    this.colors = KitoColors.light,
    this.spacing = const KitoSpacing(),
    this.radii = const KitoRadii(),
    this.typography = const KitoTypography(),
    this.motion = const KitoMotion(),
    this.brightness = Brightness.light,
  });

  /// Colour roles.
  final KitoColors colors;

  /// Spacing steps.
  final KitoSpacing spacing;

  /// Corner radii.
  final KitoRadii radii;

  /// Text styles.
  final KitoTypography typography;

  /// Durations and curves.
  final KitoMotion motion;

  /// Whether this is a light or dark theme.
  final Brightness brightness;

  /// Black primary on white.
  static const light = KitoTheme();

  /// White primary on near-black.
  static const dark =
      KitoTheme(colors: KitoColors.dark, brightness: Brightness.dark);

  /// Teal and violet on navy.
  static const neon =
      KitoTheme(colors: KitoColors.neon, brightness: Brightness.dark);

  /// The nearest installed theme, or the light/dark default for the platform brightness.
  static KitoTheme of(BuildContext context) {
    final installed = Theme.of(context).extension<KitoTheme>();
    if (installed != null) return installed;
    final brightness =
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
    return brightness == Brightness.dark ? dark : light;
  }

  /// A Material [ThemeData] built from this theme, with the extension installed, so plain
  /// Material widgets match the Kito ones.
  ThemeData toThemeData({ThemeData? base}) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.onSurface,
    );
    final start = base ?? ThemeData(useMaterial3: true, brightness: brightness);
    return start.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.border,
      extensions: [
        ...start.extensions.values.where((e) => e is! KitoTheme),
        this
      ],
    );
  }

  /// The primary colour, or [tint] when a widget was given one.
  Color accent(Color? tint) => tint ?? colors.primary;

  /// A colour that reads on [accent(tint)].
  Color onAccent(Color? tint) {
    if (tint == null) return colors.onPrimary;
    return ThemeData.estimateBrightnessForColor(tint) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  @override
  KitoTheme copyWith({
    KitoColors? colors,
    KitoSpacing? spacing,
    KitoRadii? radii,
    KitoTypography? typography,
    KitoMotion? motion,
    Brightness? brightness,
  }) =>
      KitoTheme(
        colors: colors ?? this.colors,
        spacing: spacing ?? this.spacing,
        radii: radii ?? this.radii,
        typography: typography ?? this.typography,
        motion: motion ?? this.motion,
        brightness: brightness ?? this.brightness,
      );

  @override
  KitoTheme lerp(covariant ThemeExtension<KitoTheme>? other, double t) {
    if (other is! KitoTheme) return this;
    return KitoTheme(
      colors: KitoColors.lerp(colors, other.colors, t),
      spacing: KitoSpacing.lerp(spacing, other.spacing, t),
      radii: KitoRadii.lerp(radii, other.radii, t),
      typography: KitoTypography.lerp(typography, other.typography, t),
      motion: t < 0.5 ? motion : other.motion,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// Shortcuts on [BuildContext].
extension KitoContext on BuildContext {
  /// `KitoTheme.of(this)`.
  KitoTheme get kito => KitoTheme.of(this);

  /// True in right-to-left layouts, for flipping drag maths and directional icons.
  bool get isRtl => Directionality.maybeOf(this) == TextDirection.rtl;

  /// True when the user asked for less motion.
  bool get reduceMotion => KitoMotion.reduced(this);
}
