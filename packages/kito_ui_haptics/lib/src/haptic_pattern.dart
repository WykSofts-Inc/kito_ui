// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'haptics.dart';

double _clamp(double v) => v.clamp(0.0, 1.0);
double _seconds(Duration d) =>
    d.inMicroseconds / Duration.microsecondsPerSecond;
Duration _duration(double seconds) =>
    Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round());

/// One beat in a [KitoHapticPattern]: a short tap or a held buzz, with an intensity and a
/// sharpness, both 0–1.
@immutable
class KitoHapticEvent {
  /// A tap [at] a moment in the pattern.
  KitoHapticEvent.tap(Duration at,
      {double intensity = 1, double sharpness = 0.5})
      : at = at.isNegative ? Duration.zero : at,
        isTransient = true,
        length = transientLength,
        intensity = _clamp(intensity),
        sharpness = _clamp(sharpness),
        endIntensity = null;

  /// A buzz from [at] lasting [duration], optionally ramping to [endIntensity].
  KitoHapticEvent.hold(
    Duration at, {
    required Duration duration,
    double intensity = 1,
    double sharpness = 0.5,
    double? endIntensity,
  })  : at = at.isNegative ? Duration.zero : at,
        isTransient = false,
        length = duration < const Duration(milliseconds: 10)
            ? const Duration(milliseconds: 10)
            : duration,
        intensity = _clamp(intensity),
        sharpness = _clamp(sharpness),
        endIntensity = endIntensity == null ? null : _clamp(endIntensity);

  /// How long a tap counts for when drawing and sampling.
  static const transientLength = Duration(milliseconds: 40);

  /// When it starts, from the start of the pattern.
  final Duration at;

  /// True for a tap, false for a buzz.
  final bool isTransient;

  /// How long it lasts; [transientLength] for a tap.
  final Duration length;

  /// How strong it feels, 0–1.
  final double intensity;

  /// How crisp it feels: 0 is a dull thud, 1 a sharp click.
  final double sharpness;

  /// For a buzz, the intensity it fades to by its end; null holds [intensity].
  final double? endIntensity;

  /// When it ends.
  Duration get end => at + length;

  /// The felt intensity at [moment], 0 outside the event. Taps decay linearly so they draw as
  /// spikes, not blocks.
  double intensityAt(Duration moment) {
    if (moment < at || moment > end) return 0;
    final progress = _seconds(moment - at) / _seconds(length);
    if (isTransient) return intensity * math.max(0, 1 - progress);
    final e = endIntensity;
    if (e == null) return intensity;
    return intensity + (e - intensity) * progress.clamp(0.0, 1.0);
  }

  /// A copy moved by [offset] and with intensities scaled by [factor].
  KitoHapticEvent shifted(Duration offset, {double factor = 1}) => isTransient
      ? KitoHapticEvent.tap(at + offset,
          intensity: intensity * factor, sharpness: sharpness)
      : KitoHapticEvent.hold(at + offset,
          duration: length,
          intensity: intensity * factor,
          sharpness: sharpness,
          endIntensity: endIntensity == null ? null : endIntensity! * factor);

  @override
  bool operator ==(Object other) =>
      other is KitoHapticEvent &&
      other.at == at &&
      other.isTransient == isTransient &&
      other.length == length &&
      other.intensity == intensity &&
      other.sharpness == sharpness &&
      other.endIntensity == endIntensity;

  @override
  int get hashCode =>
      Object.hash(at, isTransient, length, intensity, sharpness, endIntensity);

  @override
  String toString() => isTransient
      ? 'tap(${at.inMilliseconds}ms, $intensity, $sharpness)'
      : 'hold(${at.inMilliseconds}ms, ${length.inMilliseconds}ms, $intensity → ${endIntensity ?? intensity})';
}

/// One platform haptic call standing in for part of a pattern.
@immutable
class KitoHapticImpact {
  /// Creates an impact.
  const KitoHapticImpact(
      {required this.at, required this.intensity, required this.style});

  /// When it fires.
  final Duration at;

  /// The felt intensity it approximates.
  final double intensity;

  /// Which platform feedback plays.
  final KitoHapticImpactStyle style;

  @override
  bool operator ==(Object other) =>
      other is KitoHapticImpact &&
      other.at == at &&
      other.intensity == intensity &&
      other.style == style;

