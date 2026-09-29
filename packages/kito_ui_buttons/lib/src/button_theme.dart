// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'button_motion.dart';
import 'button_types.dart';

/// Tokens for every Kito button. Colours left null follow [KitoTheme] (primary, danger, success…),
/// so buttons match the rest of the app out of the box.
///
/// Install it app-wide as a [ThemeExtension], or for one subtree with [KitoButtonThemeScope]:
///
/// ```dart
/// MaterialApp(
///   theme: KitoTheme.light.toThemeData().copyWith(extensions: [
///     KitoTheme.light,
///     const KitoButtonTheme(shape: KitoButtonShape.rounded),
///   ]),
/// )
/// ```
@immutable
class KitoButtonTheme extends ThemeExtension<KitoButtonTheme> {
  /// Creates a button theme.
  const KitoButtonTheme({
    this.tint,
    this.onTint,
    this.destructive,
    this.onDestructive,
    this.tonalBackground,
    this.successColor,
    this.failureColor,
    this.loadingBackground,
    this.loadingForeground,
    this.shape = KitoButtonShape.capsule,
    this.borderWidth = 1.5,
    this.pressedScale = 0.97,
    this.pressedOpacity = 0.9,
    this.disabledOpacity = 0.45,
    this.disabledStyle = KitoButtonDisabledStyle.faded,
    this.pressedStyle = KitoButtonPressedStyle.scale,
    this.shadow,
    this.iconSpacing = 8,
    this.underlinesLink = true,
    this.textStyle,
    this.motion = KitoButtonMotion.standard,
    this.overrides = const {},
  });

  /// The brand colour for primary, tonal, outlined, ghost and link; the theme's primary when null.
  final Color? tint;

  /// Text on the primary fill; the theme's onPrimary when null.
  final Color? onTint;

  /// The destructive fill; the theme's danger colour when null.
  final Color? destructive;

  /// Text on the destructive fill; white when null.
  final Color? onDestructive;

  /// The tonal fill; [tint] at 14% when null.
  final Color? tonalBackground;

  /// The success phase colour; the theme's success colour when null.
  final Color? successColor;

  /// The failure phase colour; the theme's danger colour when null.
  final Color? failureColor;

  /// The fill while loading; the variant's own fill when null.
  final Color? loadingBackground;

  /// The spinner colour; the variant's foreground when null.
  final Color? loadingForeground;

  /// The outline every button draws.
  final KitoButtonShape shape;

  /// Outline width for outlined buttons.
  final double borderWidth;

  /// How far a button shrinks while pressed.
  final double pressedScale;

  /// Opacity while pressed (scale style only).
  final double pressedOpacity;

  /// Opacity while disabled (faded style only).
  final double disabledOpacity;

  /// How disabled buttons look.
  final KitoButtonDisabledStyle disabledStyle;

  /// How buttons react to presses.
  final KitoButtonPressedStyle pressedStyle;

  /// A drop shadow under filled buttons; none when null.
  final List<BoxShadow>? shadow;

  /// Space between icon and label.
  final double iconSpacing;

  /// Underline the link variant's label.
  final bool underlinesLink;

  /// Merged over each size's title style — set a `fontFamily` here to brand every button.
  final TextStyle? textStyle;

  /// Timings. Swapped for [KitoButtonMotion.subtle] under Reduce Motion.
  final KitoButtonMotion motion;

  /// Replace the colours of any variant outright.
  final Map<KitoButtonVariant, KitoButtonColors> overrides;

  /// The defaults.
  static const standard = KitoButtonTheme();

  /// The nearest [KitoButtonThemeScope], else the one installed in [ThemeData], else [standard].
  static KitoButtonTheme of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KitoButtonThemeScope>()
          ?.theme ??
      Theme.of(context).extension<KitoButtonTheme>() ??
      standard;

  /// The timings to use, given the user's Reduce Motion setting.
  KitoButtonMotion motionFor(BuildContext context) =>
      context.reduceMotion ? KitoButtonMotion.subtle : motion;

  /// Fills in every null colour from [kito].
  KitoButtonPalette resolve(KitoTheme kito) {
    final t = tint ?? kito.colors.primary;
    return KitoButtonPalette(
      tint: t,
      onTint: onTint ??
          (tint == null ? kito.colors.onPrimary : kito.onAccent(tint)),
      destructive: destructive ?? kito.colors.danger,
      onDestructive: onDestructive ?? Colors.white,
      tonalBackground: tonalBackground ?? t.withValues(alpha: 0.14),
      success: successColor ?? kito.colors.success,
      failure: failureColor ?? kito.colors.danger,
      muted: kito.colors.onSurface.withValues(alpha: 0.5),
    );
  }

