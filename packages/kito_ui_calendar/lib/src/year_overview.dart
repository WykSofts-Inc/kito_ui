// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'math.dart';
import 'models.dart';
import 'month_page.dart';
import 'parts.dart';

/// Twelve mini months for a year; tap one to zoom into it and pick a day.
///
/// Days with events are tinted in the mini months, and the zoomed month lists the selected
/// day's first three events. Chevrons change the year (or, zoomed in, the month).
///
/// ```dart
/// KitoYearOverview(
///   selected: picked,
///   onChanged: (d) => setState(() => picked = d),
///   events: holidays,
/// )
/// ```
class KitoYearOverview extends StatefulWidget {
  /// Creates a year overview.
  const KitoYearOverview({
    super.key,
    this.year,
    required this.selected,
    required this.onChanged,
    this.tint,
    this.events = const [],
    this.firstWeekday,
  });

  /// The year shown first; the selection's year, or this year, when null.
  final int? year;

  /// The selected day, or null.
  final DateTime? selected;

  /// Called with a picked day.
  final ValueChanged<DateTime> onChanged;

  /// Replaces the theme's primary colour.
  final Color? tint;

  /// Marks days in the mini months and lists them under the zoomed month.
  final List<KitoCalendarEvent> events;

  /// Overrides the locale's first day of the week.
  final int? firstWeekday;

  @override
  State<KitoYearOverview> createState() => _KitoYearOverviewState();
}

