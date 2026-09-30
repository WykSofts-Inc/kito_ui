// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'card_view.dart';
import 'models.dart';

/// A quick action on a [KitoWalletBalanceCard]: Send, Pay, Withdraw, Top up.
@immutable
class KitoWalletAction {
  /// Creates an action.
  const KitoWalletAction(
      {required this.icon, required this.label, required this.onTap});

  /// The icon.
  final IconData icon;

  /// The label under it.
  final String label;

  /// Called on tap.
  final VoidCallback onTap;
}

/// A balance at a glance: the amount (counting up when it changes, hidden behind dots at a
/// tap), a change line, an optional sparkline and a row of quick actions, on a card-style
/// gradient.
///
/// ```dart
/// KitoWalletBalanceCard(
///   title: 'M-Pesa balance',
///   balance: 12450,
///   change: '+KES 3,200 this week',
///   trend: const [8, 9.5, 9, 11, 10.2, 12.45],
///   isHidden: hidden,
///   onToggleHidden: () => setState(() => hidden = !hidden),
///   actions: [KitoWalletAction(icon: Icons.send_rounded, label: 'Send', onTap: send)],
/// )
/// ```
class KitoWalletBalanceCard extends StatelessWidget {
  /// Creates a balance card.
  const KitoWalletBalanceCard({
    super.key,
    required this.title,
    required this.balance,
    this.currencyCode = 'KES',
    this.decimals = 0,
    this.subtitle,
    this.change,
    this.changeIsPositive = true,
    this.trend = const [],
    this.isHidden = false,
    this.onToggleHidden,
    this.actions = const [],
    this.style = KitoWalletCardStyle.midnight,
    this.leading,
  });

  /// "M-Pesa balance", "Available".
  final String title;

  /// The amount.
  final double balance;

  /// ISO 4217 code.
  final String currencyCode;

  /// Decimal places shown.
  final int decimals;

  /// A quieter line under the amount, e.g. "Fuliza limit KES 5,000".
  final String? subtitle;

  /// "+KES 3,200 this week".
  final String? change;

  /// Colours [change] green (or red when false).
  final bool changeIsPositive;

  /// Recent balances for a sparkline, oldest first; hidden with fewer than two.
  final List<double> trend;

  /// Shows dots instead of the amount.
  final bool isHidden;

  /// Shows an eye button that calls this.
  final VoidCallback? onToggleHidden;

  /// Buttons along the bottom.
  final List<KitoWalletAction> actions;

  /// The fill; same styles as cards.
  final KitoWalletCardStyle style;

  /// Shown before the title, e.g. a provider mark.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final fg = style.foreground;
    final formatted =
        KitoWalletMoney.format(balance, currencyCode, decimals: decimals);
    final changeColor = changeIsPositive
        ? (fg.computeLuminance() > 0.5
            ? const Color(0xFF6EE7A0)
            : const Color(0xFF0E7A43))
        : (fg.computeLuminance() > 0.5
            ? const Color(0xFFFF8A8A)
            : const Color(0xFFB42318));
    return Semantics(
      container: true,
      label: '$title, ${isHidden ? 'hidden' : formatted}'
          '${change != null && !isHidden ? ', $change' : ''}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radii.xl),
        child: Stack(
          children: [
            Positioned.fill(child: KitoWalletCardSurface(style: style)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: fg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 8)
                        ],
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(title,
                                style: theme.typography.label.copyWith(
                                    color: fg.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        if (onToggleHidden != null)
                          _EyeButton(
                              hidden: isHidden,
                              color: fg,
                              onTap: onToggleHidden!),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: AnimatedSwitcher(
                                duration:
                                    KitoMotion.of(context, theme.motion.medium),
                                transitionBuilder: (c, a) => FadeTransition(
                                  opacity: a,
                                  child: SizeTransition(
                                      sizeFactor: a,
                                      axis: Axis.horizontal,
                                      child: c),
                                ),
                                child: isHidden
                                    ? Text('••••••',
                                        key: const ValueKey('hidden'),
                                        style: _amountStyle(fg))
                                    : TweenAnimationBuilder<double>(
                                        key: const ValueKey('shown'),
                                        tween: Tween(end: balance),
                                        duration: KitoMotion.of(context,
                                            const Duration(milliseconds: 700)),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, v, _) => Text(
                                          KitoWalletMoney.format(
                                              v, currencyCode,
                                              decimals: decimals),
                                          maxLines: 1,
                                          style: _amountStyle(fg),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          if (trend.length >= 2) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 84,
                              height: 36,
                              child: CustomPaint(
                                painter: _SparklinePainter(
                                    values: trend,
                                    color: fg,
                                    rtl: context.isRtl),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (change != null && !isHidden) ...[
                      const SizedBox(height: 4),
                      ExcludeSemantics(
                        child: Row(
                          children: [
                            Icon(
                                changeIsPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 16,
                                color: changeColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(change!,
                                  style: theme.typography.caption.copyWith(
                                      color: changeColor,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: theme.typography.caption
                              .copyWith(color: fg.withValues(alpha: 0.6))),
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          for (final a in actions)
                            Expanded(
                                child: _ActionButton(action: a, color: fg)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _amountStyle(Color fg) => TextStyle(
        color: fg,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class _EyeButton extends StatelessWidget {
  const _EyeButton(
      {required this.hidden, required this.color, required this.onTap});

  final bool hidden;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: hidden ? 'Show balance' : 'Hide balance',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          radius: 22,
          child: SizedBox(
            width: 44,
            height: 44,
            child: AnimatedSwitcher(
              duration: KitoMotion.of(context, context.kito.motion.fast),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                hidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                key: ValueKey(hidden),
                size: 20,
                color: color.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.color});

  final KitoWalletAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      container: true,
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: KitoPressable(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              action.onTap();
            },
            borderRadius: BorderRadius.circular(theme.radii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.12)),
                    ),
                    child: Icon(action.icon, size: 20, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption.copyWith(
                          color: color.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(
      {required this.values, required this.color, required this.rtl});

  final List<double> values;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          (rtl ? 1 - i / (values.length - 1) : i / (values.length - 1)) *
              size.width,
          size.height - 3 - (values[i] - lo) / span * (size.height - 6),
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final mid = (a.dx + b.dx) / 2;
      line.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.9),
    );
    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color || old.rtl != rtl;
}
