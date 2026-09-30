// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'money.dart';

/// A selectable card: fills and outlines with the accent when [selected]. Internal.
class CheckoutChoiceCard extends StatelessWidget {
  /// Creates a card.
  const CheckoutChoiceCard({
    super.key,
    required this.selected,
    required this.child,
    required this.accent,
    this.onTap,
    this.enabled = true,
    this.padding,
    this.semanticLabel,
  });

  /// Whether it's the chosen one.
  final bool selected;

  /// What's inside.
  final Widget child;

  /// The selection colour.
  final Color accent;

  /// Called on tap.
  final VoidCallback? onTap;

  /// Greys it out and ignores taps when false.
  final bool enabled;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Read by screen readers instead of the children.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final radius = BorderRadius.circular(theme.radii.lg);
    final card = AnimatedContainer(
      duration: KitoMotion.of(context, theme.motion.medium),
      curve: theme.motion.standard,
      padding: padding ?? EdgeInsets.all(theme.spacing.lg),
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.07), theme.colors.surface)
            : theme.colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: selected ? accent : theme.colors.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ]
            : const [],
      ),
      child: child,
    );
    return Semantics(
      button: onTap != null,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: KitoPressable(
          enabled: enabled && onTap != null,
          scale: 0.98,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onTap : null,
              child: card,
            ),
          ),
        ),
      ),
    );
  }
}

/// A radio dot that fills with a spring. Internal.
class CheckoutRadio extends StatelessWidget {
  /// Creates a radio.
  const CheckoutRadio(
      {super.key, required this.selected, required this.accent});

  /// Whether it's on.
  final bool selected;

  /// The fill.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return AnimatedContainer(
      duration: KitoMotion.of(context, theme.motion.fast),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected
                ? accent
                : theme.colors.onSurface.withValues(alpha: 0.3),
            width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: KitoMotion.of(context, theme.motion.medium),
        curve: theme.motion.spring,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// A rounded icon tile. Internal.
class CheckoutIconTile extends StatelessWidget {
  /// Creates a tile.
  const CheckoutIconTile(
      {super.key, required this.icon, required this.color, this.size = 40});

  /// The icon.
  final IconData icon;

  /// Its colour; the tile is a pale wash of it.
  final Color color;

  /// Width and height.
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size * 0.5, color: color),
      );
}

/// A small capsule tag. Internal.
class CheckoutBadge extends StatelessWidget {
  /// Creates a badge.
  const CheckoutBadge(this.text, {super.key, required this.color});

  /// The words.
  final String text;

  /// The colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(theme.radii.pill),
      ),
      child: Text(text,
          style: theme.typography.caption.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

/// An amount that rolls to its new value: the old one slides out, the new one in. Internal.
class CheckoutMoneyText extends StatelessWidget {
  /// Creates the text.
  const CheckoutMoneyText(this.cents,
      {super.key, required this.currencyCode, this.style, this.prefix = ''});

  /// Cents.
  final int cents;

  /// The ISO 4217 code.
  final String currencyCode;

  /// The text style.
  final TextStyle? style;

  /// Put before the amount, e.g. "−".
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final text =
        prefix + KitoCheckoutMoney.format(cents, currencyCode: currencyCode);
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, theme.motion.medium),
      switchInCurve: theme.motion.emphasized,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(text);
        final offset = Tween<Offset>(
          begin: Offset(0, incoming ? 0.6 : -0.6),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text(text, key: ValueKey(text), style: style, maxLines: 1),
    );
  }
}

/// A dashed hairline. Internal.
class CheckoutDashedDivider extends StatelessWidget {
  /// Creates a divider.
  const CheckoutDashedDivider({super.key, this.color});

  /// The dash colour.
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(
            painter: _DashPainter(color ?? context.kito.colors.border)),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 4, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A tick that draws itself from start to end over [duration]. Internal.
class CheckoutDrawnCheck extends StatelessWidget {
  /// Creates a tick.
  const CheckoutDrawnCheck({
    super.key,
    required this.color,
    this.size = 24,
    this.strokeWidth = 3,
    this.duration = const Duration(milliseconds: 420),
    this.delay = Duration.zero,
  });

  /// The stroke colour.
  final Color color;

  /// Width and height.
  final double size;

  /// The stroke width.
  final double strokeWidth;

  /// How long the stroke takes.
  final Duration duration;

  /// Waits this long (as part of the animation) before drawing.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = KitoMotion.of(context, duration + delay);
    final start = total == Duration.zero
        ? 0.0
        : delay.inMicroseconds / (duration + delay).inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: total == Duration.zero ? 1 : 0, end: 1),
      duration: total,
      builder: (context, v, _) {
        final t = start >= 1 ? v : ((v - start) / (1 - start)).clamp(0.0, 1.0);
        return CustomPaint(
          size: Size.square(size),
          painter: _CheckPainter(
              Curves.easeOutCubic.transform(t), color, strokeWidth),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress, this.color, this.strokeWidth);

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.53)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.79, size.height * 0.31);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}
