// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'carousel.dart';
import 'page_indicator.dart';

/// Full-width, auto-advancing banners with rounded corners and a progress indicator on top:
/// deals, announcements, featured stays.
///
/// It loops, pauses while touched, and the current dot fills as the next banner comes up.
///
/// ```dart
/// KitoBannerCarousel(
///   itemCount: deals.length,
///   itemBuilder: (context, i) => DealBanner(deals[i]),
///   interval: const Duration(seconds: 5),
/// )
/// ```
class KitoBannerCarousel extends StatefulWidget {
  /// Creates a banner carousel.
  const KitoBannerCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.interval = const Duration(seconds: 5),
    this.height = 180,
    this.radius,
    this.indicatorStyle = KitoCarouselIndicatorStyle.progress,
    this.effect = KitoCarouselEffect.parallax,
    this.onPageChanged,
    this.semanticLabel = 'Banners',
  });

  /// How many banners.
  final int itemCount;

  /// Builds banner `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// How long each banner stays.
  final Duration interval;

  /// The banners' height.
  final double height;

  /// Corner radius; the theme's extra-large radius when null.
  final double? radius;

  /// The dots drawn over the bottom edge.
  final KitoCarouselIndicatorStyle indicatorStyle;

  /// How banners move; parallax by default.
  final KitoCarouselEffect effect;

  /// Called with the new banner.
  final ValueChanged<int>? onPageChanged;

  /// What screen readers call it.
  final String semanticLabel;

  @override
  State<KitoBannerCarousel> createState() => _KitoBannerCarouselState();
}

class _KitoBannerCarouselState extends State<KitoBannerCarousel> {
  final _controller = KitoCarouselController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final radius = BorderRadius.circular(widget.radius ?? theme.radii.xl);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          KitoCarousel(
            itemCount: widget.itemCount,
            controller: _controller,
            itemBuilder: widget.itemBuilder,
            peek: 0,
            spacing: 0,
            height: widget.height,
            loops: true,
            autoPlay: widget.interval,
            effect: widget.effect,
            onPageChanged: widget.onPageChanged,
            semanticLabel: widget.semanticLabel,
          ),
          if (widget.itemCount > 1) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 56,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            KitoCarouselPageIndicator(
              count: widget.itemCount,
              controller: _controller,
              style: widget.indicatorStyle,
              dotSize: 6,
              activeColor: Colors.white,
              inactiveColor: Colors.white.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );
  }
}
