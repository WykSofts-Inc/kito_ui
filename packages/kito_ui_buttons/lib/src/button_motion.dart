// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Every timing KitoButtons uses, so all buttons in an app move the same way.
@immutable
class KitoButtonMotion {
  /// Creates a motion set; anything left out uses the default timings.
  const KitoButtonMotion({
    this.pressDuration = const Duration(milliseconds: 120),
    this.releaseDuration = const Duration(milliseconds: 320),
    this.pressCurve = const KitoSpringCurve(damping: 0.6, stiffness: 12),
    this.morphDuration = const Duration(milliseconds: 380),
    this.morphCurve = const KitoSpringCurve(damping: 0.72, stiffness: 11),
    this.flightDuration = const Duration(milliseconds: 700),
    this.flightCurve = const Cubic(0.25, 0.1, 0.25, 1),
    this.bounceDuration = const Duration(milliseconds: 420),
    this.shakeDuration = const Duration(milliseconds: 400),
    this.resultDuration = const Duration(milliseconds: 1200),
  });

  /// How fast a button sinks when pressed.
  final Duration pressDuration;

  /// How long it takes to spring back.
  final Duration releaseDuration;

  /// The spring used when released.
  final Curve pressCurve;

  /// Idle → loading → success/failure morphs.
  final Duration morphDuration;

  /// The curve for morphs.
  final Curve morphCurve;

  /// How long an item takes to fly to its target.
  final Duration flightDuration;

  /// The curve along the flight arc.
  final Curve flightCurve;

  /// A badge's pop when something lands on it.
  final Duration bounceDuration;

  /// The failure shake.
  final Duration shakeDuration;

  /// How long a success or failure result stays before returning to idle.
  final Duration resultDuration;

  /// The default timings.
  static const standard = KitoButtonMotion();

  /// Snappier, more playful timings.
  static const lively = KitoButtonMotion(
    pressDuration: Duration(milliseconds: 90),
    releaseDuration: Duration(milliseconds: 260),
    pressCurve: KitoSpringCurve(damping: 0.5, stiffness: 14),
    morphDuration: Duration(milliseconds: 320),
    morphCurve: KitoSpringCurve(damping: 0.55, stiffness: 12),
    bounceDuration: Duration(milliseconds: 360),
  );

  /// Calm, short, overshoot-free timings. Used automatically under Reduce Motion.
  static const subtle = KitoButtonMotion(
    pressDuration: Duration(milliseconds: 120),
    releaseDuration: Duration(milliseconds: 120),
    pressCurve: Curves.easeOut,
    morphDuration: Duration(milliseconds: 200),
    morphCurve: Curves.easeInOut,
    flightDuration: Duration(milliseconds: 400),
    flightCurve: Curves.easeInOut,
    bounceDuration: Duration(milliseconds: 200),
  );

  /// A copy with some timings replaced.
  KitoButtonMotion copyWith({
    Duration? pressDuration,
    Duration? releaseDuration,
    Curve? pressCurve,
    Duration? morphDuration,
    Curve? morphCurve,
    Duration? flightDuration,
    Curve? flightCurve,
    Duration? bounceDuration,
    Duration? shakeDuration,
    Duration? resultDuration,
  }) =>
      KitoButtonMotion(
        pressDuration: pressDuration ?? this.pressDuration,
        releaseDuration: releaseDuration ?? this.releaseDuration,
        pressCurve: pressCurve ?? this.pressCurve,
        morphDuration: morphDuration ?? this.morphDuration,
        morphCurve: morphCurve ?? this.morphCurve,
        flightDuration: flightDuration ?? this.flightDuration,
        flightCurve: flightCurve ?? this.flightCurve,
        bounceDuration: bounceDuration ?? this.bounceDuration,
        shakeDuration: shakeDuration ?? this.shakeDuration,
        resultDuration: resultDuration ?? this.resultDuration,
      );
}

/// Shakes [child] side to side each time [trigger] changes. Still under Reduce Motion.
///
/// ```dart
/// KitoButtonShake(trigger: failures, child: pinField)
/// ```
class KitoButtonShake extends StatefulWidget {
  /// Creates a shake.
  const KitoButtonShake({
    super.key,
    required this.trigger,
    required this.child,
    this.amplitude = 8,
    this.duration = const Duration(milliseconds: 400),
  });

  /// Change this (e.g. increment a counter) to shake.
  final Object? trigger;

  /// What shakes.
  final Widget child;

  /// The furthest the child moves, in logical pixels.
  final double amplitude;

  /// How long one shake lasts.
  final Duration duration;

  /// The horizontal offset [t] (0–1) of the way through a shake.
  static double offsetAt(double t, double amplitude) =>
      amplitude * math.sin(t * math.pi * 4) * (1 - t * 0.35);

  @override
  State<KitoButtonShake> createState() => _KitoButtonShakeState();
}

class _KitoButtonShakeState extends State<KitoButtonShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(KitoButtonShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.trigger != widget.trigger && !context.reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(
              _controller.isAnimating
                  ? KitoButtonShake.offsetAt(
                      _controller.value, widget.amplitude)
                  : 0,
              0),
          child: child,
        ),
      );
}

/// Pops [child] (scale up, then spring back) each time [trigger] changes — the cart badge bounce.
/// Still under Reduce Motion.
class KitoButtonBounce extends StatefulWidget {
  /// Creates a bounce.
  const KitoButtonBounce({
    super.key,
    required this.trigger,
    required this.child,
    this.scale = 1.3,
    this.duration = const Duration(milliseconds: 420),
  });

  /// Change this to bounce.
  final Object? trigger;

  /// What bounces.
  final Widget child;

  /// The peak scale.
  final double scale;

  /// How long one bounce lasts.
  final Duration duration;

  /// The scale [t] (0–1) of the way through a bounce: a quick rise then a damped settle.
  static double scaleAt(double t, double peak) {
    if (t <= 0 || t >= 1) return 1;
    const rise = 0.28;
    if (t < rise) return 1 + (peak - 1) * Curves.easeOut.transform(t / rise);
    final s = (t - rise) / (1 - rise);
    return 1 + (peak - 1) * math.cos(s * math.pi * 1.5) * math.exp(-4 * s);
  }

  @override
  State<KitoButtonBounce> createState() => _KitoButtonBounceState();
}

class _KitoButtonBounceState extends State<KitoButtonBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(KitoButtonBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.trigger != widget.trigger && !context.reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: KitoButtonBounce.scaleAt(_controller.value, widget.scale),
          child: child,
        ),
      );
}
