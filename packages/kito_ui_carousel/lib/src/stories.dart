// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// An avatar in a story ring: a bright gradient for new stories, a thin grey ring once seen, a
/// pulsing ring and LIVE badge when live, and a spinning ring while the story loads.
///
/// ```dart
/// KitoStoryRing(
///   isSeen: friend.seen,
///   isLive: friend.live,
///   child: Image.network(friend.photo, fit: BoxFit.cover),
/// )
/// ```
class KitoStoryRing extends StatefulWidget {
  /// Creates a ring around [child].
  const KitoStoryRing({
    super.key,
    required this.child,
    this.isSeen = false,
    this.isLive = false,
    this.isLoading = false,
    this.size = 68,
    this.lineWidth = 3,
    this.colors,
    this.tint,
    this.liveLabel = 'LIVE',
  });

  /// The picture, clipped to a circle.
  final Widget child;

  /// Everything has been watched; the ring turns grey.
  final bool isSeen;

  /// Broadcasting now: a pulsing ring and a badge.
  final bool isLive;

  /// Spins the ring, e.g. while the first story loads.
  final bool isLoading;

  /// The outer diameter.
  final double size;

  /// The ring's thickness.
  final double lineWidth;

  /// The ring gradient; a sunset gradient by default.
  final List<Color>? colors;

  /// When set, a gradient built from this colour.
  final Color? tint;

  /// The badge text.
  final String liveLabel;

  /// The default sunset ring.
  static const sunset = [
    Color(0xFFFFCC33),
    Color(0xFFFA7333),
    Color(0xFFE62E7A),
    Color(0xFF8C38D9),
  ];

  /// The live ring and badge.
  static const live = [Color(0xFFFA3873), Color(0xFFED1A40)];

  @override
  State<KitoStoryRing> createState() => _KitoStoryRingState();
}

