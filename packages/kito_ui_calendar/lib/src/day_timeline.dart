// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'math.dart';
import 'models.dart';

/// One day as a vertical timeline: hour lines, event blocks placed side by side when they
/// overlap, an all-day strip, and a red line at the current time that moves as the minutes
/// pass.
///
/// Given a bounded height it scrolls, opening an hour before now (or before the first event);
/// with unbounded height (inside another scroll view) it lays out at full length.
///
/// ```dart
/// KitoDayTimeline(
///   day: DateTime.now(),
///   events: meetings,
///   startHour: 7,
///   endHour: 22,
///   onEventTap: (e) => open(e),
/// )
/// ```
class KitoDayTimeline extends StatefulWidget {
  /// Creates a timeline.
  const KitoDayTimeline({
    super.key,
    required this.day,
    required this.events,
    this.onEventTap,
    this.hourHeight = 64,
    this.startHour = 0,
    this.endHour = 24,
  }) : assert(startHour >= 0 && startHour < endHour && endHour <= 24);

  /// Any time on the day to show.
  final DateTime day;

  /// The events; those outside the day or the visible hours are left out.
  final List<KitoCalendarEvent> events;

  /// Called when an event block or all-day chip is tapped.
  final ValueChanged<KitoCalendarEvent>? onEventTap;

  /// Logical pixels per hour, before text scaling.
  final double hourHeight;

  /// The first hour line (0–23).
  final int startHour;

  /// The last hour line (1–24).
  final int endHour;

  @override
  State<KitoDayTimeline> createState() => _KitoDayTimelineState();
}

class _KitoDayTimelineState extends State<KitoDayTimeline> {
  final _scroll = ScrollController();
  Timer? _tick;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(KitoDayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!KitoCalendarMath.isSameDay(oldWidget.day, widget.day)) {
      _scrolled = false;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  double _hourHeight(BuildContext context) =>
      math.max(24, MediaQuery.textScalerOf(context).scale(widget.hourHeight));

  void _scrollToStart(double offset) {
    if (_scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = offset.clamp(0.0, _scroll.position.maxScrollExtent);
      if (context.reduceMotion) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target,
            duration: context.kito.motion.slow, curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    final now = config.now;
    final dayStart = KitoCalendarMath.dateOnly(widget.day);
    final dayEnd = KitoCalendarMath.addDays(dayStart, 1);
    DateTime at(int hour) =>
        DateTime(dayStart.year, dayStart.month, dayStart.day, hour);
    final windowStart = at(widget.startHour);
    final windowEnd = at(widget.endHour);
    final hourHeight = _hourHeight(context);
    final total = (widget.endHour - widget.startHour) * hourHeight;
    final labelWidth =
        MediaQuery.textScalerOf(context).scale(52).clamp(52.0, 80.0);
    const minBlock = 24.0;

    final allDay = widget.events
        .where((e) =>
            e.isAllDay && e.start.isBefore(dayEnd) && e.end.isAfter(dayStart))
        .toList();
    final timed = widget.events
        .where((e) =>
            !e.isAllDay &&
            e.start.isBefore(windowEnd) &&
            (e.end.isAfter(windowStart) ||
                (e.end == e.start && !e.start.isBefore(windowStart))))
        .toList();
    final placements = KitoCalendarEventLayout.placements(timed,
        minimumDuration:
            Duration(seconds: (minBlock / hourHeight * 3600).round()));

    double y(DateTime t) =>
        t.difference(windowStart).inSeconds / 3600 * hourHeight;

    final isToday = KitoCalendarMath.isSameDay(dayStart, now);
    int initialHour() {
      if (isToday) return now.hour - 1;
      final starts =
          timed.map((e) => e.start).where((s) => !s.isBefore(dayStart));
      if (starts.isEmpty) return 8;
      return starts.reduce((a, b) => a.isBefore(b) ? a : b).hour - 1;
    }

    final padTop = theme.spacing.md;
    final gap = theme.spacing.sm;

    final Widget content = LayoutBuilder(builder: (context, constraints) {
      final area = math.max(
          constraints.maxWidth - labelWidth - gap - theme.spacing.xs, 1.0);
      final children = <Widget>[];

      // Hour lines and labels.
      for (var h = widget.startHour; h <= widget.endHour; h++) {
        final ly = padTop + (h - widget.startHour) * hourHeight;
        children
          ..add(PositionedDirectional(
            start: 0,
            width: labelWidth,
            top: ly - 8,
            child: Text(
              config.hourLabel(h),
              textAlign: TextAlign.end,
              maxLines: 1,
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onSurface.withValues(alpha: 0.45),
                  fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ))
          ..add(PositionedDirectional(
            start: labelWidth + gap,
            end: 0,
            top: ly,
            height: 0.5,
            child: ColoredBox(color: theme.colors.border),
          ));
      }

      // Events.
      for (final p in placements) {
        final e = p.event;
        final top = y(e.start.isBefore(windowStart) ? windowStart : e.start);
        final bottom = y(e.end.isAfter(windowEnd) ? windowEnd : e.end);
        final height = math.min(math.max(bottom - top, minBlock), total - top);
        final column = area / p.columnCount;
        children.add(PositionedDirectional(
          key: ValueKey('event-${e.id}'),
          start: labelWidth + gap + column * p.column,
          top: padTop + top + 1,
          width: math.max(column - 3, 0),
          height: math.max(height - 2, 0),
          child: _EventBlock(
            event: e,
            height: height,
            isPast: e.end.isBefore(now),
            config: config,
            onTap: widget.onEventTap,
          ),
        ));
      }

      // The now line.
      if (isToday) {
        final ny = y(now);
        if (ny >= 0 && ny <= total) {
          children.add(AnimatedPositionedDirectional(
            duration: KitoMotion.of(context, const Duration(milliseconds: 600)),
            start: 0,
            end: 0,
            top: padTop + ny - 10,
            height: 20,
            child: IgnorePointer(
              child: Semantics(
                label: 'Now, ${config.time(now)}',
                excludeSemantics: true,
                child: Row(children: [
                  SizedBox(
                    width: labelWidth + theme.spacing.xs,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.xs,
                            vertical: theme.spacing.xxs),
                        decoration: BoxDecoration(
                          color: theme.colors.danger,
                          borderRadius: BorderRadius.circular(theme.radii.pill),
                        ),
                        child: FittedBox(
                          child: Text(config.time(now),
                              style: theme.typography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ])),
                        ),
                      ),
                    ),
                  ),
                  _NowDot(color: theme.colors.danger),
                  Expanded(
                      child:
                          Container(height: 1.5, color: theme.colors.danger)),
                ]),
              ),
            ),
          ));
        }
      }

      return SizedBox(
        height: total + padTop * 2,
        child: Stack(clipBehavior: Clip.none, children: children),
      );
    });

    final body = LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) return content;
      final start = (initialHour().clamp(widget.startHour, widget.endHour) -
              widget.startHour) *
          hourHeight;
      _scrollToStart(start);
      return SingleChildScrollView(controller: _scroll, child: content);
    });

    if (allDay.isEmpty) return body;
    return LayoutBuilder(builder: (context, constraints) {
      final strip = _AllDayStrip(
          events: allDay, labelWidth: labelWidth, onTap: widget.onEventTap);
      final divider = Divider(height: 1, color: theme.colors.border);
      if (!constraints.hasBoundedHeight) {
        return Column(
            mainAxisSize: MainAxisSize.min, children: [strip, divider, body]);
      }
      return Column(children: [strip, divider, Expanded(child: body)]);
    });
  }
}

