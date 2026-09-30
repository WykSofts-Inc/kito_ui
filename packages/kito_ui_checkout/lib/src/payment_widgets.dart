// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'money.dart';
import 'parts.dart';
import 'payment.dart';

/// How [KitoCheckoutPaymentPicker] lays out its methods.
enum KitoCheckoutPaymentStyle {
  /// Full-width rows with a subtitle and a radio.
  list,

  /// A grid of square tiles with the method's mark.
  tiles,
}

/// A small, brand-coloured mark for a payment method: the M-Pesa green, a card network, Apple
/// Pay or Google Pay. Drawn with Flutter only, no image assets.
class KitoCheckoutPaymentMark extends StatelessWidget {
  /// Creates a mark.
  const KitoCheckoutPaymentMark(this.method, {super.key, this.size = 40});

  /// The method.
  final KitoCheckoutPaymentMethod method;

  /// The height; the width is 1.5×.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final w = size * 1.5;
    final radius = BorderRadius.circular(size * 0.22);
    Widget box(Color bg, Widget child, {Color? border}) => Container(
          width: w,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border == null ? null : Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            child: Padding(padding: const EdgeInsets.all(4), child: child),
          ),
        );
    TextStyle word(Color c, {FontStyle? style, double? spacing}) => TextStyle(
        color: c,
        fontWeight: FontWeight.w900,
        fontStyle: style,
        letterSpacing: spacing,
        fontSize: size * 0.34);

    final mark = switch (method.kind) {
      KitoCheckoutPaymentKind.mpesa => box(
          const Color(0xFF2FB24C),
          Text('M-PESA', style: word(Colors.white, spacing: 0.5)),
        ),
      KitoCheckoutPaymentKind.applePay => box(
          Colors.black,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.apple, color: Colors.white, size: size * 0.42),
            Text('Pay', style: word(Colors.white)),
          ]),
        ),
      KitoCheckoutPaymentKind.googlePay => box(
          Colors.white,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('G',
                style: word(const Color(0xFF4285F4))
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 2),
            Text('Pay',
                style: word(const Color(0xFF3C4043))
                    .copyWith(fontWeight: FontWeight.w600)),
          ]),
          border: const Color(0xFFDADCE0),
        ),
      KitoCheckoutPaymentKind.card => switch (method.brand) {
          KitoCheckoutCardBrand.visa => box(const Color(0xFF1A1F71),
              Text('VISA', style: word(Colors.white, style: FontStyle.italic))),
          KitoCheckoutCardBrand.mastercard => box(
              const Color(0xFF16161D),
              SizedBox(
                width: size * 0.9,
                height: size * 0.56,
                child: CustomPaint(painter: _MastercardPainter()),
              )),
          KitoCheckoutCardBrand.amex => box(const Color(0xFF2E77BC),
              Text('AMEX', style: word(Colors.white, spacing: 0.5))),
          _ => box(theme.colors.surfaceMuted,
              Icon(Icons.credit_card_rounded, color: theme.colors.onSurface)),
        },
      KitoCheckoutPaymentKind.cash => box(
          const Color(0xFFE8F5E9),
          const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32)),
        ),
      KitoCheckoutPaymentKind.wallet => box(
          theme.colors.secondary.withValues(alpha: 0.14),
          Icon(Icons.account_balance_wallet_rounded,
              color: theme.colors.secondary),
        ),
    };
    return ExcludeSemantics(child: mark);
  }
}

class _MastercardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final c1 = Offset(size.width / 2 - r * 0.55, r);
    final c2 = Offset(size.width / 2 + r * 0.55, r);
    canvas.drawCircle(c1, r, Paint()..color = const Color(0xFFEB001B));
    canvas.drawCircle(
        c2, r, Paint()..color = const Color(0xFFF79E1B).withValues(alpha: 0.9));
    final overlap = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: c1, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c2, radius: r)),
    );
    canvas.drawPath(overlap, Paint()..color = const Color(0xFFFF5F00));
  }

  @override
  bool shouldRepaint(_MastercardPainter old) => false;
}

