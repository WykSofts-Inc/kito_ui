// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'illustration.dart';

/// Draws a [KitoEmptyStateIllustration] and keeps it moving: the tile follows its motion,
/// satellites bob, sparkles twinkle and the orbit turns. It springs in when it appears.
///
/// With Reduce Motion on it's drawn once, still, in a pleasant resting pose. It also stops
/// ticking when its route is covered (via [TickerMode]).
class KitoEmptyStateIllustrationView extends StatefulWidget {
  /// Draws [illustration] in a [size]-point square.
  const KitoEmptyStateIllustrationView(this.illustration,
      {super.key, this.size = 180, this.animated = true});

  /// What to draw.
  final KitoEmptyStateIllustration illustration;

  /// Width and height.
  final double size;

  /// False draws it still even when motion is allowed.
  final bool animated;

  @override
  State<KitoEmptyStateIllustrationView> createState() =>
      _KitoEmptyStateIllustrationViewState();
}

class _KitoEmptyStateIllustrationViewState
    extends State<KitoEmptyStateIllustrationView>
    with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  final ValueNotifier<double> _time = ValueNotifier(0.6);

  void _tick(Duration elapsed) =>
      _time.value = 0.6 + elapsed.inMicroseconds / 1e6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(KitoEmptyStateIllustrationView old) {
    super.didUpdateWidget(old);
    _update();
  }

  void _update() {
    final still = context.reduceMotion || !widget.animated;
    if (still) {
      if (_ticker.isActive) _ticker.stop();
      _time.value = 0.6;
      _entrance.duration = const Duration(milliseconds: 250);
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    if (_entrance.status == AnimationStatus.dismissed) _entrance.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _entrance.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final reduce = context.reduceMotion;
    final dark = theme.brightness == Brightness.dark;
    final ill = widget.illustration;
    final base = ill.colors.isEmpty
        ? [theme.colors.primary, theme.colors.primary.withValues(alpha: 0.7)]
        : ill.colors;
    final colors =
        base.length == 1 ? [base[0], base[0].withValues(alpha: 0.75)] : base;
    final s = widget.size;

    final entrance = CurvedAnimation(
        parent: _entrance,
        curve: reduce
            ? Curves.easeOut
            : const KitoSpringCurve(damping: 0.6, stiffness: 11));

    return Semantics(
      image: true,
      label: ill.name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: s,
        child: AnimatedBuilder(
          animation: entrance,
          builder: (context, child) => Opacity(
            opacity: _entrance.value.clamp(0.0, 1.0),
            child: Transform.scale(
                scale: reduce ? 1 : 0.7 + 0.3 * entrance.value, child: child),
          ),
          child: ValueListenableBuilder<double>(
            valueListenable: _time,
            builder: (context, t, _) => _Scene(
              illustration: ill,
              colors: colors,
              size: s,
              time: t,
              dark: dark,
              theme: theme,
              reduce: reduce || !widget.animated,
            ),
          ),
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({
    required this.illustration,
    required this.colors,
    required this.size,
    required this.time,
    required this.dark,
    required this.theme,
    required this.reduce,
  });

  final KitoEmptyStateIllustration illustration;
  final List<Color> colors;
  final double size;
  final double time;
  final bool dark;
  final KitoTheme theme;
  final bool reduce;

  Widget _at(Offset unit, double extent, Widget child) {
    final c = size / 2;
    return Positioned(
      left: c + unit.dx * size - extent / 2,
      top: c + unit.dy * size - extent / 2,
      width: extent,
      height: extent,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pose = KitoEmptyStatePose.at(time, illustration.motion);
    final first = colors.first;
    final last = colors.last;
    final side = size * 0.4;

    final satellites = illustration.satellites.take(4).toList();
    const sparkleSpots = [
      Offset(-0.3, 0.18),
      Offset(0.36, -0.32),
      Offset(0.12, -0.4),
      Offset(-0.4, -0.1),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glow.
        Positioned.fill(
          child: Transform.scale(
            scale: 1 + 0.05 * math.sin(time * 1.3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  first.withValues(alpha: dark ? 0.45 : 0.3),
                  first.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        ),
        // Orbit.
        _at(
          Offset.zero,
          size * 0.86,
          Transform.rotate(
            angle: time * 8 * math.pi / 180,
            child: CustomPaint(
                painter: _DashedCirclePainter(last.withValues(alpha: 0.28))),
          ),
        ),
        // Disc.
        _at(
          Offset.zero,
          size * 0.64,
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  first.withValues(alpha: 0.16),
                  last.withValues(alpha: 0.06)
                ],
              ),
              border: Border.all(
                  color: const Color(0xFFFFFFFF)
                      .withValues(alpha: dark ? 0.08 : 0.6)),
            ),
          ),
        ),
        // Satellites.
        for (var i = 0; i < satellites.length; i++)
          _satellite(satellites[i], i),
        // Sparkles.
        for (var i = 0; i < 4; i++) _sparkle(i, sparkleSpots[i]),
        // Shadow under the tile.
        _at(
          const Offset(0, 0.26),
          size * 0.3 * (1 + pose.y * 3),
          Center(
            child: Container(
              height: size * 0.05,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000)
                        .withValues(alpha: dark ? 0.35 : 0.12),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tile.
        _at(
          Offset(pose.x, pose.y),
          side * 1.4,
          Center(child: _tile(pose, side)),
        ),
      ],
    );
  }

  Widget _tile(KitoEmptyStatePose pose, double side) {
    final radius = BorderRadius.circular(side * 0.3);
    final swing = illustration.motion == KitoEmptyStateMotion.swing;
    Widget tile = SizedBox.square(
      dimension: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                border: Border.all(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.45),
                    blurRadius: side * 0.22,
                    offset: Offset(0, side * 0.14),
                  ),
                ],
              ),
            ),
          ),
          // Gloss along the top edge.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    const Color(0xFFFFFFFF).withValues(alpha: 0.35),
                    const Color(0x00FFFFFF),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              illustration.icon,
              size: side * 0.42,
              color: const Color(0xFFFFFFFF),
              shadows: [
                Shadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1)),
              ],
            ),
          ),
          if (illustration.badge case final badge?)
            PositionedDirectional(
              top: -side * 0.12,
              end: -side * 0.12,
              child: Container(
                width: side * 0.34,
                height: side * 0.34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colors.danger,
                  border: Border.all(
                      color: theme.colors.background, width: side * 0.045),
                ),
                child: Icon(badge,
                    size: side * 0.18, color: const Color(0xFFFFFFFF)),
              ),
            ),
        ],
      ),
    );

    tile = Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.diagonal3Values(
          pose.scale * (2 - pose.squash), pose.scale * pose.squash, 1),
      child: tile,
    );
    return Transform.rotate(
      angle: pose.rotation * math.pi / 180,
      alignment: swing ? Alignment.topCenter : Alignment.center,
      child: tile,
    );
  }

  Widget _satellite(IconData icon, int index) {
    final spot = KitoEmptyStatePose.satellite(index);
    final chip = size * (index.isEven ? 0.17 : 0.14);
    final bob = KitoEmptyStatePose.bob(index, time);
    return _at(
      Offset(spot.dx, spot.dy + bob),
      chip,
      Transform.rotate(
        angle: math.sin(time + index) * 8 * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colors.surface,
            border: Border.all(color: colors.first.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF000000).withValues(alpha: dark ? 0.4 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon,
                size: chip * 0.5, color: colors[index % colors.length]),
          ),
        ),
      ),
    );
  }

  Widget _sparkle(int index, Offset spot) {
    final lit =
        reduce ? 0.7 : KitoEmptyStatePose.twinkle(index, time).toDouble();
    final star = index.isEven;
    final extent = size * (star ? 0.08 : 0.03);
    final color = colors[index % colors.length]
        .withValues(alpha: (0.4 + 0.6 * lit).clamp(0.0, 1.0));
    return _at(
      spot,
      extent,
      Transform.scale(
        scale: 0.5 + 0.5 * lit,
        child: CustomPaint(painter: _SparklePainter(color, star: star)),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    final radius = size.width / 2 - 0.6;
    final centre = size.center(Offset.zero);
    final circumference = 2 * math.pi * radius;
    const dash = 2.0, gap = 6.0;
    final count = (circumference / (dash + gap)).floor();
    for (var i = 0; i < count; i++) {
      final start = i * (dash + gap) / radius;
      canvas.drawArc(Rect.fromCircle(center: centre, radius: radius), start,
          dash / radius, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color, {required this.star});
  final Color color;
  final bool star;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    if (!star) {
      canvas.drawCircle(c, r, paint);
      return;
    }
    // A four-pointed sparkle with pinched sides.
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) =>
      old.color != color || old.star != star;
}
