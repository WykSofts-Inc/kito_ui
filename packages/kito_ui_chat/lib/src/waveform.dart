// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

// MARK: - Maths

/// Waveform maths for voice notes: downsampling to bars, metering and demo shapes.
abstract final class KitoChatWaveform {
  /// Buckets [samples] into exactly [count] bars, each the peak magnitude of its bucket, scaled
  /// so the loudest bar is 1. Fewer samples than bars are stretched.
  static List<double> downsample(List<double> samples, int count) {
    if (count <= 0 || samples.isEmpty) return const [];
    final n = samples.length;
    final bars = List<double>.generate(count, (bar) {
      final start = bar * n ~/ count;
      final end = math.max(start + 1, (bar + 1) * n ~/ count);
      var peak = 0.0;
      for (var i = start; i < math.min(end, n); i++) {
        final v = samples[i].abs();
        if (v.isFinite && v > peak) peak = v;
      }
      return peak;
    });
    return normalized(bars);
  }

  /// Scales [samples] so the loudest is 1. Silence stays silent.
  static List<double> normalized(List<double> samples) {
    final magnitudes = [for (final s in samples) s.isFinite ? s.abs() : 0.0];
    final peak = magnitudes.fold<double>(0, math.max);
    if (peak <= 0) return [for (final _ in magnitudes) 0.0];
    return [for (final m in magnitudes) m / peak];
  }

  /// Maps a power reading in dBFS (≤ 0) to 0–1, treating [floor] and below as silence.
  static double levelFromDecibels(double decibels, {double floor = -50}) {
    if (!decibels.isFinite || floor >= 0) return 0;
    return ((decibels - floor) / -floor).clamp(0.0, 1.0);
  }

  /// A natural-looking waveform for previews and simulated recordings. The same seed gives the
  /// same shape.
  static List<double> placeholder({int count = 40, int seed = 1}) {
    if (count <= 0) return const [];
    var state = seed == 0 ? 0x2545F491 : seed & 0x7FFFFFFF;
    var smooth = 0.5;
    return List<double>.generate(count, (index) {
      // xorshift32, kept in 32 bits so it's the same on every platform.
      state ^= (state << 13) & 0xFFFFFFFF;
      state ^= state >>> 17;
      state ^= (state << 5) & 0xFFFFFFFF;
      state &= 0xFFFFFFFF;
      final random = (state % 10000) / 10000;
      smooth = smooth * 0.45 + random * 0.55;
      final position = index / math.max(1, count - 1);
      final envelope = 0.55 + 0.45 * math.sin(position * math.pi);
      return (smooth * envelope + 0.06).clamp(0.08, 1.0);
    });
  }

  /// A stable seed from a string (a message id), for [placeholder].
  static int seedFor(String text) {
    var hash = 7;
    for (final unit in text.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }
}

// MARK: - Playback speed

/// Voice-note playback speed, cycled by tapping the speed pill.
enum KitoChatPlaybackSpeed {
  /// 1×.
  normal(1),

  /// 1.5×.
  fast(1.5),

  /// 2×.
  fastest(2);

  const KitoChatPlaybackSpeed(this.rate);

  /// The rate multiplier.
  final double rate;

  /// 1× → 1.5× → 2× → 1×.
  KitoChatPlaybackSpeed get next => switch (this) {
        normal => fast,
        fast => fastest,
        fastest => normal,
      };

  /// "1×", "1.5×", "2×".
  String get label => switch (this) {
        normal => '1×',
        fast => '1.5×',
        fastest => '2×',
      };
}

// MARK: - Swipe to reply

/// The rubber-banded offset and threshold for swiping a message to reply.
abstract final class KitoChatSwipeReply {
  /// The furthest a row travels.
  static const limit = 96.0;

  /// How far it must travel to reply.
  static const threshold = 60.0;

  /// Follows the finger at first, then resists; never below zero or past [limit].
  static double offset(double translation) {
    if (translation <= 0 || !translation.isFinite) return 0;
    return limit * (1 - math.exp(-translation / limit));
  }

  /// 0–1 as [offset] approaches the [threshold].
  static double progress(double offset) => (offset / threshold).clamp(0.0, 1.0);
}

// MARK: - View

/// Waveform bars with a playback progress fill that grows from the leading edge. Drag across
/// it to scrub when [onScrub] is set.
///
/// ```dart
/// KitoChatWaveformView(samples: KitoChatWaveform.placeholder(count: 32), progress: 0.4)
/// ```
class KitoChatWaveformView extends StatelessWidget {
  /// Creates a waveform.
  const KitoChatWaveformView({
    super.key,
    required this.samples,
    this.progress = 0,
    this.activeColor,
    this.inactiveColor,
    this.barWidth = 3,
    this.spacing = 2,
    this.height = 26,
    this.onScrub,
  });

  /// Bar heights, 0–1.
  final List<double> samples;

  /// How much has played, 0–1.
  final double progress;

  /// Played bars; the primary colour when null.
  final Color? activeColor;

  /// Unplayed bars; a faint text colour when null.
  final Color? inactiveColor;

  /// The widest a bar gets; bars narrow to fit.
  final double barWidth;

  /// Gap between bars.
  final double spacing;

  /// The height of the tallest bar.
  final double height;

  /// Called with 0–1 while dragging across the bars.
  final ValueChanged<double>? onScrub;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final rtl = context.isRtl;
    final active = activeColor ?? kito.colors.primary;
    final inactive =
        inactiveColor ?? kito.colors.onSurface.withValues(alpha: 0.25);
    Widget bars = TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0.0, 1.0)),
      duration: KitoMotion.of(context, const Duration(milliseconds: 120)),
      builder: (context, p, _) => CustomPaint(
        painter: _WaveformPainter(
          samples: samples,
          progress: p,
          active: active,
          inactive: inactive,
          barWidth: barWidth,
          spacing: spacing,
          rtl: rtl,
        ),
        child: SizedBox(width: double.infinity, height: height),
      ),
    );
    if (onScrub != null) {
      final painted = bars;
      bars = Builder(builder: (context) {
        void scrub(Offset local) {
          final box = context.findRenderObject();
          if (box is! RenderBox || !box.hasSize || box.size.width <= 0) return;
          final width = box.size.width;
          final x = rtl ? width - local.dx : local.dx;
          onScrub!((x / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => scrub(d.localPosition),
          onHorizontalDragUpdate: (d) => scrub(d.localPosition),
          onTapDown: (d) => scrub(d.localPosition),
          child: painted,
        );
      });
    }
    return ExcludeSemantics(child: SizedBox(height: height, child: bars));
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.active,
    required this.inactive,
    required this.barWidth,
    required this.spacing,
    required this.rtl,
  });

  final List<double> samples;
  final double progress;
  final Color active;
  final Color inactive;
  final double barWidth;
  final double spacing;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final count = samples.length;
    final fitted = math.max(
        1.0, math.min(barWidth, (size.width - spacing * (count - 1)) / count));
    final paint = Paint()..isAntiAlias = true;
    for (var i = 0; i < count; i++) {
      final played = i / count < progress;
      paint.color = played ? active : inactive;
      final h = math.max(fitted, size.height * samples[i].clamp(0.12, 1.0));
      final start = i * (fitted + spacing);
      final left = rtl ? size.width - start - fitted : start;
      final rect = Rect.fromLTWH(left, (size.height - h) / 2, fitted, h);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(fitted / 2)), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.samples != samples ||
      old.active != active ||
      old.inactive != inactive ||
      old.rtl != rtl ||
      old.barWidth != barWidth ||
      old.spacing != spacing;
}
