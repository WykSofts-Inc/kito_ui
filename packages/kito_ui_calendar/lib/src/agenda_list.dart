// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'math.dart';
import 'models.dart';
import 'parts.dart';

/// Events grouped by day under sticky headers ("TODAY · Monday, 12 October · 3 events").
///
/// Multi-day events repeat on each day they touch ("Until 14:00", "Next day"), events
/// happening now get a pulsing "Now" badge, and the list opens on today (or the next day with
/// plans) rather than the oldest event. With unbounded height (inside another scroll view) it
/// lays out in full, without sticky headers.
///
/// ```dart
/// KitoAgendaList(
///   events: events,
///   onEventTap: (e) => open(e),
///   emptyTitle: 'Hakuna matata',
///   emptyMessage: 'Nothing planned this week.',
/// )
/// ```
class KitoAgendaList extends StatefulWidget {
  /// Creates an agenda.
  const KitoAgendaList({
    super.key,
    required this.events,
    this.tint,
    this.onEventTap,
    this.emptyTitle = 'Nothing planned',
    this.emptyMessage = 'Events you add will show up here.',
  });

  /// The events, in any order.
  final List<KitoCalendarEvent> events;

  /// Replaces the theme's primary colour for the day badges.
  final Color? tint;

  /// Called when a row is tapped.
  final ValueChanged<KitoCalendarEvent>? onEventTap;

  /// The headline when there are no events.
  final String emptyTitle;

  /// The detail when there are no events.
  final String emptyMessage;

  @override
  State<KitoAgendaList> createState() => _KitoAgendaListState();
}

