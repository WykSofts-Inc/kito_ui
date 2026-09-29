// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'toast.dart';

/// The style's default icon.
IconData kitoToastDefaultIcon(KitoToastStyle style) => switch (style) {
      KitoToastStyle.success => Icons.check_circle_rounded,
      KitoToastStyle.error => Icons.cancel_rounded,
      KitoToastStyle.warning => Icons.warning_rounded,
      KitoToastStyle.info => Icons.info_rounded,
    };

/// The icon, avatar or spinner at the start of a toast. Pops in with a spring and cross-fades
/// when a loading toast completes.
class KitoToastLeading extends StatelessWidget {
  /// Creates the leading piece for [toast].
  const KitoToastLeading(
      {super.key, required this.toast, required this.color, this.size = 18});

  /// The toast.
  final KitoToast toast;

  /// Icon and spinner colour.
  final Color color;

  /// Icon size; avatars are twice this.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final Widget child;
    if (toast.isLoading) {
      child = SizedBox.square(
        key: const ValueKey('loading'),
        dimension: size,
        child: CircularProgressIndicator(
            strokeWidth: 2.2, color: color, semanticsLabel: 'Loading'),
      );
    } else if (toast.avatar case final avatar?) {
      child = _Pop(
          key: const ValueKey('avatar'),
          child: KitoToastAvatarView(avatar: avatar, size: size * 2));
    } else if (toast.showsIcon) {
      child = _Pop(
        key: ValueKey(toast.style),
        child: Icon(toast.icon ?? kitoToastDefaultIcon(toast.style),
            size: size, color: color),
      );
    } else {
      return const SizedBox.shrink();
    }
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, theme.motion.medium),
      switchInCurve: theme.motion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(animation),
            child: child),
      ),
      child: child,
    );
  }
}

class _Pop extends StatelessWidget {
  const _Pop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: const KitoSpringCurve(damping: 0.55, stiffness: 12),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

/// A round avatar: a photo, or initials or an icon on a gradient.
class KitoToastAvatarView extends StatelessWidget {
  /// Creates an avatar [size] across.
  const KitoToastAvatarView(
      {super.key, required this.avatar, required this.size});

  /// What to draw.
  final KitoToastAvatar avatar;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = avatar.image;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: avatar.colors.length > 1
              ? avatar.colors
              : List.filled(
                  2,
                  avatar.colors.isEmpty
                      ? const Color(0xFF8E8E93)
                      : avatar.colors.first),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : avatar.icon != null
              ? Icon(avatar.icon, size: size * 0.45, color: Colors.white)
              : Text(
                  avatar.initials,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700),
                ),
    );
  }
}

/// A capsule bar that fills to [value], animating between values. Fills from the start edge,
/// so it runs right to left in RTL.
class KitoToastProgressBar extends StatelessWidget {
  /// Creates a bar.
  const KitoToastProgressBar(
      {super.key,
      required this.value,
      required this.fill,
      required this.track,
      this.height = 5});

  /// 0–1.
  final double value;

  /// The filled part.
  final Color fill;

  /// The empty part.
  final Color track;

  /// Thickness.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
            color: track, borderRadius: BorderRadius.circular(height)),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: theme.motion.standard,
          builder: (context, v, _) => FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: v,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: fill, borderRadius: BorderRadius.circular(height)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A ring that empties as a toast's time runs out, with the seconds left inside. Freezes while
/// [paused].
class KitoToastCountdownRing extends StatefulWidget {
  /// Creates a ring for a toast lasting [duration] with [remaining] left.
  const KitoToastCountdownRing({
    super.key,
    required this.duration,
    required this.remaining,
    required this.color,
    this.paused = false,
    this.size = 26,
  });

  /// The toast's full duration.
  final Duration duration;

  /// How much is left now.
  final Duration remaining;

  /// Ring and number colour.
  final Color color;

  /// Stops the ring, e.g. while the stack is fanned out.
  final bool paused;

  /// Diameter.
  final double size;

  @override
  State<KitoToastCountdownRing> createState() => _KitoToastCountdownRingState();
}

class _KitoToastCountdownRingState extends State<KitoToastCountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(KitoToastCountdownRing old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused ||
        old.duration != widget.duration ||
        (old.remaining - widget.remaining).abs() >
            const Duration(milliseconds: 250)) {
      _sync();
    }
  }

  void _sync() {
    final total = widget.duration.inMicroseconds;
    _controller.duration = widget.duration;
    _controller.value =
        total == 0 ? 0 : widget.remaining.inMicroseconds / total;
    if (widget.paused || widget.remaining == Duration.zero) {
      _controller.stop();
    } else {
      _controller.animateTo(0,
          duration: widget.remaining, curve: Curves.linear);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final seconds =
                (_controller.value * widget.duration.inMilliseconds / 1000)
                    .ceil();
            return CustomPaint(
              painter: _RingPainter(_controller.value, widget.color),
              child: Center(
                child: Text(
                  '$seconds',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: widget.size * 0.4,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color);
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color.withValues(alpha: 0.2));
    canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// A toast's button: 44-point tap target, press feedback, role colour.
class KitoToastActionButton extends StatelessWidget {
  /// Creates a button for [action].
  const KitoToastActionButton({
    super.key,
    required this.action,
    required this.color,
    required this.onPressed,
    this.filled = false,
    this.onFilled,
  });

  /// The action.
  final KitoToastAction action;

  /// Text colour (or fill colour when [filled]).
  final Color color;

  /// Runs the action (and dismisses, if it does).
  final VoidCallback onPressed;

  /// Draws a filled capsule, as in the island layout.
  final bool filled;

  /// Text colour on a filled capsule.
  final Color? onFilled;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final fg = filled ? (onFilled ?? Colors.white) : color;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (action.icon != null) Icon(action.icon, size: 16, color: fg),
        if (action.icon != null && action.showsLabel) const SizedBox(width: 4),
        if (action.showsLabel || action.icon == null)
          Text(action.label,
              style: theme.typography.label
                  .copyWith(fontWeight: FontWeight.w700, color: fg)),
      ],
    );
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: KitoPressable(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: filled
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: label,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: label),
            ),
          ),
        ),
      ),
    );
  }
}
