// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'math.dart';
import 'models.dart';
import 'parts.dart';

/// A swipeable strip of week pills: weekday, date and an event dot.
///
/// The selected pill glides between days. Swiping to another week keeps the same weekday
/// selected there; setting [selected] from outside pages to its week.
///
/// ```dart
/// KitoWeekStrip(
///   selected: day,
///   onChanged: (d) => setState(() => day = d),
///   events: classes,
/// )
/// ```
class KitoWeekStrip extends StatefulWidget {
  /// Creates a week strip.
  const KitoWeekStrip({
    super.key,
    required this.selected,
    required this.onChanged,
    this.tint,
    this.events = const [],
    this.disablePastDates = false,
    this.showsHeader = true,
    this.firstWeekday,
  });

  /// The selected day.
  final DateTime selected;

  /// Called with the newly selected day (at midnight).
  final ValueChanged<DateTime> onChanged;

  /// Replaces the theme's primary colour.
  final Color? tint;

  /// Puts a dot under each day with events.
  final List<KitoCalendarEvent> events;

  /// Fades days before today and stops them being picked.
  final bool disablePastDates;

  /// Shows the month title and the "Today" capsule above the strip.
  final bool showsHeader;

  /// Overrides the locale's first day of the week.
  final int? firstWeekday;

  @override
  State<KitoWeekStrip> createState() => _KitoWeekStripState();
}

class _KitoWeekStripState extends State<KitoWeekStrip> {
  PageController? _pages;
  List<DateTime> _weeks = const [];
  int _index = 0;
  int? _programmatic;
  bool _forward = true;

  int _first(KitoCalendarConfig config) =>
      widget.firstWeekday ?? config.firstWeekday;

  void _setup(KitoCalendarConfig config) {
    final today = config.today;
    final selected = KitoCalendarMath.dateOnly(widget.selected);
    final first = _first(config);
    DateTime earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
    DateTime later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
    final lower = widget.disablePastDates
        ? earlier(today, selected)
        : earlier(KitoCalendarMath.addDays(today, -7 * 104), selected);
    final upper = later(KitoCalendarMath.addDays(today, 7 * 104), selected);
    _weeks = KitoCalendarMath.weeks(lower, upper, firstWeekday: first);
    _index = _weeks
        .indexOf(KitoCalendarMath.startOfWeek(selected, firstWeekday: first))
        .clamp(0, _weeks.length - 1);
    _pages?.dispose();
    _pages = PageController(initialPage: _index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pages == null) _setup(KitoCalendarConfig.of(context));
  }

