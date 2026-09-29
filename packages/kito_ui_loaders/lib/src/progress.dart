// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'indicators.dart';
import 'loader_strings.dart';
import 'loader_timeline.dart';
import 'shimmer.dart';

/// A determinate ring for a known fraction — an upload, a multi-step flow. Animates to each
/// new [value]. For unknown-length work use [KitoLoaderSpinner].
class KitoLoaderProgressRing extends StatelessWidget {
  /// Creates a progress ring; [value] is clamped to 0–1.
  const KitoLoaderProgressRing({
    super.key,
    required this.value,
    this.size = 48,
    this.strokeWidth = 5,
    this.color,
    this.trackColor,
    this.showPercentage = true,
    this.semanticLabel,
  });

  /// 0–1.
  final double value;

  /// Diameter.
  final double size;

  /// Ring thickness.
  final double strokeWidth;

  /// Fill colour; the theme's primary when null.
  final Color? color;

  /// Track colour; the theme's muted surface when null.
  final Color? trackColor;

  /// Show "42%" in the middle.
  final bool showPercentage;

  /// What screen readers announce; "Progress" when null.
  final String? semanticLabel;

  /// The percentage label for [value], rounded down: 0.426 → "42%".
  static String percentText(double value) =>
      '${(value.clamp(0.0, 1.0) * 100).floor()}%';

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final v = value.clamp(0.0, 1.0);
    return loaderSemantics(
      context,
      semanticLabel ?? KitoLoaderStrings.of(context, 'progress'),
      value: KitoLoaderStrings.percent(context, v),
      SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: KitoMotion.of(context, const Duration(milliseconds: 300)),
          curve: Curves.easeOut,
          builder: (context, shown, _) => CustomPaint(
            painter: _RingPainter(
              value: shown,
              color: color ?? kito.colors.primary,
              track: trackColor ?? kito.colors.surfaceMuted,
              strokeWidth: strokeWidth,
            ),
            child: showPercentage
                ? Center(
                    child: Text(
                      percentText(v),
                      style: kito.typography.caption.copyWith(
                        color: kito.colors.onBackground,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.value,
      required this.color,
      required this.track,
      required this.strokeWidth});
  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * value, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// A progress bar. With a [value] it fills from the start edge, with a sheen travelling along
/// the fill and an optional percentage; with none it's indeterminate — two segments chasing
/// across the track. Under Reduce Motion indeterminate bars breathe in place.
class KitoLoaderLinearProgress extends StatelessWidget {
  /// Creates a progress bar.
  const KitoLoaderLinearProgress({
    super.key,
    this.value,
    this.height = 6,
    this.color,
    this.trackColor,
    this.label,
    this.showPercentage = false,
  });

  /// 0–1, or null for indeterminate.
  final double? value;

  /// Bar thickness.
  final double height;

  /// Fill colour; the theme's primary when null.
  final Color? color;

  /// Track colour; the theme's muted surface when null.
  final Color? trackColor;

  /// A caption above the bar, at the start edge.
  final String? label;

  /// Show the percentage above the bar, at the end edge.
  final bool showPercentage;

  /// Where indeterminate segment [index] (0 long, 1 short) spans, as start/end fractions of the
  /// track, at [phase] 0–1 of the 1.8 s cycle.
  static ({double start, double end}) segment(double phase, int index) {
    double ease(double t) =>
        t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
    double span(double t, double head, double tail) =>
        ease(((t - head) / (tail - head)).clamp(0.0, 1.0));
    final local = index == 0 ? phase : phase - 0.45;
    if (local < 0) return (start: 0, end: 0);
    final end = span(local, 0, index == 0 ? 0.55 : 0.5) * 1.2 - 0.1;
    final start = span(local, index == 0 ? 0.15 : 0.1, 0.55) * 1.2 - 0.1;
    return (start: start.clamp(0.0, 1.0), end: end.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final fill = color ?? kito.colors.primary;
    final track = trackColor ?? kito.colors.surfaceMuted;
    final v = value?.clamp(0.0, 1.0);
    final reduce = context.reduceMotion;
    final rtl = context.isRtl;

    Widget bar;
    if (v != null) {
      bar = TweenAnimationBuilder<double>(
        tween: Tween(end: v),
        duration: KitoMotion.of(context, const Duration(milliseconds: 450)),
        curve: Curves.easeOutCubic,
        builder: (context, shown, _) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: shown.clamp(0.0, 1.0),
            heightFactor: 1,
            child: shown <= 0
                ? const SizedBox.shrink()
                : KitoLoaderShimmer(
                    enabled: shown > 0 && shown < 1,
                    duration: const Duration(milliseconds: 1800),
                    highlight: Colors.white.withValues(alpha: 0.45),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(height),
                        gradient: LinearGradient(
                          colors: [fill.withValues(alpha: fill.a * 0.75), fill],
                          begin: AlignmentDirectional.centerStart
                              .resolve(Directionality.of(context)),
                          end: AlignmentDirectional.centerEnd
                              .resolve(Directionality.of(context)),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: fill.withValues(alpha: 0.4),
                              blurRadius: height)
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      );
    } else {
      bar = KitoLoaderTimeline(
        builder: (context, t, _) => CustomPaint(
          painter: _IndeterminatePainter(
            color: fill,
            phase: (t % 1.8) / 1.8,
            breath: reduce ? kitoLoaderBreath(t, period: 2) : null,
            rtl: rtl,
          ),
        ),
      );
    }

    final header = label != null || (showPercentage && v != null);
    return Semantics(
      container: true,
      label: label ?? KitoLoaderStrings.of(context, 'progress'),
      value: v == null
          ? KitoLoaderStrings.of(context, 'inProgress')
          : KitoLoaderStrings.percent(context, v),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header) ...[
              Row(children: [
                if (label != null)
                  Expanded(
                    child: Text(label!,
                        style: kito.typography.label
                            .copyWith(color: kito.colors.onBackground)),
                  )
                else
                  const Spacer(),
                if (showPercentage && v != null)
                  Text(
                    KitoLoaderProgressRing.percentText(v),
                    style: kito.typography.label.copyWith(
                      color: kito.colors.onBackground.withValues(alpha: 0.7),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ]),
              SizedBox(height: kito.spacing.sm),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(height),
              child: SizedBox(
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: track),
                  child: bar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndeterminatePainter extends CustomPainter {
  _IndeterminatePainter(
      {required this.color,
      required this.phase,
      required this.rtl,
      this.breath});
  final Color color;
  final double phase;
  final bool rtl;
  final double? breath;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    if (breath != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, r),
          Paint()
            ..color =
                color.withValues(alpha: color.a * (0.35 + 0.35 * breath!)));
      return;
    }
    final paint = Paint()..color = color;
    for (var i = 0; i < 2; i++) {
      final s = KitoLoaderLinearProgress.segment(phase, i);
      if (s.end <= s.start) continue;
      var left = s.start * size.width, right = s.end * size.width;
      if (rtl) {
        final l = size.width - right;
        right = size.width - left;
        left = l;
      }
      canvas.drawRRect(RRect.fromLTRBR(left, 0, right, size.height, r), paint);
    }
  }

  @override
  bool shouldRepaint(_IndeterminatePainter old) => true;
}

/// How [KitoLoaderStepProgress] draws its steps.
enum KitoLoaderStepStyle {
  /// Numbered markers joined by connectors; finished steps get a tick.
  dots,

  /// A row of capsules, like story progress; the current one partly filled.
  segments,
}

/// Progress through named steps — checkout, onboarding, an order on its way.
class KitoLoaderStepProgress extends StatelessWidget {
  /// Creates a step progress. [current] is the index in progress; `steps.length` means done.
  const KitoLoaderStepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.stepFraction = 0.5,
    this.style = KitoLoaderStepStyle.dots,
    this.color,
  });

  /// Step names.
  final List<String> steps;

  /// The step in progress.
  final int current;

  /// How far into the current step, for [KitoLoaderStepStyle.segments].
  final double stepFraction;

  /// Dots or segments.
  final KitoLoaderStepStyle style;

  /// Accent; the theme's primary when null.
  final Color? color;

  /// [step] clamped to 0–[count].
  static int clampedStep(int step, int count) => step.clamp(0, count);

  /// How full segment [index] is: done ones full, the current one [fraction], the rest empty.
  static double segmentFill(int index, int current, double fraction) {
    if (index < current) return 1;
    if (index == current) return fraction.clamp(0.0, 1.0);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final tint = color ?? kito.colors.primary;
    final cur = clampedStep(current, steps.length);
    final reduce = context.reduceMotion;
    final duration = KitoMotion.of(context, kito.motion.slow);
    final curve = reduce ? Curves.easeInOut : kito.motion.emphasized;

    final Widget body = switch (style) {
      KitoLoaderStepStyle.dots => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: _connector(context, tint,
                            filled: i <= cur,
                            visible: i > 0,
                            duration: duration,
                            curve: curve)),
                    _marker(context, i, cur, tint, reduce, duration),
                    Expanded(
                        child: _connector(context, tint,
                            filled: i < cur,
                            visible: i < steps.length - 1,
                            duration: duration,
                            curve: curve)),
                  ]),
                  SizedBox(height: kito.spacing.sm),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: kito.typography.caption.copyWith(
                      fontWeight: i == cur ? FontWeight.w600 : FontWeight.w400,
                      color: kito.colors.onBackground
                          .withValues(alpha: i <= cur ? 1 : 0.45),
                    ),
                    child: Text(steps[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center),
                  ),
                ]),
              ),
          ],
        ),
      KitoLoaderStepStyle.segments => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5,
                      color: kito.colors.surfaceMuted,
                      alignment: AlignmentDirectional.centerStart,
                      child: AnimatedFractionallySizedBox(
                        duration: duration,
                        curve: curve,
                        widthFactor: segmentFill(i, cur, stepFraction),
                        heightFactor: 1,
                        alignment: AlignmentDirectional.centerStart,
                        child: ColoredBox(color: tint),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
            if (cur < steps.length) ...[
              SizedBox(height: kito.spacing.sm),
              AnimatedSwitcher(
                duration: duration,
                child: Text(
                  steps[cur],
                  key: ValueKey(cur),
                  style: kito.typography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kito.colors.onBackground.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
    };

    return Semantics(
      container: true,
      label: KitoLoaderStrings.of(context, 'step', {
        'current': math.min(cur + 1, steps.length),
        'total': steps.length,
      }),
      value: cur < steps.length
          ? steps[cur]
          : KitoLoaderStrings.of(context, 'complete'),
      child: ExcludeSemantics(child: body),
    );
  }

  Widget _connector(BuildContext context, Color tint,
      {required bool filled,
      required bool visible,
      required Duration duration,
      required Curve curve}) {
    if (!visible) return const SizedBox(height: 3);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: context.kito.colors.surfaceMuted,
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedFractionallySizedBox(
          duration: duration,
          curve: curve,
          widthFactor: filled ? 1 : 0,
          heightFactor: 1,
          alignment: AlignmentDirectional.centerStart,
          child: ColoredBox(color: tint),
        ),
      ),
    );
  }

  Widget _marker(BuildContext context, int index, int cur, Color tint,
      bool reduce, Duration duration) {
    final kito = context.kito;
    final done = index < cur;
    final active = index == cur;
    final onTint = kito.onAccent(color);
    final marker = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? tint : kito.colors.surfaceMuted,
      ),
      child: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: kito.motion.spring),
            child: FadeTransition(opacity: a, child: child)),
        child: done
            ? Icon(Icons.check_rounded,
                key: const ValueKey('done'), size: 15, color: onTint)
            : Text(
                '${index + 1}',
                key: ValueKey('n$index'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? onTint
                      : kito.colors.onBackground.withValues(alpha: 0.5),
                ),
              ),
      ),
    );
    if (!active || reduce) return marker;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        KitoLoaderTimeline(builder: (context, t, _) {
          final p = Curves.easeOut.transform((t / 1.3) % 1);
          return Transform.scale(
            scale: 1 + 0.6 * p,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: tint.withValues(alpha: 0.5 * (1 - p)), width: 3),
              ),
            ),
          );
        }),
        marker,
      ],
    );
  }
}
