// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'money.dart';
import 'parts.dart';

/// Where a place-order button is.
enum KitoCheckoutOrderState {
  /// Ready to tap.
  idle,

  /// Waiting for your server or payment provider.
  processing,

  /// The order went through.
  success,

  /// It didn't; tapping tries again.
  failure,
}

/// The place-order button: a capsule with the amount that shrinks into a spinner while
/// [state] is processing, turns green and draws a tick on success, and shakes red with "Try
/// again" on failure. You own the state — set it as your request goes.
///
/// ```dart
/// KitoCheckoutPlaceOrderButton(
///   state: state,
///   amount: totals.total,
///   onPressed: () async {
///     setState(() => state = KitoCheckoutOrderState.processing);
///     final ok = await api.placeOrder(order);
///     setState(() => state = ok ? KitoCheckoutOrderState.success : KitoCheckoutOrderState.failure);
///   },
/// )
/// ```
class KitoCheckoutPlaceOrderButton extends StatefulWidget {
  /// Creates a button.
  const KitoCheckoutPlaceOrderButton({
    super.key,
    required this.onPressed,
    this.state = KitoCheckoutOrderState.idle,
    this.title = 'Place order',
    this.amount,
    this.currencyCode = kitoCheckoutDefaultCurrency,
    this.processingLabel = 'Placing your order',
    this.successLabel = 'Order placed',
    this.failureTitle = 'Try again',
    this.enabled = true,
    this.icon = Icons.lock_rounded,
    this.tint,
  });

  /// Called on tap in [KitoCheckoutOrderState.idle] or [KitoCheckoutOrderState.failure].
  final VoidCallback? onPressed;

  /// The current state.
  final KitoCheckoutOrderState state;

  /// The idle title.
  final String title;

  /// Shown after the title: "Place order · KES 2,450". Cents.
  final int? amount;

  /// The currency for [amount].
  final String currencyCode;

  /// What screen readers hear while processing.
  final String processingLabel;

  /// What screen readers hear on success.
  final String successLabel;

  /// The title after a failure.
  final String failureTitle;

  /// Greys it out when false.
  final bool enabled;

  /// The leading icon when idle.
  final IconData? icon;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  State<KitoCheckoutPlaceOrderButton> createState() =>
      _KitoCheckoutPlaceOrderButtonState();
}

