// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Where a [KitoSlideToConfirm] is.
enum KitoSlidePhase {
  /// Waiting for a slide.
  idle,

  /// `onConfirm` is running.
  working,

  /// `onConfirm` finished.
  done,

  /// `onConfirm` threw; the knob is on its way back.
  failed,
}

/// "Slide to pay": drag the knob to the end to confirm. It runs [onConfirm], shows a spinner
/// while it does and ends on a tick. A tap with a screen reader, or Enter/Space with a
/// keyboard, confirms too.
///
/// If [onConfirm] throws, the knob shows a cross, the label reads [failureTitle] for a moment
/// and the knob slides back so the person can try again. After a success it stays on the tick
/// until [resetKey] changes, or until [resetAfter] has passed if you set it.
///
/// The knob slides toward the end edge, so it runs right to left in RTL layouts.
///
/// ```dart
/// KitoSlideToConfirm(
///   title: 'Slide to pay',
///   icon: Icons.credit_card_rounded,
///   resetKey: attempt,
///   onConfirm: () => checkout.pay(),   // throw to report failure
/// )
/// ```
class KitoSlideToConfirm extends StatefulWidget {
  /// Creates the control.
  const KitoSlideToConfirm({
    super.key,
    required this.onConfirm,
    this.title = 'Slide to confirm',
    this.icon = Icons.chevron_right_rounded,
    this.tint,
    this.failureTitle = 'Try again',
    this.doneTitle = 'Done',
    this.resetAfter,
    this.resetKey,
    this.height = 64,
    this.onPhaseChanged,
  });

  /// The work to do. Complete to succeed; throw to fail and slide back.
  final Future<void> Function() onConfirm;

  /// The label on the track.
  final String title;

  /// The knob's icon at rest. Use a direction-neutral icon, or one that mirrors in RTL (the
  /// default chevron does).
  final IconData icon;

  /// Knob and track colour; the theme's primary when null.
  final Color? tint;

  /// Shown briefly when [onConfirm] throws.
  final String failureTitle;

  /// Shown after a success.
  final String doneTitle;

  /// After a success, go back to the start once this much time has passed. Null stays on the
  /// tick.
  final Duration? resetAfter;

  /// Change this to put the control back to the start, e.g. after the order changes.
  final Object? resetKey;

  /// The control's height; the knob is 8 less.
  final double height;

  /// Called whenever the phase changes.
  final ValueChanged<KitoSlidePhase>? onPhaseChanged;

  /// Past 85% of the track counts as a confirm.
  static bool confirms({required double offset, required double track}) =>
      track > 0 && offset >= track * 0.85;

  @override
  State<KitoSlideToConfirm> createState() => _KitoSlideToConfirmState();
}

