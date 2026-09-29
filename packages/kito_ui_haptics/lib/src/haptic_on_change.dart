// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

import 'haptic_pattern.dart';
import 'haptics.dart';

/// Plays a haptic whenever [value] changes — for derived state (a validation error
/// appearing, an order flipping to delivered) rather than a tap.
///
/// ```dart
/// KitoHapticOnChange(
///   value: order.isDelivered,
///   pattern: KitoHapticPattern.successChime,
///   child: OrderStatus(order),
/// )
///
/// KitoHapticOnChange(value: form.hasError, haptic: KitoHaptics.error, child: form)
/// ```
///
/// With neither [pattern] nor [haptic] it plays a selection tick.
class KitoHapticOnChange<T> extends StatefulWidget {
  /// Creates a trigger.
  const KitoHapticOnChange({
    super.key,
    required this.value,
    required this.child,
    this.pattern,
    this.haptic,
    this.when,
  });

  /// Watched for changes.
  final T value;

  /// Rendered unchanged.
  final Widget child;

  /// A pattern to play on change.
  final KitoHapticPattern? pattern;

  /// A haptic to fire on change, e.g. `KitoHaptics.error`.
  final Future<void> Function()? haptic;

  /// Only fire when this returns true for (old, new) — e.g. only when an error appears.
  final bool Function(T previous, T current)? when;

  @override
  State<KitoHapticOnChange<T>> createState() => _KitoHapticOnChangeState<T>();
}

class _KitoHapticOnChangeState<T> extends State<KitoHapticOnChange<T>> {
  @override
  void didUpdateWidget(KitoHapticOnChange<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    if (widget.when != null && !widget.when!(oldWidget.value, widget.value)) {
      return;
    }
    if (widget.pattern != null) {
      KitoHaptics.play(widget.pattern!);
    } else if (widget.haptic != null) {
      widget.haptic!();
    } else {
      KitoHaptics.selection();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
