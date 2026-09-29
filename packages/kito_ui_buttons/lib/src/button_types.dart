// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

/// The visual weight of a [KitoButton].
enum KitoButtonVariant {
  /// Solid brand fill. The main call to action.
  primary,

  /// A soft, tinted fill.
  tonal,

  /// Border only.
  outlined,

  /// Text only; a tinted background appears while pressed.
  ghost,

  /// Solid destructive fill.
  destructive,

  /// Looks like an inline link.
  link,
}

/// The lifecycle of a [KitoButton] action: idle → loading → success or failure → idle.
enum KitoButtonPhase {
  /// Waiting for a tap.
  idle,

  /// Running an action; the button shows a spinner and ignores taps.
  loading,

  /// The action finished; the icon morphs to a tick.
  success,

  /// The action threw; the button shakes and shows a cross.
  failure;

  /// True while an action is running.
  bool get isBusy => this == loading;
}

/// Where a [KitoButton]'s icon sits relative to its label. Directional, so it mirrors in RTL.
enum KitoButtonIconPlacement {
  /// Before the label (left in LTR, right in RTL).
  leading,

  /// After the label.
  trailing,
}

/// How a [KitoButton]'s content lays out horizontally. Only [spaceBetween] changes anything on
/// its own; the others matter once the button is wider than its content (e.g. `expand: true`).
enum KitoButtonContentAlignment {
  /// Content hugs the start edge.
  start,

  /// Content is centred. The default.
  center,

  /// Content hugs the end edge.
  end,

  /// The label sits at the start edge and the trailing slot at the end edge.
  spaceBetween,
}

/// How a button reacts to being pressed.
enum KitoButtonPressedStyle {
  /// Scales down, darkens its fill and dims slightly. The default.
  scale,

  /// Darkens its fill only, with no scale or opacity change.
  darken,

  /// No press feedback at all.
  none,
}

/// How a button looks while disabled.
@immutable
sealed class KitoButtonDisabledStyle {
  const KitoButtonDisabledStyle();

  /// The variant's normal colours at the theme's disabled opacity. The default.
  static const KitoButtonDisabledStyle faded = _FadedDisabledStyle();

  /// Border only, at full opacity, in a muted colour.
  static const KitoButtonDisabledStyle outlined = _OutlinedDisabledStyle();

  /// A flat fill regardless of variant, at full opacity (a grey button instead of a dimmed one).
  const factory KitoButtonDisabledStyle.filled(
      {required Color background,
      required Color foreground}) = KitoButtonFilledDisabledStyle;
}

final class _FadedDisabledStyle extends KitoButtonDisabledStyle {
  const _FadedDisabledStyle();
}

final class _OutlinedDisabledStyle extends KitoButtonDisabledStyle {
  const _OutlinedDisabledStyle();
}

/// A disabled look with its own fill; create it with [KitoButtonDisabledStyle.filled].
final class KitoButtonFilledDisabledStyle extends KitoButtonDisabledStyle {
  /// Creates a filled disabled style.
  const KitoButtonFilledDisabledStyle(
      {required this.background, required this.foreground});

  /// The fill while disabled.
  final Color background;

  /// The label and icon colour while disabled.
  final Color foreground;

  @override
  bool operator ==(Object other) =>
      other is KitoButtonFilledDisabledStyle &&
      other.background == background &&
      other.foreground == foreground;

  @override
  int get hashCode => Object.hash(background, foreground);
}

/// The outline used for a button's background and border.
@immutable
sealed class KitoButtonShape {
  const KitoButtonShape();

  /// Fully rounded ends. The default.
  static const KitoButtonShape capsule = _CapsuleShape();

  /// Square corners.
  static const KitoButtonShape rectangle = _RoundedShape(0);

  /// 12-point corners.
  static const KitoButtonShape rounded = _RoundedShape(12);

  /// Corners of [radius] logical pixels.
  const factory KitoButtonShape.roundedRectangle(double radius) = _RoundedShape;

