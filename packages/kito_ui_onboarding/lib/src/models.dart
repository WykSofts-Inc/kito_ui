// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// The picture on an onboarding page.
@immutable
sealed class KitoOnboardingArtwork {
  const KitoOnboardingArtwork();

  /// A large icon in the page's accent colour, on a soft halo.
  const factory KitoOnboardingArtwork.icon(IconData icon) =
      KitoOnboardingIconArtwork;

  /// An image — bundled, network or memory — with rounded corners.
  const factory KitoOnboardingArtwork.image(ImageProvider image, {BoxFit fit}) =
      KitoOnboardingImageArtwork;

  /// Anything you draw: an illustration, a product shot, an animation.
  const factory KitoOnboardingArtwork.custom(WidgetBuilder builder) =
      KitoOnboardingCustomArtwork;

  /// No artwork, e.g. over a photo background.
  static const KitoOnboardingArtwork none = KitoOnboardingNoArtwork();
}

/// An icon artwork.
final class KitoOnboardingIconArtwork extends KitoOnboardingArtwork {
  /// Creates it.
  const KitoOnboardingIconArtwork(this.icon);

  /// The icon.
  final IconData icon;
}

/// An image artwork.
final class KitoOnboardingImageArtwork extends KitoOnboardingArtwork {
  /// Creates it.
  const KitoOnboardingImageArtwork(this.image, {this.fit = BoxFit.contain});

  /// The image.
  final ImageProvider image;

  /// How it fills its box.
  final BoxFit fit;
}

/// A drawn artwork.
final class KitoOnboardingCustomArtwork extends KitoOnboardingArtwork {
  /// Creates it.
  const KitoOnboardingCustomArtwork(this.builder);

  /// Builds it.
  final WidgetBuilder builder;
}

/// No artwork.
final class KitoOnboardingNoArtwork extends KitoOnboardingArtwork {
  /// Creates it.
  const KitoOnboardingNoArtwork();
}

/// A permission-style step: the primary button asks for something (notifications, location)
/// and a quieter "Not now" moves on without asking. Either way the flow continues.
@immutable
class KitoOnboardingPermission {
  /// Creates a permission step.
  const KitoOnboardingPermission({
    required this.onRequest,
    this.allowTitle = 'Allow',
    this.notNowTitle = 'Not now',
  });

  /// Asks for the permission; complete with whether it was granted. Errors count as not
  /// granted.
  final Future<bool> Function() onRequest;

  /// The primary button's text.
  final String allowTitle;

  /// The secondary button's text.
  final String notNowTitle;
}

/// One page of a Kito onboarding flow.
@immutable
class KitoOnboardingPage {
  /// Creates a page.
  const KitoOnboardingPage({
    required this.title,
    required this.message,
    this.artwork = KitoOnboardingArtwork.none,
    this.eyebrow,
    this.bullets = const [],
    this.background,
    this.foreground,
    this.accent,
    this.onAccent,
    this.permission,
  });

  /// The picture.
  final KitoOnboardingArtwork artwork;

  /// A small line above the title, e.g. "STEP 1" or "NEW".
  final String? eyebrow;

  /// The heading.
  final String title;

  /// The text under the heading.
  final String message;

  /// Short feature lines, each with a check mark.
  final List<String> bullets;

  /// A full-bleed background behind the page: a colour, a gradient, glass or a photo. Null
  /// leaves it on the theme's background.
  final KitoBackground? background;

  /// Text colour for this page (and for Skip, Back and the indicator while it shows). Null
  /// uses the theme, or white on the full-bleed layout.
  final Color? foreground;

  /// The button and indicator colour while this page shows; the theme's primary when null.
  final Color? accent;

  /// Text on the accent-coloured button; the theme's on-primary when null.
  final Color? onAccent;

  /// Makes this a permission step.
  final KitoOnboardingPermission? permission;
}
