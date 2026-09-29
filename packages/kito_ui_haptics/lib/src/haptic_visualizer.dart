// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'haptic_pattern.dart';

/// How [KitoHapticVisualizer] draws a pattern.
enum KitoHapticVisualizerStyle {
  /// Taps as capsules, buzzes as filled blocks.
  bars,

  /// A mirrored, audio-style envelope.
  waveform,
}

/// The screen-reader strings for [KitoHapticVisualizer], in English, Swahili and French.
abstract final class KitoHapticStrings {
  /// Consulted first; return null to fall back to the bundled strings.
  static String? Function(String key, Locale locale)? provider;

  /// Keys: `label` (with `{name}`) and `value` (with `{count}` and `{seconds}`).
  static const Map<String, Map<String, String>> bundled = {
    'en': {
      'label': '{name} haptic pattern',
      'value': '{count} beats over {seconds} seconds',
    },
    'sw': {
      'label': 'Mtetemo wa {name}',
      'value': 'Mapigo {count} kwa sekunde {seconds}',
    },
    'fr': {
      'label': 'Motif haptique {name}',
      'value': '{count} battements en {seconds} secondes',
    },
  };

  /// The string for [key] in [locale], falling back to English.
  static String lookup(String key, Locale locale) =>
      provider?.call(key, locale) ??
      bundled[locale.languageCode]?[key] ??
      bundled['en']![key] ??
      key;

  /// The string for [key] around [context], with `{placeholders}` filled.
  static String of(BuildContext context, String key, Map<String, Object> args) {
    var s =
        lookup(key, Localizations.maybeLocaleOf(context) ?? const Locale('en'));
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }
}

/// Draws a [KitoHapticPattern] over time: height is intensity, colour is sharpness (warm for a
/// dull thud, cool for a crisp click). Set [playedAt] when you play the pattern and a playhead
/// sweeps across, lighting each beat as it's felt — so the pattern still reads on a device
/// that can't play it. Time runs from the start edge, so right to left in RTL.
///
/// ```dart
/// DateTime? playedAt;
///
/// KitoHapticVisualizer(KitoHapticPattern.heartbeat, playedAt: playedAt, height: 90);
/// onPressed: () {
///   KitoHaptics.play(KitoHapticPattern.heartbeat);
///   setState(() => playedAt = DateTime.now());
/// }
/// ```
class KitoHapticVisualizer extends StatefulWidget {
  /// Creates a visualizer.
  const KitoHapticVisualizer(
    this.pattern, {
    super.key,
    this.playedAt,
    this.style = KitoHapticVisualizerStyle.bars,
    this.softColor,
    this.sharpColor,
    this.showGrid = true,
    this.height = 80,
  });

  /// What to draw.
  final KitoHapticPattern pattern;

  /// When the pattern was played; null for no playhead.
  final DateTime? playedAt;

  /// Bars or waveform.
  final KitoHapticVisualizerStyle style;

  /// The colour of dull events; a warm coral when null.
  final Color? softColor;

  /// The colour of crisp events; the theme's primary when null.
  final Color? sharpColor;

  /// Draw intensity guides and a tick every tenth of a second.
  final bool showGrid;

  /// The drawing's height.
  final double height;

  /// A smoothed envelope that widens taps so they read at any width.
  static double envelope(KitoHapticPattern pattern, Duration time) {
    var level = 0.0;
    for (final e in pattern.events) {
      if (e.isTransient) {
        final d = (time - e.at).inMicroseconds.abs() / 1e6;
        const spread = 0.035;
        level = math.max(
            level, e.intensity * math.exp(-(d * d) / (2 * spread * spread)));
      } else {
        level = math.max(level, e.intensityAt(time));
      }
    }
    return level;
  }

  /// The sharpness of whichever event is loudest at [time] (0.5 when none).
  static double sharpnessAt(KitoHapticPattern pattern, Duration time) {
    KitoHapticEvent? loudest;
    var best = -1.0;
    for (final e in pattern.events) {
      final v = e.intensityAt(time);
      if (v > best) {
        best = v;
        loudest = e;
      }
    }
    return loudest?.sharpness ?? 0.5;
  }

  /// How lit [event] is at [elapsed]: 1 while the playhead is on it, fading over 0.25 s.
  static double litAmount(KitoHapticEvent event, Duration? elapsed) {
    if (elapsed == null || elapsed < event.at) return 0;
    if (elapsed <= event.end) return 1;
    return math.max(0, 1 - (elapsed - event.end).inMicroseconds / 250000);
  }

