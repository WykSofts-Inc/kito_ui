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

enum _Mode { single, multiple, range }

/// A month grid you swipe through, with single, multiple or range selection.
///
/// Swipe or use the chevrons to change month; the title rolls to the new one and a "Today"
/// capsule brings you back. Set the selection from outside (a preset, a "tomorrow" button)
/// and the calendar pages to it. The selection circle glides between days, and a finished
/// range draws one continuous band between its caps.
///
/// ```dart
/// KitoMonthCalendar.single(selected: day, onChanged: (d) => setState(() => day = d));
///
/// KitoMonthCalendar.range(
///   selection: stay,
///   onChanged: (s) => setState(() => stay = s),
///   disablePastDates: true,
/// );
/// ```
///
/// Weeks start on the locale's first weekday (override with [firstWeekday] or a
/// [KitoCalendarScope]); names come from `intl`. Right-to-left layouts run the grid and the
/// paging from the right.
class KitoMonthCalendar extends StatefulWidget {
  /// Pick one day.
  const KitoMonthCalendar.single({
    super.key,
    DateTime? selected,
    required ValueChanged<DateTime> onChanged,
    this.tint,
    this.events = const [],
    this.heatmap = const {},
    this.minDate,
    this.maxDate,
    this.disablePastDates = false,
    this.isUnavailable,
    this.onMonthChanged,
    this.initialMonth,
    this.firstWeekday,
  })  : _mode = _Mode.single,
        _single = selected,
        _onSingle = onChanged,
        _multiple = const {},
        _onMultiple = null,
        _range = null,
        _onRange = null;

  /// Pick any number of days; tap one again to remove it.
  const KitoMonthCalendar.multiple({
    super.key,
    Set<DateTime> selected = const {},
    required ValueChanged<Set<DateTime>> onChanged,
    this.tint,
    this.events = const [],
    this.heatmap = const {},
    this.minDate,
    this.maxDate,
    this.disablePastDates = false,
    this.isUnavailable,
    this.onMonthChanged,
    this.initialMonth,
    this.firstWeekday,
  })  : _mode = _Mode.multiple,
        _single = null,
        _onSingle = null,
        _multiple = selected,
        _onMultiple = onChanged,
        _range = null,
        _onRange = null;

  /// Pick a range: a start, then an end. See [KitoCalendarRangeSelection] for the rules.
  const KitoMonthCalendar.range({
    super.key,
    required KitoCalendarRangeSelection selection,
    required ValueChanged<KitoCalendarRangeSelection> onChanged,
    this.tint,
    this.events = const [],
    this.heatmap = const {},
    this.minDate,
    this.maxDate,
    this.disablePastDates = false,
    this.isUnavailable,
    this.onMonthChanged,
    this.initialMonth,
    this.firstWeekday,
  })  : _mode = _Mode.range,
        _single = null,
        _onSingle = null,
        _multiple = const {},
        _onMultiple = null,
        _range = selection,
        _onRange = onChanged;

  final _Mode _mode;
  final DateTime? _single;
  final ValueChanged<DateTime>? _onSingle;
  final Set<DateTime> _multiple;
  final ValueChanged<Set<DateTime>>? _onMultiple;
  final KitoCalendarRangeSelection? _range;
  final ValueChanged<KitoCalendarRangeSelection>? _onRange;

  /// Replaces the theme's primary colour for selections and today.
  final Color? tint;

  /// Up to three coloured dots under each day with events.
  final List<KitoCalendarEvent> events;

  /// Shades days by intensity, 0–1, like a contribution graph. Keys can be any time on the day.
  final Map<DateTime, double> heatmap;

  /// Days before this are faded and can't be picked; you can't page before its month.
  final DateTime? minDate;

  /// Days after this are faded and can't be picked; you can't page past its month.
  final DateTime? maxDate;

  /// Fades days before today and stops them being picked.
  final bool disablePastDates;