class _AllDayStrip extends StatelessWidget {
  const _AllDayStrip(
      {required this.events, required this.labelWidth, required this.onTap});

  final List<KitoCalendarEvent> events;
  final double labelWidth;
  final ValueChanged<KitoCalendarEvent>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
      child: Row(children: [
        SizedBox(
          width: labelWidth,
          child: Text('All day',
              textAlign: TextAlign.end,
              maxLines: 1,
              style: theme.typography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.onSurface.withValues(alpha: 0.5))),
        ),
        SizedBox(width: theme.spacing.sm),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, __) => SizedBox(width: theme.spacing.xs),
              itemBuilder: (context, i) {
                final e = events[i];
                return Semantics(
                  button: onTap != null,
                  label: '${e.title}, all day',
                  excludeSemantics: true,
                  onTap: onTap == null ? null : () => onTap!(e),
                  child: GestureDetector(
                    onTap: onTap == null ? null : () => onTap!(e),
                    child: Center(
                      child: KitoPressable(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.sm,
                              vertical: theme.spacing.xs + 1),
                          decoration: BoxDecoration(
                            color: e.color.withValues(alpha: 0.16),
                            borderRadius:
                                BorderRadius.circular(theme.radii.pill),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                    color: e.color, shape: BoxShape.circle)),
                            SizedBox(width: theme.spacing.xs),
                            Text(e.title,
                                style: theme.typography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colors.onSurface)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.event,
    required this.height,
    required this.isPast,
    required this.config,
    required this.onTap,
  });

  final KitoCalendarEvent event;
  final double height;
  final bool isPast;
  final KitoCalendarConfig config;
  final ValueChanged<KitoCalendarEvent>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final times = '${config.time(event.start)} – ${config.time(event.end)}';
    final compact = height < 44;
    final muted = theme.colors.onSurface.withValues(alpha: 0.7);
    final radius = BorderRadius.circular(theme.radii.md);
    final details = compact
        ? Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(
                  text: '  ${config.time(event.start)}',
                  style: TextStyle(color: muted)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.caption
                .copyWith(color: theme.colors.onSurface),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title,
                  maxLines: height < 72 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.onSurface)),
              Text(times,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                      color: muted,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              if (height >= 76 && event.location != null)
                Row(children: [
                  Icon(Icons.place_outlined, size: 12, color: muted),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(event.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption.copyWith(color: muted)),
                  ),
                ]),
            ],
          );

    final block = ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.16),
          borderRadius: radius,
          border: Border.all(color: event.color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
              start: theme.spacing.xs + 2,
              end: theme.spacing.xs,
              top: compact ? 3 : theme.spacing.sm,
              bottom: compact ? 3 : theme.spacing.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                  color: event.color, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(width: theme.spacing.sm),
            Expanded(
              child: ClipRect(
                  child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: details)),
            ),
          ]),
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: [event.title, times, event.location].nonNulls.join(', '),
      hint: onTap == null ? null : 'Opens the event',
      excludeSemantics: true,
      onTap: onTap == null ? null : () => onTap!(event),
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(event),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: theme.motion.spring,
          builder: (context, v, child) => Opacity(
            opacity: ((v - 0.9) * 10).clamp(0.0, 1.0) * (isPast ? 0.6 : 1),
            child: Transform.scale(scale: v, child: child),
          ),
          child: KitoPressable(scale: 0.97, child: block),
        ),
      ),
    );
  }
}

class _NowDot extends StatefulWidget {
  const _NowDot({required this.color});

  final Color color;

  @override
  State<_NowDot> createState() => _NowDotState();
}

class _NowDotState extends State<_NowDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(alignment: Alignment.center, children: [
          if (_c.isAnimating)
            Container(
              width: 9 + 14 * _c.value,
              height: 9 + 14 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
          Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
        ]),
      ),
    );
  }
}
