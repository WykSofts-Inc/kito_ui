// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'timeline.dart';

// MARK: - Style

/// How message bubbles look.
enum KitoChatBubbleStyle {
  /// Rounded bubbles with a soft tail; grouped messages tuck their inner corners.
  modern('Modern', 20, 6, KitoChatBubbleTail.soft),

  /// Flat and tailless: a tinted wash for you, an outline for them.
  minimal('Minimal', 14, 4, KitoChatBubbleTail.none),

  /// Frosted glass with a light-catching edge — best over a wallpaper.
  glass('Glass', 20, 8, KitoChatBubbleTail.soft),

  /// A glossy outgoing bubble with the classic curled tail.
  imessage('iMessage', 18, 18, KitoChatBubbleTail.curled);

  const KitoChatBubbleStyle(
      this.title, this.cornerRadius, this.groupedRadius, this.tail);

  /// "Modern", "Minimal", "Glass", "iMessage".
  final String title;

  /// The outer corner radius.
  final double cornerRadius;

  /// The radius of corners tucked against a neighbour in the same run.
  final double groupedRadius;

  /// The tail drawn on the last bubble of a run.
  final KitoChatBubbleTail tail;

  /// The text colour inside a bubble.
  Color foreground(
      {required bool isOutgoing,
      required Color onTint,
      required KitoTheme theme}) {
    if (!isOutgoing || this == minimal) return theme.colors.onSurface;
    return onTint;
  }

  /// Whether an outgoing bubble in this style is filled with the tint (so quotes and buttons
  /// inside it draw in the foreground colour).
  bool fillsOutgoing(bool isOutgoing) => isOutgoing && this != minimal;
}

/// The tail on the author's side of a bubble.
enum KitoChatBubbleTail {
  /// No tail.
  none,

  /// A small soft hook.
  soft,

  /// The classic curl.
  curled,
}

/// The accent a chat widget draws with and the colour that reads on it.
@immutable
class KitoChatAccent {
  /// [tint], or the theme's primary colour.
  factory KitoChatAccent.of(BuildContext context, Color? tint) {
    final kito = context.kito;
    return KitoChatAccent._(kito.accent(tint), kito.onAccent(tint));
  }

  const KitoChatAccent._(this.tint, this.onTint);

  /// The accent.
  final Color tint;

  /// Text and icons on [tint].
  final Color onTint;
}

// MARK: - Palette

/// Stable avatar gradients and name colours for users.
abstract final class KitoChatPalette {
  /// The gradients users are spread across.
  static const gradients = <List<Color>>[
    [Color(0xFFFF8C59), Color(0xFFED4578)],
    [Color(0xFF40C7BF), Color(0xFF2678DE)],
    [Color(0xFF9E73FF), Color(0xFF5945D9)],
    [Color(0xFF73D973), Color(0xFF219978)],
    [Color(0xFFFFC74D), Color(0xFFF57D29)],
    [Color(0xFFFA739E), Color(0xFFB047D9)],
    [Color(0xFF66B8FF), Color(0xFF3861ED)],
    [Color(0xFFCC9973), Color(0xFF8C5940)],
  ];

  /// [user]'s gradient: their own colour when set, otherwise a stable pick.
  static List<Color> colorsFor(KitoChatUser user) {
    final c = user.color;
    if (c != null) return [c.withValues(alpha: 0.75), c];
    return gradients[user.paletteIndex(gradients.length)];
  }

  /// The colour [user]'s name is written in, in group chats.
  static Color nameColorFor(KitoChatUser user) => colorsFor(user).last;
}

// MARK: - Shape

/// A bubble outline: per-corner radii for grouping plus an optional tail on the author's side.
/// Outgoing bubbles put their tail on the trailing edge, so it flips in right-to-left layouts.
class KitoChatBubbleShape extends ShapeBorder {
  /// Creates the outline for [style].
  const KitoChatBubbleShape({
    required this.style,
    required this.isOutgoing,
    this.position = KitoChatGroupPosition.single,
    this.showsTail = true,
  });

  /// The bubble style.
  final KitoChatBubbleStyle style;

  /// Whether it's your message (trailing side).
  final bool isOutgoing;

  /// Its place in a run.
  final KitoChatGroupPosition position;

  /// Draw the tail when the style has one and this closes a run.
  final bool showsTail;

