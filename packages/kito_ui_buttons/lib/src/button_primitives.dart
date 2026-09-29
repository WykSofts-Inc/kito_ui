// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Easing helpers for timeline choreographies: map one 0–1 progress value onto many overlapping
/// segments, the way a Lottie file does.
abstract final class KitoButtonEase {
  /// Progress of [p] inside the segment [a]–[b], clamped to 0–1.
  static double segment(double p, double a, double b) {
    if (b <= a) return p >= b ? 1 : 0;
    return ((p - a) / (b - a)).clamp(0.0, 1.0);
  }

  /// Fast start, gentle end.
  static double outCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  /// Gentle start, fast end.
  static double inCubic(double t) => t * t * t;

  /// Gentle at both ends.
  static double inOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

  /// Overshoots then settles.
  static double outBack(double t, {double overshoot = 1.70158}) {
    final c3 = overshoot + 1;
    return 1 +
        c3 * math.pow(t - 1, 3).toDouble() +
        overshoot * math.pow(t - 1, 2).toDouble();
  }

  /// Bounces like a dropped ball.
  static double outBounce(double t) {
    const n1 = 7.5625, d1 = 2.75;
    if (t < 1 / d1) return n1 * t * t;
    if (t < 2 / d1) {
      final x = t - 1.5 / d1;
      return n1 * x * x + 0.75;
    }
    if (t < 2.5 / d1) {
      final x = t - 2.25 / d1;
      return n1 * x * x + 0.9375;
    }
    final x = t - 2.625 / d1;
    return n1 * x * x + 0.984375;
  }

  /// 0 → 1 → 0 across the segment.
  static double pulse(double t) => math.sin(t * math.pi);

  /// Linear interpolation.
  static double lerp(double a, double b, double t) => a + (b - a) * t;
}

/// A tick that draws itself as [progress] goes from 0 to 1.
class KitoButtonCheckmark extends StatelessWidget {
  /// Creates a tick.
  const KitoButtonCheckmark({
    super.key,
    this.progress = 1,
    required this.color,
    this.size = 18,
    this.strokeWidth = 2.5,
  });

  /// How much of the tick is drawn, 0–1.
  final double progress;

  /// Stroke colour.
  final Color color;

  /// Width and height.
  final double size;

  /// Stroke width.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
            painter: KitoButtonCheckmarkPainter(
                progress: progress, color: color, strokeWidth: strokeWidth)),
      );
}

/// Paints a partially drawn tick; see [KitoButtonCheckmark].
class KitoButtonCheckmarkPainter extends CustomPainter {
  /// Creates the painter.
  const KitoButtonCheckmarkPainter(
      {required this.progress, required this.color, this.strokeWidth = 2.5});

  /// How much of the tick is drawn, 0–1.
  final double progress;

  /// Stroke colour.
  final Color color;

  /// Stroke width.
  final double strokeWidth;

  /// The full tick path inside [size].
  static Path pathFor(Size size) => Path()
    ..moveTo(size.width * 0.12, size.height * 0.55)
    ..lineTo(size.width * 0.40, size.height * 0.85)
    ..lineTo(size.width * 0.90, size.height * 0.22);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0) return;
    final full = pathFor(size);
    final metrics = full.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var remaining = total * t;
    final drawn = Path();
    for (final m in metrics) {
      if (remaining <= 0) break;
      drawn.addPath(
          m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
      remaining -= m.length;
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(KitoButtonCheckmarkPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// A radial burst of particles; [progress] 0–1. Invisible at exactly 0 and 1.
class KitoButtonBurst extends StatelessWidget {
  /// Creates a burst.
  const KitoButtonBurst({
    super.key,
    required this.progress,
    required this.color,
    this.count = 10,
    this.radius = 34,
  });

  /// 0–1 through the burst.
  final double progress;

  /// Particle colour.
  final Color color;

  /// How many particles.
  final int count;

  /// How far they fly.
  final double radius;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          size: Size.square(radius * 2),
          painter: _BurstPainter(progress, color, count, radius),
        ),
      );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.progress, this.color, this.count, this.radius);
  final double progress;
  final Color color;
  final int count;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final t = KitoButtonEase.outCubic(progress);
    final c = size.center(Offset.zero);
    final paint = Paint()..color = color.withValues(alpha: color.a * (1 - t));
    for (var i = 0; i < count; i++) {
      final angle = i / count * 2 * math.pi;
      final r = radius * t;
      final dot = (6 - 4 * t) * (i.isEven ? 1 : 0.7) / 2;
      canvas.drawCircle(c + Offset(math.cos(angle) * r, math.sin(angle) * r),
          math.max(dot, 0.25), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.progress != progress || old.color != color;
}

/// The Kito spinner: a rotating three-quarter arc. Stops spinning under Reduce Motion
/// (it pulses its opacity instead) so there is still a sign of progress.
class KitoButtonSpinner extends StatefulWidget {
  /// Creates a spinner.
  const KitoButtonSpinner(
      {super.key, required this.color, this.size = 18, this.strokeWidth = 2.2});

  /// Arc colour.
  final Color color;

  /// Diameter.
  final double size;

  /// Arc thickness.
  final double strokeWidth;

  @override
  State<KitoButtonSpinner> createState() => _KitoButtonSpinnerState();
}

class _KitoButtonSpinnerState extends State<KitoButtonSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _controller.value;
          return Opacity(
            opacity: reduce ? 0.55 + 0.45 * math.sin(v * math.pi).abs() : 1,
            child: CustomPaint(
              painter: _ArcPainter(
                  rotation: reduce ? 0 : v * 2 * math.pi,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth),
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(
      {required this.rotation, required this.color, required this.strokeWidth});
  final double rotation;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawArc(
      rect,
      rotation - math.pi / 2,
      math.pi * 1.45,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.rotation != rotation || old.color != color;
}
