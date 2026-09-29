// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// A bar with a smooth dip cut into its top edge, as drawn behind the bubble and notched tab
/// bars. Use it with a `ShapeDecoration` to put the dip anywhere.
///
/// [notchCenter] runs 0–1 from the start edge (so it mirrors in right-to-left layouts) across
/// the width minus [horizontalInset] on each side. It lerps, so the dip can glide.
@immutable
class KitoTabBarShape extends ShapeBorder {
  /// Creates the shape.
  const KitoTabBarShape({
    required this.notchCenter,
    this.horizontalInset = 0,
    this.notchRadius = 36,
    this.notchDepth = 34,
  });

  /// Where the dip sits, 0 (start) to 1 (end).
  final double notchCenter;

  /// Room at each side the dip's centre never enters.
  final double horizontalInset;

  /// Half the dip's width at the top, before its shoulders.
  final double notchRadius;

  /// How deep the dip goes.
  final double notchDepth;

  /// The rounded shoulders either side of the dip.
  static const double shoulder = 18;

  /// The dip's centre, in [rect]'s coordinates, for [textDirection].
  double notchX(Rect rect, [TextDirection textDirection = TextDirection.ltr]) {
    final t = notchCenter.clamp(0.0, 1.0);
    final fromStart = horizontalInset + t * (rect.width - horizontalInset * 2);
    return textDirection == TextDirection.rtl
        ? rect.right - fromStart
        : rect.left + fromStart;
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final x = notchX(rect, textDirection ?? TextDirection.ltr);
    final r = notchRadius;
    final top = rect.top;
    return Path()
      ..moveTo(rect.left, top)
      ..lineTo(x - r - shoulder, top)
      ..cubicTo(
          x - r + 4, top, x - r + 2, top + notchDepth, x, top + notchDepth)
      ..cubicTo(
          x + r - 2, top + notchDepth, x + r - 4, top, x + r + shoulder, top)
      ..lineTo(rect.right, top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => KitoTabBarShape(
        notchCenter: notchCenter,
        horizontalInset: horizontalInset * t,
        notchRadius: notchRadius * t,
        notchDepth: notchDepth * t,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is KitoTabBarShape) return KitoTabBarShape.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is KitoTabBarShape) return KitoTabBarShape.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  /// Blends two shapes, gliding the dip.
  static KitoTabBarShape lerp(KitoTabBarShape a, KitoTabBarShape b, double t) =>
      KitoTabBarShape(
        notchCenter: lerpDouble(a.notchCenter, b.notchCenter, t)!,
        horizontalInset: lerpDouble(a.horizontalInset, b.horizontalInset, t)!,
        notchRadius: lerpDouble(a.notchRadius, b.notchRadius, t)!,
        notchDepth: lerpDouble(a.notchDepth, b.notchDepth, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoTabBarShape &&
      other.notchCenter == notchCenter &&
      other.horizontalInset == horizontalInset &&
      other.notchRadius == notchRadius &&
      other.notchDepth == notchDepth;

  @override
  int get hashCode =>
      Object.hash(notchCenter, horizontalInset, notchRadius, notchDepth);
}
