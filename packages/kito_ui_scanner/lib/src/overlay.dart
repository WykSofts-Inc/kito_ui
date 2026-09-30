// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// How the viewfinder is drawn.
enum KitoScanOverlayStyle {
  /// Rounded corner brackets that breathe, over a light dim.
  corners,

  /// Brackets, a hairline window and a sweeping laser line.
  laser,

  /// A solid outlined window over a heavy dim.
  frame,

  /// Just a small reticle in the middle; nothing dimmed.
  minimal,
}

/// Where the scan window sits. Pure, so `KitoScannerView` can hand the same rectangle to the
/// camera as its scan area.
abstract final class KitoScanWindow {
  /// The window for a view of [size]: [aspectRatio] wide over tall (1 for QR, about 1.8 for
  /// barcodes), [widthFraction] of the width up to [maxWidth], centred and nudged up by
  /// [lift] of the free height so the hint and controls fit below.
  static Rect rect(
    Size size, {
    double aspectRatio = 1,
    double widthFraction = 0.72,
    double maxWidth = 320,
    double lift = 0.12,
  }) {
    if (size.isEmpty) return Rect.zero;
    var w = math.min(size.width * widthFraction, maxWidth);
    var h = w / aspectRatio;
    final maxH = size.height * 0.62;
    if (h > maxH) {
      h = maxH;
      w = h * aspectRatio;
    }
    final free = size.height - h;
    final top = free / 2 - free * lift / 2;
    return Rect.fromLTWH((size.width - w) / 2, math.max(top, 0), w, h);
  }

  /// The laser's distance from the window's top at [progress] (any real number; it bounces),
  /// kept [inset] from the edges.
  static double laserOffset(
    double progress,
    double height, {
    double inset = 14,
  }) {
    final travel = math.max(height - inset * 2, 0.0);
    final phase = progress % 2;
    final t = phase <= 1 ? phase : 2 - phase;
    final eased = (1 - math.cos(t * math.pi)) / 2;
    return inset + travel * eased;
  }

  /// The corner bracket length for a window: a fifth of its short side, 18–44.
  static double bracketLength(Rect window) =>
      (math.min(window.width, window.height) / 5).clamp(18.0, 44.0);
}

/// An animated viewfinder you can lay over anything — the camera preview in
/// `KitoScannerView`, or a photo or placeholder in a gallery.
///
/// Corners breathe, the laser sweeps, and when [locked] (a code was found) the brackets snap
/// in and turn green. With Reduce Motion everything holds still.
///
/// ```dart
/// KitoScanOverlay(
///   style: KitoScanOverlayStyle.laser,
///   hint: 'Point at the QR code on the till',
///   child: Image.asset('assets/counter.jpg', fit: BoxFit.cover),
/// )
/// ```
class KitoScanOverlay extends StatefulWidget {
  /// Creates an overlay.
  const KitoScanOverlay({
    super.key,
    this.child,
    this.style = KitoScanOverlayStyle.corners,
    this.aspectRatio = 1,
    this.widthFraction = 0.72,
    this.locked = false,
    this.hint,
    this.tint,
  });

  /// What's behind the viewfinder.
  final Widget? child;

  /// How it's drawn.
  final KitoScanOverlayStyle style;

  /// The window's width over height: 1 for QR codes, ~1.8 for barcodes.
  final double aspectRatio;

  /// How much of the width the window takes.
  final double widthFraction;

  /// A code has been found: brackets snap in and turn green.
  final bool locked;

  /// A line under the window: "Point at a QR code".
  final String? hint;

  /// The laser colour; the theme's secondary when null.
  final Color? tint;

  @override
  State<KitoScanOverlay> createState() => _KitoScanOverlayState();
}