/// Choose how to pay: M-Pesa, saved cards, Apple Pay, Google Pay, cash or wallet — as rows or
/// a grid of tiles. Given the [total], methods that can't pay it (low wallet balance, over the
/// cash limit, expired card) are greyed out with the reason. UI only: charging is up to you.
///
/// ```dart
/// KitoCheckoutPaymentPicker(
///   methods: [
///     const KitoCheckoutPaymentMethod.mpesa('0712 345 678'),
///     KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.visa, '4242', expiry: '08/28'),
///     const KitoCheckoutPaymentMethod.applePay(),
///     const KitoCheckoutPaymentMethod.googlePay(),
///   ],
///   selected: method,
///   onChanged: (m) => setState(() => method = m),
///   total: totals.total,
/// )
/// ```
class KitoCheckoutPaymentPicker extends StatelessWidget {
  /// Creates a picker.
  const KitoCheckoutPaymentPicker({
    super.key,
    required this.methods,
    required this.selected,
    required this.onChanged,
    this.total,
    this.style = KitoCheckoutPaymentStyle.list,
    this.currencyCode = kitoCheckoutDefaultCurrency,
    this.now,
    this.tint,
  });

  /// The methods, in order.
  final List<KitoCheckoutPaymentMethod> methods;

  /// The chosen method, or null.
  final KitoCheckoutPaymentMethod? selected;

  /// Called with the new choice.
  final ValueChanged<KitoCheckoutPaymentMethod> onChanged;

  /// The order total in cents, to switch off methods that can't pay it.
  final int? total;

  /// Rows or tiles.
  final KitoCheckoutPaymentStyle style;

  /// The currency for balances and limits.
  final String currencyCode;

  /// "Now", for card expiry; the clock when null.
  final DateTime? now;

  /// Replaces the theme's primary colour.
  final Color? tint;

  String? _reason(KitoCheckoutPaymentMethod m) => total == null
      ? m.unavailableNote
      : m.unavailableReason(total!, currencyCode: currencyCode, now: now);