  /// The tail actually drawn.
  KitoChatBubbleTail get tail =>
      showsTail && position.isGroupEnd ? style.tail : KitoChatBubbleTail.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final right = isOutgoing != (textDirection == TextDirection.rtl);
    final r =
        math.min(style.cornerRadius, math.min(rect.height / 2, rect.width / 2));
    final grouped = math.min(style.groupedRadius, r);
    final sideTop = position.isGroupStart ? r : grouped;
    final sideBottom = tail == KitoChatBubbleTail.none
        ? (position.isGroupEnd ? r : grouped)
        : math.min(4.0, r);
    final rr = right
        ? RRect.fromRectAndCorners(rect,
            topLeft: Radius.circular(r),
            bottomLeft: Radius.circular(r),
            topRight: Radius.circular(sideTop),
            bottomRight: Radius.circular(sideBottom))
        : RRect.fromRectAndCorners(rect,
            topRight: Radius.circular(r),
            bottomRight: Radius.circular(r),
            topLeft: Radius.circular(sideTop),
            bottomLeft: Radius.circular(sideBottom));
    final body = Path()..addRRect(rr);
    if (tail == KitoChatBubbleTail.none) return body;
    return Path.combine(PathOperation.union, body, _tailPath(rect, right));
  }

  Path _tailPath(Rect rect, bool right) {
    final edge = right ? rect.right : rect.left;
    final dir = right ? 1.0 : -1.0;
    Offset p(double outward, double up) =>
        Offset(edge + outward * dir, rect.bottom - up);
    final curled = tail == KitoChatBubbleTail.curled;
    final height = math.min(curled ? 22.0 : 19.0, rect.height * 0.7);
    final path = Path()
      ..moveTo(p(-18, height).dx, p(-18, height).dy)
      ..lineTo(p(0, height).dx, p(0, height).dy);
    if (curled) {
      final c1 = p(0, height * 0.4), c2 = p(2.5, 1), e1 = p(8, 0);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e1.dx, e1.dy);
      final c3 = p(-1, -1.2), c4 = p(-10, -0.4), e2 = p(-18, 0);
      path.cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, e2.dx, e2.dy);
    } else {
      final c1 = p(0, height * 0.35), c2 = p(3, 0.5), e1 = p(7, 0);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e1.dx, e1.dy);
      final q = p(-4, 0), e2 = p(-16, 0);
      path.quadraticBezierTo(q.dx, q.dy, e2.dx, e2.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;

  @override
  bool operator ==(Object other) =>
      other is KitoChatBubbleShape &&
      other.style == style &&
      other.isOutgoing == isOutgoing &&
      other.position == position &&
      other.showsTail == showsTail;

  @override
  int get hashCode => Object.hash(style, isOutgoing, position, showsTail);
}

// MARK: - Background

/// Fills a bubble for its style — solid, washed, frosted or glossy — behind [child].
class KitoChatBubbleBackground extends StatelessWidget {
  /// Creates a bubble background.
  const KitoChatBubbleBackground({
    super.key,
    required this.style,
    required this.isOutgoing,
    this.position = KitoChatGroupPosition.single,
    this.showsTail = true,
    this.tint,
    required this.child,
  });

  /// The bubble style.
  final KitoChatBubbleStyle style;

  /// Whether it's your message.
  final bool isOutgoing;

  /// Its place in a run.
  final KitoChatGroupPosition position;

  /// Draw the tail when the style has one.
  final bool showsTail;

  /// Overrides the primary colour.
  final Color? tint;