  /// The drawn time span: the pattern plus a little breathing room.
  static Duration timelineLength(KitoHapticPattern pattern) {
    final us = math.max(pattern.duration.inMicroseconds * 1.08, 100000);
    return Duration(microseconds: us.round());
  }

  @override
  State<KitoHapticVisualizer> createState() => _KitoHapticVisualizerState();
}

class _KitoHapticVisualizerState extends State<KitoHapticVisualizer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration? _elapsed;
  Duration _startOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(KitoHapticVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playedAt != widget.playedAt ||
        oldWidget.pattern != widget.pattern) {
      _restart();
    }
  }

  void _restart() {
    _ticker.stop();
    final at = widget.playedAt;
    if (at == null) {
      _elapsed = null;
      return;
    }
    final since = DateTime.now().difference(at);
    _startOffset = since.isNegative ? Duration.zero : since;
    _elapsed = _startOffset;
    if (_startOffset < _end) _ticker.start();
  }

  Duration get _end =>
      KitoHapticVisualizer.timelineLength(widget.pattern) +
      const Duration(milliseconds: 300);

  void _tick(Duration elapsed) {
    final now = _startOffset + elapsed;
    setState(() => _elapsed = now);
    if (now >= _end) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final p = widget.pattern;
    final seconds = (p.duration.inMilliseconds / 1000).toStringAsFixed(1);
    return Semantics(
      container: true,
      label: KitoHapticStrings.of(context, 'label', {'name': p.name}),
      value: KitoHapticStrings.of(
          context, 'value', {'count': p.events.length, 'seconds': seconds}),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _VisualizerPainter(
            pattern: p,
            elapsed: _elapsed,
            style: widget.style,
            soft: widget.softColor ?? const Color(0xFFFF7552),
            sharp: widget.sharpColor ?? kito.colors.primary,
            ink: kito.colors.onBackground,
            showGrid: widget.showGrid,
            rtl: context.isRtl,
            reduceMotion: context.reduceMotion,
          ),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.pattern,
    required this.elapsed,
    required this.style,
    required this.soft,
    required this.sharp,
    required this.ink,
    required this.showGrid,
    required this.rtl,
    required this.reduceMotion,
  });

  final KitoHapticPattern pattern;
  final Duration? elapsed;
  final KitoHapticVisualizerStyle style;
  final Color soft;
  final Color sharp;
  final Color ink;
  final bool showGrid;
  final bool rtl;
  final bool reduceMotion;

  Color _color(double sharpness) => Color.lerp(soft, sharp, sharpness)!;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    final plot = Rect.fromLTWH(
        inset, inset, size.width - inset * 2, size.height - inset * 2);
    final length = KitoHapticVisualizer.timelineLength(pattern).inMicroseconds;
    double x(Duration t) {
      final f = t.inMicroseconds / length;
      return rtl ? plot.right - f * plot.width : plot.left + f * plot.width;
    }

    final waveform = style == KitoHapticVisualizerStyle.waveform;
    if (showGrid) _grid(canvas, plot, x, waveform);
    if (waveform) {
      _waveform(canvas, plot, x);
    } else {
      _bars(canvas, plot, x);
    }

    final e = elapsed;
    if (e != null && !e.isNegative && e.inMicroseconds <= length) {
      final px = x(e);
      canvas
        ..drawLine(
            Offset(px, plot.top - 2),
            Offset(px, plot.bottom + 2),
            Paint()
              ..color = ink.withValues(alpha: 0.7)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round)
        ..drawCircle(Offset(px, plot.top - 2), 4, Paint()..color = ink);
    }
  }

  void _grid(
      Canvas canvas, Rect plot, double Function(Duration) x, bool waveform) {
    final dash = Paint()
      ..color = ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final level in [0.25, 0.5, 0.75]) {
      final y = waveform
          ? plot.center.dy - level * plot.height / 2
          : plot.bottom - level * plot.height;
      for (var sx = plot.left; sx < plot.right; sx += 7) {
        canvas.drawLine(
            Offset(sx, y), Offset(math.min(sx + 3, plot.right), y), dash);
      }
    }
    final baseY = waveform ? plot.center.dy : plot.bottom;
    canvas.drawLine(Offset(plot.left, baseY), Offset(plot.right, baseY),
        Paint()..color = ink.withValues(alpha: 0.18));
    final dot = Paint()..color = ink.withValues(alpha: 0.25);
    final length = KitoHapticVisualizer.timelineLength(pattern);
    for (var t = Duration.zero;
        t <= length;
        t += const Duration(milliseconds: 100)) {
      canvas.drawCircle(Offset(x(t), plot.bottom + 4), 1, dot);
    }
  }

  void _bars(Canvas canvas, Rect plot, double Function(Duration) x) {
    // Buzzes first, so taps sit on top.
    for (final e in pattern.events.where((e) => !e.isTransient)) {
      final c = _color(e.sharpness);
      final start = x(e.at), end = x(e.end);
      final h0 = e.intensity * plot.height;
      final h1 = (e.endIntensity ?? e.intensity) * plot.height;
      final shape = Path()
        ..moveTo(start, plot.bottom)
        ..lineTo(start, plot.bottom - h0)
        ..lineTo(end, plot.bottom - h1)
        ..lineTo(end, plot.bottom)
        ..close();
      final lit = KitoHapticVisualizer.litAmount(e, elapsed);
      canvas
        ..drawPath(
            shape,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.withValues(alpha: 0.45 + 0.35 * lit),
                  c.withValues(alpha: 0.08)
                ],
              ).createShader(plot))
        ..drawLine(
            Offset(start, plot.bottom - h0),
            Offset(end, plot.bottom - h1),
            Paint()
              ..color = c
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round);
    }

    final taps = pattern.events.where((e) => e.isTransient).toList();
    final barWidth = (plot.width / math.max(pattern.events.length, 1) * 0.35)
        .clamp(4.0, 8.0);
    for (final e in taps) {
      final c = _color(e.sharpness);
      final lit = KitoHapticVisualizer.litAmount(e, elapsed);
      final grow = reduceMotion ? 1 : 1 + 0.12 * lit;
      final h = math.max(e.intensity * plot.height * grow, barWidth);
      final cx = x(e.at);
      final rect =
          Rect.fromLTWH(cx - barWidth / 2, plot.bottom - h, barWidth, h);
      if (lit > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(3), Radius.circular(barWidth)),
          Paint()
            ..color = c.withValues(alpha: 0.6 * lit)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c, c.withValues(alpha: 0.55)],
          ).createShader(rect),
      );
    }
  }

  void _waveform(Canvas canvas, Rect plot, double Function(Duration) x) {
    final length = KitoHapticVisualizer.timelineLength(pattern);
    final count = math.max(plot.width ~/ 3, 24);
    final top = <Offset>[], bottom = <Offset>[];
    for (var i = 0; i < count; i++) {
      final t = length * (i / (count - 1));
      final level = KitoHapticVisualizer.envelope(pattern, t);
      top.add(Offset(x(t), plot.center.dy - level * plot.height / 2));
      bottom.add(Offset(x(t), plot.center.dy + level * plot.height / 2));
    }
    final shape = Path()..moveTo(x(Duration.zero), plot.center.dy);
    for (final p in top) {
      shape.lineTo(p.dx, p.dy);
    }
    for (final p in bottom.reversed) {
      shape.lineTo(p.dx, p.dy);
    }
    shape.close();

    final mean = pattern.events.isEmpty
        ? 0.5
        : pattern.events.map((e) => e.sharpness).reduce((a, b) => a + b) /
            pattern.events.length;
    final colors = [soft, _color(mean), sharp];
    final shader = LinearGradient(
      colors: rtl ? colors.reversed.toList() : colors,
    ).createShader(plot);

    final e = elapsed;
    canvas.drawPath(
        shape,
        Paint()
          ..shader = shader
          ..color =
              const Color(0xFF000000).withValues(alpha: e == null ? 1 : 0.35));
    if (e != null && e > Duration.zero) {
      final px = x(e);
      canvas
        ..save()
        ..clipRect(rtl
            ? Rect.fromLTRB(px, plot.top - 4, plot.right, plot.bottom + 4)
            : Rect.fromLTRB(plot.left, plot.top - 4, px, plot.bottom + 4))
        ..drawPath(shape, Paint()..shader = shader)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) =>
      old.elapsed != elapsed ||
      old.pattern != pattern ||
      old.style != style ||
      old.soft != soft ||
      old.sharp != sharp ||
      old.rtl != rtl;
}