  @override
  int get hashCode => Object.hash(at, intensity, style);

  @override
  String toString() =>
      'KitoHapticImpact(${at.inMilliseconds}ms, ${style.name}, $intensity)';
}

/// A named sequence of haptic events — play it with [KitoHaptics.play] and draw it with
/// `KitoHapticVisualizer`. Start from a preset or build your own.
///
/// ```dart
/// final drumroll = KitoHapticPattern('Drumroll', [
///   KitoHapticEvent.tap(Duration.zero, intensity: 0.6, sharpness: 0.8),
///   KitoHapticEvent.tap(const Duration(milliseconds: 80), intensity: 0.7, sharpness: 0.8),
///   KitoHapticEvent.hold(const Duration(milliseconds: 160),
///       duration: const Duration(milliseconds: 500), intensity: 0.2, endIntensity: 1),
/// ]);
/// ```
@immutable
class KitoHapticPattern {
  /// Creates a pattern; events are sorted by start time.
  KitoHapticPattern(this.name, List<KitoHapticEvent> events)
      : events = List<KitoHapticEvent>.unmodifiable(
            <KitoHapticEvent>[...events]..sort((a, b) => a.at.compareTo(b.at)));

  /// A display name.
  final String name;

  /// The events, sorted by start time.
  final List<KitoHapticEvent> events;

  /// When the last event finishes.
  Duration get duration => events.fold(
      Duration.zero, (longest, e) => e.end > longest ? e.end : longest);

  /// The strongest felt intensity of any event at [moment].
  double intensityAt(Duration moment) =>
      events.fold(0.0, (m, e) => math.max(m, e.intensityAt(moment)));

  /// [count] evenly spaced intensity samples across the pattern, for drawing a waveform.
  List<double> samples(int count) {
    final total = _seconds(duration);
    if (count <= 1 || total <= 0) return List.filled(math.max(count, 0), 0);
    return [
      for (var i = 0; i < count; i++)
        intensityAt(_duration(total * i / (count - 1)))
    ];
  }

  /// The pattern played [times] times, [gap] apart.
  KitoHapticPattern repeated(int times,
      {Duration gap = const Duration(milliseconds: 200)}) {
    if (times <= 1) return this;
    final length = duration + gap;
    return KitoHapticPattern(name, [
      for (var round = 0; round < times; round++)
        for (final e in events) e.shifted(length * round),
    ]);
  }

  /// Every intensity scaled by [factor] — 0.5 for a gentler version.
  KitoHapticPattern scaled(double factor) => KitoHapticPattern(
      name, [for (final e in events) e.shifted(Duration.zero, factor: factor)]);

  /// The platform calls that play this pattern: one per tap, and one every [buzzInterval]
  /// through a buzz. Flutter's haptics have no intensity control, so strength picks the impact
  /// weight and very crisp, light events become selection clicks.
  List<KitoHapticImpact> impacts(
      {Duration buzzInterval = const Duration(milliseconds: 60)}) {
    final out = <KitoHapticImpact>[];
    for (final e in events) {
      if (e.isTransient) {
        out.add(KitoHapticImpact(
            at: e.at,
            intensity: e.intensity,
            style: KitoHapticImpactStyle.forEvent(e.intensity, e.sharpness)));
      } else {
        final steps = math.max(
            (_seconds(e.length) / _seconds(buzzInterval) - 1e-9).ceil(), 1);
        for (var s = 0; s < steps; s++) {
          final moment = e.at + buzzInterval * s;
          final level = e.intensityAt(moment);
          out.add(KitoHapticImpact(
              at: moment,
              intensity: level,
              style: KitoHapticImpactStyle.forEvent(level, e.sharpness)));
        }
      }
    }
    return out.where((i) => i.intensity > 0.02).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
  }

  static const _ms = Duration(milliseconds: 1);

  /// Lub-dub, twice — a living pulse.
  static final heartbeat = KitoHapticPattern('Heartbeat', [
    KitoHapticEvent.tap(Duration.zero, intensity: 1, sharpness: 0.3),
    KitoHapticEvent.tap(_ms * 140, intensity: 0.6, sharpness: 0.2),
    KitoHapticEvent.tap(_ms * 800, intensity: 1, sharpness: 0.3),
    KitoHapticEvent.tap(_ms * 940, intensity: 0.6, sharpness: 0.2),
  ]);

