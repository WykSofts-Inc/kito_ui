// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Chart-specific presentation on top of `KitoTheme`: the series palette, gridline and label
/// colours, and how long entrances take.
///
/// Every chart reads [KitoChartTheme.of]. Install one for a whole app as a [ThemeExtension]
/// (`ThemeData(extensions: [KitoChartTheme(...)])`) or for a subtree with
/// [KitoChartThemeScope]. Anything left null follows the surrounding `KitoTheme`, so charts
/// look right in light, dark and neon without any setup.
@immutable
class KitoChartTheme extends ThemeExtension<KitoChartTheme> {
  /// Creates a chart theme.
  const KitoChartTheme({
    this.palette,
    this.gridlineColor,
    this.axisColor,
    this.labelColor,
    this.labelStyle,
    this.showGridlines = true,
    this.animationDuration = const Duration(milliseconds: 700),
  });

  /// Series and slice colours, in order. Wraps around, so nine series over six colours still
  /// render. Null uses [defaultPalette] (or [neonPalette] under the neon `KitoTheme`).
  final List<Color>? palette;

  /// Horizontal gridlines behind the plot.
  final Color? gridlineColor;

  /// Axis lines, scrub guides and unlabelled reference lines.
  final Color? axisColor;

  /// Axis labels and legend text.
  final Color? labelColor;

  /// The text style for axis labels, value labels and legends.
  final TextStyle? labelStyle;

  /// Whether value axes draw gridlines.
  final bool showGridlines;

  /// How long reveals and data changes take. Reduce Motion always skips them.
  final Duration animationDuration;

  /// Blue, orange, green, rose, violet, teal: distinct in light and dark and for most colour
  /// vision.
  static const defaultPalette = <Color>[
    Color(0xFF1C6BF0),
    Color(0xFFF58C29),
    Color(0xFF21A86B),
    Color(0xFFD13D6B),
    Color(0xFF8C5CF0),
    Color(0xFF21A8C7),
  ];

  /// Electric colours for dark, glowing designs.
  static const neonPalette = <Color>[
    Color(0xFF00E5D4),
    Color(0xFFA855F7),
    Color(0xFFFF5C9A),
    Color(0xFFFBBF24),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
  ];

  /// The chart theme for [context], with every colour filled in: the nearest
  /// [KitoChartThemeScope], else the [ThemeData] extension, else defaults derived from
  /// `KitoTheme`.
  static KitoChartTheme of(BuildContext context) {
    final kito = context.kito;
    final scoped = context
        .dependOnInheritedWidgetOfExactType<KitoChartThemeScope>()
        ?.theme;
    final base = scoped ?? Theme.of(context).extension<KitoChartTheme>();
    final onSurface = kito.colors.onSurface;
    final neon = kito.colors.primary == KitoColors.neon.primary;
    return KitoChartTheme(
      palette: base?.palette?.isNotEmpty == true
          ? base!.palette
          : (neon ? neonPalette : defaultPalette),
      gridlineColor: base?.gridlineColor ?? onSurface.withValues(alpha: 0.08),
      axisColor: base?.axisColor ?? onSurface.withValues(alpha: 0.32),
      labelColor: base?.labelColor ?? onSurface.withValues(alpha: 0.6),
      labelStyle: kito.typography.caption.copyWith(
          fontSize: 11,
          fontFeatures: const [
            FontFeature.tabularFigures()
          ]).merge(base?.labelStyle),
      showGridlines: base?.showGridlines ?? true,
      animationDuration:
          base?.animationDuration ?? const Duration(milliseconds: 700),
    );
  }

  /// The colour for the [index]th series or slice, wrapping around the palette.
  Color colorAt(int index) {
    final colors =
        palette == null || palette!.isEmpty ? defaultPalette : palette!;
    return colors[index % colors.length];
  }

  @override
  KitoChartTheme copyWith({
    List<Color>? palette,
    Color? gridlineColor,
    Color? axisColor,
    Color? labelColor,
    TextStyle? labelStyle,
    bool? showGridlines,
    Duration? animationDuration,
  }) =>
      KitoChartTheme(
        palette: palette ?? this.palette,
        gridlineColor: gridlineColor ?? this.gridlineColor,
        axisColor: axisColor ?? this.axisColor,
        labelColor: labelColor ?? this.labelColor,
        labelStyle: labelStyle ?? this.labelStyle,
        showGridlines: showGridlines ?? this.showGridlines,
        animationDuration: animationDuration ?? this.animationDuration,
      );

  @override
  KitoChartTheme lerp(
      covariant ThemeExtension<KitoChartTheme>? other, double t) {
    if (other is! KitoChartTheme) return this;
    List<Color>? palette;
    final a = this.palette, b = other.palette;
    if (a != null && b != null && a.length == b.length) {
      palette = [for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!];
    } else {
      palette = t < 0.5 ? a : b;
    }
    return KitoChartTheme(
      palette: palette,
      gridlineColor: Color.lerp(gridlineColor, other.gridlineColor, t),
      axisColor: Color.lerp(axisColor, other.axisColor, t),
      labelColor: Color.lerp(labelColor, other.labelColor, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      showGridlines: t < 0.5 ? showGridlines : other.showGridlines,
      animationDuration: t < 0.5 ? animationDuration : other.animationDuration,
    );
  }
}

/// Gives every chart below it a [KitoChartTheme], e.g. to retint one dashboard.
///
/// ```dart
/// KitoChartThemeScope(
///   theme: KitoChartTheme(palette: [Colors.teal, Colors.amber], showGridlines: false),
///   child: Dashboard(),
/// )
/// ```
class KitoChartThemeScope extends InheritedWidget {
  /// Creates a scope.
  const KitoChartThemeScope(
      {super.key, required this.theme, required super.child});

  /// The theme charts below use.
  final KitoChartTheme theme;

  @override
  bool updateShouldNotify(KitoChartThemeScope oldWidget) =>
      theme != oldWidget.theme;
}
