// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'parts.dart';
import 'slots.dart';

/// Bookable times grouped into Morning, Afternoon and Evening, each with an "n open" count.
///
/// Booked or past slots are struck out behind a dashed outline and can't be picked. The picked
/// slot fills with the accent and gets a checkmark; tap it again to clear.
///
/// ```dart
/// final slots = const KitoCalendarSlotSchedule(
///   opens: KitoCalendarClockTime(8, 30),
///   closes: KitoCalendarClockTime(18),
///   duration: 45,
///   interval: 15,
/// ).slotsOn(day, booked: bookings, notBefore: DateTime.now());
///
/// KitoTimeSlotPicker(slots: slots, selected: slot, onChanged: (s) => setState(() => slot = s));
/// ```
class KitoTimeSlotPicker extends StatelessWidget {
  /// Creates a picker.
  const KitoTimeSlotPicker({
    super.key,
    required this.slots,
    required this.selected,
    required this.onChanged,
    this.tint,
    this.showsEndTime = false,
    this.emptyTitle = 'No times on this day',
    this.emptyMessage = 'Try another date.',
  });

  /// The slots, in order.
  final List<KitoCalendarTimeSlot> slots;

  /// The picked slot, or null.
  final KitoCalendarTimeSlot? selected;

  /// Called with the new pick, or null when it's cleared.
  final ValueChanged<KitoCalendarTimeSlot?> onChanged;

  /// Replaces the theme's primary colour.
  final Color? tint;

  /// Shows "09:00 – 09:45" instead of just the start.
  final bool showsEndTime;

  /// The headline when [slots] is empty.
  final String emptyTitle;

  /// The detail when [slots] is empty.
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    final palette = CalendarPalette.of(context, tint);
    if (slots.isEmpty) {
      return CalendarEmptyState(
          icon: Icons.event_busy_rounded,
          title: emptyTitle,
          message: emptyMessage);
    }
    final groups = <KitoCalendarDayPeriod, List<KitoCalendarTimeSlot>>{};
    for (final s in slots) {
      (groups[s.period] ??= []).add(s);
    }
    final minWidth = MediaQuery.textScalerOf(context)
        .scale(showsEndTime ? 148 : 92)
        .clamp(92.0, 260.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final period in KitoCalendarDayPeriod.values)
          if (groups[period] != null) ...[
            if (period != groups.keys.first) SizedBox(height: theme.spacing.xl),
            _header(context, period,
                groups[period]!.where((s) => s.isAvailable).length),
            SizedBox(height: theme.spacing.md),
            LayoutBuilder(builder: (context, constraints) {
              final gap = theme.spacing.sm;
              final columns = math.max(
                  1, ((constraints.maxWidth + gap) / (minWidth + gap)).floor());
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final slot in groups[period]!)
                    SizedBox(
                      width: width,
                      child: _SlotButton(
                        slot: slot,
                        isSelected: selected?.start == slot.start &&
                            selected?.end == slot.end,
                        label: showsEndTime
                            ? '${config.time(slot.start)} – ${config.time(slot.end)}'
                            : config.time(slot.start),
                        spoken:
                            '${config.time(slot.start)} to ${config.time(slot.end)}',
                        palette: palette,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final same = selected?.start == slot.start &&
                              selected?.end == slot.end;
                          onChanged(same ? null : slot);
                        },
                      ),
                    ),
                ],
              );
            }),
          ],
      ],
    );
  }

  Widget _header(BuildContext context, KitoCalendarDayPeriod period, int open) {
    final theme = context.kito;
    final iconColor = period == KitoCalendarDayPeriod.evening
        ? const Color(0xFF6366F1)
        : theme.colors.warning;
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: Row(children: [
          Icon(period.icon, size: 20, color: iconColor),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Text(period.title,
                style: theme.typography.bodyEmphasized
                    .copyWith(color: theme.colors.onSurface)),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.sm, vertical: theme.spacing.xxs + 1),
            decoration: BoxDecoration(
              color: theme.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(theme.radii.pill),
            ),
            child: Text(
              open == 0
                  ? 'Fully booked'
                  : open == 1
                      ? '1 open'
                      : '$open open',
              style: theme.typography.caption.copyWith(
                  color: open == 0
                      ? theme.colors.danger
                      : theme.colors.onSurface.withValues(alpha: 0.55)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.slot,
    required this.isSelected,
    required this.label,
    required this.spoken,
    required this.palette,
    required this.onTap,
  });

  final KitoCalendarTimeSlot slot;
  final bool isSelected;
  final String label;
  final String spoken;
  final CalendarPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final available = slot.isAvailable;
    final duration = KitoMotion.of(context, theme.motion.medium);
    final fg = isSelected
        ? palette.onAccent
        : theme.colors.onSurface.withValues(alpha: available ? 1 : 0.4);
    final shape = StadiumBorder(
      side: isSelected || !available
          ? BorderSide.none
          : BorderSide(color: theme.colors.border),
    );
    Widget body = AnimatedContainer(
      duration: duration,
      curve: theme.motion.standard,
      height: 44,
      decoration: ShapeDecoration(
        shape: shape,
        color: isSelected
            ? palette.accent
            : available
                ? theme.colors.surface
                : theme.colors.surfaceMuted.withValues(alpha: 0.5),
        shadows: isSelected
            ? [
                BoxShadow(
                    color: palette.accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : const [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: theme.motion.spring,
            transitionBuilder: (child, a) =>
                ScaleTransition(scale: a, child: child),
            child: isSelected
                ? Padding(
                    key: const ValueKey('check'),
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.check_rounded, size: 16, color: fg))
                : const SizedBox(key: ValueKey('none')),
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.label.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
                decoration: available ? null : TextDecoration.lineThrough,
                decorationColor: theme.colors.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
    if (!available) {
      body = CustomPaint(
          foregroundPainter: _DashedStadium(theme.colors.border), child: body);
    }
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: available,
      label: spoken,
      value: available ? null : 'Unavailable',
      excludeSemantics: true,
      onTap: available ? onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: available ? onTap : null,
        child: KitoPressable(enabled: available, scale: 0.93, child: body),
      ),
    );
  }
}

class _DashedStadium extends CustomPainter {
  _DashedStadium(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(size.height / 2));
    final path = Path()..addRRect(rrect.deflate(0.5));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadium old) => old.color != color;
}