  /// The bubble's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = KitoChatAccent.of(context, tint);
    final shape = KitoChatBubbleShape(
        style: style,
        isOutgoing: isOutgoing,
        position: position,
        showsTail: showsTail);
    final dark = kito.brightness == Brightness.dark;
    final painter = _BubblePainter(
      shape: shape,
      textDirection: Directionality.of(context),
      fill: switch (style) {
        KitoChatBubbleStyle.modern =>
          isOutgoing ? accent.tint : kito.colors.surfaceMuted,
        KitoChatBubbleStyle.minimal => isOutgoing
            ? accent.tint.withValues(alpha: 0.14)
            : kito.colors.surface,
        KitoChatBubbleStyle.glass => isOutgoing
            ? accent.tint.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: dark ? 0.10 : 0.45),
        KitoChatBubbleStyle.imessage =>
          isOutgoing ? accent.tint : kito.colors.surfaceMuted,
      },
      gloss: style == KitoChatBubbleStyle.imessage && isOutgoing,
      stroke: switch (style) {
        KitoChatBubbleStyle.minimal when !isOutgoing => kito.colors.border,
        _ => null,
      },
      glassEdge: style == KitoChatBubbleStyle.glass,
      shadow: style == KitoChatBubbleStyle.glass,
    );
    Widget result = CustomPaint(painter: painter, child: child);
    if (style == KitoChatBubbleStyle.glass) {
      result = Stack(children: [
        Positioned.fill(
          child: ClipPath(
            clipper: ShapeBorderClipper(
                shape: shape, textDirection: Directionality.of(context)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        result,
      ]);
    }
    return result;
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.shape,
    required this.textDirection,
    required this.fill,
    required this.gloss,
    required this.stroke,
    required this.glassEdge,
    required this.shadow,
  });

  final KitoChatBubbleShape shape;
  final TextDirection textDirection;
  final Color fill;
  final bool gloss;
  final Color? stroke;
  final bool glassEdge;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect, textDirection: textDirection);
    if (shadow) {
      canvas.drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPath(path, Paint()..color = fill);
    if (gloss) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.30),
              Colors.white.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0.10),
            ],
          ).createShader(rect),
      );
    }
    if (stroke != null) {
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = stroke!);
    }
    if (glassEdge) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0.05),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.textDirection != textDirection ||
      old.gloss != gloss ||
      old.glassEdge != glassEdge;

  @override
  bool hitTest(Offset position) => true;
}

// MARK: - Wallpaper

/// What sits behind a conversation.
enum KitoChatWallpaper {
  /// The theme background.
  plain,

  /// Soft drifting colour blobs from the tint — made for glass bubbles.
  aurora,

  /// A faint dot grid.
  dots,
}

/// Paints a [KitoChatWallpaper]. The aurora drifts slowly unless Reduce Motion is on.
class KitoChatWallpaperView extends StatefulWidget {
  /// Creates a wallpaper.
  const KitoChatWallpaperView(
      {super.key, this.wallpaper = KitoChatWallpaper.plain, this.tint});

  /// Which wallpaper.
  final KitoChatWallpaper wallpaper;

  /// Overrides the primary colour the aurora is made from.
  final Color? tint;

  @override
  State<KitoChatWallpaperView> createState() => _KitoChatWallpaperViewState();
}

class _KitoChatWallpaperViewState extends State<KitoChatWallpaperView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KitoChatWallpaperView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.wallpaper == KitoChatWallpaper.aurora && !context.reduceMotion;
    if (animate && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    } else if (!animate && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final tint = kito.accent(widget.tint);
    final Widget layer = switch (widget.wallpaper) {
      KitoChatWallpaper.plain => const SizedBox.expand(),
      KitoChatWallpaper.dots => CustomPaint(
          painter:
              _DotsPainter(kito.colors.onBackground.withValues(alpha: 0.10)),
          child: const SizedBox.expand(),
        ),
      KitoChatWallpaper.aurora => ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: AnimatedBuilder(
            animation: _drift,
            builder: (context, _) => CustomPaint(
              painter: _AuroraPainter(
                t: Curves.easeInOut.transform(_drift.value),
                colors: [
                  tint.withValues(alpha: 0.55),
                  const Color(0xFFFF8C66).withValues(alpha: 0.40),
                  const Color(0xFF8C66FF).withValues(alpha: 0.40),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
    };
    return ExcludeSemantics(
      child: ColoredBox(
        color: kito.colors.background,
        child: ClipRect(child: layer),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 18.0;
    final paint = Paint()..color = color;
    var row = 0;
    for (var y = step / 2; y < size.height; y += step, row++) {
      for (var x = row.isEven ? step / 2 : step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.colors});
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double lerp(double a, double b) => a + (b - a) * t;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c + Offset(lerp(-0.05, -0.25) * w, -0.28 * h), w * 0.45,
        Paint()..color = colors[0]);
    canvas.drawCircle(c + Offset(lerp(0.15, 0.3) * w, lerp(0.15, 0.05) * h),
        w * 0.4, Paint()..color = colors[1]);
    canvas.drawCircle(c + Offset(lerp(-0.3, -0.1) * w, 0.38 * h), w * 0.5,
        Paint()..color = colors[2]);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.t != t || old.colors[0] != colors[0];
}
