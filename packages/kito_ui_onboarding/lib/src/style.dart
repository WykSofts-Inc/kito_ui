// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Where the primary button sits. Every placement ends on a full-width "Get started" button
/// on the last page; this changes how "Next" reads before it.
enum KitoOnboardingButtonPlacement {
  /// A full-width capsule at the bottom.
  bottomFullWidth,

  /// A compact pill at the bottom end, beside the indicator.
  bottomTrailingCompact,

  /// A round arrow button in the top end corner, where Skip would be (Skip moves to the
  /// bottom).
  topTrailingCompact,

  /// A round arrow button in a ring that fills as you go; it stretches into "Get started" on
  /// the last page.
  progressRing,
}

/// How pages move as you swipe. Every effect tracks the finger.
enum KitoOnboardingPageTransition {
  /// Pages simply slide.
  slide,

  /// Pages fade as they leave.
  fade,

  /// Pages shrink and fade: a shallow depth effect.
  scaleFade,

  /// Artwork and background move slower than the text.
  parallax,

  /// Pages turn like the faces of a cube.
  cube,

  /// The leaving page zooms toward you and fades.
  zoom,
}

/// How the text, artwork and background of each page are arranged.
enum KitoOnboardingLayout {
  /// Artwork in the middle, centred text below it.
  centered,

  /// Large artwork filling the top, start-aligned text below.
  heroTop,

  /// The background fills the screen (best with a photo or gradient); start-aligned text sits
  /// at the bottom over a scrim.
  fullBleed,

  /// Artwork on the page background, text on a rounded card rising from the bottom.
  card,

  /// A big start-aligned title first, artwork filling the space below.
  textFirst,

  /// A rounded panel of the page's background with the artwork across the top half, text
  /// below on the theme background.
  split,
}

/// How the current position is shown.
enum KitoOnboardingIndicator {
  /// A stretched capsule for the current page.
  capsules,

  /// Round dots; the current one is larger.
  dots,

  /// "2 / 4".
  numbered,

  /// Segmented bars along the top, like stories.
  progressBar,

  /// Nothing.
  none,
}

/// Ambient motion on the current page's artwork. Off with Reduce Motion.
enum KitoOnboardingArtworkMotion {
  /// Still.
  none,

  /// Drifts gently up and down.
  float,

  /// Bounces each time its page becomes current.
  bounce,

  /// Breathes in and out.
  pulse,
}

/// The words on the buttons and in screen-reader announcements.
@immutable
class KitoOnboardingLabels {
  /// Creates labels.
  const KitoOnboardingLabels({
    this.next = 'Next',
    this.getStarted = 'Get started',
    this.skip = 'Skip',
    this.back = 'Back',
    this.pageOf = _defaultPageOf,
  });

  static String _defaultPageOf(int page, int count) => 'Page $page of $count';

  /// The primary button before the last page.
  final String next;

  /// The primary button on the last page.
  final String getStarted;

  /// Skips the rest.
  final String skip;

  /// The back button's screen-reader label.
  final String back;

  /// How the indicator is read, from a 1-based page and the count.
  final String Function(int page, int count) pageOf;
}

/// Everything about how a Kito onboarding flow looks and moves.
@immutable
class KitoOnboardingStyle {
  /// Creates a style.
  const KitoOnboardingStyle({
    this.buttonPlacement = KitoOnboardingButtonPlacement.bottomFullWidth,
    this.pageTransition = KitoOnboardingPageTransition.slide,
    this.layout = KitoOnboardingLayout.centered,
    this.indicator = KitoOnboardingIndicator.capsules,
    this.artworkMotion = KitoOnboardingArtworkMotion.none,
    this.labels = const KitoOnboardingLabels(),
    this.showsSkip = true,
    this.showsBackButton = false,
    this.cardColor,
    this.cardForeground,
  });

  /// Where the primary button sits.
  final KitoOnboardingButtonPlacement buttonPlacement;

  /// How pages move.
  final KitoOnboardingPageTransition pageTransition;

  /// How each page is arranged.
  final KitoOnboardingLayout layout;

  /// How the position is shown.
  final KitoOnboardingIndicator indicator;

  /// Ambient artwork motion.
  final KitoOnboardingArtworkMotion artworkMotion;

  /// Button words.
  final KitoOnboardingLabels labels;

  /// Shows Skip before the last page.
  final bool showsSkip;

