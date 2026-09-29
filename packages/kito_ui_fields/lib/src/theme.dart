// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

/// How a field is drawn.
enum KitoFieldStyle {
  /// A bordered box. The default.
  outlined,

  /// A soft fill with no border at rest; a border appears on focus or error.
  filled,

  /// A single line under the text.
  underlined,

  /// Material-style: the label sits inside while empty and lifts to the top edge when focused
  /// or filled.
  floatingLabel,

  /// No chrome; bring your own container.
  plain,
}

/// Field-wide design tokens. Colours come from the Kito theme; these set shape and behaviour.
/// Provide them to a subtree with [KitoFieldThemeScope].
@immutable
class KitoFieldTheme {
  /// Creates a field theme.
  const KitoFieldTheme({
    this.style = KitoFieldStyle.outlined,
    this.radius,
    this.minHeight = 52,
    this.contentPadding =
        const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 12),
    this.borderWidth = 1,
    this.focusedBorderWidth = 1.6,
    this.showsFocusGlow = true,
    this.shakesOnError = true,
    this.showsErrorIcon = true,
    this.showsSuccess = false,
    this.disabledOpacity = 0.5,
  });

  /// How fields are drawn.
  final KitoFieldStyle style;

  /// Corner radius; the Kito theme's medium radius when null.
  final double? radius;

  /// The row's minimum height (never below 44 for touch).
  final double minHeight;

  /// Padding inside the row.
  final EdgeInsetsGeometry contentPadding;

  /// Border width at rest.
  final double borderWidth;

  /// Border width while focused or showing an error.
  final double focusedBorderWidth;

  /// A soft halo in the accent colour while focused.
  final bool showsFocusGlow;

  /// A quick shake when an error appears.
  final bool shakesOnError;

  /// An icon before error messages.
  final bool showsErrorIcon;

  /// A green border and tick when the value passes every rule.
  final bool showsSuccess;

  /// Opacity when disabled.
  final double disabledOpacity;

  /// A copy with some tokens replaced.
  KitoFieldTheme copyWith({
    KitoFieldStyle? style,
    double? radius,
    double? minHeight,
    EdgeInsetsGeometry? contentPadding,
    double? borderWidth,
    double? focusedBorderWidth,
    bool? showsFocusGlow,
    bool? shakesOnError,
    bool? showsErrorIcon,
    bool? showsSuccess,
    double? disabledOpacity,
  }) =>
      KitoFieldTheme(
        style: style ?? this.style,
        radius: radius ?? this.radius,
        minHeight: minHeight ?? this.minHeight,
        contentPadding: contentPadding ?? this.contentPadding,
        borderWidth: borderWidth ?? this.borderWidth,
        focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
        showsFocusGlow: showsFocusGlow ?? this.showsFocusGlow,
        shakesOnError: shakesOnError ?? this.shakesOnError,
        showsErrorIcon: showsErrorIcon ?? this.showsErrorIcon,
        showsSuccess: showsSuccess ?? this.showsSuccess,
        disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      );

  /// The nearest scope's theme, or the defaults.
  static KitoFieldTheme of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KitoFieldThemeScope>()
          ?.theme ??
      const KitoFieldTheme();

  @override
  bool operator ==(Object other) =>
      other is KitoFieldTheme &&
      other.style == style &&
      other.radius == radius &&
      other.minHeight == minHeight &&
      other.contentPadding == contentPadding &&
      other.borderWidth == borderWidth &&
      other.focusedBorderWidth == focusedBorderWidth &&
      other.showsFocusGlow == showsFocusGlow &&
      other.shakesOnError == shakesOnError &&
      other.showsErrorIcon == showsErrorIcon &&
      other.showsSuccess == showsSuccess &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hash(
      style,
      radius,
      minHeight,
      contentPadding,
      borderWidth,
      focusedBorderWidth,
      showsFocusGlow,
      shakesOnError,
      showsErrorIcon,
      showsSuccess,
      disabledOpacity);
}

/// Sets the [KitoFieldTheme] for every Kito field below it.
///
/// ```dart
/// KitoFieldThemeScope(
///   theme: const KitoFieldTheme(style: KitoFieldStyle.floatingLabel),
///   child: SignUpForm(),
/// )
/// ```
class KitoFieldThemeScope extends InheritedWidget {
  /// Provides [theme] to [child].
  const KitoFieldThemeScope(
      {super.key, required this.theme, required super.child});

  /// The theme.
  final KitoFieldTheme theme;

  @override
  bool updateShouldNotify(KitoFieldThemeScope old) => old.theme != theme;
}
