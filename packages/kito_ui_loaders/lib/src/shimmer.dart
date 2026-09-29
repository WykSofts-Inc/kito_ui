// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'loader_strings.dart';
import 'loader_timeline.dart';

/// Sweeps a soft highlight across [child], masked to what it paints — put it on any
/// placeholder, or on a whole skeleton so every block shimmers in one pass. The sweep runs
/// from the start edge (so right to left in RTL); under Reduce Motion it breathes in place.
///
/// Toggling [enabled] keeps [child]'s state.
class KitoLoaderShimmer extends StatefulWidget {
  /// Creates a shimmer.
  const KitoLoaderShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1400),
    this.highlight,
  });

  /// What shimmers.
  final Widget child;

  /// Turn the sweep on and off.
  final bool enabled;

  /// One sweep.
  final Duration duration;

  /// The highlight; white at 65% (14% in dark themes) when null.
  final Color? highlight;

  /// Where the band's leading edge sits for [phase] 0–1: fully off the start at 0, fully off
  /// the end at 1.
  static double offset(double phase, double width, double band) =>
      -band + phase * (width + band * 2);

  @override
  State<KitoLoaderShimmer> createState() => _KitoLoaderShimmerState();
}

class _KitoLoaderShimmerState extends State<KitoLoaderShimmer> {
  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (!widget.enabled) return child;
    final kito = context.kito;
    final highlight = widget.highlight ??
        Colors.white.withValues(
            alpha: kito.brightness == Brightness.dark ? 0.14 : 0.65);
    final reduce = context.reduceMotion;
    final rtl = context.isRtl;
    final seconds = widget.duration.inMicroseconds / 1e6;
    return KitoLoaderTimeline(
      child: child,
      builder: (context, t, child) {
        final phase = (t % math.max(seconds, 0.1)) / math.max(seconds, 0.1);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            if (reduce) {
              final a = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
              return ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [
                highlight.withValues(alpha: highlight.a * a * 0.6),
                highlight.withValues(alpha: highlight.a * a * 0.6),
              ]);
            }
            final w = bounds.width;
            final band = math.max(w * 0.45, 80.0);
            var x = KitoLoaderShimmer.offset(phase, w, band);
            if (rtl) x = w - x - band;
            // The gradient axis leans 18°, so the band reads as a slanted sheen.
            const tilt = 18 * math.pi / 180;
            final from = Offset(x, 0);
            final to = from + Offset(math.cos(tilt), math.sin(tilt)) * band;
            final transparent = highlight.withValues(alpha: 0);
            return ui.Gradient.linear(
                from, to, [transparent, highlight, transparent], [0, 0.5, 1]);
          },
          child: child,
        );
      },
    );
  }
}

/// A shimmering placeholder block.
///
/// ```dart
/// KitoLoaderSkeleton(width: 120, height: 14)
/// KitoLoaderSkeleton.circle(size: 44)
/// ```
class KitoLoaderSkeleton extends StatelessWidget {
  /// A rounded block. Null sizes fill the available space.
  const KitoLoaderSkeleton(
      {super.key,
      this.width,
      this.height,
      this.radius = 6,
      this.shimmer = true})
      : _circle = false;

  /// A circle, for avatars.
  const KitoLoaderSkeleton.circle(
      {super.key, double size = 40, this.shimmer = true})
      : width = size,
        height = size,
        radius = 0,
        _circle = true;

  /// Width; fills when null.
  final double? width;

  /// Height; fills when null.
  final double? height;

  /// Corner radius.
  final double radius;

  /// Sweep a highlight across it. Turn off when an ancestor shimmers already.
  final bool shimmer;

  final bool _circle;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.kito.colors.surfaceMuted,
        shape: _circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: _circle ? null : BorderRadius.circular(radius),
      ),
    );
    return ExcludeSemantics(
        child: shimmer ? KitoLoaderShimmer(child: block) : block);
  }
}

/// Swaps [child] for a skeleton block of the same size while [loading]. The real child stays
/// laid out (hidden), so nothing jumps when the data lands.
class KitoLoaderSkeletonSwap extends StatelessWidget {
  /// Creates a swap.
  const KitoLoaderSkeletonSwap(
      {super.key, required this.loading, required this.child, this.radius = 6});

  /// Show the skeleton.
  final bool loading;

  /// The real content.
  final Widget child;

  /// The skeleton's corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final duration = KitoMotion.of(context, context.kito.motion.medium);
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: loading ? 0 : 1,
          duration: duration,
          child: IgnorePointer(
            ignoring: loading,
            child: ExcludeSemantics(excluding: loading, child: child),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !loading,
            child: AnimatedOpacity(
              opacity: loading ? 1 : 0,
              duration: duration,
              child: loading
                  ? Semantics(
                      label: KitoLoaderStrings.of(context, 'loading'),
                      child: KitoLoaderSkeleton(radius: radius))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Redacts [child] into flat placeholder shapes that shimmer while [loading], and blocks taps
/// and screen-reader access to it. Text becomes muted glyph shapes and images solid blocks;
/// the real layout stays, so nothing jumps when the data lands. Keeps [child]'s state.
///
/// ```dart
/// KitoLoaderRedacted(loading: profile == null, child: ProfileCard(profile ?? Profile.sample))
/// ```
class KitoLoaderRedacted extends StatelessWidget {
  /// Creates a redaction.
  const KitoLoaderRedacted(
      {super.key,
      required this.loading,
      required this.child,
      this.color,
      this.duration = const Duration(milliseconds: 1400)});

  /// Redact.
  final bool loading;

  /// The real content (fill it with sample data while loading).
  final Widget child;

  /// The placeholder colour; the theme's muted surface when null.
  final Color? color;

  /// One shimmer sweep.
  final Duration duration;

  /// A colour matrix blending each pixel [amount] (0–1) of the way to [target], keeping alpha.
  static List<double> redactionMatrix(Color target, double amount) {
    final a = amount.clamp(0.0, 1.0);
    final k = 1 - a;
    return [
      k, 0, 0, 0, a * target.r * 255, //
      0, k, 0, 0, a * target.g * 255, //
      0, 0, k, 0, a * target.b * 255, //
      0, 0, 0, 1, 0, //
    ];
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final target = color ?? kito.colors.surfaceMuted;
    return Semantics(
      label: loading ? KitoLoaderStrings.of(context, 'loading') : null,
      child: IgnorePointer(
        ignoring: loading,
        child: ExcludeSemantics(
          excluding: loading,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: loading ? 1 : 0),
            duration: KitoMotion.of(context, kito.motion.medium),
            curve: Curves.easeInOut,
            child: KitoLoaderShimmer(
                enabled: loading, duration: duration, child: child),
            builder: (context, amount, child) => ColorFiltered(
              colorFilter: ColorFilter.matrix(redactionMatrix(target, amount)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
