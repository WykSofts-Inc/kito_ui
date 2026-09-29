// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'toast.dart';

/// One toast at a time, or a stack.
@immutable
class KitoToastPresentation {
  /// One toast at a time; the rest wait in a queue.
  const KitoToastPresentation.single()
      : maxVisible = 1,
        isStacked = false;

  /// New toasts land on top, older ones peek out behind; tap the stack to fan it out. Past
  /// [maxVisible], the oldest goes.
  const KitoToastPresentation.stack({int maxVisible = 3})
      : maxVisible = maxVisible < 1 ? 1 : maxVisible,
        isStacked = true;

  /// A stack of up to three.
  static const stacked = KitoToastPresentation.stack();

  /// How many can be on screen.
  final int maxVisible;

  /// True for a stack.
  final bool isStacked;

  @override
  bool operator ==(Object other) =>
      other is KitoToastPresentation &&
      other.maxVisible == maxVisible &&
      other.isStacked == isStacked;

  @override
  int get hashCode => Object.hash(maxVisible, isStacked);
}

class _Countdown {
  _Countdown(this.remaining);
  Duration remaining;
  DateTime? startedAt;
  Timer? timer;
}

/// Owns the toasts on screen: show, update, complete and dismiss them from anywhere, and put a
/// [KitoToastHost] near the root to draw them.
///
/// ```dart
/// final toasts = KitoToastCenter();
///
/// MaterialApp(builder: (context, child) => KitoToastHost(center: toasts, child: child!));
///
/// toasts.success('Saved');
/// ```
class KitoToastCenter extends ChangeNotifier {
  /// Creates a center.
  KitoToastCenter({
    KitoToastPosition position = KitoToastPosition.top,
    KitoToastPresentation presentation = const KitoToastPresentation.single(),
  })  : _position = position,
        _presentation = presentation;

  KitoToastPosition _position;
  KitoToastPresentation _presentation;
  final List<KitoToast> _visible = [];
  final List<KitoToast> _queue = [];
  final Map<Object, _Countdown> _timers = {};
  bool _expanded = false;
  int _holds = 0;
  bool _disposed = false;

  /// Where toasts appear.
  KitoToastPosition get position => _position;
  set position(KitoToastPosition value) {
    if (value == _position) return;
    _position = value;
    notifyListeners();
  }

  /// One at a time, or a stack.
  KitoToastPresentation get presentation => _presentation;
  set presentation(KitoToastPresentation value) {
    if (value == _presentation) return;
    _presentation = value;
    while (_visible.length > value.maxVisible) {
      _cancel(_visible.removeLast().id);
    }
    notifyListeners();
  }

  /// Everything on screen, newest first.
  List<KitoToast> get visible => List.unmodifiable(_visible);

  /// Toasts waiting their turn (single presentation only).
  List<KitoToast> get queued => List.unmodifiable(_queue);

  /// The front-most toast.
  KitoToast? get current => _visible.isEmpty ? null : _visible.first;