  /// The border radius for a button [height] pixels tall.
  BorderRadius radiusFor(double height);

  /// The corner radius as a plain number, for a button [height] pixels tall.
  double cornerFor(double height) => radiusFor(height).topLeft.x;
}

final class _CapsuleShape extends KitoButtonShape {
  const _CapsuleShape();

  @override
  BorderRadius radiusFor(double height) => BorderRadius.circular(height / 2);
}

final class _RoundedShape extends KitoButtonShape {
  const _RoundedShape(this.radius);
  final double radius;

  @override
  BorderRadius radiusFor(double height) =>
      BorderRadius.circular(radius.clamp(0, height / 2));

  @override
  bool operator ==(Object other) =>
      other is _RoundedShape && other.radius == radius;

  @override
  int get hashCode => radius.hashCode;
}

/// Height, padding, icon size and title style for a button.
@immutable
class KitoButtonSize {
  /// Your own metrics.
  const KitoButtonSize.custom({
    required this.height,
    this.horizontalPadding = 20,
    this.iconSize = 17,
    this.textStyle =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
  }) : _name = 'custom';

  const KitoButtonSize._(this._name, this.height, this.horizontalPadding,
      this.iconSize, this.textStyle);

  /// 36 tall. Gets an automatic 44×44 tap target.
  static const small = KitoButtonSize._('small', 36, 14, 14,
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2));

  /// 48 tall. The default.
  static const medium = KitoButtonSize._('medium', 48, 20, 17,
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2));

  /// 56 tall.
  static const large = KitoButtonSize._('large', 56, 24, 20,
      TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.2));

  final String _name;

  /// The minimum height; grows with large text.
  final double height;

  /// Space either side of the content.
  final double horizontalPadding;

  /// Icon size.
  final double iconSize;

  /// The title's size and weight. Colour is set by the variant.
  final TextStyle textStyle;

  /// True for [small], which draws under the 44-point minimum tap target.
  bool get isCompact => height < 44;

  @override
  bool operator ==(Object other) =>
      other is KitoButtonSize &&
      other._name == _name &&
      other.height == height &&
      other.horizontalPadding == horizontalPadding &&
      other.iconSize == iconSize &&
      other.textStyle == textStyle;

  @override
  int get hashCode =>
      Object.hash(_name, height, horizontalPadding, iconSize, textStyle);

  @override
  String toString() => 'KitoButtonSize.$_name';
}

/// Colours resolved for one variant in one state.
@immutable
class KitoButtonColors {
  /// Creates a colour set; [pressedBackground] defaults to [background] at 85%.
  KitoButtonColors({
    required this.background,
    required this.foreground,
    this.border = const Color(0x00000000),
    Color? pressedBackground,
  }) : pressedBackground = pressedBackground ??
            background.withValues(alpha: background.a * 0.85);

  /// The fill.
  final Color background;

  /// Label and icon colour.
  final Color foreground;

  /// The outline; transparent for none.
  final Color border;

  /// The fill while pressed.
  final Color pressedBackground;

  /// True when there is an outline to draw.
  bool get hasBorder => border.a > 0;

  /// Blends two colour sets, for animated state changes.
  static KitoButtonColors lerp(
          KitoButtonColors a, KitoButtonColors b, double t) =>
      KitoButtonColors(
        background: Color.lerp(a.background, b.background, t)!,
        foreground: Color.lerp(a.foreground, b.foreground, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        pressedBackground:
            Color.lerp(a.pressedBackground, b.pressedBackground, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoButtonColors &&
      other.background == background &&
      other.foreground == foreground &&
      other.border == border &&
      other.pressedBackground == pressedBackground;

  @override
  int get hashCode =>
      Object.hash(background, foreground, border, pressedBackground);

  @override
  String toString() =>
      'KitoButtonColors(background: $background, foreground: $foreground, border: $border)';
}