class _KitoYearOverviewState extends State<KitoYearOverview> {
  int? _year;
  DateTime? _focused;
  bool _forward = true;
  Alignment _zoomFrom = Alignment.center;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _year ??= widget.year ??
        (widget.selected ?? KitoCalendarConfig.of(context).now).year;
  }

  void _changeYear(int by) {
    HapticFeedback.lightImpact();
    setState(() {
      _forward = by > 0;
      _year = _year! + by;
    });
  }

  void _focus(DateTime? month, {Alignment from = Alignment.center}) {
    HapticFeedback.lightImpact();
    setState(() {
      if (month != null) _zoomFrom = from;
      _focused = month;
      if (month != null) _year = month.year;
    });
  }

  void _moveFocus(int by) {
    HapticFeedback.lightImpact();
    setState(() {
      _forward = by > 0;
      _focused = KitoCalendarMath.addMonths(_focused!, by);
      _year = _focused!.year;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final base = KitoCalendarConfig.of(context);
    final config = widget.firstWeekday == null
        ? base
        : KitoCalendarConfig(
            locale: base.locale,
            firstWeekday: widget.firstWeekday,
            weekendDays: base.weekendDays,
            clock: base.clock,
            use24HourFormat: base.use24HourFormat);
    final palette = CalendarPalette.of(context, widget.tint);
    final byDay = KitoCalendarMath.eventsByDay(widget.events);
    final focused = _focused;
    final child = focused == null
        ? KeyedSubtree(
            key: ValueKey('year-$_year'),
            child: _overview(context, config, palette, byDay))
        : KeyedSubtree(
            key: const ValueKey('month'),
            child: _detail(context, focused, config, palette, byDay));
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, theme.motion.slow),
      switchInCurve: theme.motion.emphasized,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        final isDetail = child.key == const ValueKey('month');
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: _zoomFrom,
            scale: Tween(begin: isDetail ? 0.3 : 1.08, end: 1.0)
                .animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _overview(BuildContext context, KitoCalendarConfig config,
      CalendarPalette palette, Map<DateTime, List<KitoCalendarEvent>> byDay) {
    final theme = context.kito;
    final year = _year!;
    final thisMonth = KitoCalendarMath.startOfMonth(config.today);
    final selected = widget.selected == null
        ? null
        : KitoCalendarMath.dateOnly(widget.selected!);
    Widget mini(int m) {
      final month = DateTime(year, m);
      final eventDays =
          byDay.keys.where((d) => d.year == year && d.month == m).length;
      final row = (m - 1) ~/ 3, col = (m - 1) % 3;
      final rtl = context.isRtl;
      final from = Alignment((rtl ? 2 - col : col) - 1.0, row * 2 / 3 - 1.0);
      return Semantics(
        button: true,
        label: config.monthTitle(month),
        value: eventDays == 0
            ? null
            : eventDays == 1
                ? '1 day with events'
                : '$eventDays days with events',
        hint: 'Opens the month',
        excludeSemantics: true,
        onTap: () => _focus(month, from: from),
        child: GestureDetector(
          onTap: () => _focus(month, from: from),
          child: KitoPressable(
            scale: 0.95,
            child: _MiniMonth(
              month: month,
              isCurrent: month == thisMonth,
              today: config.today,
              selected: selected,
              byDay: byDay,
              palette: palette,
              config: config,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: CalendarRollingTitle(
              config.year(DateTime(year)),
              forward: _forward,
              style: theme.typography.display
                  .copyWith(color: theme.colors.onSurface),
            ),
          ),
          CalendarIconButton(
              icon: Icons.chevron_left_rounded,
              label: 'Previous year',
              onPressed: () => _changeYear(-1)),
          CalendarIconButton(
              icon: Icons.chevron_right_rounded,
              label: 'Next year',
              onPressed: () => _changeYear(1)),
        ]),
        SizedBox(height: theme.spacing.lg),
        for (var r = 0; r < 4; r++) ...[
          if (r > 0) SizedBox(height: theme.spacing.sm),
          Row(children: [
            for (var c = 0; c < 3; c++) ...[
              if (c > 0) SizedBox(width: theme.spacing.sm),
              Expanded(child: mini(r * 3 + c + 1)),
            ],
          ]),
        ],
      ],
    );
  }

  Widget _detail(
      BuildContext context,
      DateTime month,
      KitoCalendarConfig config,
      CalendarPalette palette,
      Map<DateTime, List<KitoCalendarEvent>> byDay) {
    final theme = context.kito;
    final selected = widget.selected == null
        ? null
        : KitoCalendarMath.dateOnly(widget.selected!);
    final dayEvents = selected == null
        ? const <KitoCalendarEvent>[]
        : (byDay[selected] ?? const <KitoCalendarEvent>[]);
    final dayContext = CalendarDayContext(
      config: config,
      palette: palette,
      today: config.today,
      eventsByDay: byDay,
      heat: const {},
      selection: CalendarSingle(selected),
      isDisabled: (_) => false,
      isUnavailable: (_) => false,
      onTap: (d) {
        HapticFeedback.selectionClick();
        widget.onChanged(d);
      },
    );
    final cellHeight =
        MediaQuery.textScalerOf(context).scale(44).clamp(44.0, 60.0);
    return Container(
      padding: EdgeInsets.all(theme.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radii.xl),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Semantics(
              button: true,
              label: 'Back to ${config.year(month)}',
              excludeSemantics: true,
              onTap: () => _focus(null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _focus(null),
                child: SizedBox(
                  height: 44,
                  child: KitoPressable(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chevron_left_rounded, color: palette.accent),
                      Text(config.year(month),
                          style: theme.typography.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.accent)),
                    ]),
                  ),
                ),
              ),
            ),
            const Spacer(),
            CalendarIconButton(
                icon: Icons.chevron_left_rounded,
                label: 'Previous month',
                onPressed: () => _moveFocus(-1)),
            CalendarIconButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next month',
                onPressed: () => _moveFocus(1)),
          ]),
          CalendarRollingTitle(config.monthName(month), forward: _forward),
          SizedBox(height: theme.spacing.md),
          CalendarWeekdayHeader(config: config),
          SizedBox(height: theme.spacing.sm),
          CalendarMonthPage(
            grid: KitoCalendarMonthGrid(month,
                firstWeekday: config.firstWeekday, fixedSixWeeks: true),
            context: dayContext,
            cellHeight: cellHeight,
            rowSpacing: theme.spacing.xxs,
          ),
          AnimatedSize(
            duration: KitoMotion.of(context, theme.motion.medium),
            curve: theme.motion.standard,
            alignment: Alignment.topCenter,
            child: dayEvents.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: EdgeInsets.only(top: theme.spacing.md),
                    child: Column(children: [
                      for (final e in dayEvents.take(3))
                        MergeSemantics(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: theme.spacing.xxs),
                            child: Row(children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                    color: e.color,
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                              SizedBox(width: theme.spacing.sm),
                              Expanded(
                                child: Text(e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.typography.label.copyWith(
                                        color: theme.colors.onSurface)),
                              ),
                              Text(
                                  e.isAllDay ? 'All day' : config.time(e.start),
                                  style: theme.typography.caption.copyWith(
                                      color: theme.colors.onSurface
                                          .withValues(alpha: 0.6))),
                            ]),
                          ),
                        ),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.month,
    required this.isCurrent,
    required this.today,
    required this.selected,
    required this.byDay,
    required this.palette,
    required this.config,
  });

  final DateTime month;
  final bool isCurrent;
  final DateTime today;
  final DateTime? selected;
  final Map<DateTime, List<KitoCalendarEvent>> byDay;
  final CalendarPalette palette;
  final KitoCalendarConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final rowHeight =
        MediaQuery.textScalerOf(context).scale(14).clamp(14.0, 20.0);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.xs + 2, vertical: theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(
            color: isCurrent
                ? palette.accent.withValues(alpha: 0.5)
                : theme.colors.border,
            width: isCurrent ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config.shortMonth(month),
              maxLines: 1,
              style: theme.typography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? palette.accent : theme.colors.onSurface)),
          SizedBox(height: theme.spacing.xs),
          SizedBox(
            height: rowHeight * 6 + 5,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniMonthPainter(
                grid: KitoCalendarMonthGrid(month,
                    firstWeekday: config.firstWeekday, fixedSixWeeks: true),
                today: today,
                selected: selected,
                byDay: byDay,
                accent: palette.accent,
                onAccent: palette.onAccent,
                text: theme.colors.onSurface.withValues(alpha: 0.85),
                style: theme.typography.caption,
                rtl: context.isRtl,
                config: config,
                textScaler: MediaQuery.textScalerOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMonthPainter extends CustomPainter {
  _MiniMonthPainter({
    required this.grid,
    required this.today,
    required this.selected,
    required this.byDay,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.style,
    required this.rtl,
    required this.config,
    required this.textScaler,
  });

  final KitoCalendarMonthGrid grid;
  final DateTime today;
  final DateTime? selected;
  final Map<DateTime, List<KitoCalendarEvent>> byDay;
  final Color accent;
  final Color onAccent;
  final Color text;
  final TextStyle style;
  final bool rtl;
  final KitoCalendarConfig config;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 7;
    final h = (size.height - 5) / 6;
    final r = (h < w ? h : w) / 2 + 0.5;
    for (var i = 0; i < grid.days.length; i++) {
      final day = grid.days[i];
      if (!day.isInMonth) continue;
      final row = i ~/ 7, col = i % 7;
      final x = rtl ? size.width - (col + 0.5) * w : (col + 0.5) * w;
      final c = Offset(x, row * (h + 1) + h / 2);
      final isToday = day.date == today;
      final events = byDay[day.date];
      if (isToday) {
        canvas.drawCircle(c, r, Paint()..color = accent);
      } else if (events != null && events.isNotEmpty) {
        canvas.drawCircle(
            c, r, Paint()..color = events.first.color.withValues(alpha: 0.28));
      }
      if (day.date == selected && !isToday) {
        canvas.drawCircle(
            c,
            r - 0.5,
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
      final painter = TextPainter(
        text: TextSpan(
          text: config.day(day.date),
          style: style.copyWith(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? onAccent : text,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler.clamp(maxScaleFactor: 1.4),
      )..layout();
      painter.paint(canvas, c - Offset(painter.width / 2, painter.height / 2));
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(_MiniMonthPainter old) =>
      old.grid.month != grid.month ||
      old.today != today ||
      old.selected != selected ||
      old.byDay != byDay ||
      old.accent != accent ||
      old.rtl != rtl ||
      old.text != text;
}