  /// Strikes through days your rule marks unavailable: sold out, closed, fully booked.
  final bool Function(DateTime day)? isUnavailable;

  /// Called with the first of the month when the visible month changes.
  final ValueChanged<DateTime>? onMonthChanged;

  /// The month shown first when nothing is selected; this month by default.
  final DateTime? initialMonth;

  /// Overrides the locale's first day of the week (`DateTime.monday` … `DateTime.sunday`).
  final int? firstWeekday;

  @override
  State<KitoMonthCalendar> createState() => _KitoMonthCalendarState();
}

class _KitoMonthCalendarState extends State<KitoMonthCalendar> {
  PageController? _pages;
  List<DateTime> _months = const [];
  int _index = 0;
  bool _forward = true;

  DateTime? get _anchor {
    final d = switch (widget._mode) {
      _Mode.single => widget._single,
      _Mode.multiple => widget._multiple.isEmpty
          ? null
          : widget._multiple.reduce((a, b) => a.isBefore(b) ? a : b),
      _Mode.range => widget._range?.start,
    };
    return d == null ? null : KitoCalendarMath.startOfMonth(d);
  }

  List<DateTime> _monthList(DateTime today) {
    final anchor = _anchor ?? today;
    DateTime earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
    DateTime later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
    var lower = widget.minDate ??
        earlier(KitoCalendarMath.addMonths(today, -60), anchor);
    if (widget.disablePastDates && widget.minDate == null) {
      lower = earlier(today, anchor);
    }
    final upper =
        widget.maxDate ?? later(KitoCalendarMath.addMonths(today, 60), anchor);
    final months =
        KitoCalendarMath.months(lower, upper.isBefore(lower) ? lower : upper);
    return months.isEmpty ? [KitoCalendarMath.startOfMonth(lower)] : months;
  }

