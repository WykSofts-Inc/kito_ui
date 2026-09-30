// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'number.dart';

const _mono = ['Menlo', 'Roboto Mono', 'Courier New', 'monospace'];

/// A payment card face, ID-1 proportioned. Flips to its back (signature strip and CVV) with
/// [isFlipped], and shows its balance in the corner with [showsBalance]. It fills the width it's
/// given; wrap it in a `SizedBox(width: …)` to size it.
///
/// ```dart
/// KitoWalletCardView(card: card)
/// KitoWalletCardView(card: card, isFlipped: true, cvv: '123')
/// KitoWalletCardView(card: card, showsBalance: true, onTap: () => flip())
/// ```
class KitoWalletCardView extends StatelessWidget {
  /// Shows [card].
  const KitoWalletCardView({
    super.key,
    required this.card,
    this.showsBalance = false,
    this.isFlipped = false,
    this.cvv,
    this.onTap,
    this.semanticHint,
  });

  /// The card.
  final KitoWalletCard card;

  /// Swaps the name in the corner for the balance.
  final bool showsBalance;

  /// Turns the card over to its back.
  final bool isFlipped;

  /// The security code on the back; dots when null.
  final String? cvv;

  /// Called on tap.
  final VoidCallback? onTap;

  /// What a tap does, for screen readers ("Flips the card").
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final label = [
      card.semanticLabel,
      if (showsBalance) 'balance ${card.formattedBalance}',
      if (isFlipped) 'showing the back',
      if (isFlipped && cvv != null) 'security code $cvv',
    ].join(', ');
    final Widget faces = context.reduceMotion
        ? AnimatedSwitcher(
            duration: theme.motion.fast,
            child: isFlipped
                ? _CardBack(key: const ValueKey('back'), card: card, cvv: cvv)
                : _CardFront(
                    key: const ValueKey('front'),
                    card: card,
                    showsBalance: showsBalance),
          )
        : TweenAnimationBuilder<double>(
            tween: Tween(end: isFlipped ? math.pi : 0),
            duration: theme.motion.slow,
            curve: Curves.easeInOutCubic,
            builder: (context, angle, _) {
              final showsBack = angle > math.pi / 2;
              final direction = context.isRtl ? -1.0 : 1.0;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateY(angle * direction),
                child: showsBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _CardBack(card: card, cvv: cvv),
                      )
                    : _CardFront(card: card, showsBalance: showsBalance),
              );
            },
          );
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      hint: semanticHint,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: KitoWalletCardGeometry.aspectRatio,
          child: faces,
        ),
      ),
    );
  }
}

/// Measures a face and hands its children a scale where the card is 320 points wide.
class _Face extends StatelessWidget {
  const _Face({required this.style, required this.builder});