  /// Three rising, brightening taps — "done, and it went well."
  static final successChime = KitoHapticPattern('Success chime', [
    KitoHapticEvent.tap(Duration.zero, intensity: 0.5, sharpness: 0.4),
    KitoHapticEvent.tap(_ms * 100, intensity: 0.75, sharpness: 0.6),
    KitoHapticEvent.tap(_ms * 220, intensity: 1, sharpness: 0.9),
    KitoHapticEvent.hold(_ms * 220,
        duration: _ms * 180, intensity: 0.35, sharpness: 0.8, endIntensity: 0),
  ]);

  /// Eight crisp, even clicks, like a dial turning.
  static final ticks = ticksOf(8, const Duration(milliseconds: 70));

  /// [count] crisp clicks, [interval] apart.
  static KitoHapticPattern ticksOf(int count, Duration interval) =>
      KitoHapticPattern('Ticks', [
        for (var i = 0; i < math.max(count, 1); i++)
          KitoHapticEvent.tap(interval * i, intensity: 0.55, sharpness: 1),
      ]);

  /// A low, heavy rumble with a few bumps on top.
  static final rumble = KitoHapticPattern('Rumble', [
    KitoHapticEvent.hold(Duration.zero,
        duration: _ms * 900, intensity: 0.8, sharpness: 0.05),
    KitoHapticEvent.tap(_ms * 150, intensity: 0.7, sharpness: 0.1),
    KitoHapticEvent.tap(_ms * 450, intensity: 0.9, sharpness: 0.1),
    KitoHapticEvent.tap(_ms * 720, intensity: 0.6, sharpness: 0.1),
  ]);

  /// Knock, knock — two firm taps.
  static final knock = KitoHapticPattern('Knock', [
    KitoHapticEvent.tap(Duration.zero, intensity: 1, sharpness: 0.55),
    KitoHapticEvent.tap(_ms * 180, intensity: 0.9, sharpness: 0.55),
  ]);

  /// A buzz that swells from nothing to full.
  static final rampUp = KitoHapticPattern('Ramp up', [
    KitoHapticEvent.hold(Duration.zero,
        duration: _ms * 800, intensity: 0.05, sharpness: 0.4, endIntensity: 1),
    KitoHapticEvent.tap(_ms * 800, intensity: 1, sharpness: 0.8),
  ]);

  /// A strong buzz that fades away.
  static final rampDown = KitoHapticPattern('Ramp down', [
    KitoHapticEvent.tap(Duration.zero, intensity: 1, sharpness: 0.8),
    KitoHapticEvent.hold(Duration.zero,
        duration: _ms * 800, intensity: 1, sharpness: 0.4, endIntensity: 0),
  ]);

  /// A sharp double buzz then a thud — "that didn't work."
  static final failure = KitoHapticPattern('Failure', [
    KitoHapticEvent.tap(Duration.zero, intensity: 0.9, sharpness: 0.9),
    KitoHapticEvent.tap(_ms * 90, intensity: 0.9, sharpness: 0.9),
    KitoHapticEvent.hold(_ms * 200,
        duration: _ms * 250, intensity: 0.7, sharpness: 0.1, endIntensity: 0.1),
  ]);

  /// A soft double tap, like a nudge on the shoulder.
  static final nudge = KitoHapticPattern('Nudge', [
    KitoHapticEvent.tap(Duration.zero, intensity: 0.45, sharpness: 0.25),
    KitoHapticEvent.tap(_ms * 120, intensity: 0.45, sharpness: 0.25),
  ]);

  /// Every built-in pattern, for pickers and galleries.
  static final presets = List<KitoHapticPattern>.unmodifiable([
    heartbeat,
    successChime,
    ticks,
    rumble,
    knock,
    rampUp,
    rampDown,
    failure,
    nudge,
  ]);

  @override
  bool operator ==(Object other) =>
      other is KitoHapticPattern &&
      other.name == name &&
      listEquals(other.events, events);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(events));

  @override
  String toString() => 'KitoHapticPattern($name, ${events.length} events)';
}
