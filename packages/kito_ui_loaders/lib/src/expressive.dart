// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'indicators.dart';
import 'loader_strings.dart';
import 'loader_timeline.dart';

/// "Someone is typing…" — three dots hopping in turn inside a chat bubble with a little tail.
/// Under Reduce Motion the dots fade in turn instead of hopping.
class KitoLoaderTypingIndicator extends StatelessWidget {
  /// Creates a typing indicator.
  const KitoLoaderTypingIndicator({
    super.key,
    this.dotSize = 8,
    this.dotColor,
    this.bubbleColor,
    this.showBubble = true,
    this.semanticLabel,
  });

  /// Each dot's diameter.
  final double dotSize;

  /// Dot colour; muted text colour when null.
  final Color? dotColor;

  /// Bubble colour; the theme's muted surface when null.
  final Color? bubbleColor;

  /// Draw the bubble; false for inline dots.
  final bool showBubble;

  /// What screen readers announce; "Typing" when null.
  final String? semanticLabel;

  /// How high dot [index] is (0–1) at [seconds]: each hops for a third of a 1.2 s cycle, one
  /// after another, then all rest.
  static double lift(double seconds, int index) {
    const cycle = 1.2;
    final phase = (seconds % cycle) / cycle;
    final local = (phase - index * 0.18) / 0.36;
    if (local <= 0 || local >= 1) return 0;
    return math.sin(local * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    final dots = dotColor ?? kito.colors.onSurface.withValues(alpha: 0.55);
    final bubble = bubbleColor ?? kito.colors.surfaceMuted;
    Widget row = KitoLoaderTimeline(
      builder: (context, t, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) SizedBox(width: dotSize * 0.55),
            Transform.translate(
              offset: Offset(0, reduce ? 0 : -lift(t, i) * dotSize * 0.7),
              child: Transform.scale(
                scale: reduce ? 1 : 0.9 + 0.15 * lift(t, i),
                child: SizedBox.square(
                  dimension: dotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dots.withValues(
                          alpha: dots.a * (0.35 + 0.65 * lift(t, i))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (showBubble) {
      row = Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: -dotSize * 0.2,
            bottom: -dotSize * 0.3,
            child: _circle(dotSize * 1.5, bubble),
          ),
          PositionedDirectional(
            start: -dotSize * 0.9,
            bottom: -dotSize * 1.1,
            child: _circle(dotSize * 0.75, bubble),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
                color: bubble, borderRadius: BorderRadius.circular(999)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: dotSize * 1.9, vertical: dotSize * 1.5),
              child: row,
            ),
          ),
        ],
      );
    }
    return loaderSemantics(
        context, semanticLabel ?? KitoLoaderStrings.of(context, 'typing'), row);
  }

  static Widget _circle(double size, Color color) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );
}

/// A glowing ECG trace running across a faint monitor line, optionally beside a heart that
/// beats in time — health, fitness and "connecting to your device". Under Reduce Motion the
/// trace holds still and the heart fades on each beat.
class KitoLoaderHeartbeat extends StatelessWidget {
  /// Creates a heartbeat.
  const KitoLoaderHeartbeat({
    super.key,
    this.width = 140,
    this.height = 44,
    this.strokeWidth = 2.5,
    this.color,
    this.beatsPerMinute = 72,
    this.showHeart = false,
    this.semanticLabel,
  });

  /// The trace's width.
  final double width;

  /// The trace's height.
  final double height;

  /// Line thickness.
  final double strokeWidth;

  /// Colour; the theme's danger colour when null.
  final Color? color;

  /// Speed, clamped to 30–200.
  final double beatsPerMinute;

  /// Show a beating heart before the trace.
  final bool showHeart;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// The ECG shape over one beat, [unit] 0–1 → about −1–1: flat, a small P wave, the sharp QRS
  /// spike, then a rounded T wave.
  static double ecg(double unit) {
    double bump(double center, double width, double height) {
      final d = (unit - center) / width;
      return height * math.exp(-d * d);
    }

    return bump(0.18, 0.035, 0.18) +
        bump(0.34, 0.012, -0.25) +
        bump(0.38, 0.016, 1.0) +
        bump(0.42, 0.014, -0.45) +
        bump(0.62, 0.06, 0.3);
  }

