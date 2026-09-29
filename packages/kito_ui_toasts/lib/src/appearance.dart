// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'toast.dart';

/// App-wide toast styling; pass it to [KitoToastHost]. Colours come from the Kito theme.
@immutable
class KitoToastAppearance {
  /// Creates an appearance; anything left out uses the Kito defaults.
  const KitoToastAppearance({
    this.radius = 16,
    this.showsAccentBar = true,
    this.iconSize = 18,
    this.maxTitleLines = 2,
    this.maxMessageLines = 3,
    this.maxWidth = 480,
    this.background,
    this.playsHaptics = true,
    this.titleStyle,
    this.messageStyle,
    this.edgeSpacing = 8,
  });

  /// Card corner radius.
  final double radius;

  /// The coloured bar at the start of card toasts.
  final bool showsAccentBar;

  /// Icon size in card toasts.
  final double iconSize;

  /// Title line limit.
  final int maxTitleLines;

  /// Message line limit.
  final int maxMessageLines;

  /// The widest a card, glass or pill toast grows (tablets, desktop). Null fills the width.
  final double? maxWidth;

  /// The default fill for card and pill toasts; the theme's surface when null.
  final KitoBackground? background;

  /// Plays a light, medium or heavy haptic when a success, warning or error toast appears or a
  /// loading toast completes.
  final bool playsHaptics;

  /// Overrides the title style (merged over the size from [KitoToastTitleStyle]).
  final TextStyle? titleStyle;

  /// Overrides the message style.
  final TextStyle? messageStyle;

  /// Gap between the safe area and the toast.
  final double edgeSpacing;

  /// The title style for a toast.
  TextStyle resolveTitle(KitoToast toast) {
    final base = switch (toast.titleStyle) {
      KitoToastTitleStyle.large =>
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      KitoToastTitleStyle.medium =>
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      KitoToastTitleStyle.small =>
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    };
    final merged = base.merge(titleStyle);
    return toast.isBold ? merged.copyWith(fontWeight: FontWeight.w800) : merged;
  }

  /// The message style for a toast.
  TextStyle resolveMessage(KitoToast toast) {
    final merged = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)
        .merge(messageStyle);
    return toast.isBold ? merged.copyWith(fontWeight: FontWeight.w700) : merged;
  }
}

/// The accent colour for [toast] under [theme]: its tint, or the style's theme colour.
Color kitoToastAccent(KitoTheme theme, KitoToast toast) =>
    toast.tint ??
    switch (toast.style) {
      KitoToastStyle.success => theme.colors.success,
      KitoToastStyle.error => theme.colors.danger,
      KitoToastStyle.warning => theme.colors.warning,
      KitoToastStyle.info => theme.colors.primary,
    };
