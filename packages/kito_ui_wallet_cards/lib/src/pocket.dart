// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'card_view.dart';
import 'models.dart';

/// Colours for [KitoWalletPocket].
@immutable
class KitoWalletPocketStyle {
  /// Creates a style.
  const KitoWalletPocketStyle({
    required this.pocket,
    this.foreground = Colors.white,
    this.secondaryForeground,
    this.stitch,
    required this.glow,
  });

  /// The leather.
  final Color pocket;

  /// The total.
  final Color foreground;

  /// The title and button; [foreground] at 60% when null.
  final Color? secondaryForeground;

  /// The dashed stitching; [foreground] at 25% when null.
  final Color? stitch;

  /// The light that blooms behind the cards as they rise.
  final List<Color> glow;

  /// Deep navy with a blue-violet glow.
  static const midnight = KitoWalletPocketStyle(
      pocket: Color(0xFF21244D), glow: [Color(0xFF7359FF), Color(0xFF1ACCFF)]);

  /// Slate leather with a soft blue glow.
  static const slate = KitoWalletPocketStyle(
      pocket: Color(0xFF1C2B3D),
      secondaryForeground: Color(0xFF739ED9),
      glow: [Color(0xFF6699FF)]);

  /// Warm tan leather.
  static const tan = KitoWalletPocketStyle(
      pocket: Color(0xFF9E6B42), glow: [Color(0xFFFFCC80)]);

  /// Deep green leather with a mint glow.
  static const forest = KitoWalletPocketStyle(
      pocket: Color(0xFF123B2A), glow: [Color(0xFF34D399), Color(0xFFA3E635)]);
}

/// Cards tucked into a stitched pocket with the total hidden. Reveal it and the cards spring up
/// out of the pocket and fan, each showing its balance, while a glow blooms behind them and the
/// total counts up. Hide it and they sink back.
///
/// ```dart
/// KitoWalletPocket(
///   cards: cards,
///   isRevealed: revealed,
///   onChanged: (v) => setState(() => revealed = v),
/// )
/// ```
class KitoWalletPocket extends StatelessWidget {
  /// Creates a pocket.
  const KitoWalletPocket({
    super.key,
    required this.cards,
    required this.isRevealed,
    required this.onChanged,
    this.style = KitoWalletPocketStyle.midnight,
    this.title = 'Total balance',
    this.showLabel = 'Show the balance',
    this.hideLabel = 'Hide the balance',
    this.currencyCode,
  });

  /// The cards, back to front.
  final List<KitoWalletCard> cards;

  /// Whether the cards are out and the total shows.
  final bool isRevealed;

  /// Called with the new state when the button is tapped.
  final ValueChanged<bool> onChanged;

  /// The colours.
  final KitoWalletPocketStyle style;

  /// Above the total.
  final String title;

  /// The button while hidden.
  final String showLabel;

  /// The button while revealed.
  final String hideLabel;

  /// The total's currency; the first card's when null.
  final String? currencyCode;