class _KitoScanOverlayState extends State<KitoScanOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _lock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: widget.locked ? 1 : 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(KitoScanOverlay old) {
    super.didUpdateWidget(old);
    if (old.locked != widget.locked) {
      if (context.reduceMotion) {
        _lock.value = widget.locked ? 1 : 0;
      } else if (widget.locked) {
        _lock.animateTo(1, curve: const KitoSpringCurve());
      } else {
        _lock.animateBack(0, curve: Curves.easeOut);
      }
    }
    _syncLoop();
  }

  void _syncLoop() {
    final still =
        context.reduceMotion ||
        widget.locked ||
        widget.style == KitoScanOverlayStyle.minimal ||
        widget.style == KitoScanOverlayStyle.frame;
    if (still) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _lock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final laser = widget.tint ?? theme.colors.secondary;
    final green = theme.colors.success;
    final still = context.reduceMotion;
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(
          c.maxWidth.isFinite ? c.maxWidth : 360,
          c.maxHeight.isFinite ? c.maxHeight : 480,
        );
        final window = KitoScanWindow.rect(
          size,
          aspectRatio: widget.aspectRatio,
          widthFraction: widget.widthFraction,
        );
        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.child != null) widget.child!,
              ExcludeSemantics(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_loop, _lock]),
                    builder:
                        (context, _) => CustomPaint(
                          painter: _OverlayPainter(
                            style: widget.style,
                            window: window,
                            loop: still ? 0.5 : _loop.value,
                            lock: _lock.value,
                            laser: laser,
                            green: green,
                            animated: !still,
                          ),
                        ),
                  ),
                ),
              ),
              if (widget.hint != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: window.bottom + 20,
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      child: AnimatedSwitcher(
                        duration: KitoMotion.of(context, theme.motion.medium),
                        child: Container(
                          key: ValueKey(widget.hint),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(
                              theme.radii.pill,
                            ),
                          ),
                          child: Text(
                            widget.hint!,
                            textAlign: TextAlign.center,
                            style: theme.typography.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.style,
    required this.window,
    required this.loop,
    required this.lock,
    required this.laser,
    required this.green,
    required this.animated,
  });

  final KitoScanOverlayStyle style;
  final Rect window;
  final double loop;
  final double lock;
  final Color laser;
  final Color green;
  final bool animated;

  @override
  void paint(Canvas canvas, Size size) {
    const white = Colors.white;
    final bracket = Color.lerp(white, green, lock)!;
    switch (style) {
      case KitoScanOverlayStyle.minimal:
        final c = window.center;
        final r = 20 - 5 * lock;
        final ring =
            Paint()
              ..color = bracket.withValues(alpha: 0.9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;
        canvas.drawCircle(c, r, ring);
        canvas.drawCircle(c, 3, Paint()..color = bracket);
        return;
      case KitoScanOverlayStyle.frame:
        _dim(canvas, size, 24, 0.62);
        canvas.drawRRect(
          RRect.fromRectAndRadius(window, const Radius.circular(24)),
          Paint()
            ..color = bracket
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + 2 * lock,
        );
        return;
      case KitoScanOverlayStyle.corners:
        _dim(canvas, size, 26, 0.35);
        final breathe =
            animated ? 5 * (1 - math.cos(loop * 4 * math.pi)) / 2 : 0.0;
        final grow = breathe * (1 - lock) - 10 * lock;
        _brackets(canvas, window.inflate(grow), bracket, 5, 26);
        return;
      case KitoScanOverlayStyle.laser:
        _dim(canvas, size, 22, 0.4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(window, const Radius.circular(22)),
          Paint()
            ..color = white.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        _brackets(canvas, window.inflate(-6 * lock), bracket, 3, 22);
        final color = Color.lerp(laser, green, lock)!;
        final y =
            window.top +
            (lock > 0 || !animated
                ? window.height / 2
                : KitoScanWindow.laserOffset(loop * 2, window.height));
        final line = Rect.fromLTRB(
          window.left + 14,
          y - 1.25,
          window.right - 14,
          y + 1.25,
        );
        final glow = Rect.fromLTRB(
          window.left + 10,
          y - 13,
          window.right - 10,
          y + 13,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(glow, const Radius.circular(13)),
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0),
              ],
            ).createShader(glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(line, const Radius.circular(2)),
          Paint()
            ..shader = LinearGradient(
              colors: [
                color.withValues(alpha: 0),
                color,
                Colors.white,
                color,
                color.withValues(alpha: 0),
              ],
            ).createShader(line),
        );
        return;
    }
  }

  void _dim(Canvas canvas, Size size, double radius, double opacity) {
    final path =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRRect(RRect.fromRectAndRadius(window, Radius.circular(radius)));
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: opacity),
    );
  }

  void _brackets(
    Canvas canvas,
    Rect w,
    Color color,
    double width,
    double radius,
  ) {
    final len = KitoScanWindow.bracketLength(w);
    final r = math.min(radius, len * 0.8);
    final path = Path();
    void corner(Offset c, double dx, double dy) {
      path
        ..moveTo(c.dx, c.dy + dy * len)
        ..lineTo(c.dx, c.dy + dy * r)
        ..arcToPoint(
          Offset(c.dx + dx * r, c.dy),
          radius: Radius.circular(r),
          clockwise: dx * dy > 0,
        )
        ..lineTo(c.dx + dx * len, c.dy);
    }

    corner(w.topLeft, 1, 1);
    corner(w.topRight, -1, 1);
    corner(w.bottomRight, -1, -1);
    corner(w.bottomLeft, 1, -1);
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.loop != loop ||
      old.lock != lock ||
      old.window != window ||
      old.style != style ||
      old.laser != laser ||
      old.animated != animated;
}
