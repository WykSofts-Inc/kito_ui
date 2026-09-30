// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'carousel.dart';
import 'logic.dart';

/// How a [KitoCarouselPageIndicator] draws pages.
enum KitoCarouselIndicatorStyle {
  /// A row of dots; the current one grows and takes the colour.
  dots,

  /// The current dot stretches into a capsule.
  capsule,

  /// A liquid blob that stretches across to the next page and snaps back.
  worm,

  /// "3 / 8" with previous and next chevrons.
  numbers,

  /// The current page is a capsule that fills with auto-play progress.
  progress,
}

/// Page dots for a [KitoCarousel] (or anything paged).
///
/// Give it a [controller] and it follows the carousel's fractional position as you swipe, so
/// the worm stretches with your finger; or give it [current] and [onChanged]. Tap a dot to
/// jump, or drag along the row to scrub. Screen readers hear "Page 3 of 8" and can swipe up
/// and down. It mirrors in right-to-left layouts.
///
/// ```dart
/// KitoCarouselPageIndicator(
///   count: lodges.length,
///   controller: carousel,
///   style: KitoCarouselIndicatorStyle.worm,
/// )
/// ```
class KitoCarouselPageIndicator extends StatelessWidget {
  /// Creates an indicator.
  const KitoCarouselPageIndicator({
    super.key,
    required this.count,
    this.controller,
    this.current = 0,
    this.onChanged,
    this.style = KitoCarouselIndicatorStyle.capsule,
    this.progress,
    this.dotSize = 8,
    this.activeColor,
    this.inactiveColor,
    this.interactive = true,
  });

  /// How many pages.
  final int count;

  /// Follows this carousel, and moves it when tapped.
  final KitoCarouselController? controller;

  /// The current page, when there's no [controller].
  final int current;

  /// Called with a tapped or scrubbed page; with a [controller] the carousel moves anyway.
  final ValueChanged<int>? onChanged;

  /// How pages are drawn.
  final KitoCarouselIndicatorStyle style;

  /// The current page's fill for [KitoCarouselIndicatorStyle.progress], 0–1; with a
  /// [controller] it follows auto-play when left null.
  final double? progress;

  /// One dot's diameter.
  final double dotSize;

  /// The current page's colour; the theme's `onBackground` when null.
  final Color? activeColor;

  /// The other pages' colour.
  final Color? inactiveColor;

  /// Lets taps and drags change page.
  final bool interactive;

  int _clamp(int i) => count == 0 ? 0 : i.clamp(0, count - 1);

  void _select(int index) {
    final i = _clamp(index);
    HapticFeedback.selectionClick();
    controller?.animateToPage(i);
    onChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      final theme = context.kito;
      return TweenAnimationBuilder<double>(
        tween: Tween(end: _clamp(current).toDouble()),
        duration: KitoMotion.of(context, const Duration(milliseconds: 420)),
        curve: style == KitoCarouselIndicatorStyle.worm
            ? Curves.easeInOutCubic
            : theme.motion.spring,
        builder: (context, position, _) =>
            _build(context, position, _clamp(current), progress ?? 0),
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge([c, c.autoPlayProgress]),
      builder: (context, _) {
        var position = c.position;
        if (position > count - 1) {
          // Wrapping from the last page to the first.
          position = position - (count - 1) < 0.5 ? count - 1.0 : 0;
        }
        return _build(context, position, _clamp(c.page),
            progress ?? c.autoPlayProgress.value);
      },
    );
  }