class _KitoAgendaListState extends State<KitoAgendaList> {
  final _scroll = ScrollController();
  final _anchorKey = GlobalKey();
  bool _positioned = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openOn(int index, List<KitoCalendarAgendaDay> days, double header) {
    if (_positioned || index <= 0) return;
    _positioned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      var estimate = 0.0;
      for (var i = 0; i < index; i++) {
        estimate += header + days[i].events.length * 84;
      }
      _scroll.jumpTo(estimate.clamp(0.0, _scroll.position.maxScrollExtent));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _anchorKey.currentContext;
        if (target != null && mounted) {
          Scrollable.ensureVisible(target, duration: Duration.zero);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    final palette = CalendarPalette.of(context, widget.tint);
    final days = KitoCalendarMath.agenda(widget.events);
    if (days.isEmpty) {
      return Center(
        child: CalendarEmptyState(
          icon: Icons.event_available_rounded,
          title: widget.emptyTitle,
          message: widget.emptyMessage,
        ),
      );
    }
    final today = config.today;
    final openIndex = days.indexWhere((d) => !d.date.isBefore(today));
    final headerHeight =
        MediaQuery.textScalerOf(context).scale(48).clamp(48.0, 80.0);

    Widget header(KitoCalendarAgendaDay day, {Key? key}) => _DayHeader(
          key: key,
          day: day,
          today: today,
          palette: palette,
          config: config,
          height: headerHeight,
        );

    Widget rows(KitoCalendarAgendaDay day) => Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
          child: Column(children: [
            for (final e in day.events)
              Padding(
                padding: EdgeInsets.only(bottom: theme.spacing.sm),
                child: _AgendaRow(
                  key: ValueKey('${day.date}-${e.id}'),
                  event: e,
                  day: day.date,
                  config: config,
                  onTap: widget.onEventTap,
                ),
              ),
          ]),
        );

    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final day in days) ...[header(day), rows(day)],
          ],
        );
      }
      _openOn(openIndex, days, headerHeight);
      return CustomScrollView(
        controller: _scroll,
        slivers: [
          for (var i = 0; i < days.length; i++)
            SliverMainAxisGroup(slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  height: headerHeight,
                  child:
                      header(days[i], key: i == openIndex ? _anchorKey : null),
                ),
              ),
              SliverToBoxAdapter(child: rows(days[i])),
            ]),
          SliverToBoxAdapter(child: SizedBox(height: theme.spacing.xl)),
        ],
      );
    });
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.height != height || old.child != child;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    super.key,
    required this.day,
    required this.today,
    required this.palette,
    required this.config,
    required this.height,
  });

  final KitoCalendarAgendaDay day;
  final DateTime today;
  final CalendarPalette palette;
  final KitoCalendarConfig config;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final offset = KitoCalendarMath.nights(today, day.date);
    final relative = switch (offset) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => null,
    };
    final isToday = offset == 0;
    final count =
        day.events.length == 1 ? '1 event' : '${day.events.length} events';
    return Semantics(
      header: true,
      label: [relative, config.dayHeading(day.date), count].nonNulls.join(', '),
      excludeSemantics: true,
      child: Container(
        height: height,
        color: theme.colors.background.withValues(alpha: 0.96),
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
        child: Row(children: [
          if (relative != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.sm,
                  vertical: theme.spacing.xxs + 1),
              decoration: BoxDecoration(
                color: isToday ? palette.accent : null,
                border: isToday
                    ? null
                    : Border.all(color: palette.accent.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(theme.radii.pill),
              ),
              child: Text(relative.toUpperCase(),
                  style: theme.typography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isToday ? palette.onAccent : palette.accent)),
            ),
            SizedBox(width: theme.spacing.sm),
          ],
          Expanded(
            child: Text(config.dayHeading(day.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.bodyEmphasized
                    .copyWith(color: theme.colors.onBackground)),
          ),
          Text(count,
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onBackground.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    super.key,
    required this.event,
    required this.day,
    required this.config,
    required this.onTap,
  });

  final KitoCalendarEvent event;
  final DateTime day;
  final KitoCalendarConfig config;
  final ValueChanged<KitoCalendarEvent>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final dayEnd = KitoCalendarMath.addDays(day, 1);
    final coversDay = event.isAllDay ||
        (!event.start.isAfter(day) && !event.end.isBefore(dayEnd));
    final startsEarlier = event.start.isBefore(day);
    final top = coversDay
        ? 'All day'
        : startsEarlier
            ? 'Until'
            : config.time(event.start);
    final String? bottom = coversDay
        ? null
        : !event.end.isAfter(dayEnd)
            ? config.time(event.end)
            : 'Next day';
    final live = !event.isAllDay && event.isOngoingAt(config.now);
    final timeWidth =
        MediaQuery.textScalerOf(context).scale(60).clamp(60.0, 96.0);
    final muted = theme.colors.onSurface.withValues(alpha: 0.55);

    final card = Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: timeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(top,
                    maxLines: 1,
                    style: theme.typography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                if (bottom != null)
                  Text(bottom,
                      maxLines: 1,
                      style: theme.typography.caption.copyWith(
                          color: muted,
                          fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
          SizedBox(width: theme.spacing.md),
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(event.color, Colors.white, 0.2)!,
                  event.color
                ],
              ),
            ),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(event.title,
                    style: theme.typography.bodyEmphasized
                        .copyWith(color: theme.colors.onSurface)),
                if (event.location != null)
                  Row(children: [
                    Icon(Icons.place_outlined, size: 13, color: muted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(event.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.typography.caption.copyWith(color: muted)),
                    ),
                  ]),
              ],
            ),
          ),
          if (live) ...[
            SizedBox(width: theme.spacing.sm),
            Center(child: _LiveBadge(color: theme.colors.danger)),
          ],
        ]),
      ),
    );

    final when = coversDay
        ? 'All day'
        : bottom == null
            ? top
            : '$top to $bottom';
    return Semantics(
      button: onTap != null,
      label: [event.title, when, event.location].nonNulls.join(', '),
      value: live ? 'Happening now' : null,
      excludeSemantics: true,
      onTap: onTap == null ? null : () => onTap!(event),
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(event),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: theme.motion.standard,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset((1 - v) * 24 * (context.isRtl ? -1 : 1), 0),
              child: child,
            ),
          ),
          child: KitoPressable(scale: 0.98, child: card),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge({required this.color});

  final Color color;

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm, vertical: theme.spacing.xxs + 1),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(theme.radii.pill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.3).animate(_c),
          child: Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: math.max(theme.spacing.xs, 4)),
        Text('Now',
            style: theme.typography.caption
                .copyWith(fontWeight: FontWeight.w700, color: widget.color)),
      ]),
    );
  }
}