  @override
  void didUpdateWidget(KitoWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final config = KitoCalendarConfig.of(context);
    if (widget.disablePastDates != oldWidget.disablePastDates ||
        widget.firstWeekday != oldWidget.firstWeekday) {
      _setup(config);
      return;
    }
    final week = KitoCalendarMath.startOfWeek(widget.selected,
        firstWeekday: _first(config));
    final target = _weeks.indexOf(week);
    if (target < 0) {
      _setup(config);
      return;
    }
    if (target != _index) {
      _programmatic = target;
      final pages = _pages!;
      if (!pages.hasClients) return;
      if (context.reduceMotion || (target - _index).abs() > 3) {
        pages.jumpToPage(target);
      } else {
        pages.animateToPage(target,
            duration: context.kito.motion.slow, curve: Curves.easeInOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _select(DateTime day) {
    final d = KitoCalendarMath.dateOnly(day);
    if (d == KitoCalendarMath.dateOnly(widget.selected)) return;
    HapticFeedback.selectionClick();
    widget.onChanged(d);
  }

  void _onPage(int index, KitoCalendarConfig config) {
    final old = _index;
    setState(() {
      _forward = index > old;
      _index = index;
    });
    if (_programmatic != null) {
      if (_programmatic == index) _programmatic = null;
      return;
    }
    // A swipe: keep the same weekday selected in the new week.
    final first = _first(config);
    final selected = KitoCalendarMath.dateOnly(widget.selected);
    final offset = KitoCalendarMath.nights(
        KitoCalendarMath.startOfWeek(selected, firstWeekday: first), selected);
    var day = KitoCalendarMath.addDays(_weeks[index], offset);
    if (widget.disablePastDates && day.isBefore(config.today)) {
      day = config.today;
    }
    _select(day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    final palette = CalendarPalette.of(context, widget.tint);
    final today = config.today;
    final selected = KitoCalendarMath.dateOnly(widget.selected);
    final byDay = KitoCalendarMath.eventsByDay(widget.events);
    final height =
        MediaQuery.textScalerOf(context).scale(76).clamp(76.0, 104.0);
    final first = _first(config);
    final selectionInView = _weeks.isNotEmpty &&
        KitoCalendarMath.startOfWeek(selected, firstWeekday: first) ==
            _weeks[_index];
    final titleDate = selectionInView ? selected : _weeks[_index];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showsHeader) ...[
          Row(children: [
            Expanded(
                child: CalendarRollingTitle(config.monthTitle(titleDate),
                    forward: _forward)),
            AnimatedSwitcher(
              duration: KitoMotion.of(context, theme.motion.medium),
              switchInCurve: theme.motion.spring,
              transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(a),
                      child: child)),
              child: selected != today
                  ? CalendarTodayCapsule(
                      key: const ValueKey('today'),
                      palette: palette,
                      onPressed: () => _select(today))
                  : const SizedBox(key: ValueKey('none'), height: 44),
            ),
          ]),
          SizedBox(height: theme.spacing.sm),
        ],
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pages,
            itemCount: _weeks.length,
            onPageChanged: (i) => _onPage(i, config),
            itemBuilder: (context, i) => _WeekPage(
              days: KitoCalendarMath.week(_weeks[i], firstWeekday: first),
              selected: selected,
              today: today,
              byDay: byDay,
              palette: palette,
              config: config,
              disablePast: widget.disablePastDates,
              onTap: _select,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekPage extends StatelessWidget {
  const _WeekPage({
    required this.days,
    required this.selected,
    required this.today,
    required this.byDay,
    required this.palette,
    required this.config,
    required this.disablePast,
    required this.onTap,
  });

  final List<DateTime> days;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, List<KitoCalendarEvent>> byDay;
  final CalendarPalette palette;
  final KitoCalendarConfig config;
  final bool disablePast;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final gap = theme.spacing.xs;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.xxs),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = math.max((constraints.maxWidth - gap * 6) / 7, 1.0);
        final index = days.indexOf(selected);
        final radius = BorderRadius.circular(theme.radii.pill);
        return Stack(children: [
          if (index >= 0)
            AnimatedPositionedDirectional(
              duration: KitoMotion.of(context, theme.motion.medium),
              curve: theme.motion.spring,
              start: index * (width + gap),
              top: 0,
              bottom: 0,
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(palette.accent, Colors.white, 0.12)!,
                      palette.accent
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: palette.accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
              ),
            ),
          Row(children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(width: width, child: _pill(context, days[i], radius)),
            ],
          ]),
        ]);
      }),
    );
  }

  Widget _pill(BuildContext context, DateTime day, BorderRadius radius) {
    final theme = context.kito;
    final isSelected = day == selected;
    final isToday = day == today;
    final disabled = disablePast && day.isBefore(today);
    final events = byDay[day] ?? const <KitoCalendarEvent>[];
    final fg = isSelected
        ? palette.onAccent
        : isToday
            ? palette.accent
            : theme.colors.onSurface;
    final value = [
      if (isToday) 'Today',
      if (events.isNotEmpty)
        events.length == 1 ? '1 event' : '${events.length} events',
    ].join(', ');
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !disabled,
      label: config.fullDate(day),
      value: value.isEmpty ? null : value,
      excludeSemantics: true,
      onTap: disabled ? null : () => onTap(day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onTap(day),
        child: KitoPressable(
          enabled: !disabled,
          scale: 0.92,
          child: AnimatedOpacity(
            opacity: disabled ? 0.35 : 1,
            duration: KitoMotion.of(context, theme.motion.fast),
            child: AnimatedContainer(
              duration: KitoMotion.of(context, theme.motion.medium),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: isSelected || isToday ? null : theme.colors.surfaceMuted,
                border: isToday && !isSelected
                    ? Border.all(
                        color: palette.accent.withValues(alpha: 0.45),
                        width: 1.5)
                    : null,
              ),
              child: CalendarPop(
                trigger: isSelected,
                amount: 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(config.weekdayShort(day).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: theme.typography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: fg.withValues(
                                alpha: isSelected ? 0.85 : 0.55))),
                    SizedBox(height: theme.spacing.xxs),
                    AnimatedDefaultTextStyle(
                      duration: KitoMotion.of(context, theme.motion.fast),
                      style: theme.typography.title.copyWith(
                          fontSize: 20,
                          color: fg,
                          fontFeatures: const [FontFeature.tabularFigures()]),
                      child: Text(config.day(day), maxLines: 1),
                    ),
                    SizedBox(height: theme.spacing.xxs),
                    AnimatedOpacity(
                      opacity: events.isEmpty ? 0 : 1,
                      duration: KitoMotion.of(context, theme.motion.fast),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? palette.onAccent
                              : (events.firstOrNull?.color ??
                                  Colors.transparent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