  Widget _build(BuildContext context, double position, int page, double fill) {
    final theme = context.kito;
    final active = activeColor ?? theme.colors.onBackground;
    final idle =
        inactiveColor ?? theme.colors.onBackground.withValues(alpha: 0.22);
    final rtl = context.isRtl;

    final Widget body;
    if (style == KitoCarouselIndicatorStyle.numbers) {
      body = _Numbers(
        page: page,
        count: count,
        active: active,
        onStep: interactive ? (d) => _select(page + d) : null,
      );
    } else {
      final spacing = dotSize;
      final extra = switch (style) {
        KitoCarouselIndicatorStyle.capsule => dotSize * 2.2,
        KitoCarouselIndicatorStyle.progress => dotSize * 3.5,
        _ => 0.0,
      };
      final width = count * dotSize + math.max(count - 1, 0) * spacing + extra;
      int indexAt(double x) {
        final fx = rtl ? width - x : x;
        return (fx / math.max(width, 1) * count).floor();
      }

      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp:
            interactive ? (d) => _select(indexAt(d.localPosition.dx)) : null,
        onHorizontalDragUpdate: interactive
            ? (d) {
                final i = _clamp(indexAt(d.localPosition.dx));
                if (i != page) _select(i);
              }
            : null,
        child: SizedBox(
          width: width,
          height: math.max(44, dotSize * 2),
          child: CustomPaint(
            painter: _IndicatorPainter(
              style: style,
              count: count,
              position: position.clamp(0.0, math.max(count - 1.0, 0)),
              dotSize: dotSize,
              spacing: spacing,
              extra: extra,
              active: active,
              idle: idle,
              fill: fill.clamp(0.0, 1.0),
              rtl: rtl,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Page',
      value: count == 0 ? null : '${page + 1} of $count',
      increasedValue: count == 0 ? null : '${_clamp(page + 1) + 1} of $count',
      decreasedValue: count == 0 ? null : '${_clamp(page - 1) + 1} of $count',
      onIncrease:
          interactive && page < count - 1 ? () => _select(page + 1) : null,
      onDecrease: interactive && page > 0 ? () => _select(page - 1) : null,
      excludeSemantics: true,
      child: body,
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers(
      {required this.page,
      required this.count,
      required this.active,
      required this.onStep});

  final int page;
  final int count;
  final Color active;
  final ValueChanged<int>? onStep;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final muted = theme.colors.onBackground;
    Widget chevron(IconData icon, int delta, bool enabled) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && onStep != null ? () => onStep!(delta) : null,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon,
                size: 18, color: muted.withValues(alpha: enabled ? 0.8 : 0.25)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(theme.radii.pill),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        chevron(Icons.chevron_left_rounded, -1, page > 0),
        AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.medium),
          transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(a),
                  child: child)),
          child: Text('${page + 1}',
              key: ValueKey(page),
              style: theme.typography.label.copyWith(
                  color: active,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        Text(' / $count',
            style: theme.typography.label.copyWith(
                color: muted.withValues(alpha: 0.55),
                fontFeatures: const [FontFeature.tabularFigures()])),
        chevron(Icons.chevron_right_rounded, 1, page < count - 1),
      ]),
    );
  }
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    required this.style,
    required this.count,
    required this.position,
    required this.dotSize,
    required this.spacing,
    required this.extra,
    required this.active,
    required this.idle,
    required this.fill,
    required this.rtl,
  });

  final KitoCarouselIndicatorStyle style;
  final int count;
  final double position;
  final double dotSize;
  final double spacing;
  final double extra;
  final Color active;
  final Color idle;
  final double fill;
  final bool rtl;

  Rect _mirror(Rect r, Size size) =>
      rtl ? Rect.fromLTWH(size.width - r.right, r.top, r.width, r.height) : r;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final cy = size.height / 2;
    final radius = Radius.circular(dotSize / 2);
    final idlePaint = Paint()..color = idle;
    switch (style) {
      case KitoCarouselIndicatorStyle.dots:
        for (var i = 0; i < count; i++) {
          final x = i * (dotSize + spacing) + dotSize / 2;
          final c = _mirror(
                  Rect.fromCircle(center: Offset(x, cy), radius: dotSize / 2),
                  size)
              .center;
          canvas.drawCircle(c, dotSize / 2, idlePaint);
        }
        final x = position * (dotSize + spacing) + dotSize / 2;
        final c = _mirror(
                Rect.fromCircle(center: Offset(x, cy), radius: dotSize / 2),
                size)
            .center;
        canvas
          ..drawCircle(
              c,
              dotSize * 0.9,
              Paint()
                ..color = active.withValues(alpha: 0.3)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3))
          ..drawCircle(c, dotSize * 0.7, Paint()..color = active);
      case KitoCarouselIndicatorStyle.capsule:
      case KitoCarouselIndicatorStyle.progress:
        var x = 0.0;
        for (var i = 0; i < count; i++) {
          final near = math.max(0.0, 1 - (i - position).abs());
          final w = dotSize + extra * near;
          final rect =
              _mirror(Rect.fromLTWH(x, cy - dotSize / 2, w, dotSize), size);
          final rr = RRect.fromRectAndRadius(rect, radius);
          if (style == KitoCarouselIndicatorStyle.capsule) {
            canvas.drawRRect(
                rr, Paint()..color = Color.lerp(idle, active, near)!);
          } else {
            canvas.drawRRect(rr, idlePaint);
            if (near > 0.5) {
              final fw = math.max(dotSize, w * fill);
              final filled = rtl
                  ? Rect.fromLTRB(
                      rect.right - fw, rect.top, rect.right, rect.bottom)
                  : Rect.fromLTWH(rect.left, rect.top, fw, rect.height);
              canvas.save();
              canvas.clipRRect(rr);
              canvas.drawRRect(RRect.fromRectAndRadius(filled, radius),
                  Paint()..color = active.withValues(alpha: (near - 0.5) * 2));
              canvas.restore();
            }
          }
          x += w + spacing;
        }
      case KitoCarouselIndicatorStyle.worm:
        for (var i = 0; i < count; i++) {
          final rect = _mirror(
              Rect.fromLTWH(
                  i * (dotSize + spacing), cy - dotSize / 2, dotSize, dotSize),
              size);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), idlePaint);
        }
        final (start, width) = KitoCarouselWormMath.frame(position,
            dotSize: dotSize, spacing: spacing);
        final span = KitoCarouselWormMath.span(position);
        final squash = math.min(span.length, 1.0) * dotSize * 0.18;
        final rect = _mirror(
            Rect.fromLTWH(
                start, cy - dotSize / 2 + squash / 2, width, dotSize - squash),
            size);
        canvas
          ..drawRRect(
              RRect.fromRectAndRadius(
                  rect.inflate(1.5), Radius.circular(rect.height / 2 + 1.5)),
              Paint()
                ..color = active.withValues(alpha: 0.25)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3))
          ..drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
              Paint()..color = active);
      case KitoCarouselIndicatorStyle.numbers:
        break;
    }
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) =>
      old.position != position ||
      old.count != count ||
      old.fill != fill ||
      old.active != active ||
      old.idle != idle ||
      old.style != style ||
      old.rtl != rtl ||
      old.dotSize != dotSize;
}