  void _setup(DateTime today) {
    final visible = _pages == null ? null : _months[_index];
    _months = _monthList(today);
    final wanted = visible ??
        KitoCalendarMath.startOfMonth(_anchor ?? widget.initialMonth ?? today);
    var index = _months.indexOf(wanted);
    if (index < 0) {
      index = _months.indexWhere((m) => !m.isBefore(wanted));
      if (index < 0) index = _months.length - 1;
    }
    _index = index;
    if (_pages == null) {
      _pages = PageController(initialPage: index);
    } else if (_pages!.hasClients && _pages!.page?.round() != index) {
      _pages!.jumpToPage(index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pages == null) _setup(KitoCalendarConfig.of(context).today);
  }

  @override
  void didUpdateWidget(KitoMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final today = KitoCalendarConfig.of(context).today;
    if (widget.minDate != oldWidget.minDate ||
        widget.maxDate != oldWidget.maxDate ||
        widget.disablePastDates != oldWidget.disablePastDates) {
      _setup(today);
    }
    final anchor = _anchor;
    if (anchor != null && anchor != _months[_index]) {
      final oldAnchor = switch (oldWidget._mode) {
        _Mode.single => oldWidget._single,
        _Mode.multiple => null,
        _Mode.range => oldWidget._range?.start,
      };
      final moved = oldAnchor == null ||
          KitoCalendarMath.startOfMonth(oldAnchor) != anchor;
      if (moved) {
        if (!_months.contains(anchor)) _setup(today);
        final target = _months.indexOf(anchor);
        if (target >= 0) _goTo(target);
      }
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    if (context.reduceMotion || (index - _index).abs() > 3) {
      pages.jumpToPage(index);
    } else {
      pages.animateToPage(index,
          duration: context.kito.motion.slow, curve: Curves.easeInOutCubic);
    }
  }

  void _onPage(int index) {
    if (index == _index) return;
    setState(() {
      _forward = index > _index;
      _index = index;
    });
    HapticFeedback.lightImpact();
    widget.onMonthChanged?.call(_months[index]);
  }

  void _tap(DateTime day) {
    HapticFeedback.selectionClick();
    switch (widget._mode) {
      case _Mode.single:
        widget._onSingle!(day);
      case _Mode.multiple:
        final next = {...widget._multiple.map(KitoCalendarMath.dateOnly)};
        if (!next.remove(day)) next.add(day);
        widget._onMultiple!(next);
      case _Mode.range:
        widget._onRange!(widget._range!.select(day));
    }
  }

  CalendarSelection get _selection => switch (widget._mode) {
        _Mode.single => CalendarSingle(widget._single == null
            ? null
            : KitoCalendarMath.dateOnly(widget._single!)),
        _Mode.multiple => CalendarMultiple(
            {...widget._multiple.map(KitoCalendarMath.dateOnly)}),
        _Mode.range =>
          CalendarRangeSnapshot(widget._range?.start, widget._range?.end),
      };

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
    final today = config.today;
    final minDay = widget.minDate == null
        ? null
        : KitoCalendarMath.dateOnly(widget.minDate!);
    final maxDay = widget.maxDate == null
        ? null
        : KitoCalendarMath.dateOnly(widget.maxDate!);
    final heat = <DateTime, double>{};
    widget.heatmap.forEach((k, v) {
      final d = KitoCalendarMath.dateOnly(k);
      final value = v.clamp(0.0, 1.0);
      heat[d] = heat[d] == null || heat[d]! < value ? value : heat[d]!;
    });
    final dayContext = CalendarDayContext(
      config: config,
      palette: palette,
      today: today,
      eventsByDay: KitoCalendarMath.eventsByDay(widget.events),
      heat: heat,
      selection: _selection,
      isDisabled: (d) =>
          (widget.disablePastDates && d.isBefore(today)) ||
          (minDay != null && d.isBefore(minDay)) ||
          (maxDay != null && d.isAfter(maxDay)),
      isUnavailable: widget.isUnavailable ?? (_) => false,
      onTap: _tap,
    );
    final cellHeight =
        MediaQuery.textScalerOf(context).scale(46).clamp(46.0, 64.0);
    final rowSpacing = theme.spacing.xs;
    final shown = _months[_index];
    final thisMonth = KitoCalendarMath.startOfMonth(today);
    final canBack = _index > 0, canForward = _index < _months.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(
            child: CalendarRollingTitle(config.monthTitle(shown),
                forward: _forward),
          ),
          AnimatedSwitcher(
            duration: KitoMotion.of(context, theme.motion.medium),
            switchInCurve: theme.motion.spring,
            transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                    scale: Tween(begin: 0.6, end: 1.0).animate(a),
                    child: child)),
            child: shown != thisMonth && _months.contains(thisMonth)
                ? CalendarTodayCapsule(
                    key: const ValueKey('today'),
                    palette: palette,
                    onPressed: () => _goTo(_months.indexOf(thisMonth)))
                : const SizedBox(key: ValueKey('none')),
          ),
          SizedBox(width: theme.spacing.xs),
          CalendarIconButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous month',
            onPressed: canBack ? () => _goTo(_index - 1) : null,
          ),
          CalendarIconButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next month',
            onPressed: canForward ? () => _goTo(_index + 1) : null,
          ),
        ]),
        SizedBox(height: theme.spacing.sm),
        CalendarWeekdayHeader(config: config),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: CalendarMonthPage.heightFor(6, cellHeight, rowSpacing),
          child: PageView.builder(
            controller: _pages,
            itemCount: _months.length,
            onPageChanged: _onPage,
            itemBuilder: (context, i) => Semantics(
              container: true,
              label: config.monthTitle(_months[i]),
              child: CalendarMonthPage(
                grid: KitoCalendarMonthGrid(_months[i],
                    firstWeekday: config.firstWeekday, fixedSixWeeks: true),
                context: dayContext,
                cellHeight: cellHeight,
                rowSpacing: rowSpacing,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
