// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';

/// The default colour of the user-location puck.
const Color kitoMapUserBlue = Color(0xFF2F80ED);

const _bubbleText =
    TextStyle(fontSize: 13, fontWeight: FontWeight.w800, height: 1.1);

/// Draws a [KitoMapPin] — dot, icon, bubble, avatar, teardrop or pulse — and springs it up
/// when selected. Use it in your own marker layers, or let `KitoMap` place it.
class KitoMapPinView extends StatelessWidget {
  /// Creates a pin view.
  const KitoMapPinView({
    super.key,
    required this.pin,
    this.selected = false,
    this.onTap,
  });

  /// The pin.
  final KitoMapPin pin;

  /// Grows and lifts it.
  final bool selected;

  /// Called on tap.
  final VoidCallback? onTap;

  /// How much a selected pin grows.
  static double selectedScale(KitoMapPinKind kind) => switch (kind) {
        KitoMapPinKind.dot => 1.5,
        KitoMapPinKind.icon => 1.25,
        KitoMapPinKind.bubble => 1.12,
        KitoMapPinKind.avatar => 1.2,
        KitoMapPinKind.teardrop => 1.25,
        KitoMapPinKind.pulse => 1.15,
      };

  /// The box a marker needs for [pin], with room for the selected size.
  static Size markerSize(KitoMapPin pin, {TextScaler? textScaler}) {
    switch (pin.style.kind) {
      case KitoMapPinKind.dot:
        return const Size(36, 36);
      case KitoMapPinKind.icon:
        return const Size(56, 56);
      case KitoMapPinKind.teardrop:
        return const Size(52, 64);
      case KitoMapPinKind.pulse:
        return const Size(76, 76);
      case KitoMapPinKind.avatar:
        return const Size(64, 72);
      case KitoMapPinKind.bubble:
        final painter = TextPainter(
          text: TextSpan(text: pin.style.text ?? '', style: _bubbleText),
          textDirection: TextDirection.ltr,
          textScaler: textScaler ?? TextScaler.noScaling,
          maxLines: 1,
        )..layout();
        final w = painter.width + 28 + (pin.badge != null ? 16 : 0);
        final h = painter.height + 22;
        painter.dispose();
        return Size(w * 1.14 + 8, h * 1.14 + 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final tint = pin.tint ?? theme.colors.primary;
    final bottom = pin.style.anchorsAtBottom;
    Widget body = switch (pin.style.kind) {
      KitoMapPinKind.dot => _Dot(tint: tint),
      KitoMapPinKind.icon => _IconBadge(
          tint: tint, icon: pin.style.icon ?? pin.icon ?? Icons.place_rounded),
      KitoMapPinKind.teardrop =>
        _Teardrop(tint: tint, icon: pin.icon ?? Icons.circle),
      KitoMapPinKind.bubble =>
        _Bubble(text: pin.style.text ?? '', tint: tint, selected: selected),
      KitoMapPinKind.avatar => _Avatar(
          tint: tint, initials: pin.style.text ?? '', image: pin.style.image),
      KitoMapPinKind.pulse => KitoMapPulse(
          color: tint, heading: pin.heading, icon: pin.icon, size: 18),
    };
    if (pin.badge != null) {
      body = Stack(clipBehavior: Clip.none, children: [
        body,
        PositionedDirectional(
          top: -6,
          end: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colors.onSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colors.surface, width: 1.5),
            ),
            child: Text(pin.badge!,
                style: TextStyle(
                    color: theme.colors.surface,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ]);
    }
    final alignment = bottom ? Alignment.bottomCenter : Alignment.center;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: pin.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          alignment: alignment,
          child: AnimatedScale(
            scale: selected ? selectedScale(pin.style.kind) : 1,
            alignment: alignment,
            duration: KitoMotion.of(context, theme.motion.medium),
            curve: theme.motion.spring,
            child: body,
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _shadow([double lift = 1]) => [
      BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 6 * lift,
          offset: Offset(0, 2 * lift)),
    ];

class _Dot extends StatelessWidget {
  const _Dot({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: tint,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: _shadow(),
        ),
      );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.tint, required this.icon});

  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: tint,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: _shadow(),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: _on(tint)),
      );
}

Color _on(Color c) => ThemeData.estimateBrightnessForColor(c) == Brightness.dark
    ? Colors.white
    : Colors.black;

class _Teardrop extends StatelessWidget {
  const _Teardrop({required this.tint, required this.icon});

  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 46,
        child: CustomPaint(
          painter: _TeardropPainter(tint),
          child: Align(
            alignment: const Alignment(0, -0.42),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child:
                  Icon(icon, size: icon == Icons.circle ? 8 : 13, color: tint),
            ),
          ),
        ),
      );
}

