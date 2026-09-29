// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'config.dart';
import 'models.dart';
import 'month_calendar.dart';
import 'parts.dart';

/// How a [KitoDateRangeBar] looks while closed.
enum KitoDateRangeBarStyle {
  /// A full-width field with a title and the dates underneath.
  field,

  /// A compact capsule with just the dates.
  chip,
}

/// A date range field: tap it for a sheet with preset chips, a range calendar and Apply.
///
/// Past days are blocked unless [allowPastDates]. Presets are resolved when tapped, so
/// "This weekend" is right whenever the sheet opens.
///
/// ```dart
/// KitoDateRangeBar(
///   range: stay,
///   onChanged: (r) => setState(() => stay = r),
///   title: 'Check-in – Check-out',
/// )
/// ```
class KitoDateRangeBar extends StatelessWidget {
  /// Creates a range field.
  const KitoDateRangeBar({
    super.key,
    required this.range,
    required this.onChanged,
    this.title = 'Dates',
    this.placeholder = 'Add dates',
    this.unit = KitoCalendarRangeUnit.nights,
    this.style = KitoDateRangeBarStyle.field,
    this.tint,
    this.presets,
    this.minDate,
    this.maxDate,
    this.allowPastDates = false,
    this.isUnavailable,
    this.allowsSingleDay = false,
  });

  /// The chosen range, or null.
  final KitoCalendarRange? range;

  /// Called with the applied range, or null when it's cleared.
  final ValueChanged<KitoCalendarRange?> onChanged;

  /// The field's label and the sheet's title.
  final String title;

  /// Shown while no range is chosen.
  final String placeholder;

  /// Nights for stays, days for trips; null shows only the dates.
  final KitoCalendarRangeUnit? unit;

  /// Field or chip.
  final KitoDateRangeBarStyle style;

  /// Replaces the theme's primary colour.
  final Color? tint;

  /// The preset chips in the sheet; null uses [KitoCalendarPreset.standard], empty hides them.
  final List<KitoCalendarPreset>? presets;

  /// The earliest pickable day.
  final DateTime? minDate;

  /// The latest pickable day.
  final DateTime? maxDate;

  /// Lets days before today be picked (off by default: most ranges are bookings).
  final bool allowPastDates;

  /// Strikes through days your rule marks unavailable.
  final bool Function(DateTime day)? isUnavailable;

  /// Lets a second tap on the start pick a one-day range.
  final bool allowsSingleDay;

  Future<void> _open(BuildContext context) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          KitoCalendarScope.inherit(context, child: _RangeSheet(bar: this)),
    );
    if (result != null) onChanged(result.range);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final config = KitoCalendarConfig.of(context);
    final palette = CalendarPalette.of(context, tint);
    final value = range == null ? null : config.formatRange(range!, unit: unit);
    final muted = theme.colors.onSurface.withValues(alpha: 0.5);

    final Widget look;
    if (style == KitoDateRangeBarStyle.chip) {
      look = Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
        decoration: BoxDecoration(
          color: range == null ? theme.colors.surfaceMuted : palette.accent,
          borderRadius: BorderRadius.circular(theme.radii.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.date_range_rounded,
              size: 18,
              color: range == null ? theme.colors.onSurface : palette.onAccent),
          SizedBox(width: theme.spacing.xs),
          AnimatedSwitcher(
            duration: KitoMotion.of(context, theme.motion.medium),
            child: Text(value ?? placeholder,
                key: ValueKey(value),
                style: theme.typography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: range == null
                        ? theme.colors.onSurface
                        : palette.onAccent)),
          ),
        ]),
      );
    } else {
      look = KitoSurface(
        border: true,
        radius: theme.radii.lg,
        padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md, vertical: theme.spacing.sm + 2),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month_rounded,
                size: 20, color: palette.accent),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.typography.caption.copyWith(color: muted)),
                AnimatedSwitcher(
                  duration: KitoMotion.of(context, theme.motion.medium),
                  transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(0, 0.3), end: Offset.zero)
                              .animate(a),
                          child: child)),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Text(value ?? placeholder,
                      key: ValueKey(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.bodyEmphasized.copyWith(
                          color:
                              value == null ? muted : theme.colors.onSurface)),
                ),
              ],
            ),
          ),
          if (range != null)
            Semantics(
              button: true,
              label: 'Clear dates',
              excludeSemantics: true,
              onTap: () => onChanged(null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(null),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(Icons.close_rounded, size: 18, color: muted),
                ),
              ),
            )
          else
            Icon(Icons.chevron_right_rounded, color: muted),
        ]),
      );
    }

    return Semantics(
      button: true,
      label: title,
      value: value ?? placeholder,
      hint: 'Opens the date picker',
      onTap: () => _open(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: ExcludeSemantics(
          excluding: style == KitoDateRangeBarStyle.chip,
          child: KitoPressable(scale: 0.97, child: look),
        ),
      ),
    );
  }
}

