// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A three-second burst of confetti falling from the top, as used by celebrating alerts.
///
/// It plays once when it appears, never takes taps, is hidden from screen readers, and draws
/// nothing when the user asked for less motion.
class KitoModalConfetti extends StatefulWidget {
  /// Creates a confetti burst.
  const KitoModalConfetti({
    super.key,
    this.colors = defaultColors,
    this.pieceCount = 90,
    this.duration = const Duration(seconds: 3),
  });

  /// Pink, orange, yellow, green, blue and purple.
  static const defaultColors = [
    Color(0xFFFF3D77),
    Color(0xFFFF8A3D),
    Color(0xFFFFC53D),
    Color(0xFF30A46C),
    Color(0xFF3E63DD),
    Color(0xFF8E4EC6),
  ];

  /// The colours the pieces cycle through.
  final List<Color> colors;

  /// How many pieces fall.
  final int pieceCount;

  /// How long the burst lasts.
  final Duration duration;

  @override
  State<KitoModalConfetti> createState() => _KitoModalConfettiState();
}

class _Piece {
  _Piece(int index) {
    final seed = index.toDouble();
    double unit(double n) {
      final v = math.sin(seed * 12.9898 + n * 78.233) * 43758.5453;
      return (v - v.truncateToDouble()).abs();
    }

    x = unit(1);
    speed = 0.55 + unit(2) * 0.6;
    drift = unit(3) - 0.5;
    spin = unit(4) * 8;
    size = 6 + unit(5) * 6;
    delay = unit(6) * 0.35;
  }

  late final double x, speed, drift, spin, size, delay;
}

class _KitoModalConfettiState extends State<KitoModalConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: widget.duration);
  late List<_Piece> _pieces =
      List.generate(widget.pieceCount, _Piece.new, growable: false);

  @override
  void didUpdateWidget(KitoModalConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pieceCount != widget.pieceCount) {
      _pieces = List.generate(widget.pieceCount, _Piece.new, growable: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _clock.stop();
    } else if (!_clock.isAnimating && _clock.value == 0) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return const SizedBox.expand();
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              clock: _clock,
              pieces: _pieces,
              colors: widget.colors.isEmpty
                  ? KitoModalConfetti.defaultColors
                  : widget.colors,
              seconds: widget.duration.inMilliseconds / 1000,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.clock,
    required this.pieces,
    required this.colors,
    required this.seconds,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final List<_Piece> pieces;
  final List<Color> colors;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value * seconds;
    if (clock.value <= 0 || clock.value >= 1) return;
    final paint = Paint();
    for (var i = 0; i < pieces.length; i++) {
      final piece = pieces[i];
      final local = math.max(t - piece.delay, 0.0);
      final y =
          -20 + local * piece.speed * size.height * 0.9 + 60 * local * local;
      if (y > size.height + 20) continue;
      final x = piece.x * size.width +
          math.sin(local * 3 + piece.spin) * 60 * piece.drift;
      final opacity = (2.6 - local).clamp(0.0, 1.0);
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(local * piece.spin);
      final rect = Rect.fromLTWH(
          -piece.size / 2, -piece.size / 4, piece.size, piece.size / 2);
      canvas
        ..drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.colors != colors;
}