  /// The toast with [id], on screen or queued.
  KitoToast? toastWithId(Object id) {
    for (final t in _visible) {
      if (t.id == id) return t;
    }
    for (final t in _queue) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// True while a stack is fanned out to show every toast. Auto-dismissal pauses meanwhile.
  bool get isStackExpanded => _expanded;
  set isStackExpanded(bool value) {
    if (value == _expanded) return;
    if (value && _visible.length < 2) return;
    _expanded = value;
    value ? pause() : resume();
    notifyListeners();
  }

  /// Fans the stack out, or folds it back.
  void toggleStack() => isStackExpanded = !_expanded;

  /// True while auto-dismissal is paused (stack fanned out, pointer hovering, finger down).
  bool get isPaused => _holds > 0;

  /// Pauses every auto-dismiss timer. Calls nest: each [pause] needs a [resume].
  void pause() {
    _holds++;
    if (_holds != 1) return;
    final now = clock.now();
    for (final c in _timers.values) {
      if (c.startedAt != null) {
        c.remaining -= now.difference(c.startedAt!);
        if (c.remaining.isNegative) c.remaining = Duration.zero;
      }
      c.timer?.cancel();
      c.timer = null;
      c.startedAt = null;
    }
    notifyListeners();
  }

  /// Undoes one [pause]; timers pick up where they left off.
  void resume() {
    if (_holds == 0) return;
    _holds--;
    if (_holds != 0) return;
    for (final entry in _timers.entries) {
      _start(entry.key, entry.value);
    }
    notifyListeners();
  }

  /// How long [id] has left before it goes by itself, or null when it has no timer.
  Duration? remainingFor(Object id) {
    final c = _timers[id];
    if (c == null) return null;
    if (c.startedAt == null) return c.remaining;
    final left = c.remaining - clock.now().difference(c.startedAt!);
    return left.isNegative ? Duration.zero : left;
  }

  // MARK: - Showing

  /// Shows [toast] and returns its id.
  Object show(KitoToast toast) {
    if (_presentation.isStacked) {
      _visible.insert(0, toast);
      while (_visible.length > _presentation.maxVisible) {
        _cancel(_visible.removeLast().id);
      }
      _schedule(toast);
      notifyListeners();
    } else {
      _queue.add(toast);
      if (_visible.isEmpty) {
        _advance();
      } else {
        notifyListeners();
      }
    }
    return toast.id;
  }

  /// Shows a message toast.
  Object showMessage(
    String message, {
    String? title,
    KitoToastStyle style = KitoToastStyle.info,
    KitoToastLayout layout = KitoToastLayout.card,
    Duration? duration = const Duration(seconds: 3),
    List<KitoToastAction> actions = const [],
  }) =>
      show(KitoToast(
          message: message,
          title: title,
          style: style,
          layout: layout,
          duration: duration,
          actions: actions));

  /// A success toast.
  Object success(String message,
          {String? title, KitoToastLayout layout = KitoToastLayout.card}) =>
      showMessage(message,
          title: title, style: KitoToastStyle.success, layout: layout);

  /// An error toast.
  Object error(String message,
          {String? title, KitoToastLayout layout = KitoToastLayout.card}) =>
      showMessage(message,
          title: title, style: KitoToastStyle.error, layout: layout);

  /// A warning toast.
  Object warning(String message,
          {String? title, KitoToastLayout layout = KitoToastLayout.card}) =>
      showMessage(message,
          title: title, style: KitoToastStyle.warning, layout: layout);

  /// An info toast.
  Object info(String message,
          {String? title, KitoToastLayout layout = KitoToastLayout.card}) =>
      showMessage(message, title: title, layout: layout);

  /// "Message deleted · Undo" with a ring counting down [duration]. [onUndo] runs if the user
  /// taps Undo in time; [onExpire] runs otherwise — when the ring runs out or the toast is
  /// swiped away — so commit the delete there.
  Object undo(
    String message, {
    required VoidCallback onUndo,
    VoidCallback? onExpire,
    String? title,
    String actionLabel = 'Undo',
    Duration duration = const Duration(seconds: 5),
    KitoToastLayout layout = KitoToastLayout.card,
    KitoToastStyle style = KitoToastStyle.info,
  }) {
    var undone = false;
    final toast = KitoToast(
      message: message,
      title: title,
      style: style,
      layout: layout,
      duration: duration,
      showsCountdown: true,
      actions: [
        KitoToastAction(
          label: actionLabel,
          role: KitoToastActionRole.destructive,
          onPressed: () {
            undone = true;
            onUndo();
          },
        ),
      ],
    );
    if (onExpire != null) {
      _onExpire[toast.id] = () {
        if (!undone) onExpire();
      };
    }
    return show(toast);
  }

  final Map<Object, VoidCallback> _onExpire = {};

  // MARK: - Updating

  /// Replaces the toast with [id] by `change(old)`, keeping its id and slot. A no-op when it's
  /// gone. Returns whether it was found.
  bool update(Object id, KitoToast Function(KitoToast toast) change) {
    for (final list in [_visible, _queue]) {
      final i = list.indexWhere((t) => t.id == id);
      if (i >= 0) {
        final updated = change(list[i]);
        assert(updated.id == id, 'update() must keep the id; use copyWith');
        list[i] = updated;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Moves a progress toast's bar in place, so an upload reads as one continuous toast.
  void updateProgress(Object id, double fraction) =>
      update(id, (t) => t.copyWith(progress: fraction));

  /// Turns a progress or loading toast into a finished one — same toast, same slot — and
  /// starts its [duration] like any other.
  void complete(
    Object id, {
    required KitoToastStyle style,
    String? title,
    String? message,
    Duration? duration = const Duration(seconds: 3),
  }) {
    final found = update(
      id,
      (t) => t.copyWith(
        style: style,
        title: title,
        message: message,
        isLoading: false,
        clearProgress: true,
        duration: duration,
        clearDuration: duration == null,
      ),
    );
    if (!found) return;
    final toast = toastWithId(id);
    if (toast != null && _visible.contains(toast)) _schedule(toast);
  }

  /// Shows a spinner while [future] runs, then turns it into a success or error toast. Returns
  /// the future's value, or rethrows its error.
  ///
  /// ```dart
  /// await toasts.promise(api.save(), loading: 'Saving…', success: (_) => 'Saved');
  /// ```
  Future<T> promise<T>(
    Future<T> future, {
    required String loading,
    required String Function(T value) success,
    String Function(Object error)? error,
    String? title,
    KitoToastLayout layout = KitoToastLayout.card,
  }) async {
    final id = show(KitoToast(
        message: loading, title: title, layout: layout, isLoading: true));
    try {
      final value = await future;
      complete(id, style: KitoToastStyle.success, message: success(value));
      return value;
    } catch (e) {
      complete(id,
          style: KitoToastStyle.error,
          message: error?.call(e) ?? 'Something went wrong');
      rethrow;
    }
  }

  // MARK: - Dismissing

  /// Dismisses one toast, wherever it is.
  void dismiss(Object id) {
    _cancel(id);
    final expire = _onExpire.remove(id);
    final before = _visible.length + _queue.length;
    _visible.removeWhere((t) => t.id == id);
    _queue.removeWhere((t) => t.id == id);
    if (before == _visible.length + _queue.length) return;
    if (_visible.length < 2 && _expanded) {
      _expanded = false;
      resume();
    }
    if (!_advance()) notifyListeners();
    expire?.call();
  }

  /// Dismisses the front toast.
  void dismissCurrent() {
    final c = current;
    if (c != null) dismiss(c.id);
  }

  /// Clears the screen and the queue.
  void dismissAll() {
    for (final c in _timers.values) {
      c.timer?.cancel();
    }
    _timers.clear();
    final expiring = _onExpire.values.toList();
    _onExpire.clear();
    _visible.clear();
    _queue.clear();
    if (_expanded) {
      _expanded = false;
      resume();
    }
    notifyListeners();
    for (final expire in expiring) {
      expire();
    }
  }

  // MARK: - Internals

  bool _advance() {
    if (_presentation.isStacked || _visible.isNotEmpty || _queue.isEmpty) {
      return false;
    }
    final next = _queue.removeAt(0);
    _visible.add(next);
    _schedule(next);
    notifyListeners();
    return true;
  }

  void _schedule(KitoToast toast) {
    _cancel(toast.id);
    final duration = toast.duration;
    if (duration == null) return;
    final c = _timers[toast.id] = _Countdown(duration);
    if (!isPaused) _start(toast.id, c);
  }

  void _start(Object id, _Countdown c) {
    c.timer?.cancel();
    c.startedAt = clock.now();
    c.timer = Timer(c.remaining, () {
      if (_disposed) return;
      _timers.remove(id);
      dismiss(id);
    });
  }

  void _cancel(Object id) {
    _timers.remove(id)?.timer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final c in _timers.values) {
      c.timer?.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
