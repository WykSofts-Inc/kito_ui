// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A scroll view with a stretchy hero header. Pull down and the header grows to fill the gap;
/// scroll up and it drifts at half speed and softens, the large title fades, and a compact title
/// bar settles in at the top.
///
/// ```dart
/// KitoParallaxHeader(
///   title: 'Zanzibar',
///   subtitle: 'Stone Town · Nungwi · Paje',
///   header: Image.asset('assets/beach.jpg', fit: BoxFit.cover),
///   child: GuideSections(),
/// )
/// ```
///
/// Pass [pinnedHeader] for a strip (category tabs, a filter row) that sits under the hero and,
/// once the hero has collapsed, sticks just below the compact title bar while the content
/// scrolls underneath it. Use [slivers] instead of [child] for long, lazily built content.
class KitoParallaxHeader extends StatefulWidget {
  /// Creates a parallax header.
  const KitoParallaxHeader({
    super.key,
    required this.title,
    required this.header,
    this.subtitle,
    this.child,
    this.slivers = const [],
    this.pinnedHeader,
    this.height = 320,
    this.tint,
    this.controller,
    this.leading,
  });

  /// Shown large over the header, then small in the title bar.
  final String title;

  /// A line under the large title.
  final String? subtitle;

  /// The hero, usually an image; it fills the header.
  final Widget header;

  /// Everything below, as one box.
  final Widget? child;

  /// Everything below, as slivers, after [child].
  final List<Widget> slivers;

  /// Sits under the hero and sticks below the title bar once the hero has collapsed. It gets
  /// the theme background so content scrolls out of sight beneath it.
  final Widget? pinnedHeader;

  /// The header's height at rest, status bar included.
  final double height;

  /// The compact title's colour.
  final Color? tint;

  /// The scroll controller.
  final ScrollController? controller;

  /// A button at the start of the title bar, such as a back button; always visible.
  final Widget? leading;

  @override
  State<KitoParallaxHeader> createState() => _KitoParallaxHeaderState();
}

class _KitoParallaxHeaderState extends State<KitoParallaxHeader> {
  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final top = MediaQuery.paddingOf(context).top;
    final bar = top + 44;
    return ColoredBox(
      color: kito.colors.background,
      child: CustomScrollView(
        controller: widget.controller,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeroDelegate(
              title: widget.title,
              subtitle: widget.subtitle,
              header: widget.header,
              maxHeight: math.max(widget.height, bar + 1),
              minHeight: bar,
              topInset: top,
              tint: widget.tint,
              leading: widget.leading,
              theme: kito,
              reduceMotion: context.reduceMotion,
            ),
          ),
          if (widget.pinnedHeader case final pinned?)
            PinnedHeaderSliver(
              child: ColoredBox(color: kito.colors.background, child: pinned),
            ),
          if (widget.child case final child?)
            SliverToBoxAdapter(
              child: ColoredBox(color: kito.colors.background, child: child),
            ),
          ...widget.slivers,
        ],
      ),
    );
  }
}

class _HeroDelegate extends SliverPersistentHeaderDelegate {
  _HeroDelegate({
    required this.title,
    required this.subtitle,
    required this.header,
    required this.maxHeight,
    required this.minHeight,
    required this.topInset,
    required this.tint,
    required this.leading,
    required this.theme,
    required this.reduceMotion,
  });

  final String title;
  final String? subtitle;
  final Widget header;
  final double maxHeight;
  final double minHeight;
  final double topInset;
  final Color? tint;
  final Widget? leading;
  final KitoTheme theme;
  final bool reduceMotion;

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration(stretchTriggerOffset: 1e9);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final kito = theme;
    return LayoutBuilder(builder: (context, constraints) {
      final extent = constraints.maxHeight;
      final stretch = math.max(extent - maxHeight, 0.0);
      final collapse = math.min(shrinkOffset, maxHeight - minHeight);
      final distance = math.max(maxHeight - minHeight, 1.0);
      final progress = (collapse / distance).clamp(0.0, 1.0);
      final reveal = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

      Widget hero = SizedBox(
        height: maxHeight + stretch,
        width: constraints.maxWidth,
        child: header,
      );
      if (!reduceMotion && progress > 0.01) {
        hero = ImageFiltered(
          imageFilter:
              ui.ImageFilter.blur(sigmaX: progress * 10, sigmaY: progress * 10),
          child: hero,
        );
      }

      return ClipRect(
        child: Stack(children: [
          // The hero drifts at half speed as it collapses and grows when pulled.
          Positioned(
            left: 0,
            right: 0,
            top: reduceMotion ? -collapse : -collapse * 0.5,
            height: maxHeight + stretch,
            child: hero,
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x8C000000)],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: kito.spacing.xl,
            end: kito.spacing.xl,
            bottom: kito.spacing.xl - (reduceMotion ? 0 : collapse * 0.15),
            child: Opacity(
              opacity: (1 - progress * 1.6).clamp(0.0, 1.0),
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Color(0x4D000000),
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: kito.spacing.xs),
                      Text(
                        subtitle!,
                        style: kito.typography.bodyEmphasized.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          shadows: const [
                            Shadow(color: Color(0x4D000000), blurRadius: 8)
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // The compact title bar.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: minHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: reveal,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kito.colors.background.withValues(alpha: 0.92),
                    border: Border(
                        bottom:
                            BorderSide(color: kito.colors.border, width: 0.5)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, (1 - reveal) * 10),
                        child: ExcludeSemantics(
                          excluding: reveal < 0.5,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kito.typography.bodyEmphasized.copyWith(
                                color: tint ?? kito.colors.onBackground),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (leading != null)
            PositionedDirectional(
              start: kito.spacing.xs,
              top: topInset,
              height: 44,
              child: Center(child: leading),
            ),
        ]),
      );
    });
  }

  @override
  bool shouldRebuild(_HeroDelegate old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.header != header ||
      old.maxHeight != maxHeight ||
      old.minHeight != minHeight ||
      old.topInset != topInset ||
      old.tint != tint ||
      old.leading != leading ||
      old.theme != theme ||
      old.reduceMotion != reduceMotion;
}