class _SheetResult {
  const _SheetResult(this.range);
  final KitoCalendarRange? range;
}

class _RangeSheet extends StatefulWidget {
  const _RangeSheet({required this.bar});

  final KitoDateRangeBar bar;

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late KitoCalendarRangeSelection _draft = KitoCalendarRangeSelection(
      range: widget.bar.range, allowsSingleDay: widget.bar.allowsSingleDay);

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final bar = widget.bar;
    final config = KitoCalendarConfig.of(context);
    final palette = CalendarPalette.of(context, bar.tint);
    final presets = bar.presets ?? KitoCalendarPreset.standard;
    final draftRange = _draft.range;
    final summary = draftRange != null
        ? config.formatRange(draftRange, unit: bar.unit)
        : _draft.isAwaitingEnd
            ? 'Now pick the last day'
            : 'Pick the first day';
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(theme.radii.xl)),
      ),
      padding: EdgeInsets.fromLTRB(theme.spacing.lg, theme.spacing.sm,
          theme.spacing.lg, theme.spacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            SizedBox(height: theme.spacing.md),
            Row(children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(bar.title,
                      style: theme.typography.title
                          .copyWith(color: theme.colors.onSurface)),
                ),
              ),
              CalendarIconButton(
                icon: Icons.close_rounded,
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
            if (presets.isNotEmpty) ...[
              SizedBox(height: theme.spacing.sm),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: theme.spacing.xs),
                  itemBuilder: (context, i) {
                    final preset = presets[i];
                    final range = preset.rangeFor(config.now,
                        weekendDays: config.weekendDays);
                    final active = draftRange == range;
                    return Semantics(
                      button: true,
                      selected: active,
                      label: preset.title,
                      value: config.rangeDates(range),
                      excludeSemantics: true,
                      onTap: () =>
                          setState(() => _draft = _draft.withRange(range)),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _draft = _draft.withRange(range));
                        },
                        child: KitoPressable(
                          child: AnimatedContainer(
                            duration:
                                KitoMotion.of(context, theme.motion.medium),
                            padding: EdgeInsets.symmetric(
                                horizontal: theme.spacing.md),
                            decoration: BoxDecoration(
                              color: active
                                  ? palette.accent
                                  : theme.colors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(theme.radii.pill),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(preset.icon,
                                  size: 16,
                                  color: active
                                      ? palette.onAccent
                                      : theme.colors.onSurface),
                              SizedBox(width: theme.spacing.xs),
                              Text(preset.title,
                                  style: theme.typography.label.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? palette.onAccent
                                          : theme.colors.onSurface)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: theme.spacing.md),
            KitoMonthCalendar.range(
              selection: _draft,
              onChanged: (s) => setState(() => _draft = s),
              tint: bar.tint,
              minDate: bar.minDate,
              maxDate: bar.maxDate,
              disablePastDates: !bar.allowPastDates,
              isUnavailable: bar.isUnavailable,
            ),
            SizedBox(height: theme.spacing.md),
            Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: KitoMotion.of(context, theme.motion.medium),
                child: Text(summary,
                    key: ValueKey(summary),
                    textAlign: TextAlign.center,
                    style: draftRange == null
                        ? theme.typography.body.copyWith(color: muted)
                        : theme.typography.bodyEmphasized
                            .copyWith(color: theme.colors.onSurface)),
              ),
            ),
            SizedBox(height: theme.spacing.md),
            Row(children: [
              Expanded(
                child: _SheetButton(
                  label: 'Clear',
                  filled: false,
                  palette: palette,
                  onPressed: _draft.isEmpty
                      ? null
                      : () => setState(() => _draft = _draft.cleared()),
                ),
              ),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                flex: 2,
                child: _SheetButton(
                  label: 'Apply',
                  filled: true,
                  palette: palette,
                  onPressed: draftRange == null && !_draft.isEmpty
                      ? null
                      : () =>
                          Navigator.of(context).pop(_SheetResult(draftRange)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.filled,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final CalendarPalette palette;
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
        onTap: onPressed,
        child: KitoPressable(
          enabled: enabled,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: KitoMotion.of(context, theme.motion.fast),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? palette.accent : theme.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(theme.radii.pill),
              ),
              child: Text(label,
                  style: theme.typography.button.copyWith(
                      color:
                          filled ? palette.onAccent : theme.colors.onSurface)),
            ),
          ),
        ),
      ),
    );
  }
}
