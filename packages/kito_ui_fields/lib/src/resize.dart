// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

/// [AnimatedSize] that steps aside when there's nothing to animate: with Reduce Motion the
/// duration is zero, and a zero-length AnimatedSize trips a layout assertion.
class FieldResize extends StatelessWidget {
  /// Animates [child]'s size changes over [duration].
  const FieldResize({
    super.key,
    required this.duration,
    required this.child,
    this.curve = Curves.linear,
    this.alignment = Alignment.center,
  });

  /// How long a resize takes.
  final Duration duration;

  /// The easing.
  final Curve curve;

  /// Where the child sits while resizing.
  final AlignmentGeometry alignment;

  /// What resizes.
  final Widget child;

  @override
  Widget build(BuildContext context) => duration == Duration.zero
      ? child
      : AnimatedSize(
          duration: duration, curve: curve, alignment: alignment, child: child);
}