class _TeardropPainter extends CustomPainter {
  _TeardropPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..moveTo(r, size.height)
      ..cubicTo(r * 0.55, size.height * 0.78, 0, size.height * 0.62, 0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..cubicTo(size.width, size.height * 0.62, r * 1.45, size.height * 0.78, r,
          size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_TeardropPainter old) => old.color != color;
}

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.text, required this.tint, required this.selected});

  final String text;
  final Color tint;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final bg = selected ? tint : theme.colors.surface;
    final fg = selected ? _on(tint) : theme.colors.onSurface;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: KitoMotion.of(context, theme.motion.fast),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  selected ? bg : theme.colors.border.withValues(alpha: 0.4)),
          boxShadow: _shadow(selected ? 1.6 : 1),
        ),
        child: Text(text, maxLines: 1, style: _bubbleText.copyWith(color: fg)),
      ),
      CustomPaint(size: const Size(12, 6), painter: _TailPainter(bg)),
    ]);
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.tint, required this.initials, this.image});

  final Color tint;
  final String initials;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final letters = initials.characters.take(2).toString().toUpperCase();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: tint,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: _shadow(),
          image: image == null
              ? null
              : DecorationImage(image: image!, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: image == null
            ? Text(letters,
                style: TextStyle(
                    color: _on(tint),
                    fontWeight: FontWeight.w800,
                    fontSize: 15))
            : null,
      ),
      CustomPaint(size: const Size(12, 7), painter: _TailPainter(Colors.white)),
    ]);
  }
}

/// A live-location dot: a solid core with a white ring, a halo that pulses outward and, with
/// a [heading], a soft cone showing the direction of travel. Reduce Motion keeps the halo
/// still.
class KitoMapPulse extends StatefulWidget {
  /// Creates a pulse.
  const KitoMapPulse({
    super.key,
    this.color = kitoMapUserBlue,
    this.heading,
    this.icon,
    this.size = 18,
  });

  /// The colour.
  final Color color;

  /// Direction of travel in degrees, 0 is north.
  final double? heading;

  /// A glyph in the core (a bike for a rider).
  final IconData? icon;

  /// The core's diameter.
  final double size;

  @override
  State<KitoMapPulse> createState() => _KitoMapPulseState();
}

class _KitoMapPulseState extends State<KitoMapPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c
        ..stop()
        ..value = 0.35;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = widget.icon != null ? widget.size + 8 : widget.size;
    final box = core * 3.4;
    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => CustomPaint(
          painter: _HaloPainter(
              t: _c.value,
              color: widget.color,
              core: core,
              heading: widget.heading),
          child: child,
        ),
        child: Center(
          child: Container(
            width: core,
            height: core,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: _shadow(),
            ),
            alignment: Alignment.center,
            child: widget.icon == null
                ? null
                : Icon(widget.icon, size: core * 0.5, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter(
      {required this.t,
      required this.color,
      required this.core,
      required this.heading});

  final double t;
  final Color color;
  final double core;
  final double? heading;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    if (heading != null) {
      final a = (heading! - 90) * math.pi / 180;
      const spread = 0.5;
      final r = maxR * 0.95;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), a - spread, spread * 2,
            false)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    final r = core / 2 + (maxR - core / 2) * t;
    canvas.drawCircle(
        c, r, Paint()..color = color.withValues(alpha: 0.28 * (1 - t)));
    canvas.drawCircle(
        c, core * 0.9, Paint()..color = color.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.t != t || old.color != color || old.heading != heading;
}

/// A count bubble for a group of pins; bigger for bigger groups.
class KitoMapClusterView extends StatelessWidget {
  /// Creates a cluster bubble.
  const KitoMapClusterView(
      {super.key, required this.count, this.tint, this.onTap});

  /// How many pins it stands for.
  final int count;

  /// Its colour; the theme's primary when null.
  final Color? tint;

  /// Called on tap (typically zooms in).
  final VoidCallback? onTap;

  /// The diameter for [count].
  static double diameter(int count) =>
      (34 + 7 * math.log(math.max(count, 2)) / math.ln2).clamp(38.0, 64.0);

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final color = tint ?? theme.colors.primary;
    final d = diameter(count);
    return Semantics(
      button: onTap != null,
      label: '$count places',
      hint: onTap != null ? 'Zoom in' : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: d + 10,
            height: d + 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            alignment: Alignment.center,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: _shadow(),
              ),
              alignment: Alignment.center,
              child: Text(count > 99 ? '99+' : '$count',
                  style: TextStyle(
                      color: _on(color),
                      fontWeight: FontWeight.w800,
                      fontSize: d * 0.34)),
            ),
          ),
        ),
      ),
    );
  }
}
