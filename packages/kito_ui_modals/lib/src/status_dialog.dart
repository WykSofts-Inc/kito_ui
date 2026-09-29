// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Which phase a status dialog is in.
enum KitoStatusKind {
  /// Work is under way; a spinner turns.
  pending,

  /// It worked; a tick draws itself in.
  success,

  /// It failed; a cross draws itself in.
  failure,
}

/// What a status dialog shows: a phase and an optional message.
@immutable
class KitoStatusDialogState {
  /// Work under way.
  const KitoStatusDialogState.pending([this.message])
      : kind = KitoStatusKind.pending;

  /// It worked.
  const KitoStatusDialogState.success([this.message])
      : kind = KitoStatusKind.success;

  /// It failed.
  const KitoStatusDialogState.failure([this.message])
      : kind = KitoStatusKind.failure;

  /// The phase.
  final KitoStatusKind kind;

  /// The line under the icon.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is KitoStatusDialogState &&
      other.kind == kind &&
      other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'KitoStatusDialogState.${kind.name}($message)';
}

/// The animated card a status dialog shows: a circle that pops in, then a spinner, a tick or
/// a cross drawn as a stroke. It replays its entrance whenever the phase changes.
class KitoStatusDialogView extends StatefulWidget {
  /// Creates the card.
  const KitoStatusDialogView({super.key, required this.state});

  /// What to show.
  final KitoStatusDialogState state;

  @override
  State<KitoStatusDialogView> createState() => _KitoStatusDialogViewState();
}