  void _pick(KitoCheckoutPaymentMethod m) {
    HapticFeedback.selectionClick();
    onChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    if (style == KitoCheckoutPaymentStyle.tiles) {
      return LayoutBuilder(builder: (context, c) {
        final gap = theme.spacing.sm;
        final columns = math.max(2, (c.maxWidth / 170).floor());
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in methods)
              SizedBox(width: w, child: _tile(context, m, accent)),
          ],
        );
      });
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in methods) ...[
          if (m != methods.first) SizedBox(height: theme.spacing.sm),
          _row(context, m, accent),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, KitoCheckoutPaymentMethod m, Color accent) {
    final theme = context.kito;
    final reason = _reason(m);
    final isSelected = selected?.id == m.id;
    final sub = reason ?? m.subtitle(currencyCode: currencyCode);
    return CheckoutChoiceCard(
      selected: isSelected,
      accent: accent,
      enabled: reason == null,
      padding: EdgeInsets.all(theme.spacing.md),
      semanticLabel: '${m.title}, $sub',
      onTap: () => _pick(m),
      child: Row(children: [
        KitoCheckoutPaymentMark(m, size: 34),
        SizedBox(width: theme.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.title,
                  style: theme.typography.label.copyWith(
                      color: theme.colors.onSurface,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub,
                  style: theme.typography.caption.copyWith(
                      color: reason != null
                          ? theme.colors.danger
                          : theme.colors.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        SizedBox(width: theme.spacing.sm),
        CheckoutRadio(selected: isSelected, accent: accent),
      ]),
    );
  }

  Widget _tile(
      BuildContext context, KitoCheckoutPaymentMethod m, Color accent) {
    final theme = context.kito;
    final reason = _reason(m);
    final isSelected = selected?.id == m.id;
    return CheckoutChoiceCard(
      selected: isSelected,
      accent: accent,
      enabled: reason == null,
      padding: EdgeInsets.all(theme.spacing.md),
      semanticLabel:
          '${m.title}, ${reason ?? m.subtitle(currencyCode: currencyCode)}',
      onTap: () => _pick(m),
      child: SizedBox(
        height: 96,
        child: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              KitoCheckoutPaymentMark(m, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.label.copyWith(
                          color: theme.colors.onSurface,
                          fontWeight: FontWeight.w700)),
                  Text(reason ?? m.subtitle(currencyCode: currencyCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption.copyWith(
                          fontSize: 11,
                          color: reason != null
                              ? theme.colors.danger
                              : theme.colors.onSurface
                                  .withValues(alpha: 0.55))),
                ],
              ),
            ],
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: AnimatedScale(
              scale: isSelected ? 1 : 0,
              duration: KitoMotion.of(context, theme.motion.medium),
              curve: theme.motion.spring,
              child: Icon(Icons.check_circle_rounded, color: accent, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Tip chips — No tip, 5%, 10%, 15% with what each costs, and a custom amount.
///
/// ```dart
/// KitoCheckoutTipSelector(
///   selected: tip,
///   subtotal: totals.subtotal,
///   onChanged: (t) => setState(() => tip = t),
/// )
/// ```
class KitoCheckoutTipSelector extends StatefulWidget {
  /// Creates a selector.
  const KitoCheckoutTipSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.subtotal,
    this.percents = KitoCheckoutTip.standardPercents,
    this.allowsCustom = true,
    this.currencyCode = kitoCheckoutDefaultCurrency,
    this.tint,
  });

  /// The tip.
  final KitoCheckoutTip selected;

  /// Called with the new tip.
  final ValueChanged<KitoCheckoutTip> onChanged;

  /// The subtotal in cents, to show what each percentage costs.
  final int subtotal;

  /// The percentage chips.
  final List<int> percents;

  /// Adds a **Custom** chip with an amount field.
  final bool allowsCustom;

  /// The currency.
  final String currencyCode;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  State<KitoCheckoutTipSelector> createState() =>
      _KitoCheckoutTipSelectorState();
}

class _KitoCheckoutTipSelectorState extends State<KitoCheckoutTipSelector> {
  late bool _custom = widget.selected.isCustom;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(widget.tint);
    final choices = <(String, String?, KitoCheckoutTip?)>[
      ('No tip', null, KitoCheckoutTip.none),
      for (final p in widget.percents)
        (
          '$p%',
          KitoCheckoutMoney.format(
              KitoCheckoutTip.percentOf(p)
                  .amountOn(widget.subtotal, currencyCode: widget.currencyCode),
              currencyCode: widget.currencyCode),
          KitoCheckoutTip.percentOf(p)
        ),
      if (widget.allowsCustom) ('Custom', null, null),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          for (final (i, c) in choices.indexed) ...[
            if (i > 0) SizedBox(width: theme.spacing.xs),
            Expanded(
              child: _chip(
                context,
                title: c.$1,
                detail: c.$2,
                selected: c.$3 == null
                    ? _custom
                    : !_custom && widget.selected == c.$3,
                accent: accent,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (c.$3 == null) {
                    setState(() => _custom = true);
                    final v = int.tryParse(_controller.text);
                    widget.onChanged(v == null
                        ? KitoCheckoutTip.none
                        : KitoCheckoutTip.custom(KitoCheckoutMoney.fromMajor(v,
                            currencyCode: widget.currencyCode)));
                  } else {
                    setState(() => _custom = false);
                    widget.onChanged(c.$3!);
                  }
                },
              ),
            ),
          ],
        ]),
        AnimatedSize(
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: theme.motion.emphasized,
          alignment: AlignmentDirectional.topStart,
          child: _custom
              ? Padding(
                  padding: EdgeInsets.only(top: theme.spacing.sm),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      widget.onChanged(n == null || n == 0
                          ? KitoCheckoutTip.none
                          : KitoCheckoutTip.custom(KitoCheckoutMoney.fromMajor(
                              n,
                              currencyCode: widget.currencyCode)));
                    },
                    decoration: InputDecoration(
                      labelText: 'Tip amount',
                      prefixText: '${widget.currencyCode} ',
                      filled: true,
                      fillColor: theme.colors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.radii.md)),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context,
      {required String title,
      required String? detail,
      required bool selected,
      required Color accent,
      required VoidCallback onTap}) {
    final theme = context.kito;
    final fg = selected ? theme.onAccent(widget.tint) : theme.colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: detail == null ? title : '$title, $detail',
      excludeSemantics: true,
      child: KitoPressable(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: KitoMotion.of(context, theme.motion.medium),
            curve: theme.motion.standard,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? accent : theme.colors.surface,
              borderRadius: BorderRadius.circular(theme.radii.md),
              border:
                  Border.all(color: selected ? accent : theme.colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.typography.label
                        .copyWith(color: fg, fontWeight: FontWeight.w700)),
                if (detail != null)
                  FittedBox(
                    child: Text(detail,
                        style: theme.typography.caption.copyWith(
                            fontSize: 10, color: fg.withValues(alpha: 0.7))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