  /// Each card's top edge relative to the pocket's top. Hidden, they peek out in tight steps;
  /// revealed, they rise and fan so every card's top strip shows. Card 0 is at the back.
  static double cardOffset(
      {required int index,
      required int count,
      required double cardHeight,
      required bool revealed}) {
    final fromFront = (count - 1 - index).toDouble();
    return revealed
        ? -cardHeight * 0.62 - fromFront * cardHeight * 0.2
        : -cardHeight * 0.2 - fromFront * cardHeight * 0.07;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final reduce = context.reduceMotion;
    final secondary =
        style.secondaryForeground ?? style.foreground.withValues(alpha: 0.6);
    final stitch = style.stitch ?? style.foreground.withValues(alpha: 0.25);
    final currency =
        currencyCode ?? (cards.isEmpty ? 'KES' : cards.first.currencyCode);
    final total = cards.totalBalance;
    final duration = KitoMotion.of(
        context,
        reduce
            ? const Duration(milliseconds: 250)
            : const Duration(milliseconds: 620));
    final curve =
        reduce ? Curves.easeInOut : const KitoSpringCurve(damping: 0.72);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width * 0.84;
      final cardHeight = cardWidth / KitoWalletCardGeometry.aspectRatio;
      final pocketHeight = cardHeight * 1.05;
      final fan = cardHeight * (0.62 + 0.2 * math.max(cards.length - 1, 0)) +
          width * 0.06;
      final height = pocketHeight + fan;
      final pocketTop = height - pocketHeight;
      final start = (width - cardWidth) / 2;

      return Semantics(
        container: true,
        label: 'Wallet with ${cards.length} cards',
        child: SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow behind the cards.
              Positioned(
                left: -width * 0.05,
                width: width * 1.1,
                top: pocketTop - cardHeight * 1.5,
                height: cardHeight * 1.6,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: isRevealed ? 0.85 : 0,
                    duration: duration,
                    child: AnimatedScale(
                      scale: isRevealed ? 1 : 0.6,
                      duration: duration,
                      curve: curve,
                      child: ImageFiltered(
                        imageFilter:
                            ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              ...style.glow
                                  .map((c) => c.withValues(alpha: 0.9)),
                              style.glow.last.withValues(alpha: 0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Pocket back.
              Positioned(
                left: 0,
                right: 0,
                top: pocketTop - cardHeight * 0.18,
                height: pocketHeight + cardHeight * 0.18,
                child: CustomPaint(
                  painter: _PocketPainter(
                      fill: style.pocket.withValues(alpha: 0.55), dip: 0),
                ),
              ),
              // Cards, back to front.
              for (var i = 0; i < cards.length; i++)
                AnimatedPositionedDirectional(
                  key: ValueKey(cards[i].id),
                  duration: duration +
                      (reduce
                          ? Duration.zero
                          : Duration(
                              milliseconds: 45 * (cards.length - 1 - i))),
                  curve: curve,
                  start: start,
                  width: cardWidth,
                  top: pocketTop +
                      cardOffset(
                          index: i,
                          count: cards.length,
                          cardHeight: cardHeight,
                          revealed: isRevealed),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          cards[i].style.cornerRadius *
                              cardWidth /
                              KitoWalletCardGeometry.designWidth),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, -2)),
                      ],
                    ),
                    child: ExcludeSemantics(
                      excluding: !isRevealed,
                      child: KitoWalletCardView(
                          card: cards[i], showsBalance: isRevealed),
                    ),
                  ),
                ),
              // Pocket front with its stitching and the total.
              Positioned(
                left: 0,
                right: 0,
                top: pocketTop,
                height: pocketHeight,
                child: CustomPaint(
                  painter: _PocketPainter(
                      fill: style.pocket,
                      dip: 18,
                      stitch: stitch,
                      shadow: true),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 38, 20, 20),
                    child: Column(
                      children: [
                        Text(title.toUpperCase(),
                            style: theme.typography.caption.copyWith(
                                color: secondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4)),
                        const SizedBox(height: 6),
                        Semantics(
                          container: true,
                          liveRegion: true,
                          label: isRevealed
                              ? '$title ${KitoWalletMoney.format(total, currency)}'
                              : '$title hidden',
                          excludeSemantics: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: isRevealed ? total : 0),
                              duration: KitoMotion.of(
                                  context, const Duration(milliseconds: 900)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => AnimatedSwitcher(
                                duration:
                                    KitoMotion.of(context, theme.motion.fast),
                                child: Text(
                                  isRevealed || value > 0.5
                                      ? KitoWalletMoney.format(value, currency)
                                      : '••••••',
                                  key: ValueKey(isRevealed || value > 0.5),
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: style.foreground,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _PocketButton(
                          label: isRevealed ? hideLabel : showLabel,
                          icon: isRevealed
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: secondary,
                          fill: style.foreground.withValues(alpha: 0.08),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onChanged(!isRevealed);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PocketButton extends StatelessWidget {
  const _PocketButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: KitoPressable(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Ink(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration:
                  ShapeDecoration(color: fill, shape: const StadiumBorder()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: KitoMotion.of(context, theme.motion.fast),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child:
                        Icon(icon, key: ValueKey(icon), size: 18, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(label,
                      style: theme.typography.label
                          .copyWith(color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded corners and a top edge that dips gently in the middle, like leather.
Path _pocketPath(Rect r, double dip, double radius) {
  final rad = math.max(radius, 4.0);
  return Path()
    ..moveTo(r.left, r.top + rad)
    ..quadraticBezierTo(r.left, r.top, r.left + rad, r.top)
    ..cubicTo(r.center.dx - r.width * 0.2, r.top + dip,
        r.center.dx + r.width * 0.2, r.top + dip, r.right - rad, r.top)
    ..quadraticBezierTo(r.right, r.top, r.right, r.top + rad)
    ..lineTo(r.right, r.bottom - rad)
    ..quadraticBezierTo(r.right, r.bottom, r.right - rad, r.bottom)
    ..lineTo(r.left + rad, r.bottom)
    ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - rad)
    ..close();
}

class _PocketPainter extends CustomPainter {
  const _PocketPainter(
      {required this.fill,
      required this.dip,
      this.stitch,
      this.shadow = false});

  final Color fill;
  final double dip;
  final Color? stitch;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _pocketPath(rect, dip, 34);
    if (shadow) {
      canvas.drawShadow(path.shift(const Offset(0, -6)),
          Colors.black.withValues(alpha: 0.6), 16, false);
    }
    canvas.drawPath(path, Paint()..color = fill);
    if (stitch case final color?) {
      final inner = _pocketPath(rect.deflate(9), dip, 25);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color;
      for (final metric in inner.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, d + 5), paint);
          d += 9;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PocketPainter old) =>
      old.fill != fill || old.dip != dip || old.stitch != stitch;
}
