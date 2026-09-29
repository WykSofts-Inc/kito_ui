// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'math.dart';
import 'models.dart';
import 'parts.dart';

/// What's selected on a month page.
@immutable
sealed class CalendarSelection {
  const CalendarSelection();
}

/// One day, or none.
final class CalendarSingle extends CalendarSelection {
  /// Creates the selection.
  const CalendarSingle(this.date);

  /// Midnight on the day, or null.
  final DateTime? date;
}

/// Any number of days.
final class CalendarMultiple extends CalendarSelection {
  /// Creates the selection.
  const CalendarMultiple(this.dates);

  /// Midnights.
  final Set<DateTime> dates;
}

/// A range in progress or finished.
final class CalendarRangeSnapshot extends CalendarSelection {
  /// Creates the selection.
  const CalendarRangeSnapshot(this.start, this.end);

  /// The first day.
  final DateTime? start;

  /// The last day.
  final DateTime? end;
}

enum _Fill { none, single, multiple, rangeStart, rangeEnd }

/// Everything a month page needs to draw its days.
@immutable
class CalendarDayContext {
  /// Creates a context.
  const CalendarDayContext({
    required this.config,
    required this.palette,
    required this.today,
    required this.eventsByDay,
    required this.heat,
    required this.selection,
    required this.isDisabled,
    required this.isUnavailable,
    required this.onTap,
  });

  /// Locale and formatting.
  final KitoCalendarConfig config;

  /// Accent colours.
  final CalendarPalette palette;

  /// Midnight today.
  final DateTime today;

  /// Events keyed by midnight.
  final Map<DateTime, List<KitoCalendarEvent>> eventsByDay;

  /// 0–1 intensities keyed by midnight.
  final Map<DateTime, double> heat;

  /// What's picked.
  final CalendarSelection selection;

  /// Out of bounds or past: faded and not tappable.
  final bool Function(DateTime) isDisabled;

  /// Unavailable by the caller's rule: struck through and not tappable.
  final bool Function(DateTime) isUnavailable;

  /// Called with a tapped day.
  final ValueChanged<DateTime> onTap;

  _Fill _fill(DateTime d) => switch (selection) {
        CalendarSingle(:final date) => date == d ? _Fill.single : _Fill.none,
        CalendarMultiple(:final dates) =>
          dates.contains(d) ? _Fill.multiple : _Fill.none,
        CalendarRangeSnapshot(:final start, :final end) => start == d
            ? _Fill.rangeStart
            : end == d
                ? _Fill.rangeEnd
                : _Fill.none,
      };

  bool _inBand(DateTime d) => switch (selection) {
        CalendarRangeSnapshot(:final start?, :final end?) =>
          d.isAfter(start) && d.isBefore(end),
        _ => false,
      };
}

/// One month of days in six rows, with gliding selection circles and a continuous range band.
class CalendarMonthPage extends StatelessWidget {
  /// Creates a page.
  const CalendarMonthPage({
    super.key,
    required this.grid,
    required this.context,
    required this.cellHeight,
    this.rowSpacing = 4,
  });

  /// The days.
  final KitoCalendarMonthGrid grid;

  /// How to draw them.
  final CalendarDayContext context;

  /// Each row's height.
  final double cellHeight;

  /// The gap between rows.
  final double rowSpacing;

  /// The page's height for [rows] rows.
  static double heightFor(int rows, double cellHeight, double rowSpacing) =>
      rows * cellHeight + math.max(rows - 1, 0) * rowSpacing;