class _KitoCheckoutPlaceOrderButtonState
    extends State<KitoCheckoutPlaceOrderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void didUpdateWidget(KitoCheckoutPlaceOrderButton old) {
    super.didUpdateWidget(old);
    if (old.state == widget.state) return;
    switch (widget.state) {
      case KitoCheckoutOrderState.success:
        HapticFeedback.mediumImpact();
      case KitoCheckoutOrderState.failure:
        HapticFeedback.heavyImpact();
        if (!context.reduceMotion) _shake.forward(from: 0);
      case KitoCheckoutOrderState.idle:
      case KitoCheckoutOrderState.processing:
        break;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    const height = 56.0;
    final s = widget.state;
    final compact = s == KitoCheckoutOrderState.processing ||
        s == KitoCheckoutOrderState.success;
    final color = switch (s) {
      KitoCheckoutOrderState.success => theme.colors.success,
      KitoCheckoutOrderState.failure => theme.colors.danger,
      _ => theme.accent(widget.tint),
    };
    final fg = switch (s) {
      KitoCheckoutOrderState.success ||
      KitoCheckoutOrderState.failure =>
        Colors.white,
      _ => theme.onAccent(widget.tint),
    };
    final tappable = widget.enabled &&
        widget.onPressed != null &&
        (s == KitoCheckoutOrderState.idle ||
            s == KitoCheckoutOrderState.failure);
    final amount = widget.amount == null
        ? null
        : KitoCheckoutMoney.format(widget.amount!,
            currencyCode: widget.currencyCode);
    final label = switch (s) {
      KitoCheckoutOrderState.idle =>
        amount == null ? widget.title : '${widget.title}, $amount',
      KitoCheckoutOrderState.processing => widget.processingLabel,
      KitoCheckoutOrderState.success => widget.successLabel,
      KitoCheckoutOrderState.failure => widget.failureTitle,
    };

    final content = switch (s) {
      KitoCheckoutOrderState.processing => SizedBox(
          key: const ValueKey('spin'),
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
        ),
      KitoCheckoutOrderState.success => CheckoutDrawnCheck(
          key: const ValueKey('tick'), color: fg, size: 30, strokeWidth: 3.5),
      KitoCheckoutOrderState.failure => Row(
          key: const ValueKey('fail'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: fg, size: 20),
            const SizedBox(width: 8),
            Text(widget.failureTitle,
                maxLines: 1,
                style: theme.typography.button.copyWith(color: fg)),
          ],
        ),
      KitoCheckoutOrderState.idle => Row(
          key: const ValueKey('idle'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            Text(widget.title,
                maxLines: 1,
                style: theme.typography.button.copyWith(color: fg)),
            if (amount != null) ...[
              Text('  ·  ',
                  style: theme.typography.button
                      .copyWith(color: fg.withValues(alpha: 0.6))),
              Text(amount,
                  style: theme.typography.button.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ],
        ),
    };

    return Semantics(
      button: true,
      enabled: tappable,
      liveRegion: s != KitoCheckoutOrderState.idle,
      label: label,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, c) {
        final full = c.maxWidth.isFinite ? c.maxWidth : 320.0;
        return AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
                0),
            child: child,
          ),
          child: Center(
            child: KitoPressable(
              enabled: tappable,
              child: AnimatedOpacity(
                opacity: widget.enabled ? 1 : 0.45,
                duration: KitoMotion.of(context, theme.motion.fast),
                child: AnimatedContainer(
                  duration: KitoMotion.of(context, theme.motion.slow),
                  curve:
                      compact ? theme.motion.emphasized : theme.motion.spring,
                  width: compact ? height : full,
                  height: height,
                  decoration: ShapeDecoration(
                    color: color,
                    shape: const StadiumBorder(),
                    shadows: [
                      BoxShadow(
                        color:
                            color.withValues(alpha: widget.enabled ? 0.3 : 0),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: tappable
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onPressed!();
                            }
                          : null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: compact ? 0 : theme.spacing.lg),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration:
                                KitoMotion.of(context, theme.motion.medium),
                            switchInCurve: theme.motion.spring,
                            transitionBuilder: (child, a) => FadeTransition(
                              opacity: a,
                              child: ScaleTransition(
                                  scale: Tween(begin: 0.6, end: 1.0).animate(a),
                                  child: child),
                            ),
                            child: FittedBox(
                              key: content.key,
                              fit: BoxFit.scaleDown,
                              child: content,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// The sticky bar at the bottom of a checkout: the live total with a caption, a hint when the
/// step isn't complete yet, and the place-order button.
///
/// ```dart
/// KitoCheckoutTotalBar(
///   total: totals.total,
///   caption: 'Includes VAT',
///   hint: address == null ? 'Choose a delivery address' : null,
///   state: state,
///   onPlaceOrder: place,
/// )
/// ```
class KitoCheckoutTotalBar extends StatelessWidget {
  /// Creates a bar.
  const KitoCheckoutTotalBar({
    super.key,
    required this.total,
    required this.onPlaceOrder,
    this.currencyCode = kitoCheckoutDefaultCurrency,
    this.caption,
    this.hint,
    this.state = KitoCheckoutOrderState.idle,
    this.buttonTitle = 'Place order',
    this.tint,
  });

  /// Cents.
  final int total;

  /// Called when the button is tapped.
  final VoidCallback? onPlaceOrder;

  /// The currency.
  final String currencyCode;

  /// A line under the total: "Includes VAT · 3 items".
  final String? caption;

  /// When set, the button is disabled and this explains what's missing.
  final String? hint;

  /// The button's state.
  final KitoCheckoutOrderState state;

  /// The button's title.
  final String buttonTitle;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(top: BorderSide(color: theme.colors.border)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.spacing.lg, theme.spacing.md,
            theme.spacing.lg, theme.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: KitoMotion.of(context, theme.motion.medium),
              curve: theme.motion.emphasized,
              child: hint == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(bottom: theme.spacing.md),
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.md,
                              vertical: theme.spacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colors.warning.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(theme.radii.pill),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_rounded,
                                size: 16, color: theme.colors.warning),
                            SizedBox(width: theme.spacing.sm),
                            Expanded(
                              child: Text(hint!,
                                  style: theme.typography.caption.copyWith(
                                      color: theme.colors.onSurface,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),
                      ),
                    ),
            ),
            Row(children: [
              MergeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total',
                        style: theme.typography.caption.copyWith(
                            color: theme.colors.onSurface
                                .withValues(alpha: 0.55))),
                    CheckoutMoneyText(total,
                        currencyCode: currencyCode,
                        style: theme.typography.title.copyWith(
                            color: theme.colors.onSurface,
                            fontWeight: FontWeight.w800)),
                    if (caption != null)
                      Text(caption!,
                          style: theme.typography.caption.copyWith(
                              fontSize: 11,
                              color: theme.colors.onSurface
                                  .withValues(alpha: 0.5))),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.lg),
              Expanded(
                child: KitoCheckoutPlaceOrderButton(
                  state: state,
                  title: buttonTitle,
                  enabled: hint == null,
                  onPressed: onPlaceOrder,
                  tint: tint,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
