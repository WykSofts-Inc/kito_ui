// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'money.dart';
import 'parts.dart';

/// The order summary: line items (collapsible), then subtotal, promo, discounts, delivery,
/// fees, VAT, tip and the total. Amounts roll when they change, a waived delivery fee is struck
/// through next to "Free", and a bar shows how far the order is from free delivery.
///
/// ```dart
/// KitoCheckoutSummary(
///   totals: KitoCheckoutTotals(
///     items: items,
///     deliveryFee: 25000,
///     promo: promo,
///     pricing: const KitoCheckoutPricing(
///         vat: KitoCheckoutVat.kenya, freeDeliveryThreshold: 500000),
///   ),
/// )
/// ```
class KitoCheckoutSummary extends StatefulWidget {
  /// Creates a summary.
  const KitoCheckoutSummary({
    super.key,
    required this.totals,
    this.title = 'Order summary',
    this.showsItems = true,
    this.initiallyExpanded = true,
    this.collapsible = true,
    this.showsFreeDeliveryProgress = true,
    this.tint,
  });

  /// The maths to show.
  final KitoCheckoutTotals totals;

  /// The header.
  final String title;

  /// Lists the items above the totals.
  final bool showsItems;

  /// Whether the item list starts open.
  final bool initiallyExpanded;

  /// Lets the header fold the item list away.
  final bool collapsible;

  /// Shows "Add KES 450 more for free delivery" when there's a threshold.
  final bool showsFreeDeliveryProgress;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  State<KitoCheckoutSummary> createState() => _KitoCheckoutSummaryState();
}

class _KitoCheckoutSummaryState extends State<KitoCheckoutSummary> {
  late bool _expanded = widget.initiallyExpanded;

