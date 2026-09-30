// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'money.dart';
import 'parts.dart';
import 'payment.dart';

String _stamp(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, ${two(d.hour)}:${two(d.minute)}';
}

/// A paper receipt: a ticket with a torn edge, the order number (tap to copy), the date, the
/// items, every summary line, the total and how it was paid.
///
/// ```dart
/// KitoCheckoutReceipt(order: placed, merchant: 'Kahawa House')
/// ```
class KitoCheckoutReceipt extends StatefulWidget {
  /// Creates a receipt.
  const KitoCheckoutReceipt({
    super.key,
    required this.order,
    this.merchant,
    this.showsItems = true,
    this.tint,
  });

  /// The order.
  final KitoCheckoutPlacedOrder order;

  /// The shop name at the top.
  final String? merchant;

  /// Lists the items.
  final bool showsItems;

  /// Replaces the success green on the header.
  final Color? tint;

  @override
  State<KitoCheckoutReceipt> createState() => _KitoCheckoutReceiptState();
}

class _KitoCheckoutReceiptState extends State<KitoCheckoutReceipt> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _copy() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.order.number));
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final o = widget.order;
    String money(int c) =>
        KitoCheckoutMoney.format(c, currencyCode: o.currencyCode);
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);
    final accent = widget.tint ?? theme.colors.success;

    Widget line(String title, String value,
            {TextStyle? style, Color? color, String? spoken}) =>
        Semantics(
          label: '$title, ${spoken ?? value}',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Expanded(
                  child: Text(title,
                      style: style ??
                          theme.typography.label.copyWith(color: muted))),
              Text(value,
                  style: (style ?? theme.typography.label).copyWith(
                      color: color ?? theme.colors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipPath(
        clipper: _TornEdgeClipper(),
        child: ColoredBox(
          color: theme.colors.surface,
          child: Padding(
            padding: EdgeInsets.fromLTRB(theme.spacing.lg, theme.spacing.lg,
                theme.spacing.lg, theme.spacing.xl + 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  CheckoutIconTile(
                      icon: Icons.receipt_long_rounded,
                      color: accent,
                      size: 40),
                  SizedBox(width: theme.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(widget.merchant ?? 'Receipt',
                              style: theme.typography.headline
                                  .copyWith(color: theme.colors.onSurface)),
                        ),
                        Text(_stamp(o.placedAt),
                            style: theme.typography.caption
                                .copyWith(color: muted)),
                      ],
                    ),
                  ),
                ]),
                SizedBox(height: theme.spacing.md),
                Semantics(
                  button: true,
                  label: 'Order number ${o.number}',
                  hint: _copied ? 'Copied' : 'Copy',
                  excludeSemantics: true,
                  child: Material(
                    color: theme.colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(theme.radii.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(theme.radii.md),
                      onTap: _copy,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.md, vertical: 12),
                        child: Row(children: [
                          Text('Order',
                              style: theme.typography.caption
                                  .copyWith(color: muted)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(o.number,
                                style: theme.typography.bodyEmphasized.copyWith(
                                    color: theme.colors.onSurface,
                                    letterSpacing: 1,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ])),
                          ),
                          AnimatedSwitcher(
                            duration: KitoMotion.of(context, theme.motion.fast),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Icon(
                                _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                key: ValueKey(_copied),
                                size: 18,
                                color: _copied ? accent : muted),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                if (widget.showsItems && o.items.isNotEmpty) ...[
                  SizedBox(height: theme.spacing.md),
                  for (final i in o.items)
                    line(
                      '${i.quantity} × ${i.title}',
                      money(i.lineTotal),
                      style: theme.typography.label
                          .copyWith(color: theme.colors.onSurface),
                    ),
                ],
                SizedBox(height: theme.spacing.md),
                const CheckoutDashedDivider(),
                SizedBox(height: theme.spacing.md),
                for (final l in o.lines)
                  line(
                    l.title,
                    l.originalAmount != null && l.amount == 0
                        ? 'Free'
                        : l.isIncluded
                            ? '${money(l.amount)} incl.'
                            : money(l.amount),
                    color: l.amount < 0 ||
                            (l.originalAmount != null && l.amount == 0)
                        ? theme.colors.success
                        : null,
                  ),
                SizedBox(height: theme.spacing.sm),
                const CheckoutDashedDivider(),
                SizedBox(height: theme.spacing.sm),
                line('Total', money(o.total),
                    style: theme.typography.title.copyWith(
                        color: theme.colors.onSurface,
                        fontWeight: FontWeight.w800)),
                if (o.paymentTitle != null)
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.sm),
                    child: Row(children: [
                      Icon(Icons.verified_rounded, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Paid with ${o.paymentTitle}',
                            style: theme.typography.caption
                                .copyWith(color: muted)),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TornEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const tooth = 12.0;
    const depth = 7.0;
    const r = 18.0;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - depth);
    final count = math.max(1, (size.width / tooth).round());
    final step = size.width / count;
    for (var i = count; i > 0; i--) {
      final x = i * step;
      path
        ..lineTo(x - step / 2, size.height)
        ..lineTo(x - step, size.height - depth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdgeClipper old) => false;
}

/// The confirmation after an order is placed: a ring that pulses out, a tick that draws
/// itself, the title and ETA, then the receipt and your actions rising in. Reduce Motion shows
/// it all at once.
///
/// ```dart
/// KitoCheckoutSuccess(
///   order: placed,
///   onTrackOrder: openTracking,
///   onContinueShopping: () => Navigator.pop(context),
/// )
/// ```
class KitoCheckoutSuccess extends StatefulWidget {
  /// Creates the confirmation.
  const KitoCheckoutSuccess({
    super.key,
    required this.order,
    this.title = 'Order placed!',
    this.message,
    this.merchant,
    this.onTrackOrder,
    this.onContinueShopping,
    this.showsReceipt = true,
    this.tint,
  });

  /// The order.
  final KitoCheckoutPlacedOrder order;

  /// The headline.
  final String title;

  /// A line under it; the order's ETA when null.
  final String? message;

  /// The shop name on the receipt.
  final String? merchant;

  /// Shows **Track order** when set.
  final VoidCallback? onTrackOrder;

  /// Shows **Continue shopping** when set.
  final VoidCallback? onContinueShopping;

  /// Shows the receipt under the heading.
  final bool showsReceipt;

  /// Replaces the success green.
  final Color? tint;

  @override
  State<KitoCheckoutSuccess> createState() => _KitoCheckoutSuccessState();
}

class _KitoCheckoutSuccessState extends State<KitoCheckoutSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _c.value = 1;
    } else {
      HapticFeedback.mediumImpact();
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _stage(double from, double to,
          [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(from, to, curve: curve));

  Widget _rise(Animation<double> a, Widget child) => AnimatedBuilder(
        animation: a,
        builder: (context, c) => Opacity(
          opacity: a.value.clamp(0, 1),
          child: Transform.translate(
              offset: Offset(0, 28 * (1 - a.value)), child: c),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = widget.tint ?? theme.colors.success;
    final ring = _stage(0, 0.45, const KitoSpringCurve());
    final pulse = _stage(0.15, 0.8);
    final heading = _stage(0.3, 0.6);
    final receipt = _stage(0.45, 0.85);
    final actions = _stage(0.6, 1);
    final message = widget.message ?? widget.order.eta;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: theme.spacing.lg),
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _PulsePainter(pulse.value, accent),
                child: Center(
                  child: Transform.scale(
                    scale: ring.value,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _c.value >= 0.25
                          ? const CheckoutDrawnCheck(
                              color: Colors.white, size: 52, strokeWidth: 5)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: theme.spacing.lg),
        _rise(
          heading,
          Semantics(
            liveRegion: true,
            child: Column(children: [
              Semantics(
                header: true,
                child: Text(widget.title,
                    textAlign: TextAlign.center,
                    style: theme.typography.display
                        .copyWith(color: theme.colors.onBackground)),
              ),
              if (message != null) ...[
                SizedBox(height: theme.spacing.xs),
                Text(message,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.copyWith(
                        color:
                            theme.colors.onBackground.withValues(alpha: 0.65))),
              ],
              if (widget.order.destination != null) ...[
                SizedBox(height: theme.spacing.xs),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.place_rounded,
                      size: 16,
                      color: theme.colors.onBackground.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(widget.order.destination!,
                        textAlign: TextAlign.center,
                        style: theme.typography.caption.copyWith(
                            color: theme.colors.onBackground
                                .withValues(alpha: 0.6))),
                  ),
                ]),
              ],
            ]),
          ),
        ),
        if (widget.showsReceipt) ...[
          SizedBox(height: theme.spacing.xl),
          _rise(
              receipt,
              KitoCheckoutReceipt(
                  order: widget.order,
                  merchant: widget.merchant,
                  tint: widget.tint)),
        ],
        if (widget.onTrackOrder != null || widget.onContinueShopping != null)
          _rise(
            actions,
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onTrackOrder != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colors.primary,
                        foregroundColor: theme.colors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        textStyle: theme.typography.button,
                      ),
                      onPressed: widget.onTrackOrder,
                      icon: const Icon(Icons.near_me_rounded, size: 18),
                      label: const Text('Track order'),
                    ),
                  if (widget.onTrackOrder != null &&
                      widget.onContinueShopping != null)
                    SizedBox(height: theme.spacing.sm),
                  if (widget.onContinueShopping != null)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colors.onBackground,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: theme.colors.border),
                        textStyle: theme.typography.button,
                      ),
                      onPressed: widget.onContinueShopping,
                      child: const Text('Continue shopping'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    for (final lag in const [0.0, 0.25]) {
      final v = ((t - lag) / (1 - lag)).clamp(0.0, 1.0);
      if (v <= 0) continue;
      canvas.drawCircle(
        c,
        44 + 26 * v,
        Paint()
          ..color = color.withValues(alpha: 0.35 * (1 - v))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - v) + 1,
      );
    }
    const dots = 10;
    for (var i = 0; i < dots; i++) {
      final a = i / dots * math.pi * 2;
      final d = 50 + 20 * t;
      canvas.drawCircle(
        c + Offset(math.cos(a) * d, math.sin(a) * d),
        3 * (1 - t),
        Paint()..color = color.withValues(alpha: 1 - t),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color;
}
