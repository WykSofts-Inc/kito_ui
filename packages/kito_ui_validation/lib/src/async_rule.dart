// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Where a field's validation stands.
enum KitoValidationStatus {
  /// Nothing has been checked yet, or the value is empty.
  idle,

  /// An async check is in flight.
  validating,

  /// Every rule passed.
  valid,

  /// A rule failed.
  invalid,
}

/// A check that needs a round trip — "is this username taken?", "is this promo code live?".
///
/// ```dart
/// final available = KitoAsyncValidationRule.available(
///   (name) => api.isUsernameFree(name),
///   message: 'That username is taken',
/// );
/// ```
@immutable
class KitoAsyncValidationRule {
  /// A rule whose [check] returns an error message, or null when the value is fine.
  const KitoAsyncValidationRule(this.check,
      {this.debounce = const Duration(milliseconds: 400)});

  /// A rule that fails with [message] when [isAvailable] resolves to false.
  factory KitoAsyncValidationRule.available(
    Future<bool> Function(String value) isAvailable, {
    String message = "That one isn't available",
    Duration debounce = const Duration(milliseconds: 400),
  }) =>
      KitoAsyncValidationRule(
        (v) async => await isAvailable(v) ? null : message,
        debounce: debounce,
      );

  /// Resolves to an error message, or null.
  final Future<String?> Function(String value) check;

  /// How long typing must pause before [check] runs.
  final Duration debounce;
}

/// Runs a [KitoAsyncValidationRule] as the user types: debounces, ignores stale answers when a
/// newer value has been typed, and reports [status] and [error] as it goes.
///
/// Listen to it (it's a [ChangeNotifier]) to rebuild a spinner or tick next to the field.
class KitoAsyncValidator extends ChangeNotifier {
  /// Creates a validator for [rule].
  KitoAsyncValidator(this.rule);

  /// The rule it runs.
  final KitoAsyncValidationRule rule;

  KitoValidationStatus _status = KitoValidationStatus.idle;
  String? _error;
  String? _checkedValue;
  Timer? _timer;
  int _generation = 0;
  Completer<String?>? _pending;
  bool _disposed = false;

  /// Where the check stands.
  KitoValidationStatus get status => _status;

  /// The last failure, or null.
  String? get error => _error;

  /// True while a check is waiting or in flight.
  bool get isValidating => _status == KitoValidationStatus.validating;

  /// The value the current [status] describes.
  String? get checkedValue => _checkedValue;

  /// Schedules a check of [value] after the rule's debounce. An empty value resets to idle.
  /// The returned future completes with the error (or null) for this value, or with the newer
  /// value's result if the user kept typing.
  Future<String?> validate(String value, {bool immediate = false}) {
    _timer?.cancel();
    final generation = ++_generation;
    if (value.trim().isEmpty) {
      _finishPending(null);
      _set(KitoValidationStatus.idle, null, value);
      return Future.value(null);
    }
    if (value == _checkedValue && _status != KitoValidationStatus.validating) {
      return Future.value(_error);
    }
    _pending ??= Completer<String?>();
    final completer = _pending!;
    _set(KitoValidationStatus.validating, _error, value);
    void run() => _run(value, generation);
    if (immediate || rule.debounce == Duration.zero) {
      run();
    } else {
      _timer = Timer(rule.debounce, run);
    }
    return completer.future;
  }

  Future<void> _run(String value, int generation) async {
    String? result;
    try {
      result = await rule.check(value);
    } catch (_) {
      result = "Couldn't check right now";
    }
    if (_disposed || generation != _generation) return;
    _set(
        result == null
            ? KitoValidationStatus.valid
            : KitoValidationStatus.invalid,
        result,
        value);
    _finishPending(result);
  }

  void _finishPending(String? result) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  /// Forgets the last result.
  void reset() {
    _timer?.cancel();
    _generation++;
    _finishPending(null);
    _set(KitoValidationStatus.idle, null, null);
  }

  void _set(KitoValidationStatus status, String? error, String? value) {
    final changed = status != _status || error != _error;
    _status = status;
    _error = error;
    _checkedValue = value;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _finishPending(null);
    super.dispose();
  }
}
