// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'loader_strings.dart';
import 'loader_timeline.dart';

/// Wraps a loader in one screen-reader node ("Loading" unless [label] says otherwise).
Widget loaderSemantics(BuildContext context, String? label, Widget child,
        {String? value}) =>
    Semantics(
      container: true,
      label: label ?? KitoLoaderStrings.of(context, 'loading'),
      value: value,
      child: ExcludeSemantics(child: child),
    );

/// The gentle breathing (0–1) loaders fall back to under Reduce Motion.
double kitoLoaderBreath(double seconds, {double period = 1.6}) =>
    0.5 + 0.5 * math.sin(seconds / period * 2 * math.pi);

/// A rotating three-quarter arc. Under Reduce Motion it holds still and breathes.
class KitoLoaderSpinner extends StatelessWidget {
  /// Creates a spinner.
  const KitoLoaderSpinner({
    super.key,
    this.size = 24,
    this.strokeWidth = 3,
    this.color,
    this.period = const Duration(milliseconds: 800),
    this.semanticLabel,
  });

  /// Diameter.
  final double size;

  /// Arc thickness.
  final double strokeWidth;

  /// Arc colour; the theme's primary when null.
  final Color? color;

  /// One full turn.
  final Duration period;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// The rotation (radians) at [seconds].
  static double angleAt(double seconds, Duration period) =>
      (seconds / (period.inMicroseconds / 1e6)) % 1 * 2 * math.pi;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox.square(
        dimension: size,
        child: KitoLoaderTimeline(
          builder: (context, t, _) => Opacity(
            opacity: reduce ? 0.4 + 0.6 * kitoLoaderBreath(t) : 1,
            child: CustomPaint(
              painter: _ArcPainter(
                color: c,
                strokeWidth: strokeWidth,
                start: reduce ? 0 : angleAt(t, period),
                sweep: math.pi * 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(
      {required this.color,
      required this.strokeWidth,
      required this.start,
      required this.sweep});
  final Color color;
  final double strokeWidth;
  final double start;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (sweep > 0) {
      canvas.drawArc(
          rect, start - math.pi / 2, sweep, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.start != start ||
      old.sweep != sweep ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// A spinning ring stroked with a sweep gradient that fades into the primary colour, with a
/// round head, so the direction of travel reads even in a still frame.
class KitoLoaderGradientRing extends StatelessWidget {
  /// Creates a gradient ring.
  const KitoLoaderGradientRing({
    super.key,
    this.size = 28,
    this.strokeWidth = 4,
    this.colors,
    this.period = const Duration(milliseconds: 900),
    this.semanticLabel,
  });

  /// Diameter.
  final double size;

  /// Ring thickness.
  final double strokeWidth;

  /// Tail to head; the primary colour fading from transparent when null.
  final List<Color>? colors;

  /// One full turn.
  final Duration period;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final primary = context.kito.colors.primary;
    final palette = colors ?? [primary.withValues(alpha: 0), primary];
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox.square(
        dimension: size,
        child: KitoLoaderTimeline(
          builder: (context, t, _) => Opacity(
            opacity: reduce ? 0.5 + 0.5 * kitoLoaderBreath(t) : 1,
            child: CustomPaint(
              painter: _GradientRingPainter(
                colors: palette,
                strokeWidth: strokeWidth,
                rotation: reduce ? 0 : KitoLoaderSpinner.angleAt(t, period),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter(
      {required this.colors,
      required this.strokeWidth,
      required this.rotation});
  final List<Color> colors;
  final double strokeWidth;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final c = rect.center;
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(rotation - math.pi / 2)
      ..translate(-c.dx, -c.dy);
    final shader = SweepGradient(colors: colors).createShader(rect);
    canvas.drawArc(
      rect,
      0.08,
      math.pi * 2 - 0.16,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    // The bright, rounded head.
    final head = Offset(c.dx + rect.width / 2 * math.cos(-0.08),
        c.dy + rect.height / 2 * math.sin(-0.08));
    canvas
      ..drawCircle(head, strokeWidth / 2, Paint()..color = colors.last)
      ..restore();
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) =>
      old.rotation != rotation || old.colors != colors;
}

/// Three dots that swell in sequence.
class KitoLoaderDots extends StatelessWidget {
  /// Creates the dots.
  const KitoLoaderDots(
      {super.key, this.dotSize = 8, this.color, this.semanticLabel});

  /// Each dot's diameter.
  final double dotSize;

  /// Dot colour; the theme's primary when null.
  final Color? color;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// How lit dot [index] is (0–1) at [seconds]; each takes a turn over a 0.75 s cycle.
  static double intensity(double seconds, int index) {
    final local = ((seconds / 0.75) * 3 - index) % 3;
    return local < 1 ? math.sin(local * math.pi) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      KitoLoaderTimeline(
        builder: (context, t, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: dotSize * 0.6),
              Transform.scale(
                scale: reduce ? 1 : 0.6 + 0.4 * intensity(t, i),
                child: _Dot(
                    size: dotSize,
                    color: c.withValues(
                        alpha: c.a * (0.4 + 0.6 * intensity(t, i)))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );
}

/// A dot with a halo that swells outward and fades — a low-key "something is happening".
class KitoLoaderPulse extends StatelessWidget {
  /// Creates a pulse.
  const KitoLoaderPulse(
      {super.key, this.size = 24, this.color, this.semanticLabel});

  /// The dot's diameter; the halo reaches 1.8×.
  final double size;

  /// Colour; the theme's primary when null.
  final Color? color;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox.square(
        dimension: size * 1.8,
        child: KitoLoaderTimeline(
          builder: (context, t, _) {
            final phase = Curves.easeOut.transform((t / 1.1) % 1);
            return Stack(alignment: Alignment.center, children: [
              if (!reduce)
                Transform.scale(
                  scale: 1 + 0.8 * phase,
                  child: _Dot(
                      size: size,
                      color: c.withValues(alpha: c.a * 0.5 * (1 - phase))),
                ),
              _Dot(
                  size: size,
                  color: reduce
                      ? c.withValues(
                          alpha: c.a * (0.5 + 0.5 * kitoLoaderBreath(t)))
                      : c),
            ]);
          },
        ),
      ),
    );
  }
}

/// Equaliser bars bouncing at staggered heights — audio, uploads, processing.
class KitoLoaderBars extends StatelessWidget {
  /// Creates the bars.
  const KitoLoaderBars({
    super.key,
    this.barCount = 5,
    this.barWidth = 5,
    this.maxHeight = 28,
    this.color,
    this.semanticLabel,
  });

  /// How many bars.
  final int barCount;

  /// Each bar's width.
  final double barWidth;

  /// The tallest a bar gets.
  final double maxHeight;

  /// Colour; the theme's primary when null.
  final Color? color;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// Bar [index]'s height as a fraction of the max (0.25–1) at [seconds].
  static double heightAt(double seconds, int index) {
    final local = ((seconds - index * 0.1) / 1.0) % 1;
    final tri = local < 0.5 ? local * 2 : (1 - local) * 2;
    return 0.25 + 0.75 * Curves.easeInOut.transform(tri.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox(
        height: maxHeight,
        child: KitoLoaderTimeline(
          builder: (context, t, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < barCount; i++) ...[
                if (i > 0) SizedBox(width: barWidth * 0.6),
                Container(
                  width: barWidth,
                  height: maxHeight *
                      (reduce
                          ? 0.4 + 0.5 * ((i * 37) % 10) / 10
                          : heightAt(t, i)),
                  decoration: BoxDecoration(
                    color: reduce
                        ? c.withValues(
                            alpha: c.a *
                                (0.45 + 0.55 * kitoLoaderBreath(t + i * 0.15)))
                        : c,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of dots riding a sine wave, each a little behind the one before.
class KitoLoaderWave extends StatelessWidget {
  /// Creates a wave.
  const KitoLoaderWave(
      {super.key,
      this.dotCount = 5,
      this.dotSize = 8,
      this.color,
      this.semanticLabel});

  /// How many dots.
  final int dotCount;

  /// Each dot's diameter.
  final double dotSize;

  /// Colour; the theme's primary when null.
  final Color? color;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// Dot [index]'s height on the wave (−1–1) at [seconds].
  static double liftAt(double seconds, int index) =>
      math.sin(seconds * 4 - index * 0.6);

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox(
        height: dotSize * 3,
        child: KitoLoaderTimeline(
          builder: (context, t, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < dotCount; i++) ...[
                if (i > 0) SizedBox(width: dotSize * 0.7),
                Transform.translate(
                  offset: Offset(0, reduce ? 0 : liftAt(t, i) * dotSize),
                  child: _Dot(
                    size: dotSize,
                    color: reduce
                        ? c.withValues(
                            alpha: c.a * (0.4 + 0.3 * (1 + liftAt(t, i))))
                        : c,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Concentric rings expanding and fading outward in turn — a radar ping.
class KitoLoaderRipple extends StatelessWidget {
  /// Creates a ripple.
  const KitoLoaderRipple(
      {super.key,
      this.size = 40,
      this.ringCount = 3,
      this.color,
      this.semanticLabel});

  /// The widest ring's diameter.
  final double size;

  /// How many rings.
  final int ringCount;

  /// Colour; the theme's primary when null.
  final Color? color;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// How far out ring [index] of [count] is (0–1) at [seconds].
  static double phaseAt(double seconds, int index, int count) =>
      (seconds / 1.4 + index / count) % 1;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox.square(
        dimension: size,
        child: KitoLoaderTimeline(
          builder: (context, t, _) => CustomPaint(
            painter: _RipplePainter(
              color: c,
              phases: reduce
                  ? [0.7]
                  : [
                      for (var i = 0; i < ringCount; i++)
                        Curves.easeOut.transform(phaseAt(t, i, ringCount))
                    ],
              breath: reduce ? kitoLoaderBreath(t) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.color, required this.phases, this.breath});
  final Color color;
  final List<double> phases;
  final double? breath;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2 - 1;
    for (final p in phases) {
      final alpha = breath == null ? 0.8 * (1 - p) : 0.3 + 0.5 * breath!;
      canvas.drawCircle(
        c,
        maxR * (0.2 + 0.8 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: color.a * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => true;
}

/// Dots circling a centre, each dimmer than the last so the direction reads at a glance.
/// Turns the other way in right-to-left layouts.
class KitoLoaderOrbit extends StatelessWidget {
  /// Creates an orbit.
  const KitoLoaderOrbit(
      {super.key,
      this.size = 32,
      this.dotCount = 3,
      this.color,
      this.semanticLabel});

  /// The orbit's diameter.
  final double size;

  /// How many dots.
  final int dotCount;

  /// Colour; the theme's primary when null.
  final Color? color;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// The lead dot's angle (radians) at [seconds]; one lap every 1.5 s.
  static double angleAt(double seconds) => (seconds / 1.5) % 1 * 2 * math.pi;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    final reduce = context.reduceMotion;
    final dir = context.isRtl ? -1.0 : 1.0;
    final dot = size * 0.18;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox.square(
        dimension: size + dot,
        child: KitoLoaderTimeline(
          builder: (context, t, _) {
            final lead = reduce ? 0.0 : angleAt(t) * dir;
            return Stack(children: [
              for (var i = 0; i < dotCount; i++)
                Positioned(
                  left: size / 2 +
                      math.cos(lead - dir * 2 * math.pi / dotCount * i) *
                          size /
                          2,
                  top: size / 2 +
                      math.sin(lead - dir * 2 * math.pi / dotCount * i) *
                          size /
                          2,
                  child: _Dot(
                    size: dot,
                    color: c.withValues(
                        alpha: c.a *
                            (1 - i * (0.6 / dotCount)) *
                            (reduce ? 0.5 + 0.5 * kitoLoaderBreath(t) : 1)),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