  final KitoWalletCardStyle style;
  final Widget Function(BuildContext context, double unit) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : KitoWalletCardGeometry.designWidth;
      final unit = width / KitoWalletCardGeometry.designWidth;
      final radius = BorderRadius.circular(style.cornerRadius * unit);
      return ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            KitoWalletCardSurface(style: style, unit: unit),
            DefaultTextStyle.merge(
              style: TextStyle(color: style.foreground, height: 1.15),
              child: IconTheme.merge(
                data: IconThemeData(color: style.foreground),
                child: builder(context, unit),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({super.key, required this.card, required this.showsBalance});

  final KitoWalletCard card;
  final bool showsBalance;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final mobile = card.brand.isMobileMoney;
    return _Face(
      style: card.style,
      builder: (context, u) => Padding(
        padding: EdgeInsets.all(20 * u),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28 * u,
              child: Row(
                children: [
                  KitoWalletCardMarkView(
                      mark: card.mark,
                      height: 22 * u,
                      foreground: card.style.foreground),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: KitoMotion.of(context, theme.motion.medium),
                    switchInCurve: theme.motion.spring,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(
                          scale: Tween(begin: 0.8, end: 1.0).animate(a),
                          child: child),
                    ),
                    child: showsBalance
                        ? Text(card.formattedBalance,
                            key: const ValueKey('balance'),
                            style: TextStyle(
                                fontSize: 15 * u,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ]))
                        : Opacity(
                            key: const ValueKey('name'),
                            opacity: 0.75,
                            child: Text(card.name.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10 * u,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2 * u)),
                          ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (mobile)
              Text(card.issuer ?? card.brand.displayName,
                  style: TextStyle(
                      fontSize: 18 * u,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2 * u))
            else
              Row(
                children: [
                  SizedBox(
                      width: 40 * u,
                      height: 30 * u,
                      child: CustomPaint(painter: _ChipPainter(unit: u))),
                  SizedBox(width: 10 * u),
                  Opacity(
                    opacity: 0.8,
                    child: Transform.rotate(
                      angle: context.isRtl ? math.pi : 0,
                      child: Icon(Icons.contactless_outlined, size: 20 * u),
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(card.maskedNumber,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 19 * u,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1 * u,
                        fontFamilyFallback: _mono,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _Labelled(
                      unit: u,
                      label: mobile ? 'ACCOUNT' : 'CARD HOLDER',
                      value: card.holder.isEmpty ? '—' : card.holder),
                ),
                if (card.expiry.isNotEmpty)
                  _Labelled(
                      unit: u, label: 'EXPIRES', value: card.expiry, end: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled(
      {required this.unit,
      required this.label,
      required this.value,
      this.end = false});

  final double unit;
  final String label;
  final String value;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: 0.6,
          child: Text(label,
              style: TextStyle(
                  fontSize: 8 * u,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8 * u)),
        ),
        SizedBox(height: 2 * u),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13 * u,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key, required this.card, required this.cvv});

  final KitoWalletCard card;
  final String? cvv;

  @override
  Widget build(BuildContext context) {
    final code = cvv ??
        KitoWalletCardNumber.dot *
            (card.brand.cvvLength == 0 ? 3 : card.brand.cvvLength);
    return _Face(
      style: card.style,
      builder: (context, u) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 22 * u),
          Container(
              height: 40 * u, color: Colors.black.withValues(alpha: 0.85)),
          SizedBox(height: 14 * u),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * u),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32 * u,
                    alignment: AlignmentDirectional.centerStart,
                    padding: EdgeInsetsDirectional.only(start: 8 * u),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4 * u),
                      gradient: LinearGradient(colors: [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.8),
                      ]),
                    ),
                    child: Text(card.holder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11 * u,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.55))),
                  ),
                ),
                if (card.brand.cvvLength > 0) ...[
                  SizedBox(width: 10 * u),
                  Container(
                    width: 54 * u,
                    height: 32 * u,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4 * u),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(code,
                          style: TextStyle(
                              fontSize: 15 * u,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              fontFamilyFallback: _mono)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(20 * u, 0, 20 * u, 20 * u),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(
                        card.brand.isMobileMoney
                            ? 'Keep your PIN secret · never share it'
                            : 'Authorised signature · not valid unless signed',
                        maxLines: 2,
                        style: TextStyle(fontSize: 8 * u)),
                  ),
                ),
                SizedBox(width: 8 * u),
                KitoWalletCardMarkView(
                    mark: card.mark,
                    height: 16 * u,
                    foreground: card.style.foreground),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The fill, pattern and border of a card, at a given scale ([unit] = width / 320).
class KitoWalletCardSurface extends StatelessWidget {
  /// Paints [style].
  const KitoWalletCardSurface({super.key, required this.style, this.unit = 1});

  /// The style.
  final KitoWalletCardStyle style;

  /// Width / 320, for the border and pattern.
  final double unit;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final gradient = LinearGradient(
      begin: AlignmentDirectional.topStart.resolve(direction),
      end: AlignmentDirectional.bottomEnd.resolve(direction),
      colors: style.colors.length == 1
          ? [style.colors.first, style.colors.first]
          : style.colors,
    );
    Widget fill = DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    if (style.isGlass) {
      fill = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: fill,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        fill,
        CustomPaint(
          painter: _PatternPainter(
            pattern: style.pattern,
            color: style.foreground,
            rtl: direction == TextDirection.rtl,
          ),
        ),
        if (style.showsBorder)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(style.cornerRadius * unit),
              border: Border.all(
                  color: style.foreground.withValues(alpha: 0.18), width: 1),
            ),
          ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter(
      {required this.pattern, required this.color, required this.rtl});

  final KitoWalletCardPattern pattern;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == KitoWalletCardPattern.none) return;
    canvas.save();
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final w = size.width;
    final h = size.height;
    switch (pattern) {
      case KitoWalletCardPattern.none:
        break;
      case KitoWalletCardPattern.waves:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 0.08);
        for (var i = 0; i < 7; i++) {
          canvas.drawCircle(Offset(w, h), w * (0.35 + i * 0.16), paint);
        }
      case KitoWalletCardPattern.circles:
        canvas.drawOval(Rect.fromLTWH(w * 0.55, -h * 0.35, w * 0.75, w * 0.75),
            Paint()..color = color.withValues(alpha: 0.12));
        canvas.drawOval(Rect.fromLTWH(-w * 0.25, h * 0.45, w * 0.6, w * 0.6),
            Paint()..color = color.withValues(alpha: 0.08));
      case KitoWalletCardPattern.brushed:
        final paint = Paint()
          ..strokeWidth = 0.6
          ..color = color.withValues(alpha: 0.05);
        for (var x = -h; x < w; x += 3) {
          canvas.drawLine(Offset(x, h), Offset(x + h, 0), paint);
        }
      case KitoWalletCardPattern.dots:
        final paint = Paint()..color = color.withValues(alpha: 0.1);
        const step = 12.0;
        for (var y = step / 2; y < h; y += step) {
          for (var x = step / 2; x < w; x += step) {
            canvas.drawCircle(Offset(x, y), 1, paint);
          }
        }
      case KitoWalletCardPattern.gloss:
        final path = Path()
          ..moveTo(w * 0.35, 0)
          ..lineTo(w * 0.75, 0)
          ..lineTo(w * 0.35, h)
          ..lineTo(-w * 0.05, h)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader =
                ui.Gradient.linear(Offset(w * 0.5, 0), Offset(w * 0.3, h), [
              Colors.white.withValues(alpha: 0.28),
              Colors.white.withValues(alpha: 0),
            ]),
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.pattern != pattern || old.color != color || old.rtl != rtl;
}

