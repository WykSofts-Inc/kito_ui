// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'delivery.dart';
import 'money.dart';
import 'parts.dart';

/// Delivery options as cards: icon, title, ETA, price ("Free" when zero) and a badge such as
/// "Fastest". Unavailable options say why and can't be picked.
///
/// ```dart
/// KitoCheckoutDeliveryOptions(
///   options: const [
///     KitoCheckoutDeliveryOption.standard(price: 20000),
///     KitoCheckoutDeliveryOption.express(price: 35000),
///     KitoCheckoutDeliveryOption.pickup(),
///   ],
///   selected: option,
///   onChanged: (o) => setState(() => option = o),
/// )
/// ```
class KitoCheckoutDeliveryOptions extends StatelessWidget {
  /// Creates the list.
  const KitoCheckoutDeliveryOptions({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.currencyCode = kitoCheckoutDefaultCurrency,
    this.tint,
  });

  /// The options.
  final List<KitoCheckoutDeliveryOption> options;

  /// The chosen option, or null.
  final KitoCheckoutDeliveryOption? selected;

  /// Called with the new choice.
  final ValueChanged<KitoCheckoutDeliveryOption> onChanged;

  /// The currency for prices.
  final String currencyCode;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in options) ...[
          if (o != options.first) SizedBox(height: theme.spacing.sm),
          _option(context, o, accent),
        ],
      ],
    );
  }

  Widget _option(
      BuildContext context, KitoCheckoutDeliveryOption o, Color accent) {
    final theme = context.kito;
    final isSelected = selected?.id == o.id;
    final price = o.price == 0
        ? 'Free'
        : KitoCheckoutMoney.format(o.price, currencyCode: currencyCode);
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);
    return CheckoutChoiceCard(
      selected: isSelected,
      accent: accent,
      enabled: o.isAvailable,
      padding: EdgeInsets.all(theme.spacing.md),
      semanticLabel: [
        o.title,
        o.eta.label,
        price,
        if (o.badge != null) o.badge!,
        if (o.unavailableReason != null) o.unavailableReason!,
      ].join(', '),
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(o);
      },
      child: Row(children: [
        CheckoutIconTile(
            icon: o.kind.icon,
            color: isSelected ? accent : theme.colors.onSurface),
        SizedBox(width: theme.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(o.title,
                      style: theme.typography.label.copyWith(
                          color: theme.colors.onSurface,
                          fontWeight: FontWeight.w700)),
                  if (o.badge != null)
                    CheckoutBadge(o.badge!, color: theme.colors.warning),
                ],
              ),
              const SizedBox(height: 2),
              Text(o.unavailableReason ?? o.subtitle ?? o.eta.label,
                  style: theme.typography.caption.copyWith(
                      color: o.unavailableReason != null
                          ? theme.colors.danger
                          : muted)),
              if (o.subtitle != null && o.unavailableReason == null)
                Text(o.eta.label,
                    style: theme.typography.caption.copyWith(color: muted)),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.sm),
        Text(price,
            style: theme.typography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: o.price == 0
                    ? theme.colors.success
                    : theme.colors.onSurface)),
        SizedBox(width: theme.spacing.md),
        CheckoutRadio(selected: isSelected, accent: accent),
      ]),
    );
  }
}

/// Saved addresses to pick from, each with its label, recipient, a short address and the
/// landmark, plus an optional **Add address** row.
///
/// ```dart
/// KitoCheckoutAddressList(
///   addresses: saved,
///   selected: address,
///   onChanged: (a) => setState(() => address = a),
///   onAdd: openAddressForm,
/// )
/// ```
class KitoCheckoutAddressList extends StatelessWidget {
  /// Creates the list.
  const KitoCheckoutAddressList({
    super.key,
    required this.addresses,
    required this.selected,
    required this.onChanged,
    this.onAdd,
    this.onEdit,
    this.addLabel = 'Add a new address',
    this.tint,
  });

  /// The saved addresses.
  final List<KitoCheckoutAddress> addresses;

