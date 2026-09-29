// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

import 'illustration.dart';

/// What an empty state shows above (or beside) its text.
@immutable
sealed class KitoEmptyStateMedia {
  const KitoEmptyStateMedia();

  /// Nothing.
  const factory KitoEmptyStateMedia.none() = KitoEmptyStateNoMedia;

  /// An icon in a soft tinted circle.
  const factory KitoEmptyStateMedia.icon(IconData icon) =
      KitoEmptyStateIconMedia;

  /// An animated, code-drawn illustration.
  const factory KitoEmptyStateMedia.illustration(
          KitoEmptyStateIllustration illustration) =
      KitoEmptyStateIllustrationMedia;

  /// Your own image (asset, network, memory).
  const factory KitoEmptyStateMedia.image(ImageProvider image,
      {String? semanticLabel}) = KitoEmptyStateImageMedia;

  /// Any widget — a Lottie or Rive animation, a video, a custom painter.
  const factory KitoEmptyStateMedia.widget(Widget child) =
      KitoEmptyStateWidgetMedia;
}

/// See [KitoEmptyStateMedia.none].
final class KitoEmptyStateNoMedia extends KitoEmptyStateMedia {
  /// Nothing.
  const KitoEmptyStateNoMedia();
}

/// See [KitoEmptyStateMedia.icon].
final class KitoEmptyStateIconMedia extends KitoEmptyStateMedia {
  /// An icon.
  const KitoEmptyStateIconMedia(this.icon);

  /// The icon.
  final IconData icon;
}

/// See [KitoEmptyStateMedia.illustration].
final class KitoEmptyStateIllustrationMedia extends KitoEmptyStateMedia {
  /// An illustration.
  const KitoEmptyStateIllustrationMedia(this.illustration);

  /// The illustration.
  final KitoEmptyStateIllustration illustration;
}

/// See [KitoEmptyStateMedia.image].
final class KitoEmptyStateImageMedia extends KitoEmptyStateMedia {
  /// An image.
  const KitoEmptyStateImageMedia(this.image, {this.semanticLabel});

  /// The image.
  final ImageProvider image;

  /// What screen readers say; decorative (skipped) when null.
  final String? semanticLabel;
}

/// See [KitoEmptyStateMedia.widget].
final class KitoEmptyStateWidgetMedia extends KitoEmptyStateMedia {
  /// A widget.
  const KitoEmptyStateWidgetMedia(this.child);

  /// The widget.
  final Widget child;
}

/// How an action button looks.
enum KitoEmptyStateActionRole {
  /// Filled with the primary colour.
  primary,

  /// A quiet muted fill.
  secondary,

  /// Filled with the danger colour.
  destructive,
}

/// A button on an empty state ("Retry", "Browse products").
@immutable
class KitoEmptyStateAction {
  /// Creates an action.
  const KitoEmptyStateAction(
      {required this.label,
      required this.onPressed,
      this.role = KitoEmptyStateActionRole.primary,
      this.icon});

  /// The title.
  final String label;

  /// Runs when tapped.
  final VoidCallback onPressed;

  /// Sets the colours.
  final KitoEmptyStateActionRole role;

  /// An optional leading icon.
  final IconData? icon;
}

/// How an empty state is arranged.
enum KitoEmptyStateLayout {
  /// Centred and stacked: media, title, message, actions. The default.
  standard,

  /// Media at the start, text and actions beside it — inside a card or a list section.
  compact,

  /// One quiet row with a small icon, the message and a text action, in a dashed outline —
  /// for an empty slot in a form ("No payment methods yet · Add").
  inline,

  /// Fills the screen: a tinted backdrop, large media, actions pinned to the bottom.
  fullScreen,
}
