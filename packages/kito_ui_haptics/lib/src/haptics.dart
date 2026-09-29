// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/services.dart';

import 'haptic_pattern.dart';

/// The platform haptics Flutter can play.
enum KitoHapticImpactStyle {
  /// A crisp, light tick — pickers and toggles.
  selection,

  /// A light tap.
  light,

  /// A medium tap.
  medium,

  /// A heavy tap.
  heavy,

  /// The system vibration (long on Android, a buzz on iOS).
  vibrate;

  /// The weight that best stands in for an event of [intensity] and [sharpness]: very crisp,
  /// light events become selection ticks; otherwise strength picks light, medium or heavy.
  static KitoHapticImpactStyle forEvent(double intensity, double sharpness) {
    if (sharpness >= 0.85 && intensity <= 0.6) return selection;
    if (intensity < 0.4) return light;
    if (intensity < 0.75) return medium;
    return heavy;
  }

  /// Plays it now, ignoring [KitoHaptics.isEnabled].
  Future<void> fire() => switch (this) {
        selection => HapticFeedback.selectionClick(),
        light => HapticFeedback.lightImpact(),
        medium => HapticFeedback.mediumImpact(),
        heavy => HapticFeedback.heavyImpact(),
        vibrate => HapticFeedback.vibrate(),
      };
}

/// Semantic haptics — call what you mean, not a platform feedback type.
///
/// ```dart
/// onPressed: () {
///   save();
///   KitoHaptics.success();
/// }
/// ```
///
/// Everything respects [isEnabled], so one settings toggle silences every haptic in the app.
abstract final class KitoHaptics {
  /// The global switch. Bind a settings toggle to it.
  static bool isEnabled = true;

  static int _generation = 0;
  static final List<Timer> _timers = [];
  static Completer<void>? _playing;

  static const _ms = Duration(milliseconds: 1);

  /// "Done, and it went well" — a light tap rising into a medium one.
  static Future<void> success() => play(_success);

  /// "Careful" — two even medium taps.
  static Future<void> warning() => play(_warning);

  /// "That didn't work" — three heavy taps.
  static Future<void> error() => play(_error);

  /// A selection moved — pickers, segmented controls, sliders snapping.
  static Future<void> selection() => impact(KitoHapticImpactStyle.selection);

  /// A single tap of [style].
  static Future<void> impact(
      [KitoHapticImpactStyle style = KitoHapticImpactStyle.medium]) async {
    if (!isEnabled) return;
    await style.fire();
  }

  static final _success = KitoHapticPattern('Success', [
    KitoHapticEvent.tap(Duration.zero, intensity: 0.35, sharpness: 0.5),
    KitoHapticEvent.tap(_ms * 110, intensity: 0.7, sharpness: 0.6),
  ]);

  static final _warning = KitoHapticPattern('Warning', [
    KitoHapticEvent.tap(Duration.zero, intensity: 0.7, sharpness: 0.5),
    KitoHapticEvent.tap(_ms * 160, intensity: 0.7, sharpness: 0.5),
  ]);

  static final _error = KitoHapticPattern('Error', [
    KitoHapticEvent.tap(Duration.zero, intensity: 0.9, sharpness: 0.5),
    KitoHapticEvent.tap(_ms * 100, intensity: 0.9, sharpness: 0.5),
    KitoHapticEvent.tap(_ms * 200, intensity: 0.8, sharpness: 0.5),
  ]);

  /// True while a pattern is playing.
  static bool get isPlaying => _playing != null;

  /// Plays [pattern] as a timed sequence of platform haptics (see
  /// [KitoHapticPattern.impacts]). Starting a pattern stops the one before. The future
  /// completes when it finishes or is stopped.
  static Future<void> play(KitoHapticPattern pattern) {
    stop();
    if (!isEnabled || pattern.events.isEmpty) return Future.value();
    final generation = ++_generation;
    final done = _playing = Completer<void>();
    for (final impact in pattern.impacts()) {
      void fire() {
        if (generation == _generation && isEnabled) impact.style.fire();
      }

      if (impact.at <= Duration.zero) {
        fire();
      } else {
        _timers.add(Timer(impact.at, fire));
      }
    }
    _timers.add(Timer(pattern.duration, () {
      if (generation == _generation) _finish();
    }));
    return done.future;
  }

  /// Stops a pattern that's still playing.
  static void stop() {
    _generation++;
    _finish();
  }

  static void _finish() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    final done = _playing;
    _playing = null;
    if (done != null && !done.isCompleted) done.complete();
  }
}
