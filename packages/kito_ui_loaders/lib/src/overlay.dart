// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'loader_strings.dart';
import 'loader_view.dart';
import 'progress.dart';

/// A frosted card with a loader, a message and an optional detail or progress — what
/// [KitoLoaderOverlay] floats over the blurred screen. Usable on its own too.
class KitoLoaderCard extends StatelessWidget {
  /// Creates a loading card.
  const KitoLoaderCard({
    super.key,
    this.message,
    this.detail,
    this.progress,
    this.loader = const KitoLoaderStyle(
        kind: KitoLoaderKind.gradientRing, size: 44, strokeWidth: 4),
    this.color,
  });

  /// The headline ("Saving…").
  final String? message;

  /// A quieter second line.
  final String? detail;

  /// 0–1 to show a determinate ring instead of [loader].
  final double? progress;

  /// The indeterminate loader.
  final KitoLoaderStyle loader;

  /// The loader colour; the theme's primary when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final dark = kito.brightness == Brightness.dark;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message ?? KitoLoaderStrings.of(context, 'loading'),
      value: progress == null
          ? null
          : KitoLoaderStrings.percent(context, progress!),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 14)),
              ],
            ),
            child: KitoSurface(
              radius: 28,
              background: KitoBackground.glass(opacity: dark ? 0.12 : 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 56, minHeight: 56),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: progress != null
                          ? KitoLoaderProgressRing(
                              value: progress!,
                              size: 56,
                              strokeWidth: 5,
                              color: color)
                          : KitoLoaderView(style: loader, color: color),
                    ),
                  ),
                  if (message != null) ...[
                    SizedBox(height: kito.spacing.md),
                    Text(message!,
                        textAlign: TextAlign.center,
                        style: kito.typography.bodyEmphasized
                            .copyWith(color: kito.colors.onSurface)),
                  ],
                  if (detail != null) ...[
                    SizedBox(height: kito.spacing.xs),
                    Text(detail!,
                        textAlign: TextAlign.center,
                        style: kito.typography.caption.copyWith(
                            color:
                                kito.colors.onSurface.withValues(alpha: 0.6))),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blurs and dims [child] and floats a [KitoLoaderCard] over it while [isPresented], blocking
/// taps and hiding it from screen readers — for a save, a payment or a sign-in the user must
/// wait on.
///
/// ```dart
/// KitoLoaderOverlay(
///   isPresented: saving,
///   message: 'Saving',
///   progress: uploadFraction,   // optional: a determinate ring
///   child: form,
/// )
/// ```
class KitoLoaderOverlay extends StatelessWidget {
  /// Creates an overlay.
  const KitoLoaderOverlay({
    super.key,
    required this.isPresented,
    required this.child,
    this.message,
    this.detail,
    this.progress,
    this.loader = const KitoLoaderStyle(
        kind: KitoLoaderKind.gradientRing, size: 44, strokeWidth: 4),
    this.blur = 8,
    this.dimming = 0.2,
  });

  /// Show the overlay.
  final bool isPresented;

  /// The screen underneath.
  final Widget child;

  /// The card's headline.
  final String? message;

  /// The card's second line.
  final String? detail;

  /// 0–1 for a determinate ring.
  final double? progress;

  /// The indeterminate loader.
  final KitoLoaderStyle loader;

  /// Blur radius behind the card.
  final double blur;

  /// Black dimming, 0–1.
  final double dimming;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    final duration =
        reduce ? const Duration(milliseconds: 200) : kito.motion.medium;
    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: isPresented ? blur : 0),
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AbsorbPointer(
            absorbing: isPresented,
            child: ExcludeSemantics(excluding: isPresented, child: child),
          ),
          builder: (context, sigma, child) => ImageFiltered(
            enabled: sigma > 0.01,
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: child,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: isPresented ? 1 : 0,
              duration: duration,
              child: ColoredBox(color: Colors.black.withValues(alpha: dimming)),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: reduce
                    ? child
                    : ScaleTransition(
                        scale: Tween(begin: 0.88, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation,
                                curve: kito.motion.spring,
                                reverseCurve: Curves.easeIn)),
                        child: child),
              ),
              child: isPresented
                  ? KitoLoaderCard(
                      key: const ValueKey('kito-loader-card'),
                      message: message,
                      detail: detail,
                      progress: progress,
                      loader: loader)
                  : const SizedBox.shrink(key: ValueKey('kito-loader-none')),
            ),
          ),
        ),
      ],
    );
  }
}