  /// Shows a back button after the first page.
  final bool showsBackButton;

  /// The card layout's card colour; the theme's surface when null.
  final Color? cardColor;

  /// The card layout's text colour; the theme's on-surface when null.
  final Color? cardForeground;
}

/// Moves a [KitoOnboarding] from code and reports where it is.
class KitoOnboardingController extends ChangeNotifier {
  /// Creates a controller starting at [initialPage].
  KitoOnboardingController({int initialPage = 0}) : _page = initialPage;

  int _page;
  int _count = 0;
  VoidCallback? _finish;
  VoidCallback? _skip;

  /// The current page's index.
  int get page => _page;

  /// How many pages there are (0 until attached to a [KitoOnboarding]).
  int get pageCount => _count;

  /// On the first page.
  bool get isFirstPage => _page == 0;

  /// On the last page.
  bool get isLastPage => _count == 0 || _page >= _count - 1;

  /// From 1/pageCount on the first page to 1 on the last.
  double get progress => _count == 0 ? 0 : (_page + 1) / _count;

  /// Goes to the next page, or finishes on the last.
  void next() {
    if (isLastPage) {
      _finish?.call();
    } else {
      goTo(_page + 1);
    }
  }

  /// Goes back a page; nothing on the first.
  void back() {
    if (_page > 0) goTo(_page - 1);
  }

  /// Skips the rest of the flow.
  void skip() => (_skip ?? _finish)?.call();

  /// Goes to page [index], clamped to the pages.
  void goTo(int index) {
    final target = _count == 0 ? index : index.clamp(0, _count - 1);
    if (target == _page) return;
    _page = target;
    notifyListeners();
  }

  void _attach(int count, VoidCallback finish, VoidCallback skip) {
    _count = count;
    _finish = finish;
    _skip = skip;
    if (count > 0 && _page >= count) _page = count - 1;
  }

  void _settle(int page) {
    if (page == _page) return;
    _page = page;
    notifyListeners();
  }
}

/// Wires a controller to its view. Internal to the kit; not exported.
extension KitoOnboardingControllerBinding on KitoOnboardingController {
  /// Attaches the view's page count and callbacks.
  void attach(int count, VoidCallback finish, VoidCallback skip) =>
      _attach(count, finish, skip);

  /// Records the page the pager settled on, after a swipe.
  void settle(int page) => _settle(page);
}

/// The onboarding transition maths, public so it's easy to reason about and test. `value`
/// is a page's distance from the centre of the screen in pages: 0 is centred, −1 one page
/// before, 1 one page after.
abstract final class KitoOnboardingMath {
  /// Cube, zoom and parallax are big motions; Reduce Motion swaps them for a fade.
  static KitoOnboardingPageTransition effectiveTransition(
      KitoOnboardingPageTransition transition,
      {required bool reduceMotion}) {
    if (!reduceMotion) return transition;
    return switch (transition) {
      KitoOnboardingPageTransition.cube ||
      KitoOnboardingPageTransition.zoom ||
      KitoOnboardingPageTransition.parallax =>
        KitoOnboardingPageTransition.fade,
      _ => transition,
    };
  }

  /// A page's opacity.
  static double opacity(KitoOnboardingPageTransition transition, double value) {
    final d = math.min(value.abs(), 1.0);
    return switch (transition) {
      KitoOnboardingPageTransition.fade => 1 - d * 0.75,
      KitoOnboardingPageTransition.scaleFade => 1 - d * 0.55,
      KitoOnboardingPageTransition.zoom => 1 - d,
      _ => 1,
    };
  }

  /// A page's scale.
  static double scale(KitoOnboardingPageTransition transition, double value) {
    final d = math.min(value.abs(), 1.0);
    return switch (transition) {
      KitoOnboardingPageTransition.scaleFade => 1 - d * 0.14,
      KitoOnboardingPageTransition.zoom => 1 + d * 0.35,
      _ => 1,
    };
  }

  /// A page's turn about the vertical axis, in degrees.
  static double cubeAngle(
          KitoOnboardingPageTransition transition, double value) =>
      transition == KitoOnboardingPageTransition.cube
          ? value.clamp(-1.0, 1.0) * 75
          : 0;

  /// How far the artwork lags behind the page with parallax, in logical pixels.
  static double parallaxOffset(
          KitoOnboardingPageTransition transition, double value) =>
      transition == KitoOnboardingPageTransition.parallax ? value * 110 : 0;
}
