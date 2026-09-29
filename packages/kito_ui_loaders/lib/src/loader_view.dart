// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

import 'expressive.dart';
import 'indicators.dart';
import 'progress.dart';
import 'shimmer.dart';

/// Every loader [KitoLoaderView] can draw.
enum KitoLoaderKind {
  /// [KitoLoaderSpinner].
  spinner,

  /// [KitoLoaderGradientRing].
  gradientRing,

  /// [KitoLoaderDots].
  dots,

  /// [KitoLoaderPulse].
  pulse,

  /// [KitoLoaderBars].
  bars,

  /// [KitoLoaderWave].
  wave,

  /// [KitoLoaderRipple].
  ripple,

  /// [KitoLoaderOrbit].
  orbit,

  /// [KitoLoaderTypingIndicator] without its bubble.
  typing,

  /// [KitoLoaderHeartbeat].
  heartbeat,

  /// [KitoLoaderMorph].
  morph,

  /// [KitoLoaderProgressRing] at [KitoLoaderStyle.value].
  progressRing,

  /// A [KitoLoaderSkeleton] block.
  skeleton,
}

/// A loader as configuration — which kind, how big — so a screen can take a `loader:` parameter
/// and callers can swap every loader by changing one value.
@immutable
class KitoLoaderStyle {
  /// Creates a style.
  const KitoLoaderStyle({
    this.kind = KitoLoaderKind.spinner,
    this.size = 24,
    this.strokeWidth = 3,
    this.value = 0,
  });

  /// Which loader.
  final KitoLoaderKind kind;

  /// Its overall size.
  final double size;

  /// Line thickness, where the loader has lines.
  final double strokeWidth;

  /// The fraction for [KitoLoaderKind.progressRing].
  final double value;

  /// A spinner, 24 across.
  static const standard = KitoLoaderStyle();

  /// A copy with some fields replaced.
  KitoLoaderStyle copyWith(
          {KitoLoaderKind? kind,
          double? size,
          double? strokeWidth,
          double? value}) =>
      KitoLoaderStyle(
        kind: kind ?? this.kind,
        size: size ?? this.size,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        value: value ?? this.value,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoLoaderStyle &&
      other.kind == kind &&
      other.size == size &&
      other.strokeWidth == strokeWidth &&
      other.value == value;

  @override
  int get hashCode => Object.hash(kind, size, strokeWidth, value);
}

/// Draws whichever loader [style] names.
///
/// ```dart
/// KitoLoaderView(style: const KitoLoaderStyle(kind: KitoLoaderKind.orbit, size: 36))
/// ```
class KitoLoaderView extends StatelessWidget {
  /// Creates a loader view.
  const KitoLoaderView(
      {super.key, this.style = KitoLoaderStyle.standard, this.color});

  /// Which loader and how big.
  final KitoLoaderStyle style;

  /// Its colour; the theme's primary (danger for the heartbeat) when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = style.size;
    final w = style.strokeWidth;
    final c = color;
    return switch (style.kind) {
      KitoLoaderKind.spinner =>
        KitoLoaderSpinner(size: s, strokeWidth: w, color: c),
      KitoLoaderKind.gradientRing => KitoLoaderGradientRing(
          size: s,
          strokeWidth: w,
          colors: c == null ? null : [c.withValues(alpha: 0), c]),
      KitoLoaderKind.dots => KitoLoaderDots(dotSize: s / 3, color: c),
      KitoLoaderKind.pulse => KitoLoaderPulse(size: s, color: c),
      KitoLoaderKind.bars =>
        KitoLoaderBars(barWidth: s / 6, maxHeight: s, color: c),
      KitoLoaderKind.wave => KitoLoaderWave(dotSize: s / 3, color: c),
      KitoLoaderKind.ripple => KitoLoaderRipple(size: s, color: c),
      KitoLoaderKind.orbit => KitoLoaderOrbit(size: s, color: c),
      KitoLoaderKind.typing => KitoLoaderTypingIndicator(
          dotSize: s / 3, dotColor: c, showBubble: false),
      KitoLoaderKind.heartbeat => KitoLoaderHeartbeat(
          width: s * 4, height: s * 1.3, strokeWidth: w, color: c),
      KitoLoaderKind.morph => KitoLoaderMorph(
          size: s, colors: c == null ? null : [c, c.withValues(alpha: 0.6), c]),
      KitoLoaderKind.progressRing => KitoLoaderProgressRing(
          value: style.value, size: s, strokeWidth: w, color: c),
      KitoLoaderKind.skeleton => KitoLoaderSkeleton(width: s * 3, height: s),
    };
  }
}