  /// The chosen one, or null.
  final KitoCheckoutAddress? selected;

  /// Called with the new choice.
  final ValueChanged<KitoCheckoutAddress> onChanged;

  /// Shows an **Add address** row when set.
  final VoidCallback? onAdd;

  /// Shows an edit button on each address when set.
  final ValueChanged<KitoCheckoutAddress>? onEdit;

  /// The add row's words.
  final String addLabel;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in addresses) ...[
          CheckoutChoiceCard(
            selected: selected?.id == a.id,
            accent: accent,
            padding: EdgeInsets.all(theme.spacing.md),
            semanticLabel:
                '${a.title}, ${a.recipient}, ${a.singleLine}${a.landmark.isEmpty ? '' : ', near ${a.landmark}'}',
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(a);
            },
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CheckoutIconTile(
                  icon: a.label.icon,
                  color:
                      selected?.id == a.id ? accent : theme.colors.onSurface),
              SizedBox(width: theme.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: theme.typography.label.copyWith(
                            color: theme.colors.onSurface,
                            fontWeight: FontWeight.w700)),
                    if (a.recipient.isNotEmpty)
                      Text(
                          [
                            a.recipient,
                            if (KitoCheckoutPhone.display(a.phone) != null)
                              KitoCheckoutPhone.display(a.phone)!,
                          ].join(' · '),
                          style:
                              theme.typography.caption.copyWith(color: muted)),
                    const SizedBox(height: 2),
                    Text(a.singleLine,
                        style: theme.typography.caption
                            .copyWith(color: theme.colors.onSurface)),
                    if (a.landmark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          Icon(Icons.flag_rounded, size: 12, color: muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Near ${a.landmark}',
                                style: theme.typography.caption
                                    .copyWith(color: muted)),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit ${a.title}',
                  onPressed: () => onEdit!(a),
                  icon: Icon(Icons.edit_rounded, size: 18, color: muted),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CheckoutRadio(
                      selected: selected?.id == a.id, accent: accent),
                ),
            ]),
          ),
          SizedBox(height: theme.spacing.sm),
        ],
        if (onAdd != null)
          Semantics(
            button: true,
            label: addLabel,
            excludeSemantics: true,
            child: KitoPressable(
              scale: 0.98,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(theme.radii.lg),
                  onTap: onAdd,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(theme.radii.lg),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(children: [
                      Icon(Icons.add_location_alt_rounded, color: accent),
                      SizedBox(width: theme.spacing.sm),
                      Text(addLabel,
                          style: theme.typography.label.copyWith(
                              color: accent, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A delivery slot picker: a row of day chips (with how many windows are still open) and the
/// day's windows below, each with its places left. Full, cut-off and past windows are struck
/// out.
///
/// ```dart
/// KitoCheckoutSlotPicker(
///   schedule: const KitoCheckoutSchedule(closedWeekdays: {DateTime.sunday}),
///   selected: slot,
///   onChanged: (s) => setState(() => slot = s),
/// )
/// ```
class KitoCheckoutSlotPicker extends StatefulWidget {
  /// Creates a picker.
  const KitoCheckoutSlotPicker({
    super.key,
    required this.schedule,
    required this.selected,
    required this.onChanged,
    this.now,
    this.use24Hour = false,
    this.tint,
  });

  /// The rules and bookings.
  final KitoCheckoutSchedule schedule;

  /// The chosen slot, or null.
  final KitoCheckoutSlot? selected;

  /// Called with the new slot.
  final ValueChanged<KitoCheckoutSlot> onChanged;

  /// "Now", for demos and tests; the clock when null.
  final DateTime? now;

  /// "08:00–10:00" instead of "8–10 AM".
  final bool use24Hour;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  State<KitoCheckoutSlotPicker> createState() => _KitoCheckoutSlotPickerState();
}

class _KitoCheckoutSlotPickerState extends State<KitoCheckoutSlotPicker> {
  DateTime? _day;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(widget.tint);
    final now = _now;
    final days = widget.schedule.days(from: now);
    if (days.isEmpty) return const SizedBox.shrink();
    final selectedDay = widget.selected == null
        ? null
        : DateUtils.dateOnly(widget.selected!.start);
    final firstOpen = days.firstWhere(
        (d) => d.slots
            .any((s) => widget.schedule.status(s, now: now).isSelectable),
        orElse: () => days.first);
    final day = days.firstWhere(
        (d) =>
            DateUtils.isSameDay(d.date, _day ?? selectedDay ?? firstOpen.date),
        orElse: () => firstOpen);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => SizedBox(width: theme.spacing.sm),
            itemBuilder: (context, i) =>
                _dayChip(context, days[i], days[i] == day, accent, now),
          ),
        ),
        SizedBox(height: theme.spacing.md),
        AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.medium),
          switchInCurve: theme.motion.emphasized,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(a),
              child: child,
            ),
          ),
          child: LayoutBuilder(
            key: ValueKey(day.date),
            builder: (context, c) {
              final gap = theme.spacing.sm;
              final columns = c.maxWidth >= 360 ? 2 : 1;
              final w = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in day.slots)
                    SizedBox(width: w, child: _slot(context, s, accent, now)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dayChip(BuildContext context, KitoCheckoutSlotDay d, bool isSelected,
      Color accent, DateTime now) {
    final theme = context.kito;
    final open = d.slots
        .where((s) => widget.schedule.status(s, now: now).isSelectable)
        .length;
    final title = KitoCheckoutSchedule.dayTitle(d.date, now: now);
    final fg =
        isSelected ? theme.onAccent(widget.tint) : theme.colors.onSurface;
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$title ${d.date.day}, ${open == 0 ? 'no times left' : '$open times open'}',
      excludeSemantics: true,
      child: KitoPressable(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _day = d.date);
          },
          child: AnimatedContainer(
            duration: KitoMotion.of(context, theme.motion.medium),
            curve: theme.motion.standard,
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent : theme.colors.surface,
              borderRadius: BorderRadius.circular(theme.radii.lg),
              border:
                  Border.all(color: isSelected ? accent : theme.colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.typography.caption.copyWith(
                        color: fg.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600)),
                Text('${d.date.day}',
                    style: theme.typography.title
                        .copyWith(color: fg, fontWeight: FontWeight.w800)),
                Text(open == 0 ? 'Full' : '$open open',
                    style: theme.typography.caption.copyWith(
                        fontSize: 10,
                        color: isSelected
                            ? fg.withValues(alpha: 0.8)
                            : open == 0
                                ? theme.colors.danger
                                : theme.colors.success)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(
      BuildContext context, KitoCheckoutSlot s, Color accent, DateTime now) {
    final theme = context.kito;
    final status = widget.schedule.status(s, now: now);
    final enabled = status.isSelectable;
    final isSelected = widget.selected?.id == s.id;
    final label = s.window.label(use24Hour: widget.use24Hour);
    final note = widget.schedule.statusLabel(s, now: now);
    final fg =
        isSelected ? theme.onAccent(widget.tint) : theme.colors.onSurface;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      label: '$label, $note',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: KitoPressable(
          enabled: enabled,
          child: GestureDetector(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(s);
                  }
                : null,
            child: AnimatedContainer(
              duration: KitoMotion.of(context, theme.motion.medium),
              curve: theme.motion.standard,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? accent : theme.colors.surface,
                borderRadius: BorderRadius.circular(theme.radii.md),
                border: Border.all(
                    color: isSelected ? accent : theme.colors.border),
              ),
              child: Row(children: [
                Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 18,
                    color: isSelected ? fg : fg.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: theme.typography.label.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          decoration:
                              enabled ? null : TextDecoration.lineThrough)),
                ),
                Text(note,
                    style: theme.typography.caption.copyWith(
                        color: isSelected
                            ? fg.withValues(alpha: 0.85)
                            : status == KitoCheckoutSlotStatus.fewLeft
                                ? theme.colors.warning
                                : fg.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
