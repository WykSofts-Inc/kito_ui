// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';

/// The accent a calendar draws selections with, and the colour that reads on it.
@immutable
class CalendarPalette {
  /// Resolves [tint] against the theme.
  factory CalendarPalette.of(BuildContext context, Color? tint) {
    final theme = context.kito;
    return CalendarPalette._(theme.accent(tint), theme.onAccent(tint));
  }

  const CalendarPalette._(this.accent, this.onAccent);

  /// Selection fills, today rings, bands.
  final Color accent;

  /// Text on [accent].
  final Color onAccent;
}

/// A round, muted icon button with a 44-point target, like the month chevrons.
class CalendarIconButton extends StatelessWidget {
  /// Creates a button; [onPressed] null disables it.
  const CalendarIconButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed});

  /// The glyph (directional icons mirror in right-to-left layouts).
  final IconData icon;

  /// Read by screen readers.
  final String label;

  /// Called on tap.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: KitoPressable(
              enabled: enabled,
              scale: 0.88,
              child: AnimatedOpacity(
                opacity: enabled ? 1 : 0.35,
                duration: KitoMotion.of(context, theme.motion.fast),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: theme.colors.surfaceMuted, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: theme.colors.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Today" capsule that jumps a calendar back to today.
class CalendarTodayCapsule extends StatelessWidget {
  /// Creates the capsule.
  const CalendarTodayCapsule(
      {super.key, required this.palette, required this.onPressed});

  /// Its colours.
  final CalendarPalette palette;

  /// Called on tap.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      button: true,
      label: 'Today',
      hint: 'Jumps back to today',
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: Center(
            child: KitoPressable(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                    vertical: theme.spacing.xs + 2),
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(theme.radii.pill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.undo_rounded, size: 14, color: palette.onAccent),
                  const SizedBox(width: 4),
                  Text('Today',
                      style: theme.typography.caption.copyWith(
                          color: palette.onAccent,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A title that rolls up (forward) or down (back) when its text changes.
class CalendarRollingTitle extends StatelessWidget {
  /// Creates a title.
  const CalendarRollingTitle(this.text,
      {super.key, required this.forward, this.style});

  /// The text.
  final String text;

  /// Which way to roll.
  final bool forward;

  /// Overrides the theme's title style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      header: true,
      child: AnimatedSwitcher(
        duration: KitoMotion.of(context, theme.motion.medium),
        switchInCurve: theme.motion.standard,
        switchOutCurve: theme.motion.standard,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(text);
          final from = Offset(0, forward == incoming ? 0.6 : -0.6);
          return ClipRect(
            child: SlideTransition(
              position: Tween(begin: from, end: Offset.zero).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: Text(
          text,
          key: ValueKey(text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ??
              theme.typography.title.copyWith(color: theme.colors.onSurface),
        ),
      ),
    );
  }
}

/// The weekday initials above a month grid, weekends softer.
class CalendarWeekdayHeader extends StatelessWidget {
  /// Creates the header.
  const CalendarWeekdayHeader({super.key, required this.config});

  /// The locale and first weekday.
  final KitoCalendarConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final names = config.weekdaySymbols();
    final order = config.weekdayOrder;
    return ExcludeSemantics(
      child: Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(
              names[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              style: theme.typography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.onSurface.withValues(
                    alpha: config.weekendDays.contains(order[i]) ? 0.38 : 0.55),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A squash-and-spring when [trigger] changes; nothing under Reduce Motion.
class CalendarPop extends StatefulWidget {
  /// Wraps [child].
  const CalendarPop(
      {super.key,
      required this.trigger,
      required this.child,
      this.amount = 0.84});

  /// Pops when this changes.
  final Object? trigger;

  /// What pops.
  final Widget child;

  /// How far it squashes.
  final double amount;

  @override
  State<CalendarPop> createState() => _CalendarPopState();
}

class _CalendarPopState extends State<CalendarPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420), value: 1);
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.amount)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18),
    TweenSequenceItem(
        tween: Tween(begin: widget.amount, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35),
    TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 47),
  ]).animate(_c);

  @override
  void didUpdateWidget(CalendarPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && !context.reduceMotion) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// A light pill: an icon, a title and a message, for "nothing here" moments.
class CalendarEmptyState extends StatelessWidget {
  /// Creates the message.
  const CalendarEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});

  /// The glyph.
  final IconData icon;

  /// The headline.
  final String title;

  /// The detail.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: theme.spacing.xxl, horizontal: theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: KitoMotion.of(context, theme.motion.slow),
              curve: theme.motion.spring,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Icon(icon,
                  size: 44,
                  color: theme.colors.onSurface.withValues(alpha: 0.35)),
            ),
            SizedBox(height: theme.spacing.md),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.typography.headline
                    .copyWith(color: theme.colors.onSurface)),
            SizedBox(height: theme.spacing.xs),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.typography.body.copyWith(
                    color: theme.colors.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