class _ChipPainter extends CustomPainter {
  const _ChipPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(6 * unit));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2D480), Color(0xFFC79E4D)],
        ).createShader(rect),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.black.withValues(alpha: 0.18);
    final w = size.width;
    final h = size.height;
    canvas
      ..drawLine(Offset(w * 0.33, 0), Offset(w * 0.33, h), line)
      ..drawLine(Offset(w * 0.66, 0), Offset(w * 0.66, h), line)
      ..drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), line);
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.unit != unit;
}

/// Draws a [KitoWalletCardMark] at [height].
class KitoWalletCardMarkView extends StatelessWidget {
  /// Draws [mark].
  const KitoWalletCardMarkView({
    super.key,
    required this.mark,
    this.height = 22,
    this.foreground = Colors.white,
  });

  /// The mark.
  final KitoWalletCardMark mark;

  /// Its height.
  final double height;

  /// Text and icon colour.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    switch (mark) {
      case KitoWalletWordmark(:final text, :final italic):
        return Text(text,
            maxLines: 1,
            style: TextStyle(
                color: foreground,
                fontSize: height * 0.8,
                height: 1,
                fontWeight: FontWeight.w900,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                letterSpacing: height * 0.02));
      case KitoWalletIconMark(:final icon):
        return Icon(icon, size: height, color: foreground);
      case KitoWalletCirclesMark(:final first, :final second):
        return SizedBox(
          width: height * 1.6,
          height: height,
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                child: _Dot(size: height, color: first),
              ),
              PositionedDirectional(
                start: height * 0.6,
                child: _Dot(size: height, color: second),
              ),
            ],
          ),
        );
      case KitoWalletNoMark():
        return const SizedBox.shrink();
    }
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Tilts [child] toward the finger in 3D, with a moving highlight like light on foil, and
/// springs back on release. Holds still with Reduce Motion.
///
/// ```dart
/// KitoWalletCardTilt(child: KitoWalletCardView(card: card))
/// ```
class KitoWalletCardTilt extends StatefulWidget {
  /// Wraps [child].
  const KitoWalletCardTilt(
      {super.key, required this.child, this.maxAngle = 14, this.radius = 20});

  /// What tilts.
  final Widget child;

  /// The most it leans, in degrees.
  final double maxAngle;

  /// The highlight's corner radius, to match the card at 320 points.
  final double radius;

  @override
  State<KitoWalletCardTilt> createState() => _KitoWalletCardTiltState();
}

class _KitoWalletCardTiltState extends State<KitoWalletCardTilt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _release = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  Offset _tilt = Offset.zero;
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    _release.addListener(() {
      final t = const KitoSpringCurve(damping: 0.5).transform(_release.value);
      setState(() => _tilt = Offset.lerp(_from, Offset.zero, t)!);
    });
  }

  @override
  void dispose() {
    _release.dispose();
    super.dispose();
  }

  void _move(Offset local, Size size) {
    if (context.reduceMotion || size.isEmpty) return;
    _release.stop();
    var x = (local.dx / size.width - 0.5) * 2;
    final y = (local.dy / size.height - 0.5) * 2;
    if (context.isRtl) x = -x;
    setState(() => _tilt = Offset(x.clamp(-1, 1), y.clamp(-1, 1)));
  }

  void _end() {
    if (_tilt == Offset.zero) return;
    _from = _tilt;
    _release.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Listener(
        onPointerDown: (e) => _move(e.localPosition, context.size ?? Size.zero),
        onPointerMove: (e) => _move(e.localPosition, context.size ?? Size.zero),
        onPointerUp: (_) => _end(),
        onPointerCancel: (_) => _end(),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(_tilt.dy * widget.maxAngle * math.pi / 180)
            ..rotateY((context.isRtl ? 1 : -1) *
                -_tilt.dx *
                widget.maxAngle *
                math.pi /
                180),
          child: Stack(
            children: [
              widget.child,
              if (_tilt != Offset.zero)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(builder: (context, c) {
                      final u = c.maxWidth / KitoWalletCardGeometry.designWidth;
                      final dx = context.isRtl ? -_tilt.dx : _tilt.dx;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius * u),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(dx * 0.6 - 0.8, -1),
                              end: Alignment(dx * 0.6 + 0.8, 1),
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