class _KitoStoryRingState extends State<KitoStoryRing>
    with TickerProviderStateMixin {
  AnimationController? _spin;
  AnimationController? _pulse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KitoStoryRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = context.reduceMotion;
    if (widget.isLoading && !reduce) {
      _spin ??=
          AnimationController(vsync: this, duration: const Duration(seconds: 1))
            ..repeat();
    } else {
      _spin?.dispose();
      _spin = null;
    }
    if (widget.isLive && !reduce) {
      _pulse ??= AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    _pulse?.dispose();
    super.dispose();
  }

  List<Color> _ringColors(KitoTheme kito) {
    final c = widget.colors;
    if (c != null && c.isNotEmpty) return c;
    final t = widget.tint;
    if (t != null) {
      return [
        t,
        t.withValues(alpha: 0.55),
        kito.colors.secondary.withValues(alpha: 0.7),
        t
      ];
    }
    return KitoStoryRing.sunset;
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final size = widget.size;
    final gap = math.max(widget.lineWidth, 2.5);
    final inner = size - (widget.lineWidth + gap) * 2;
    final seen = widget.isSeen && !widget.isLive;
    final colors = widget.isLive ? KitoStoryRing.live : _ringColors(kito);

    final Widget ring = CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(
        colors: colors,
        seen: seen,
        loading: widget.isLoading,
        lineWidth: widget.lineWidth,
        seenColor: kito.colors.border,
        spin: _spin,
      ),
    );

    Widget avatar = ClipOval(
      child: SizedBox.square(dimension: inner, child: widget.child),
    );
    if (seen) {
      avatar = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.9, 0.1, 0.0, 0, 0, //
          0.05, 0.9, 0.05, 0, 0, //
          0.05, 0.1, 0.85, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: avatar,
      );
    }

    return Semantics(
      value: widget.isLive ? 'Live' : (seen ? 'Seen' : 'New story'),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_pulse case final pulse?)
              AnimatedBuilder(
                animation: pulse,
                builder: (context, _) {
                  final t = Curves.easeOut.transform(pulse.value);
                  return Opacity(
                    opacity: 0.8 * (1 - t),
                    child: Transform.scale(
                      scale: 1 + 0.16 * t,
                      child: CustomPaint(
                        size: Size.square(size),
                        painter: _RingPainter(
                            colors: KitoStoryRing.live,
                            seen: false,
                            loading: false,
                            lineWidth: 2,
                            seenColor: Colors.transparent),
                      ),
                    ),
                  );
                },
              ),
            AnimatedSwitcher(
              duration:
                  KitoMotion.of(context, const Duration(milliseconds: 350)),
              child: KeyedSubtree(
                  key: ValueKey((seen, widget.isLoading, widget.isLive)),
                  child: ring),
            ),
            avatar,
            if (widget.isLive)
              Positioned(
                bottom: -5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: KitoStoryRing.live),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kito.colors.background, width: 2),
                  ),
                  child: Text(
                    widget.liveLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: math.max(size * 0.14, 8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.colors,
    required this.seen,
    required this.loading,
    required this.lineWidth,
    required this.seenColor,
    this.spin,
  }) : super(repaint: spin);

  final List<Color> colors;
  final bool seen;
  final bool loading;
  final double lineWidth;
  final Color seenColor;
  final Animation<double>? spin;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (seen && !loading) {
      final w = math.max(lineWidth * 0.55, 1.2);
      canvas.drawCircle(
          center,
          size.width / 2 - w / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..color = seenColor);
      return;
    }
    final rect = Offset.zero & size;
    final r = size.width / 2 - lineWidth / 2;
    final sweep = [...colors, colors.first];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: sweep,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    if (!loading) {
      canvas.drawCircle(center, r, paint);
      return;
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((spin?.value ?? 0) * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);
    // Dashes round 82% of the circle.
    final circumference = 2 * math.pi * r;
    final dash = lineWidth * 1.4, space = lineWidth * 1.6;
    final end = 0.82 * circumference;
    for (var d = 0.0; d < end; d += dash + space) {
      final a = d / r - math.pi / 2;
      final b = math.min(d + dash, end) / r - math.pi / 2;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: r), a, b - a, false, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.seen != seen ||
      old.loading != loading ||
      old.lineWidth != lineWidth ||
      old.seenColor != seenColor ||
      old.spin != spin ||
      !_same(old.colors, colors);

  static bool _same(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The "Your story" tile at the start of a [KitoStoryTray].
@immutable
class KitoYourStory {
  /// Creates the tile.
  const KitoYourStory({
    required this.onTap,
    this.title = 'Your story',
    this.image,
    this.initials = '',
    this.hasStory = false,
  });

  /// The caption under the tile.
  final String title;

  /// Your picture; [initials] on a gradient when null.
  final ImageProvider? image;

  /// Shown when there's no image.
  final String initials;

  /// Whether you've posted something; shows a ring instead of the + badge.
  final bool hasStory;

  /// Called when the tile is tapped.
  final VoidCallback onTap;
}

/// A horizontal row of story rings, with an optional "Your story +" tile first. Tapping a ring
/// spins it briefly, then calls [onSelect].
///
/// ```dart
/// KitoStoryTray(
///   itemCount: friends.length,
///   titleBuilder: (i) => friends[i].name,
///   isSeen: (i) => friends[i].seen,
///   avatarBuilder: (context, i) => Avatar(friends[i]),
///   yourStory: KitoYourStory(initials: 'WN', onTap: compose),
///   onSelect: open,
/// )
/// ```
class KitoStoryTray extends StatefulWidget {
  /// Creates a tray.
  const KitoStoryTray({
    super.key,
    required this.itemCount,
    required this.titleBuilder,
    required this.avatarBuilder,
    required this.onSelect,
    this.isSeen,
    this.isLive,
    this.yourStory,
    this.ringSize = 68,
    this.tint,
    this.padding,
  });

  /// How many people have stories.
  final int itemCount;

  /// The caption under ring `index`.
  final String Function(int index) titleBuilder;

  /// The picture inside ring `index`.
  final IndexedWidgetBuilder avatarBuilder;

  /// Called with the index of the ring tapped.
  final ValueChanged<int> onSelect;

  /// Whether everything person `index` posted has been watched.
  final bool Function(int index)? isSeen;

  /// Whether person `index` is live now.
  final bool Function(int index)? isLive;

  /// The first tile, for posting your own.
  final KitoYourStory? yourStory;

  /// Each ring's diameter.
  final double ringSize;

  /// The ring gradient colour; a sunset gradient by default.
  final Color? tint;

  /// Padding around the row; the theme's large spacing at the sides when null.
  final EdgeInsetsGeometry? padding;

  @override
  State<KitoStoryTray> createState() => _KitoStoryTrayState();
}

class _KitoStoryTrayState extends State<KitoStoryTray> {
  int? _loading;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _select(int i) {
    HapticFeedback.selectionClick();
    if (context.reduceMotion) {
      widget.onSelect(i);
      return;
    }
    _timer?.cancel();
    setState(() => _loading = i);
    _timer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _loading = null);
      widget.onSelect(i);
    });
  }

  Widget _tile(BuildContext context,
      {required String title,
      required String? hint,
      required VoidCallback onTap,
      required Widget ring}) {
    final kito = context.kito;
    return Semantics(
      container: true,
      button: true,
      label: title,
      hint: hint,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KitoPressable(
          scale: 0.9,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ring,
            SizedBox(height: kito.spacing.xs + 2),
            SizedBox(
              width: widget.ringSize + 8,
              child: ExcludeSemantics(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: kito.typography.caption
                      .copyWith(color: kito.colors.onBackground),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _yours(BuildContext context, KitoYourStory story) {
    final kito = context.kito;
    final size = widget.ringSize;
    final picture = story.image != null
        ? Image(image: story.image!, fit: BoxFit.cover)
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kito.colors.surfaceMuted, kito.colors.border],
              ),
            ),
            child: Center(
              child: Text(
                story.initials,
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w600,
                  color: kito.colors.onSurface,
                ),
              ),
            ),
          );
    return _tile(
      context,
      title: story.title,
      hint: story.hasStory ? 'Opens your story' : 'Adds to your story',
      onTap: () {
        HapticFeedback.selectionClick();
        story.onTap();
      },
      ring: SizedBox.square(
        dimension: size,
        child: Stack(clipBehavior: Clip.none, children: [
          KitoStoryRing(
              isSeen: !story.hasStory,
              size: size,
              tint: widget.tint,
              child: picture),
          if (!story.hasStory)
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kito.accent(widget.tint),
                  border: Border.all(color: kito.colors.background, width: 2.5),
                ),
                child: Icon(Icons.add_rounded,
                    size: size * 0.2, color: kito.onAccent(widget.tint)),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final yours = widget.yourStory;
    final offset = yours == null ? 0 : 1;
    return SizedBox(
      height: widget.ringSize + 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: widget.padding ??
            EdgeInsetsDirectional.symmetric(
                horizontal: kito.spacing.lg, vertical: kito.spacing.xs),
        itemCount: widget.itemCount + offset,
        separatorBuilder: (_, __) => SizedBox(width: kito.spacing.lg),
        itemBuilder: (context, j) {
          if (yours != null && j == 0) return _yours(context, yours);
          final i = j - offset;
          return _tile(
            context,
            title: widget.titleBuilder(i),
            hint: null,
            onTap: () => _select(i),
            ring: KitoStoryRing(
              isSeen: widget.isSeen?.call(i) ?? false,
              isLive: widget.isLive?.call(i) ?? false,
              isLoading: _loading == i,
              size: widget.ringSize,
              tint: widget.tint,
              child: widget.avatarBuilder(context, i),
            ),
          );
        },
      ),
    );
  }
}