class _KitoStatusDialogViewState extends State<KitoStatusDialogView>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _draw = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));
  late final AnimationController _spin = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  bool _started = false;
  Timer? _drawIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _animateIn();
    }
  }

  @override
  void didUpdateWidget(KitoStatusDialogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.kind != widget.state.kind) _animateIn();
  }

  void _animateIn() {
    final reduce = context.reduceMotion;
    _drawIn?.cancel();
    _spin.stop();
    if (reduce) {
      _pop.value = 1;
      _draw.value = 1;
      return;
    }
    _pop.forward(from: 0);
    _draw.value = 0;
    if (widget.state.kind == KitoStatusKind.pending) {
      _spin.repeat();
    } else {
      // A timer rather than Future.delayed, so dispose can cancel it.
      _drawIn = Timer(
          const Duration(milliseconds: 100), () => _draw.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _drawIn?.cancel();
    _pop.dispose();
    _draw.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final state = widget.state;
    final accent = switch (state.kind) {
      KitoStatusKind.pending => theme.colors.primary,
      KitoStatusKind.success => theme.colors.success,
      KitoStatusKind.failure => theme.colors.danger,
    };
    final pop = CurvedAnimation(
        parent: _pop, curve: const KitoSpringCurve(damping: 0.62));
    return Semantics(
      liveRegion: true,
      label: state.message ?? state.kind.name,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 300),
        padding: EdgeInsets.all(theme.spacing.xl),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(theme.radii.xl),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_pop, _draw, _spin]),
              builder: (context, _) => Transform.scale(
                scale: 0.6 + 0.4 * pop.value,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: KitoStatusIconPainter(
                      kind: state.kind,
                      color: accent,
                      progress: _draw.value,
                      rotation: _spin.value,
                    ),
                  ),
                ),
              ),
            ),
            if (state.message != null) ...[
              SizedBox(height: theme.spacing.md),
              Text(state.message!,
                  textAlign: TextAlign.center,
                  style: theme.typography.body
                      .copyWith(color: theme.colors.onSurface)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Paints a status icon: a tinted disc with a spinning arc, or a tick or cross drawn up to
/// [progress]. The tick is never mirrored, like the system checkmark.
class KitoStatusIconPainter extends CustomPainter {
  /// Creates the painter.
  const KitoStatusIconPainter({
    required this.kind,
    required this.color,
    this.progress = 1,
    this.rotation = 0,
  });

  /// Which icon.
  final KitoStatusKind kind;

  /// Its colour.
  final Color color;

  /// How much of the tick or cross is drawn, 0–1.
  final double progress;

  /// The spinner's turn, 0–1.
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, size.shortestSide / 2,
        Paint()..color = color.withValues(alpha: 0.12));
    final glyph = Rect.fromCenter(center: center, width: 36, height: 36);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = kind == KitoStatusKind.pending ? 4 : 4.5;
    switch (kind) {
      case KitoStatusKind.pending:
        canvas.drawArc(glyph, rotation * 2 * math.pi - math.pi / 2,
            0.7 * 2 * math.pi, false, stroke);
      case KitoStatusKind.success:
        final path = Path()
          ..moveTo(
              glyph.left + glyph.width * 0.20, glyph.top + glyph.height * 0.52)
          ..lineTo(
              glyph.left + glyph.width * 0.42, glyph.top + glyph.height * 0.74)
          ..lineTo(
              glyph.left + glyph.width * 0.82, glyph.top + glyph.height * 0.26);
        canvas.drawPath(_trim(path, progress), stroke);
      case KitoStatusKind.failure:
        final path = Path()
          ..moveTo(
              glyph.left + glyph.width * 0.26, glyph.top + glyph.height * 0.26)
          ..lineTo(
              glyph.left + glyph.width * 0.74, glyph.top + glyph.height * 0.74)
          ..moveTo(
              glyph.left + glyph.width * 0.74, glyph.top + glyph.height * 0.26)
          ..lineTo(
              glyph.left + glyph.width * 0.26, glyph.top + glyph.height * 0.74);
        canvas.drawPath(_trim(path, progress), stroke);
    }
  }

  static Path _trim(Path path, double t) {
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * t.clamp(0.0, 1.0);
    final out = Path();
    for (final ui.PathMetric m in metrics) {
      if (remaining <= 0) break;
      out.addPath(m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
      remaining -= m.length;
    }
    return out;
  }

  @override
  bool shouldRepaint(KitoStatusIconPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.rotation != rotation;
}

/// Drives a status dialog shown with [showKitoStatusDialog].
class KitoStatusDialogController {
  KitoStatusDialogController._(this._state, this._autoDismissAfter);

  final ValueNotifier<KitoStatusDialogState> _state;
  final Duration? _autoDismissAfter;
  final Completer<void> _closed = Completer<void>();
  Timer? _timer;
  VoidCallback? _pop;

  /// What the dialog shows now.
  KitoStatusDialogState get state => _state.value;

  /// Completes once the dialog has closed.
  Future<void> get closed => _closed.future;

  /// True once the dialog has closed.
  bool get isClosed => _closed.isCompleted;

  /// Moves to [state]; success and failure close by themselves after the auto-dismiss delay.
  void update(KitoStatusDialogState state) {
    if (isClosed) return;
    _state.value = state;
    _timer?.cancel();
    final after = _autoDismissAfter;
    if (state.kind != KitoStatusKind.pending && after != null) {
      _timer = Timer(after, close);
    }
  }

  /// Closes the dialog now.
  void close() {
    _timer?.cancel();
    if (isClosed) return;
    _pop?.call();
  }

  void _didClose() {
    _timer?.cancel();
    if (!_closed.isCompleted) _closed.complete();
  }
}

/// Shows blocking, animated status feedback for work with a real effect — a payment, a
/// submitted form — where a toast would be the wrong weight. Returns a controller: call
/// `update` with success or failure when the work resolves (those close by themselves after
/// [autoDismissAfter]; pass null to keep them up), or `close`. Pass `useRootNavigator: false`
/// to show it inside a nested navigator.
///
/// ```dart
/// final status = showKitoStatusDialog(context,
///     state: const KitoStatusDialogState.pending('Processing payment…'));
/// try {
///   await api.charge();
///   status.update(const KitoStatusDialogState.success('Payment complete'));
/// } catch (_) {
///   status.update(const KitoStatusDialogState.failure('Payment failed'));
/// }
/// ```
KitoStatusDialogController showKitoStatusDialog(
  BuildContext context, {
  KitoStatusDialogState state = const KitoStatusDialogState.pending(),
  Duration? autoDismissAfter = const Duration(milliseconds: 1600),
  bool dimsBackground = true,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final controller =
      KitoStatusDialogController._(ValueNotifier(state), autoDismissAfter);
  final route = _KitoStatusRoute(
    status: controller,
    dims: dimsBackground,
    reduceMotion: KitoMotion.reduced(context),
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
  );
  controller._pop = () {
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }
  };
  navigator.push(route).whenComplete(controller._didClose);
  controller.update(state);
  return controller;
}

/// Runs [task] behind a status dialog: pending while it runs, then success or failure.
/// Returns the task's result, or rethrows its error once the failure state is showing.
/// `useRootNavigator: false` shows the dialog inside a nested navigator.
Future<T> runWithKitoStatusDialog<T>(
  BuildContext context,
  Future<T> Function() task, {
  String? pendingMessage,
  String? successMessage,
  String? failureMessage,
  Duration autoDismissAfter = const Duration(milliseconds: 1600),
  bool useRootNavigator = true,
}) async {
  final status = showKitoStatusDialog(context,
      state: KitoStatusDialogState.pending(pendingMessage),
      autoDismissAfter: autoDismissAfter,
      useRootNavigator: useRootNavigator);
  try {
    final result = await task();
    status.update(KitoStatusDialogState.success(successMessage));
    return result;
  } catch (_) {
    status.update(KitoStatusDialogState.failure(failureMessage));
    rethrow;
  }
}

class _KitoStatusRoute extends PopupRoute<void> {
  _KitoStatusRoute({
    required this.status,
    required this.dims,
    required this.reduceMotion,
    this.capturedThemes,
  });

  final KitoStatusDialogController status;
  final bool dims;
  final bool reduceMotion;
  final CapturedThemes? capturedThemes;

  @override
  Color? get barrierColor =>
      dims ? Colors.black.withValues(alpha: 0.35) : Colors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final page = PopScope(
      canPop: false,
      child: Center(
        child: ValueListenableBuilder<KitoStatusDialogState>(
          valueListenable: status._state,
          builder: (context, state, _) => KitoStatusDialogView(state: state),
        ),
      ),
    );
    return capturedThemes?.wrap(page) ?? page;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    if (reduceMotion || context.reduceMotion) {
      return FadeTransition(opacity: fade, child: child);
    }
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(
            parent: animation,
            curve: const KitoSpringCurve(damping: 0.8),
            reverseCurve: Curves.easeIn)),
        child: child,
      ),
    );
  }
}