  /// The heart's "lub-dub" swell over one beat, 0–1.
  static double pulse(double unit) {
    final lub = math.exp(-math.pow((unit - 0.1) / 0.06, 2));
    final dub = 0.6 * math.exp(-math.pow((unit - 0.3) / 0.06, 2));
    return math.min(lub + dub, 1);
  }

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.kito.colors.danger;
    final reduce = context.reduceMotion;
    final beat = 60 / beatsPerMinute.clamp(30, 200);
    return loaderSemantics(
      context,
      semanticLabel,
      KitoLoaderTimeline(
        builder: (context, t, _) {
          final head = reduce ? 1.0 : (t % (beat * 2)) / (beat * 2);
          final p = pulse((t % beat) / beat);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            if (showHeart) ...[
              Opacity(
                opacity: reduce ? 0.55 + 0.45 * p : 1,
                child: Transform.scale(
                  scale: reduce ? 1 : 1 + 0.22 * p,
                  child: DecoratedBox(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: tint.withValues(alpha: 0.5 * p),
                          blurRadius: 12)
                    ], shape: BoxShape.circle),
                    child: Icon(Icons.favorite_rounded,
                        size: height * 0.6, color: tint),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            CustomPaint(
              size: Size(width, height),
              painter: _EcgPainter(
                  color: tint, strokeWidth: strokeWidth, head: head),
            ),
          ]);
        },
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(
      {required this.color, required this.strokeWidth, required this.head});
  final Color color;
  final double strokeWidth;
  final double head;

  Offset _point(double unit, Size size) {
    final local = (unit * 2) % 1;
    return Offset(unit * size.width,
        size.height / 2 - KitoLoaderHeartbeat.ecg(local) * size.height * 0.45);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const samples = 160;
    final full = Path()..moveTo(_point(0, size).dx, _point(0, size).dy);
    for (var i = 1; i <= samples; i++) {
      final p = _point(i / samples, size);
      full.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(full, stroke(color.withValues(alpha: color.a * 0.14)));

    const trail = 0.45;
    const steps = 48;
    for (var s = 0; s < steps; s++) {
      final from = head - trail * (steps - s) / steps;
      final to = head - trail * (steps - s - 1) / steps;
      if (to <= 0) continue;
      final a = _point(math.max(from, 0), size);
      final b = _point(to, size);
      canvas.drawLine(
          a, b, stroke(color.withValues(alpha: color.a * (s + 1) / steps)));
    }

    final tip = _point(head, size);
    canvas
      ..drawCircle(
          tip,
          6,
          Paint()
            ..color = color.withValues(alpha: color.a * 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5))
      ..drawCircle(tip, strokeWidth * 1.3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.head != head || old.color != color;
}

/// One shape [KitoLoaderMorph] can flow through.
enum KitoLoaderMorphForm {
  /// A circle.
  circle,

  /// A triangle, point up.
  triangle,

  /// A square.
  square,

  /// A pentagon.
  pentagon,

  /// A hexagon.
  hexagon,

  /// A five-pointed star.
  star;

  /// Corner points on the unit circle, first corner pointing up (empty for [circle]).
  List<Offset> get vertices {
    List<Offset> polygon(int sides, {required bool flatTop}) {
      final start = -math.pi / 2 + (flatTop ? math.pi / sides : 0);
      return [
        for (var i = 0; i < sides; i++)
          Offset(math.cos(start + 2 * math.pi * i / sides),
              math.sin(start + 2 * math.pi * i / sides)),
      ];
    }

    switch (this) {
      case circle:
        return const [];
      case triangle:
        return polygon(3, flatTop: false);
      case square:
        return polygon(4, flatTop: true);
      case pentagon:
        return polygon(5, flatTop: false);
      case hexagon:
        return polygon(6, flatTop: true);
      case star:
        return [
          for (var i = 0; i < 10; i++)
            Offset(math.cos(-math.pi / 2 + math.pi * i / 5),
                    math.sin(-math.pi / 2 + math.pi * i / 5)) *
                (i.isEven ? 1.0 : 0.5),
        ];
    }
  }

  /// How far the outline is from the centre in direction [angle], as a fraction of the radius.
  double radiusAt(double angle) {
    final corners = vertices;
    if (corners.length < 3) return 1;
    final dx = math.cos(angle), dy = math.sin(angle);
    var nearest = double.infinity;
    for (var i = 0; i < corners.length; i++) {
      final a = corners[i], b = corners[(i + 1) % corners.length];
      final ex = b.dx - a.dx, ey = b.dy - a.dy;
      final den = dx * ey - dy * ex;
      if (den.abs() < 1e-9) continue;
      final distance = (a.dx * ey - a.dy * ex) / den;
      final along = (a.dx * dy - a.dy * dx) / den;
      if (distance > 0 && along >= -1e-9 && along <= 1 + 1e-9) {
        nearest = math.min(nearest, distance);
      }
    }
    return nearest.isFinite ? nearest : 1;
  }
}

/// A blob that flows from shape to shape while its gradient turns — playful for creative apps,
/// onboarding and short waits. Under Reduce Motion it morphs in place without spinning.
class KitoLoaderMorph extends StatelessWidget {
  /// Creates a morphing loader. Fewer than two [forms] falls back to circle and square.
  const KitoLoaderMorph({
    super.key,
    this.size = 44,
    this.forms = const [
      KitoLoaderMorphForm.circle,
      KitoLoaderMorphForm.triangle,
      KitoLoaderMorphForm.square,
      KitoLoaderMorphForm.star,
      KitoLoaderMorphForm.hexagon,
    ],
    this.colors,
    this.stepDuration = const Duration(milliseconds: 900),
    this.semanticLabel,
  });

  /// The shape's size.
  final double size;

  /// The shapes to cycle through.
  final List<KitoLoaderMorphForm> forms;

  /// Gradient colours; primary and secondary when null.
  final List<Color>? colors;

  /// Time per shape.
  final Duration stepDuration;

  /// What screen readers announce; "Loading" when null.
  final String? semanticLabel;

  /// Which form is showing at [seconds] and how far (eased 0–1) into the morph to the next.
  /// Each step holds its shape for the first 35%.
  static ({int index, double progress}) step(
      double seconds, double stepSeconds, int count) {
    if (count <= 0) return (index: 0, progress: 0);
    final total = seconds / math.max(stepSeconds, 0.2);
    final index = total.floor() % count;
    final local = total - total.floor();
    final moving = math.max(0.0, (local - 0.35) / 0.65);
    final eased = moving < 0.5
        ? 4 * math.pow(moving, 3).toDouble()
        : 1 - math.pow(-2 * moving + 2, 3) / 2;
    return (index: index, progress: eased);
  }

  /// The blended outline radius between [from] and [to] at [angle].
  static double radius(KitoLoaderMorphForm from, KitoLoaderMorphForm to,
      double progress, double angle,
      {double softness = 0.1}) {
    final t = progress.clamp(0.0, 1.0);
    final blended = from.radiusAt(angle) * (1 - t) + to.radiusAt(angle) * t;
    return blended * (1 - softness) + softness;
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final list = forms.length >= 2
        ? forms
        : const [KitoLoaderMorphForm.circle, KitoLoaderMorphForm.square];
    final palette = colors ??
        [
          kito.colors.primary,
          kito.colors.secondary.withValues(alpha: 0.9),
          kito.colors.primary
        ];
    final reduce = context.reduceMotion;
    final stepSeconds = stepDuration.inMicroseconds / 1e6;
    return loaderSemantics(
      context,
      semanticLabel,
      SizedBox.square(
        dimension: size * 1.2,
        child: KitoLoaderTimeline(
          builder: (context, t, _) {
            final s = step(t, stepSeconds, list.length);
            return Center(
              child: Transform.rotate(
                angle: reduce ? 0 : t * math.pi / 3,
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _MorphPainter(
                    from: list[s.index],
                    to: list[(s.index + 1) % list.length],
                    progress: s.progress,
                    colors: palette,
                    turn: t * math.pi / 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter(
      {required this.from,
      required this.to,
      required this.progress,
      required this.colors,
      required this.turn});
  final KitoLoaderMorphForm from;
  final KitoLoaderMorphForm to;
  final double progress;
  final List<Color> colors;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    const samples = 144;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i <= samples; i++) {
      final angle = 2 * math.pi * i / samples - math.pi / 2;
      final rad = KitoLoaderMorph.radius(from, to, progress, angle);
      final p = c + Offset(math.cos(angle), math.sin(angle)) * rad * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path.shift(Offset(0, size.height * 0.08)),
      Paint()
        ..color = colors.first.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = SweepGradient(
          colors: [...colors, colors.first],
          transform: GradientRotation(turn),
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_MorphPainter old) => true;
}
