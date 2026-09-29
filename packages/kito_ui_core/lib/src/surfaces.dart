// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// A reusable gradient description.
@immutable
class KitoGradient {
  /// A linear gradient from [begin] to [end].
  const KitoGradient.linear(
    this.colors, {
    this.begin = AlignmentDirectional.topStart,
    this.end = AlignmentDirectional.bottomEnd,
    this.stops,
  }) : _kind = _GradientKind.linear;

  /// A radial gradient from the centre out.
  const KitoGradient.radial(this.colors, {this.stops})
      : begin = AlignmentDirectional.center,
        end = AlignmentDirectional.center,
        _kind = _GradientKind.radial;

  /// A sweep around the centre.
  const KitoGradient.sweep(this.colors, {this.stops})
      : begin = AlignmentDirectional.center,
        end = AlignmentDirectional.center,
        _kind = _GradientKind.sweep;

  /// The colours, in order.
  final List<Color> colors;

  /// Where each colour sits, 0–1; evenly spaced when null.
  final List<double>? stops;

  /// Where a linear gradient starts. Directional, so it mirrors in RTL.
  final AlignmentDirectional begin;

  /// Where a linear gradient ends.
  final AlignmentDirectional end;

  final _GradientKind _kind;

  /// The Flutter [Gradient] for a text direction.
  Gradient resolve(TextDirection direction) {
    switch (_kind) {
      case _GradientKind.linear:
        return LinearGradient(
            colors: colors,
            stops: stops,
            begin: begin.resolve(direction),
            end: end.resolve(direction));
      case _GradientKind.radial:
        return RadialGradient(colors: colors, stops: stops);
      case _GradientKind.sweep:
        return SweepGradient(colors: colors, stops: stops);
    }
  }

  /// Sunset orange to pink.
  static const sunset =
      KitoGradient.linear([Color(0xFFFF8A3D), Color(0xFFFF3D77)]);

  /// Deep blue to violet.
  static const ocean =
      KitoGradient.linear([Color(0xFF1E3A8A), Color(0xFF7C3AED)]);

  /// Teal to blue.
  static const lagoon =
      KitoGradient.linear([Color(0xFF0EA5A4), Color(0xFF2563EB)]);

  /// Near-black to charcoal.
  static const midnight =
      KitoGradient.linear([Color(0xFF0B0B0F), Color(0xFF2A2A35)]);
}

enum _GradientKind { linear, radial, sweep }

/// What a Kito surface is filled with.
@immutable
sealed class KitoBackground {
  const KitoBackground();

  /// A solid colour.
  const factory KitoBackground.color(Color color) = _ColorBackground;

  /// A gradient.
  const factory KitoBackground.gradient(KitoGradient gradient) =
      _GradientBackground;

  /// Frosted glass: blurs what's behind and tints it.
  const factory KitoBackground.glass({double blur, double opacity}) =
      _GlassBackground;

  /// An image, optionally tinted so text on top stays readable.
  const factory KitoBackground.image(ImageProvider image, {Color? overlay}) =
      _ImageBackground;
}

final class _ColorBackground extends KitoBackground {
  const _ColorBackground(this.color);
  final Color color;
}

final class _GradientBackground extends KitoBackground {
  const _GradientBackground(this.gradient);
  final KitoGradient gradient;
}

final class _GlassBackground extends KitoBackground {
  const _GlassBackground({this.blur = 18, this.opacity = 0.14});
  final double blur;
  final double opacity;
}

final class _ImageBackground extends KitoBackground {
  const _ImageBackground(this.image, {this.overlay});
  final ImageProvider image;
  final Color? overlay;
}

/// A rounded container filled with a [KitoBackground], with an optional border and shadow.
class KitoSurface extends StatelessWidget {
  /// Creates a surface.
  const KitoSurface({
    super.key,
    required this.child,
    this.background,
    this.radius,
    this.padding,
    this.border = false,
    this.elevation = 0,
  });

  /// What's inside.
  final Widget child;

  /// The fill; the theme's surface colour when null.
  final KitoBackground? background;

  /// Corner radius; the theme's large radius when null.
  final double? radius;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Draws the theme's hairline border.
  final bool border;

  /// 0 for flat; larger values cast a softer, wider shadow.
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final r = BorderRadius.circular(radius ?? theme.radii.lg);
    final fill = background ?? KitoBackground.color(theme.colors.surface);
    final shadows = elevation <= 0
        ? const <BoxShadow>[]
        : [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08 + elevation * 0.01),
                blurRadius: elevation * 4,
                offset: Offset(0, elevation))
          ];
    final outline = border ? Border.all(color: theme.colors.border) : null;
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    switch (fill) {
      case _ColorBackground(:final color):
        return DecoratedBox(
            decoration: BoxDecoration(
                color: color,
                borderRadius: r,
                border: outline,
                boxShadow: shadows),
            child: content);
      case _GradientBackground(:final gradient):
        return DecoratedBox(
          decoration: BoxDecoration(
              gradient: gradient.resolve(Directionality.of(context)),
              borderRadius: r,
              border: outline,
              boxShadow: shadows),
          child: content,
        );
      case _ImageBackground(:final image, :final overlay):
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            border: outline,
            boxShadow: shadows,
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
              colorFilter: overlay == null
                  ? null
                  : ColorFilter.mode(overlay, BlendMode.srcOver),
            ),
          ),
          child: content,
        );
      case _GlassBackground(:final blur, :final opacity):
        final tint =
            theme.brightness == Brightness.dark ? Colors.white : Colors.white;
        return DecoratedBox(
          decoration: BoxDecoration(borderRadius: r, boxShadow: shadows),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: opacity),
                  borderRadius: r,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: content,
              ),
            ),
          ),
        );
    }
  }
}

/// A coloured glow behind [child], like a soft neon halo.
class KitoGlow extends StatelessWidget {
  /// Creates a glow.
  const KitoGlow(
      {super.key,
      required this.child,
      this.color,
      this.radius = 18,
      this.intensity = 0.5});

  /// What glows.
  final Widget child;

  /// The glow colour; the theme's primary when null.
  final Color? color;

  /// How far the glow spreads.
  final double radius;

  /// 0–1.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.kito.colors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: c.withValues(alpha: intensity.clamp(0, 1) * 0.6),
              blurRadius: radius,
              spreadRadius: radius * 0.05)
        ],
      ),
      child: child,
    );
  }
}

/// Shrinks [child] slightly while it's pressed, then springs back — the Kito tap feel.
/// Put it around anything tappable; it doesn't handle the tap itself.
class KitoPressable extends StatefulWidget {
  /// Creates a press effect.
  const KitoPressable(
      {super.key, required this.child, this.scale = 0.96, this.enabled = true});

  /// What shrinks.
  final Widget child;

  /// The pressed size, as a fraction.
  final double scale;

  /// Turn the effect off, e.g. for disabled controls.
  final bool enabled;

  @override
  State<KitoPressable> createState() => _KitoPressableState();
}

class _KitoPressableState extends State<KitoPressable> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: KitoMotion.of(
            context, _down ? theme.motion.fast : theme.motion.medium),
        curve: _down ? Curves.easeOut : theme.motion.spring,
        child: widget.child,
      ),
    );
  }
}