  @override
  Widget build(BuildContext buildContext) {
    final theme = buildContext.kito;
    final weeks = grid.weeks;
    final motion = KitoMotion.of(buildContext, theme.motion.medium);
    return LayoutBuilder(builder: (_, constraints) {
      final cellWidth = constraints.maxWidth / 7;
      final diameter = math.max(22.0, math.min(cellWidth, cellHeight) - 4);
      double top(int row) =>
          row * (cellHeight + rowSpacing) + (cellHeight - diameter) / 2;

      (int, int)? locate(DateTime? date) {
        if (date == null) return null;
        final i = grid.days.indexWhere((d) => d.isInMonth && d.date == date);
        return i < 0 ? null : (i ~/ 7, i % 7);
      }

      Widget circle(String key, (int, int) at, {bool glide = true}) {
        final (row, col) = at;
        final fill = DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(context.palette.accent, Colors.white, 0.12)!,
                context.palette.accent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                  color: context.palette.accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
        );
        final appear = TweenAnimationBuilder<double>(
          key: ValueKey('appear-$key'),
          tween: Tween(begin: 0.4, end: 1),
          duration: motion,
          curve: theme.motion.spring,
          builder: (_, v, child) => Opacity(
              opacity: ((v - 0.4) / 0.6).clamp(0.0, 1.0),
              child: Transform.scale(scale: v, child: child)),
          child: fill,
        );
        return AnimatedPositionedDirectional(
          key: ValueKey(key),
          duration: glide ? motion : Duration.zero,
          curve: theme.motion.spring,
          start: col * cellWidth + (cellWidth - diameter) / 2,
          top: top(row),
          width: diameter,
          height: diameter,
          child: appear,
        );
      }

      final layers = <Widget>[];

      // The range band, one rounded segment per week row.
      final sel = context.selection;
      if (sel is CalendarRangeSnapshot &&
          sel.start != null &&
          sel.end != null &&
          sel.start!.isBefore(sel.end!)) {
        for (var r = 0; r < weeks.length; r++) {
          final week = weeks[r];
          final covered = [
            for (var c = 0; c < 7; c++)
              if (week[c].isInMonth &&
                  !week[c].date.isBefore(sel.start!) &&
                  !week[c].date.isAfter(sel.end!))
                c
          ];
          if (covered.isEmpty) continue;
          final first = covered.first, last = covered.last;
          final startX = first * cellWidth +
              (week[first].date == sel.start ? cellWidth / 2 : 0);
          final endX = (last + 1) * cellWidth -
              (week[last].date == sel.end ? cellWidth / 2 : 0);
          if (endX <= startX) continue;
          layers.add(PositionedDirectional(
            key: ValueKey('band-$r-${sel.start}-${sel.end}'),
            start: startX,
            top: top(r),
            width: endX - startX,
            height: diameter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: motion,
              curve: theme.motion.standard,
              builder: (_, v, child) => Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: FractionallySizedBox(
                    widthFactor: math.max(v, 0.01),
                    heightFactor: 1,
                    child: child),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(diameter / 2),
                ),
              ),
            ),
          ));
        }
      }

      // Selection circles: single and range caps glide between days.
      switch (sel) {
        case CalendarSingle(:final date):
          final at = locate(date);
          if (at != null) layers.add(circle('single', at));
        case CalendarMultiple(:final dates):
          for (final d in dates) {
            final at = locate(d);
            if (at != null) {
              layers.add(circle('multi-${d.millisecondsSinceEpoch}', at,
                  glide: false));
            }
          }
        case CalendarRangeSnapshot(:final start, :final end):
          final a = locate(start);
          if (a != null) layers.add(circle('start', a));
          final b = locate(end);
          if (b != null && end != start) layers.add(circle('end', b));
      }

      final rows = Column(
        children: [
          for (var r = 0; r < weeks.length; r++) ...[
            if (r > 0) SizedBox(height: rowSpacing),
            SizedBox(
              height: cellHeight,
              child: Row(children: [
                for (final day in weeks[r])
                  Expanded(
                      child: _DayCell(
                          day: day, context: context, diameter: diameter)),
              ]),
            ),
          ],
        ],
      );

      return SizedBox(
        height: heightFor(weeks.length, cellHeight, rowSpacing),
        child: Stack(clipBehavior: Clip.none, children: [
          ...layers,
          Positioned.fill(child: rows),
        ]),
      );
    });
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(
      {required this.day, required this.context, required this.diameter});

  final KitoCalendarGridDay day;
  final CalendarDayContext context;
  final double diameter;

  @override
  Widget build(BuildContext buildContext) {
    final theme = buildContext.kito;
    final date = day.date;
    final c = context;
    if (!day.isInMonth) {
      return ExcludeSemantics(
        child: Center(
          child: Text(c.config.day(date),
              style: theme.typography.body.copyWith(
                  color: theme.colors.onSurface.withValues(alpha: 0.22))),
        ),
      );
    }
    final isToday = date == c.today;
    final disabled = c.isDisabled(date);
    final unavailable = !disabled && c.isUnavailable(date);
    final fill = c._fill(date);
    final filled = fill != _Fill.none;
    final inBand = c._inBand(date);
    final events = c.eventsByDay[date] ?? const <KitoCalendarEvent>[];
    final heat = c.heat[date];

    Color text;
    if (filled || (heat != null && heat > 0.55)) {
      text = c.palette.onAccent;
    } else if (isToday) {
      text = c.palette.accent;
    } else {
      text = theme.colors.onSurface;
    }

    final dotColors = <Color>[];
    for (final e in events) {
      if (!dotColors.contains(e.color)) dotColors.add(e.color);
      if (dotColors.length == 3) break;
    }

    final number = Text(
      c.config.day(date),
      maxLines: 1,
      style: (filled || isToday
              ? theme.typography.bodyEmphasized
              : theme.typography.body)
          .copyWith(
        color: text,
        fontFeatures: const [FontFeature.tabularFigures()],
        decoration: unavailable ? TextDecoration.lineThrough : null,
        decorationColor: theme.colors.onSurface.withValues(alpha: 0.5),
      ),
    );

    final content = Stack(
      alignment: Alignment.center,
      children: [
        if (heat != null && !filled)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                duration: KitoMotion.of(buildContext, theme.motion.medium),
                decoration: BoxDecoration(
                  color: c.palette.accent
                      .withValues(alpha: 0.06 + 0.8 * heat.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(theme.radii.md),
                ),
              ),
            ),
          ),
        if (isToday && !filled)
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.palette.accent, width: 1.5),
            ),
          ),
        CalendarPop(trigger: fill, child: number),
        if (dotColors.isNotEmpty)
          Positioned(
            bottom: math.max(2, (diameter * 0.18)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final color in dotColors)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: filled ? c.palette.onAccent : color,
                        shape: BoxShape.circle),
                  ),
                ),
            ]),
          ),
      ],
    );

    final parts = [
      if (isToday) 'Today',
      switch (fill) {
        _Fill.single || _Fill.multiple => 'Selected',
        _Fill.rangeStart => 'Start date',
        _Fill.rangeEnd => 'End date',
        _Fill.none => inBand ? 'In selected range' : null,
      },
      if (unavailable) 'Unavailable',
      if (events.isNotEmpty)
        events.length == 1 ? '1 event' : '${events.length} events',
      if (heat != null) 'Activity ${(heat * 100).round()} percent',
    ].nonNulls.join(', ');

    final enabled = !disabled && !unavailable;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: filled,
      label: c.config.fullDate(date),
      value: parts.isEmpty ? null : parts,
      excludeSemantics: true,
      onTap: enabled ? () => c.onTap(date) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => c.onTap(date) : null,
        child: KitoPressable(
          enabled: enabled,
          scale: 0.88,
          child: AnimatedOpacity(
            duration: KitoMotion.of(buildContext, theme.motion.fast),
            opacity: disabled
                ? 0.3
                : unavailable
                    ? 0.45
                    : 1,
            child: content,
          ),
        ),
      ),
    );
  }
}
