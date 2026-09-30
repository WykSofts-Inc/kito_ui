// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';

/// How [KitoCheckoutProgress] draws the steps.
enum KitoCheckoutProgressStyle {
  /// Numbered dots joined by a line that fills as you go; finished steps show a tick.
  dots,

  /// One bar per step.
  segmented,

  /// "STEP 2 OF 4", the step name and a thin bar.
  text,
}

/// Where the customer is in the checkout: cart → delivery → payment → review.
///
/// Finished steps can be tapped to go back when [onStepTap] is set.
///
/// ```dart
/// KitoCheckoutProgress(
///   current: KitoCheckoutStep.payment,
///   onStepTap: (step) => setState(() => this.step = step),
/// )
/// ```
class KitoCheckoutProgress extends StatelessWidget {
  /// Creates a progress header.
  const KitoCheckoutProgress({
    super.key,
    required this.current,
    this.steps = KitoCheckoutStep.standard,
    this.style = KitoCheckoutProgressStyle.dots,
    this.tint,
    this.onStepTap,
  });

  /// The step the customer is on. [KitoCheckoutStep.done] shows every step finished.
  final KitoCheckoutStep current;

  /// The steps to show, in order.
  final List<KitoCheckoutStep> steps;

  /// Dots, segments or text.
  final KitoCheckoutProgressStyle style;

  /// Replaces the theme's primary colour.
  final Color? tint;

  /// Called when a finished step is tapped.
  final ValueChanged<KitoCheckoutStep>? onStepTap;

  List<KitoCheckoutStep> get _steps =>
      steps.where((s) => s != KitoCheckoutStep.done).toList();

  int get _index {
    final i = _steps.indexOf(current);
    return i < 0 ? _steps.length : i;
  }

  @override
  Widget build(BuildContext context) {
    final position = (_index + 1).clamp(1, _steps.length);
    final name = current.title;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Checkout progress',
      value: 'Step $position of ${_steps.length}, $name',
      child: switch (style) {
        KitoCheckoutProgressStyle.dots => _dots(context),
        KitoCheckoutProgressStyle.segmented => _segmented(context, position),
        KitoCheckoutProgressStyle.text => _text(context, position),
      },
    );
  }

  Widget _dots(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final onAccent = theme.onAccent(tint);
    final children = <Widget>[];
    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final done = i < _index;
      final active = i == _index;
      children.add(SizedBox(
        width: 64,
        child: Semantics(
          container: true,
          button: done && onStepTap != null,
          label:
              '${step.title}, ${done ? 'done' : active ? 'current' : 'to do'}',
          excludeSemantics: true,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: done && onStepTap != null ? () => onStepTap!(step) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _Dot(
                  number: i + 1,
                  done: done,
                  active: active,
                  accent: accent,
                  onAccent: onAccent,
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: KitoMotion.of(context, theme.motion.fast),
                  style: theme.typography.caption.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: theme.colors.onBackground
                        .withValues(alpha: active || done ? 0.9 : 0.45),
                  ),
                  child: Text(step.title,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false),
                ),
              ]),
            ),
          ),
        ),
      ));
      if (i < _steps.length - 1) {
        children.add(Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 14),
            child: _Bar(filled: i < _index, accent: accent, height: 3),
          ),
        ));
      }
    }
    return Material(
      type: MaterialType.transparency,
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _segmented(BuildContext context, int position) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
                child: _Bar(filled: i <= _index, accent: accent, height: 6)),
          ],
        ]),
        SizedBox(height: theme.spacing.sm),
        Row(children: [
          Icon(current.icon, size: 18, color: theme.colors.onBackground),
          SizedBox(width: theme.spacing.xs),
          Expanded(
            child: AnimatedSwitcher(
              duration: KitoMotion.of(context, theme.motion.fast),
              layoutBuilder: (c, p) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [...p, if (c != null) c]),
              child: Text(current.title,
                  key: ValueKey(current),
                  style: theme.typography.label
                      .copyWith(color: theme.colors.onBackground)),
            ),
          ),
          Text('$position/${_steps.length}',
              style: theme.typography.caption.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colors.onBackground.withValues(alpha: 0.5))),
        ]),
      ],
    );
  }

  Widget _text(BuildContext context, int position) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final next = _index + 1 < _steps.length ? _steps[_index + 1] : null;
    final fraction = _steps.isEmpty ? 0.0 : position / _steps.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP $position OF ${_steps.length}',
                    style: theme.typography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: accent.withValues(alpha: 0.85))),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: KitoMotion.of(context, theme.motion.medium),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                              begin: Offset(context.isRtl ? -0.15 : 0.15, 0),
                              end: Offset.zero)
                          .animate(a),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (c, p) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [...p, if (c != null) c]),
                  child: Text(current.title,
                      key: ValueKey(current),
                      style: theme.typography.display
                          .copyWith(color: theme.colors.onBackground)),
                ),
              ],
            ),
          ),
          if (next != null)
            Text('Next: ${next.title}',
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onBackground.withValues(alpha: 0.5))),
        ]),
        SizedBox(height: theme.spacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: Stack(children: [
              Positioned.fill(
                  child: ColoredBox(
                      color: theme.colors.border.withValues(alpha: 0.6))),
              TweenAnimationBuilder<double>(
                tween: Tween(end: fraction),
                duration: KitoMotion.of(context, theme.motion.slow),
                curve: theme.motion.spring,
                builder: (context, v, _) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: v.clamp(0, 1),
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4))),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.filled, required this.accent, required this.height});

  final bool filled;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          Positioned.fill(
              child: ColoredBox(
                  color: theme.colors.border.withValues(alpha: 0.6))),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: filled ? 1 : 0),
              duration: KitoMotion.of(context, theme.motion.slow),
              curve: theme.motion.emphasized,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: v,
                child: ColoredBox(color: accent),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.number,
    required this.done,
    required this.active,
    required this.accent,
    required this.onAccent,
  });

  final int number;
  final bool done;
  final bool active;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final filled = done || active;
    return AnimatedScale(
      scale: active ? 1.1 : 1,
      duration: KitoMotion.of(context, theme.motion.medium),
      curve: theme.motion.spring,
      child: AnimatedContainer(
        duration: KitoMotion.of(context, theme.motion.medium),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? accent : theme.colors.surface,
          border: Border.all(
              color: filled ? accent : theme.colors.border, width: 1.5),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.fast),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: done
              ? Icon(Icons.check_rounded,
                  key: const ValueKey('tick'), size: 18, color: onAccent)
              : Text('$number',
                  key: ValueKey(number),
                  style: theme.typography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: filled
                          ? onAccent
                          : theme.colors.onSurface.withValues(alpha: 0.6))),
        ),
      ),
    );
  }
}