class _KitoSlideToConfirmState extends State<KitoSlideToConfirm>
    with TickerProviderStateMixin {
  /// Knob position as a fraction of the track, 0–1.
  late final AnimationController _knob =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));
  KitoSlidePhase _phase = KitoSlidePhase.idle;
  int _run = 0;
  double _track = 1;
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void didUpdateWidget(KitoSlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) _reset();
  }

  @override
  void dispose() {
    _knob.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _setPhase(KitoSlidePhase phase) {
    if (!mounted || _phase == phase) return;
    setState(() => _phase = phase);
    widget.onPhaseChanged?.call(phase);
  }

  void _springTo(double target, {double velocity = 0}) {
    if (context.reduceMotion) {
      _knob.animateTo(target,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      return;
    }
    const spring = SpringDescription(mass: 1, stiffness: 250, damping: 22);
    _knob.animateWith(SpringSimulation(spring, _knob.value, target, velocity));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_phase != KitoSlidePhase.idle) return;
    final dx = details.delta.dx * (context.isRtl ? -1 : 1);
    _knob.value = (_knob.value + dx / _track).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_phase != KitoSlidePhase.idle) return;
    if (KitoSlideToConfirm.confirms(
        offset: _knob.value * _track, track: _track)) {
      _confirm();
    } else {
      _springTo(0);
    }
  }

  Future<void> _confirm() async {
    if (_phase != KitoSlidePhase.idle) return;
    _springTo(1);
    _setPhase(KitoSlidePhase.working);
    final run = ++_run;
    try {
      await widget.onConfirm();
      if (!mounted || run != _run) return;
      _setPhase(KitoSlidePhase.done);
      final after = widget.resetAfter;
      if (after != null) {
        await Future<void>.delayed(after);
        if (mounted && run == _run && _phase == KitoSlidePhase.done) _reset();
      }
    } catch (_) {
      if (!mounted || run != _run) return;
      _setPhase(KitoSlidePhase.failed);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted || run != _run) return;
      _springTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted || run != _run || _phase != KitoSlidePhase.failed) return;
      _setPhase(KitoSlidePhase.idle);
    }
  }

  /// Back to the start: knob home, title restored. A result still on its way is ignored.
  void _reset() {
    _run++;
    _springTo(0);
    _setPhase(KitoSlidePhase.idle);
  }

  String get _label => switch (_phase) {
        KitoSlidePhase.done => widget.doneTitle,
        KitoSlidePhase.failed => widget.failureTitle,
        _ => widget.title,
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final color = widget.tint ?? theme.colors.primary;
    final knobColor =
        _phase == KitoSlidePhase.failed ? theme.colors.danger : color;
    final onKnob = widget.tint == null && _phase != KitoSlidePhase.failed
        ? theme.colors.onPrimary
        : (ThemeData.estimateBrightnessForColor(knobColor) == Brightness.dark
            ? Colors.white
            : Colors.black);
    final knobSize = widget.height - 8;
    final fast = KitoMotion.of(context, theme.motion.fast);

    final semanticsValue = switch (_phase) {
      KitoSlidePhase.done => widget.doneTitle,
      KitoSlidePhase.failed => widget.failureTitle,
      KitoSlidePhase.working => '…',
      KitoSlidePhase.idle => '',
    };

    return Semantics(
      container: true,
      button: true,
      enabled: _phase == KitoSlidePhase.idle,
      label: widget.title,
      value: semanticsValue,
      liveRegion:
          _phase == KitoSlidePhase.failed || _phase == KitoSlidePhase.done,
      onTap: _phase == KitoSlidePhase.idle ? _confirm : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent:
              CallbackAction<ActivateIntent>(onInvoke: (_) => _confirm()),
        },
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(builder: (context, constraints) {
            _track = (constraints.maxWidth - knobSize - 8)
                .clamp(1.0, double.infinity);
            return AnimatedBuilder(
              animation: Listenable.merge([_knob, _shimmer]),
              builder: (context, _) {
                final fraction = _knob.value.clamp(0.0, 1.0);
                final offset = fraction * _track;
                final shimmerX = _shimmer.value * 2 - 1;
                return Stack(children: [
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: fast,
                      decoration: ShapeDecoration(
                        color: knobColor.withValues(alpha: 0.15),
                        shape: StadiumBorder(
                          side: _focused
                              ? BorderSide(color: knobColor, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    width: offset + knobSize + 8,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                          color: knobColor.withValues(alpha: 0.35),
                          shape: const StadiumBorder()),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                          start: knobSize + 12, end: 16),
                      child: Center(
                        child: Opacity(
                          opacity: _phase == KitoSlidePhase.failed
                              ? 1
                              : (1 - fraction * 0.9).clamp(0.0, 1.0),
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment(shimmerX * 2 - 1, 0),
                              end: Alignment(shimmerX * 2 + 1, 0),
                              colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white,
                                Colors.white.withValues(alpha: 0.35),
                              ],
                            ).createShader(rect),
                            child: AnimatedSwitcher(
                              duration: fast,
                              child: Text(
                                _label,
                                key: ValueKey(_label),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.typography.headline.copyWith(
                                    color: theme.colors.onSurface
                                        .withValues(alpha: 0.8)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 4 + offset,
                    top: 4,
                    child: GestureDetector(
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      child: AnimatedContainer(
                        duration: fast,
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          color: knobColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: knobColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: KitoMotion.of(context, theme.motion.medium),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                      opacity: animation, child: child)),
                          child: _knobGlyph(onKnob),
                        ),
                      ),
                    ),
                  ),
                ]);
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _knobGlyph(Color color) => switch (_phase) {
        KitoSlidePhase.idle => Icon(widget.icon,
            key: const ValueKey('idle'), color: color, size: 26),
        KitoSlidePhase.working => SizedBox(
            key: const ValueKey('working'),
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
          ),
        KitoSlidePhase.done => Icon(Icons.check_rounded,
            key: const ValueKey('done'), color: color, size: 26),
        KitoSlidePhase.failed => Icon(Icons.close_rounded,
            key: const ValueKey('failed'), color: color, size: 26),
      };
}
