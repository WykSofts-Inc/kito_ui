// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Links, the orb and highlights: [tint], or the theme's primary.
Color aiAccent(KitoTheme theme, Color? tint) => tint ?? theme.colors.primary;

/// The send button: [tint], or the text colour (black in light mode, white in dark).
Color aiStrong(KitoTheme theme, Color? tint) =>
    tint ?? theme.colors.onBackground;

/// What reads on [aiStrong].
Color aiOnStrong(KitoTheme theme, Color? tint) {
  if (tint == null) return theme.colors.background;
  return ThemeData.estimateBrightnessForColor(tint) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

/// Quieter text on a surface.
Color aiMuted(KitoTheme theme, [double alpha = 0.6]) =>
    theme.colors.onSurface.withValues(alpha: alpha);

/// The orb's default colours around [tint].
List<Color> aiOrbColors(Color tint) => [
      tint,
      const Color(0xFF8C5CFA),
      const Color(0xFFFA6B9E),
      const Color(0xFF40D6ED),
      tint,
    ];

/// A tappable area with the Kito press feel, a 44-point minimum and button semantics.
class AiTap extends StatelessWidget {
  /// Creates a tap target.
  const AiTap({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
    this.onLongPress,
    this.minSize = 44,
    this.radius = 999,
    this.selected,
    this.scale = 0.95,
  });

  /// What's shown.
  final Widget child;

  /// Called on tap; null disables it.
  final VoidCallback? onTap;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Read by screen readers; the child's text is used when null.
  final String? label;

  /// The smallest width and height.
  final double minSize;

  /// The ink's corner radius.
  final double radius;

  /// Exposed as the selected state.
  final bool? selected;

  /// The pressed size.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: label != null,
      child: KitoPressable(
        enabled: onTap != null,
        scale: scale,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(radius),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: minSize, minHeight: minSize),
              child: Center(widthFactor: 1, heightFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round icon button with a tooltip-like label, used under messages.
class AiIconAction extends StatelessWidget {
  /// Creates an icon action.
  const AiIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.selected,
  });

  /// The icon.
  final IconData icon;

  /// Read by screen readers and shown as a tooltip.
  final String label;

  /// Called on tap.
  final VoidCallback? onTap;

  /// The icon colour.
  final Color? color;

  /// Exposed as the selected state (for thumbs).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: AiTap(
        onTap: onTap,
        label: label,
        selected: selected,
        minSize: 36,
        child: SizedBox(
          width: 36,
          height: 36,
          child: AnimatedSwitcher(
            duration: KitoMotion.of(context, theme.motion.fast),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(icon,
                key: ValueKey(icon),
                size: 18,
                color: color ?? aiMuted(theme, 0.55)),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides [child] in the first time it's built. Holds still with Reduce Motion.
class AiEntrance extends StatelessWidget {
  /// Creates an entrance.
  const AiEntrance(
      {super.key,
      required this.child,
      this.delay = Duration.zero,
      this.dy = 8,
      this.animate = true});

  /// What appears.
  final Widget child;

  /// Extra time before it starts, for staggering.
  final Duration delay;

  /// How far it rises, in pixels.
  final double dy;

  /// False shows [child] in place straight away (for content that was already on screen).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    final theme = context.kito;
    final total = theme.motion.medium + delay;
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: theme.motion.standard),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * dy), child: child),
      ),
      child: child,
    );
  }
}