  String _money(int c) =>
      KitoCheckoutMoney.format(c, currencyCode: widget.totals.currencyCode);

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final t = widget.totals;
    final count = t.itemCount;
    final header = Row(children: [
      Expanded(
        child: Text(widget.title,
            style: theme.typography.headline
                .copyWith(color: theme.colors.onSurface)),
      ),
      Text('$count item${count == 1 ? '' : 's'}',
          style: theme.typography.caption
              .copyWith(color: theme.colors.onSurface.withValues(alpha: 0.55))),
      if (widget.showsItems && widget.collapsible) ...[
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: theme.motion.spring,
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: theme.colors.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    ]);

    return KitoSurface(
      border: true,
      padding: EdgeInsets.all(theme.spacing.lg),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showsItems && widget.collapsible)
              Semantics(
                button: true,
                expanded: _expanded,
                label: '${widget.title}, $count item${count == 1 ? '' : 's'}',
                hint: _expanded ? 'Hide items' : 'Show items',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(theme.radii.sm),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: header),
                ),
              )
            else
              Semantics(header: true, child: header),
            if (widget.showsItems)
              AnimatedSize(
                duration: KitoMotion.of(context, theme.motion.medium),
                curve: theme.motion.emphasized,
                alignment: AlignmentDirectional.topStart,
                child: _expanded || !widget.collapsible
                    ? Padding(
                        padding: EdgeInsets.only(top: theme.spacing.md),
                        child: Column(children: [
                          for (final item in t.items) ...[
                            _ItemRow(item: item, money: _money),
                            SizedBox(height: theme.spacing.md),
                          ],
                        ]),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            SizedBox(height: theme.spacing.md),
            const CheckoutDashedDivider(),
            SizedBox(height: theme.spacing.md),
            for (final line in t.lines)
              if (line.kind == KitoCheckoutLineKind.total) ...[
                SizedBox(height: theme.spacing.xs),
                Divider(height: theme.spacing.lg, color: theme.colors.border),
                _TotalRow(line: line, currencyCode: t.currencyCode),
              ] else
                _LineRow(line: line, currencyCode: t.currencyCode),
            if (widget.showsFreeDeliveryProgress &&
                t.amountToFreeDelivery != null)
              _FreeDeliveryBar(totals: t, money: _money, tint: widget.tint),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.money});

  final KitoCheckoutItem item;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final color = item.color ?? theme.colors.secondary;
    final thumb = item.image != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
                image: item.image!, width: 48, height: 48, fit: BoxFit.cover),
          )
        : CheckoutIconTile(
            icon: item.icon ?? Icons.shopping_bag_rounded,
            color: color,
            size: 48);
    return MergeSemantics(
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          thumb,
          if (item.quantity > 1)
            PositionedDirectional(
              top: -6,
              end: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colors.surface, width: 2),
                ),
                child: Text('${item.quantity}',
                    style: theme.typography.caption.copyWith(
                        color: theme.colors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
            ),
        ]),
        SizedBox(width: theme.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.label.copyWith(
                      color: theme.colors.onSurface,
                      fontWeight: FontWeight.w600)),
              Text(
                [
                  if (item.subtitle != null) item.subtitle!,
                  if (item.quantity > 1)
                    '${item.quantity} × ${money(item.unitPrice)}',
                ].join(' · '),
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onSurface.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.sm),
        Text(money(item.lineTotal),
            style: theme.typography.label.copyWith(
                color: theme.colors.onSurface, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.currencyCode});

  final KitoCheckoutLine line;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final isDiscount = line.amount < 0;
    final waived = line.originalAmount != null && line.amount == 0;
    final muted = theme.colors.onSurface.withValues(alpha: 0.65);
    final valueStyle = theme.typography.label.copyWith(
      color: isDiscount || waived
          ? theme.colors.success
          : line.isIncluded
              ? muted
              : theme.colors.onSurface,
      fontWeight: FontWeight.w600,
    );
    final spoken = waived
        ? 'Free, was ${KitoCheckoutMoney.format(line.originalAmount!, currencyCode: currencyCode)}'
        : KitoCheckoutMoney.format(line.amount, currencyCode: currencyCode);
    return Semantics(
      label: '${line.title}, $spoken${line.isIncluded ? ', included' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          if (line.kind == KitoCheckoutLineKind.promo) ...[
            Icon(Icons.local_offer_rounded,
                size: 14, color: theme.colors.success),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(line.title,
                style: theme.typography.label.copyWith(color: muted)),
          ),
          if (waived) ...[
            Text(
                KitoCheckoutMoney.format(line.originalAmount!,
                    currencyCode: currencyCode),
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onSurface.withValues(alpha: 0.4),
                    decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 6),
            Text('Free', style: valueStyle),
          ] else
            CheckoutMoneyText(line.amount,
                currencyCode: currencyCode, style: valueStyle),
        ]),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.line, required this.currencyCode});

  final KitoCheckoutLine line;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      label:
          'Total, ${KitoCheckoutMoney.format(line.amount, currencyCode: currencyCode)}',
      excludeSemantics: true,
      child: Row(children: [
        Expanded(
          child: Text(line.title,
              style: theme.typography.headline
                  .copyWith(color: theme.colors.onSurface)),
        ),
        CheckoutMoneyText(line.amount,
            currencyCode: currencyCode,
            style: theme.typography.title.copyWith(
                color: theme.colors.onSurface, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _FreeDeliveryBar extends StatelessWidget {
  const _FreeDeliveryBar(
      {required this.totals, required this.money, required this.tint});

  final KitoCheckoutTotals totals;
  final String Function(int) money;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final left = totals.amountToFreeDelivery!;
    final threshold = totals.pricing.freeDeliveryThreshold!;
    final fraction =
        threshold == 0 ? 1.0 : math.min(totals.subtotal / threshold, 1.0);
    final color = tint ?? theme.colors.success;
    return Padding(
      padding: EdgeInsets.only(top: theme.spacing.md),
      child: Container(
        padding: EdgeInsets.all(theme.spacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(theme.radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.local_shipping_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Add ${money(left)} more for free delivery',
                    style: theme.typography.caption.copyWith(
                        color: theme.colors.onSurface,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fraction),
                duration: KitoMotion.of(context, theme.motion.slow),
                curve: theme.motion.emphasized,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A promo code field: type a code, tap **Apply**, and it's checked with your [validate]
/// function. A good code becomes a chip with its saving and a remove button; a bad one shakes
/// the field and says why.
///
/// ```dart
/// const codes = KitoCheckoutPromoValidator([...]);
///
/// KitoCheckoutPromoField(
///   applied: promo,
///   onChanged: (p) => setState(() => promo = p),
///   validate: (code) async => codes.validate(code, subtotal: subtotal),
/// )
/// ```
class KitoCheckoutPromoField extends StatefulWidget {
  /// Creates a field.
  const KitoCheckoutPromoField({
    super.key,
    required this.applied,
    required this.onChanged,
    required this.validate,
    this.currencyCode = kitoCheckoutDefaultCurrency,
    this.placeholder = 'Promo code',
    this.tint,
  });

  /// The applied code, or null.
  final KitoCheckoutPromo? applied;

  /// Called with the new code, or null when it's removed.
  final ValueChanged<KitoCheckoutPromo?> onChanged;

  /// Checks a code — typically a server call.
  final Future<KitoCheckoutPromoResult> Function(String code) validate;

  /// The currency for error messages.
  final String currencyCode;

  /// The hint in the empty field.
  final String placeholder;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  State<KitoCheckoutPromoField> createState() => _KitoCheckoutPromoFieldState();
}

class _KitoCheckoutPromoFieldState extends State<KitoCheckoutPromoField>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  bool _checking = false;
  KitoCheckoutPromoError? _error;
  int _request = 0;

  @override
  void dispose() {
    _controller.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_checking) return;
    final code = _controller.text;
    if (code.trim().isEmpty) {
      _fail(KitoCheckoutPromoError.empty);
      return;
    }
    final request = ++_request;
    setState(() {
      _checking = true;
      _error = null;
    });
    final result = await widget.validate(code);
    if (!mounted || request != _request) return;
    setState(() => _checking = false);
    if (result.promo != null) {
      HapticFeedback.mediumImpact();
      _controller.clear();
      widget.onChanged(result.promo);
    } else {
      _fail(result.error ?? KitoCheckoutPromoError.notFound);
    }
  }

  void _fail(KitoCheckoutPromoError error) {
    HapticFeedback.heavyImpact();
    setState(() => _error = error);
    if (!context.reduceMotion) _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final applied = widget.applied;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.medium),
          switchInCurve: theme.motion.spring,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.0).animate(a), child: child),
          ),
          child: applied != null ? _chip(context, applied) : _entry(context),
        ),
        AnimatedSize(
          duration: KitoMotion.of(context, theme.motion.fast),
          alignment: AlignmentDirectional.topStart,
          child: _error != null && applied == null
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(children: [
                      Icon(Icons.error_rounded,
                          size: 16, color: theme.colors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            _error!.message(currencyCode: widget.currencyCode),
                            style: theme.typography.caption.copyWith(
                                color: theme.colors.danger,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _entry(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(widget.tint);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(theme.radii.pill),
      borderSide: BorderSide(
          color: _error != null ? theme.colors.danger : theme.colors.border),
    );
    return AnimatedBuilder(
      key: const ValueKey('entry'),
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_checking,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: theme.typography.bodyEmphasized.copyWith(
                color: theme.colors.onSurface,
                letterSpacing: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()]),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              isDense: true,
              filled: true,
              fillColor: theme.colors.surface,
              prefixIcon: Icon(Icons.confirmation_number_outlined,
                  color: theme.colors.onSurface.withValues(alpha: 0.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: accent, width: 2)),
            ),
          ),
        ),
        SizedBox(width: theme.spacing.sm),
        Semantics(
          button: true,
          label: _checking ? 'Checking code' : 'Apply code',
          excludeSemantics: true,
          child: KitoPressable(
            child: Material(
              color: accent,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _checking ? null : _apply,
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 48, minWidth: 88),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _checking
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.onAccent(widget.tint)))
                      : Text('Apply',
                          style: theme.typography.button
                              .copyWith(color: theme.onAccent(widget.tint))),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _chip(BuildContext context, KitoCheckoutPromo promo) {
    final theme = context.kito;
    final green = theme.colors.success;
    return Container(
      key: ValueKey(promo.code),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radii.pill),
        border: Border.all(color: green.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Icon(Icons.verified_rounded, color: green, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: 'Promo ${promo.code} applied, ${promo.title}',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: promo.code,
                    style: theme.typography.label.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: theme.colors.onSurface)),
                TextSpan(
                    text: '  ${promo.title}',
                    style: theme.typography.caption
                        .copyWith(color: green, fontWeight: FontWeight.w700)),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Remove ${promo.code}',
          onPressed: () {
            HapticFeedback.selectionClick();
            widget.onChanged(null);
          },
          icon: Icon(Icons.close_rounded,
              size: 18, color: theme.colors.onSurface.withValues(alpha: 0.6)),
        ),
      ]),
    );
  }
}
