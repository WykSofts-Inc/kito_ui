// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'parts.dart';

/// The assistant's presence: a glassy orb of slowly drifting colour that breathes while it
/// works. With Reduce Motion it holds still.
///
/// ```dart
/// const KitoAiOrb(size: 96)
/// KitoAiOrb(size: 22, isActive: isGenerating, tint: Colors.orange)
/// ```
class KitoAiOrb extends StatefulWidget {
  /// Creates an orb.
  const KitoAiOrb({
    super.key,
    this.size = 64,
    this.isActive = true,
    this.animatesWhenIdle = true,
    this.colors,
    this.tint,
  });

  /// Its diameter.
  final double size;

  /// Animates faster and breathes when true; drifts gently when false.
  final bool isActive;

  /// Pass false to hold still while not active — for many small orbs in a list.
  final bool animatesWhenIdle;

  /// The orb's colours; by default the tint with violet, pink and cyan.
  final List<Color>? colors;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  State<KitoAiOrb> createState() => _KitoAiOrbState();
}

class _KitoAiOrbState extends State<KitoAiOrb>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _time = ValueNotifier(0);
  Duration _base = Duration.zero;
  Duration _last = Duration.zero;

  void _tick(Duration elapsed) {
    _last = elapsed;
    _time.value = (_base + elapsed).inMicroseconds / 1e6;
  }

  bool _paused(BuildContext context) =>
      context.reduceMotion || (!widget.isActive && !widget.animatesWhenIdle);

  void _sync() {
    final paused = _paused(context);
    if (paused && _ticker.isActive) {
      _base += _last;
      _last = Duration.zero;
      _ticker.stop();
    } else if (!paused && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KitoAiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final base = widget.colors ?? aiOrbColors(aiAccent(theme, widget.tint));
    final palette = base.length >= 4
        ? base
        : [...base, ...aiOrbColors(aiAccent(theme, widget.tint))];
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _OrbPainter(
              time: _time,
              colors: palette,
              isActive: widget.isActive,
              breathes: widget.isActive && !context.reduceMotion,
              rtl: context.isRtl,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.time,
    required this.colors,
    required this.isActive,
    required this.breathes,
    required this.rtl,
  }) : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;
  final bool isActive;
  final bool breathes;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final speed = isActive ? 1.0 : 0.35;
    final d = size.shortestSide;
    final center = size.center(Offset.zero);
    final scale = breathes ? 1 + 0.045 * math.sin(t * 2.4) : 1.0;
    final radius = d / 2 * scale;
    final circle = Rect.fromCircle(center: center, radius: radius);
    final direction = rtl ? -1.0 : 1.0;

    // Glow.
    canvas.drawCircle(
      center.translate(0, d * 0.06),
      radius * 0.92,
      Paint()
        ..color = colors.first.withValues(alpha: isActive ? 0.35 : 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.14),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    final rotation = (t * 40 * speed * direction) * math.pi / 180;
    canvas.drawRect(
      circle,
      Paint()
        ..shader = SweepGradient(
          colors: colors,
          transform: GradientRotation(rotation),
        ).createShader(circle),
    );
    for (var i = 0; i < 3; i++) {
      final phase = i * 2.1;
      final rate = (0.9 + i * 0.35) * speed;
      final r = d * 0.22;
      final offset = Offset(math.cos(t * rate + phase) * r * direction,
          math.sin(t * rate * 1.3 + phase) * r);
      canvas.drawCircle(
        center + offset,
        d * 0.31,
        Paint()
          ..color = colors[(i + 1) % colors.length].withValues(alpha: 0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.14),
      );
    }
    canvas.drawRect(
      circle,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.8,
          colors: [
            Colors.white.withValues(alpha: 0.7),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(circle),
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      radius - math.max(0.75, d * 0.02) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.75, d * 0.02)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.05),
          ],
        ).createShader(circle),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.colors != colors ||
      old.isActive != isActive ||
      old.breathes != breathes ||
      old.rtl != rtl;
}

/// A soft band of light sweeping across [child] in the reading direction — for "Thinking…" and
/// running tool chips. Holds still with Reduce Motion or when [isActive] is false.
class KitoAiShimmer extends StatefulWidget {
  /// Wraps [child].
  const KitoAiShimmer({
    super.key,
    required this.child,
    this.isActive = true,
    this.period = const Duration(milliseconds: 1600),
  });

  /// What shimmers.
  final Widget child;

  /// Turns the sweep on and off.
  final bool isActive;

  /// One sweep.
  final Duration period;

  @override
  State<KitoAiShimmer> createState() => _KitoAiShimmerState();
}

class _KitoAiShimmerState extends State<KitoAiShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);

  void _sync() {
    final run = widget.isActive && !context.reduceMotion;
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KitoAiShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.period;
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || context.reduceMotion) return widget.child;
    final rtl = context.isRtl;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final phase = rtl ? 1 - _controller.value : _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final band = math.max(40.0, bounds.width * 0.45);
            final travel = bounds.width + band * 2;
            final start = phase * travel - band;
            final rect = Rect.fromLTWH(start, 0, band, bounds.height);
            return LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0),
              ],
              tileMode: TileMode.decal,
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}

/// "Thinking…" with a small orb and a light sweep — shown before the first token arrives.
///
/// ```dart
/// const KitoAiThinkingIndicator()
/// const KitoAiThinkingIndicator(label: 'Reading your file')
/// ```
class KitoAiThinkingIndicator extends StatelessWidget {
  /// Creates the indicator.
  const KitoAiThinkingIndicator(
      {super.key, this.label = 'Thinking', this.tint, this.showsOrb = true});

  /// The word before the ellipsis.
  final String label;

  /// Replaces the theme's primary colour for the orb.
  final Color? tint;

  /// Shows the small orb before the text.
  final bool showsOrb;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      liveRegion: true,
      label: '$label…',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showsOrb) ...[
            KitoAiOrb(size: 22, tint: tint),
            SizedBox(width: theme.spacing.sm),
          ],
          KitoAiShimmer(
            child: Text('$label…',
                style: theme.typography.label
                    .copyWith(color: aiMuted(theme, 0.55))),
          ),
        ],
      ),
    );
  }
}

/// The blinking bar that follows streamed text. Solid with Reduce Motion.
class KitoAiStreamingCursor extends StatefulWidget {
  /// Creates a cursor.
  const KitoAiStreamingCursor({super.key, this.tint, this.height = 16});

  /// Its colour; the text colour when null.
  final Color? tint;

  /// Its height; about one line of body text.
  final double height;

  @override
  State<KitoAiStreamingCursor> createState() => _KitoAiStreamingCursorState();
}

class _KitoAiStreamingCursorState extends State<KitoAiStreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      lowerBound: 0.25);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: widget.height / 2,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.tint ?? theme.colors.onSurface,
            borderRadius: BorderRadius.circular(widget.height),
          ),
        ),
      ),
    );
  }
}