  /// The resting colours of [variant], with an optional per-button [tintOverride].
  KitoButtonColors colorsFor(KitoButtonVariant variant, KitoTheme kito,
      {Color? tintOverride}) {
    final custom = overrides[variant];
    if (custom != null) return custom;
    final p = resolve(kito);
    final t = tintOverride ?? p.tint;
    final onT = tintOverride == null ? p.onTint : kito.onAccent(tintOverride);
    const clear = Color(0x00000000);
    switch (variant) {
      case KitoButtonVariant.primary:
        return KitoButtonColors(
            background: t,
            foreground: onT,
            pressedBackground: Color.alphaBlend(
                (onT.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                    .withValues(alpha: 0.14),
                t));
      case KitoButtonVariant.tonal:
        return KitoButtonColors(
            background: tintOverride == null
                ? p.tonalBackground
                : t.withValues(alpha: 0.14),
            foreground: t,
            pressedBackground: t.withValues(alpha: 0.24));
      case KitoButtonVariant.outlined:
        return KitoButtonColors(
            background: clear,
            foreground: t,
            border: t,
            pressedBackground: t.withValues(alpha: 0.1));
      case KitoButtonVariant.ghost:
        return KitoButtonColors(
            background: clear,
            foreground: t,
            pressedBackground: t.withValues(alpha: 0.1));
      case KitoButtonVariant.destructive:
        final d = tintOverride ?? p.destructive;
        return KitoButtonColors(
            background: d,
            foreground: tintOverride == null
                ? p.onDestructive
                : kito.onAccent(tintOverride),
            pressedBackground:
                Color.alphaBlend(Colors.black.withValues(alpha: 0.14), d));
      case KitoButtonVariant.link:
        return KitoButtonColors(
            background: clear, foreground: t, pressedBackground: clear);
    }
  }

  /// The colours for [variant] in a given state: disabled, loading, success or failure.
  KitoButtonColors colorsForState(
    KitoButtonVariant variant,
    KitoTheme kito, {
    required bool enabled,
    required KitoButtonPhase phase,
    KitoButtonDisabledStyle? disabledStyle,
    Color? tintOverride,
  }) {
    final base = colorsFor(variant, kito, tintOverride: tintOverride);
    final p = resolve(kito);
    const clear = Color(0x00000000);
    if (!enabled && phase == KitoButtonPhase.idle) {
      final style = disabledStyle ?? this.disabledStyle;
      if (style is KitoButtonFilledDisabledStyle) {
        return KitoButtonColors(
            background: style.background,
            foreground: style.foreground,
            pressedBackground: style.background);
      }
      if (style == KitoButtonDisabledStyle.outlined) {
        // Muted text, not base.foreground: on a filled variant that is the on-tint colour,
        // which would vanish against the now clear background.
        return KitoButtonColors(
            background: clear,
            foreground: p.muted,
            border: p.muted.withValues(alpha: 0.35),
            pressedBackground: clear);
      }
      return base;
    }
    if (phase == KitoButtonPhase.loading &&
        (loadingBackground != null || loadingForeground != null)) {
      final bg = loadingBackground ?? base.background;
      return KitoButtonColors(
          background: bg,
          foreground: loadingForeground ?? base.foreground,
          border: base.hasBorder ? (loadingBackground ?? base.border) : clear,
          pressedBackground: bg);
    }
    final Color accent;
    switch (phase) {
      case KitoButtonPhase.success:
        accent = p.success;
      case KitoButtonPhase.failure:
        accent = p.failure;
      case KitoButtonPhase.idle:
      case KitoButtonPhase.loading:
        return base;
    }
    switch (variant) {
      case KitoButtonVariant.primary:
      case KitoButtonVariant.destructive:
        return KitoButtonColors(
            background: accent,
            foreground: kito.onAccent(accent),
            pressedBackground: accent.withValues(alpha: 0.8));
      case KitoButtonVariant.tonal:
        return KitoButtonColors(
            background: accent.withValues(alpha: 0.14),
            foreground: accent,
            pressedBackground: accent.withValues(alpha: 0.24));
      case KitoButtonVariant.outlined:
        return KitoButtonColors(
            background: clear,
            foreground: accent,
            border: accent,
            pressedBackground: accent.withValues(alpha: 0.1));
      case KitoButtonVariant.ghost:
      case KitoButtonVariant.link:
        return KitoButtonColors(
            background: clear,
            foreground: accent,
            pressedBackground: accent.withValues(alpha: 0.1));
    }
  }

  /// The opacity for a state: faded when disabled, slightly dimmed while pressed.
  double opacityFor({
    required bool enabled,
    required KitoButtonPhase phase,
    required bool pressed,
    KitoButtonDisabledStyle? disabledStyle,
    KitoButtonPressedStyle? pressedStyle,
  }) {
    if (!enabled &&
        phase == KitoButtonPhase.idle &&
        (disabledStyle ?? this.disabledStyle) ==
            KitoButtonDisabledStyle.faded) {
      return disabledOpacity;
    }
    if (pressed &&
        (pressedStyle ?? this.pressedStyle) == KitoButtonPressedStyle.scale) {
      return pressedOpacity;
    }
    return 1;
  }

  /// The title style for [size], with [textStyle] merged on top.
  TextStyle textStyleFor(KitoButtonSize size) =>
      textStyle == null ? size.textStyle : size.textStyle.merge(textStyle);

  @override
  KitoButtonTheme copyWith({
    Color? tint,
    Color? onTint,
    Color? destructive,
    Color? onDestructive,
    Color? tonalBackground,
    Color? successColor,
    Color? failureColor,
    Color? loadingBackground,
    Color? loadingForeground,
    KitoButtonShape? shape,
    double? borderWidth,
    double? pressedScale,
    double? pressedOpacity,
    double? disabledOpacity,
    KitoButtonDisabledStyle? disabledStyle,
    KitoButtonPressedStyle? pressedStyle,
    List<BoxShadow>? shadow,
    double? iconSpacing,
    bool? underlinesLink,
    TextStyle? textStyle,
    KitoButtonMotion? motion,
    Map<KitoButtonVariant, KitoButtonColors>? overrides,
  }) =>
      KitoButtonTheme(
        tint: tint ?? this.tint,
        onTint: onTint ?? this.onTint,
        destructive: destructive ?? this.destructive,
        onDestructive: onDestructive ?? this.onDestructive,
        tonalBackground: tonalBackground ?? this.tonalBackground,
        successColor: successColor ?? this.successColor,
        failureColor: failureColor ?? this.failureColor,
        loadingBackground: loadingBackground ?? this.loadingBackground,
        loadingForeground: loadingForeground ?? this.loadingForeground,
        shape: shape ?? this.shape,
        borderWidth: borderWidth ?? this.borderWidth,
        pressedScale: pressedScale ?? this.pressedScale,
        pressedOpacity: pressedOpacity ?? this.pressedOpacity,
        disabledOpacity: disabledOpacity ?? this.disabledOpacity,
        disabledStyle: disabledStyle ?? this.disabledStyle,
        pressedStyle: pressedStyle ?? this.pressedStyle,
        shadow: shadow ?? this.shadow,
        iconSpacing: iconSpacing ?? this.iconSpacing,
        underlinesLink: underlinesLink ?? this.underlinesLink,
        textStyle: textStyle ?? this.textStyle,
        motion: motion ?? this.motion,
        overrides: overrides ?? this.overrides,
      );

  @override
  KitoButtonTheme lerp(
      covariant ThemeExtension<KitoButtonTheme>? other, double t) {
    if (other is! KitoButtonTheme) return this;
    final near = t < 0.5 ? this : other;
    return near.copyWith(
      tint: Color.lerp(tint, other.tint, t),
      onTint: Color.lerp(onTint, other.onTint, t),
      destructive: Color.lerp(destructive, other.destructive, t),
      successColor: Color.lerp(successColor, other.successColor, t),
      failureColor: Color.lerp(failureColor, other.failureColor, t),
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
    );
  }
}

/// A [KitoButtonTheme] with every colour filled in.
@immutable
class KitoButtonPalette {
  /// Creates a palette.
  const KitoButtonPalette({
    required this.tint,
    required this.onTint,
    required this.destructive,
    required this.onDestructive,
    required this.tonalBackground,
    required this.success,
    required this.failure,
    required this.muted,
  });

  /// Brand colour.
  final Color tint;

  /// Text on [tint].
  final Color onTint;

  /// Destructive fill.
  final Color destructive;

  /// Text on [destructive].
  final Color onDestructive;

  /// Tonal fill.
  final Color tonalBackground;

  /// Success phase.
  final Color success;

  /// Failure phase.
  final Color failure;

  /// Quiet text, for the outlined disabled style.
  final Color muted;
}

/// Overrides the [KitoButtonTheme] for everything below it.
///
/// ```dart
/// KitoButtonThemeScope(
///   theme: KitoButtonTheme.of(context).copyWith(shape: KitoButtonShape.rectangle),
///   child: checkoutForm,
/// )
/// ```
class KitoButtonThemeScope extends InheritedWidget {
  /// Creates a scope.
  const KitoButtonThemeScope(
      {super.key, required this.theme, required super.child});

  /// The theme for this subtree.
  final KitoButtonTheme theme;

  @override
  bool updateShouldNotify(KitoButtonThemeScope oldWidget) =>
      theme != oldWidget.theme;
}
