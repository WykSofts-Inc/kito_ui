// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';

/// A round map button: a frosted surface, a 44-point target and a tooltip.
class KitoMapControlButton extends StatelessWidget {
  /// Creates a button.
  const KitoMapControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.tint,
  });

  /// The glyph.
  final IconData icon;

  /// The tooltip and spoken label.
  final String label;

  /// Called on tap.
  final VoidCallback? onPressed;

  /// Draws it in the accent, e.g. while following the user.
  final bool active;

  /// Replaces the theme's primary colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = tint ?? theme.colors.secondary;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: active ? true : null,
        label: label,
        excludeSemantics: true,
        child: KitoPressable(
          scale: 0.9,
          child: Material(
            color: theme.colors.surface,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onPressed!();
                    },
              child: SizedBox(
                width: 44,
                height: 44,
                child: AnimatedSwitcher(
                  duration: KitoMotion.of(context, theme.motion.fast),
                  child: Icon(icon,
                      key: ValueKey((icon, active)),
                      size: 20,
                      color: active ? accent : theme.colors.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The usual map buttons in a column: zoom in and out as one capsule, then locate and fit.
/// Buttons without a callback are left out.
class KitoMapControls extends StatelessWidget {
  /// Creates the controls.
  const KitoMapControls({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
    this.onLocate,
    this.onFitAll,
    this.isFollowingUser = false,
    this.tint,
  });

  /// Zooms in.
  final VoidCallback? onZoomIn;

  /// Zooms out.
  final VoidCallback? onZoomOut;

  /// Centres on the user.
  final VoidCallback? onLocate;

  /// Shows every pin.
  final VoidCallback? onFitAll;

  /// Highlights the locate button.
  final bool isFollowingUser;

  /// Replaces the accent.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final gap = SizedBox(height: theme.spacing.sm);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onZoomIn != null || onZoomOut != null)
          Material(
            color: theme.colors.surface,
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (onZoomIn != null)
                _flat(context, Icons.add_rounded, 'Zoom in', onZoomIn!),
              if (onZoomIn != null && onZoomOut != null)
                SizedBox(
                    width: 24,
                    child: Divider(height: 1, color: theme.colors.border)),
              if (onZoomOut != null)
                _flat(context, Icons.remove_rounded, 'Zoom out', onZoomOut!),
            ]),
          ),
        if (onLocate != null) ...[
          gap,
          KitoMapControlButton(
            icon: isFollowingUser
                ? Icons.near_me_rounded
                : Icons.near_me_outlined,
            label: 'Show my location',
            active: isFollowingUser,
            tint: tint,
            onPressed: onLocate,
          ),
        ],
        if (onFitAll != null) ...[
          gap,
          KitoMapControlButton(
            icon: Icons.fit_screen_rounded,
            label: 'Show all places',
            tint: tint,
            onPressed: onFitAll,
          ),
        ],
      ],
    );
  }

  Widget _flat(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = context.kito;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20, color: theme.colors.onSurface)),
        ),
      ),
    );
  }
}

/// An action on a [KitoMapPlaceCard].
@immutable
class KitoMapPlaceAction {
  /// Creates an action.
  const KitoMapPlaceAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  /// The glyph.
  final IconData icon;

  /// "Directions".
  final String label;

  /// Called on tap.
  final VoidCallback onPressed;

  /// Draws it as the filled, wide button.
  final bool isPrimary;
}

/// The card that rises from the bottom of a map for a chosen place: a handle, a thumbnail, the
/// title and details, a rating and distance, tags and actions such as **Directions** and
/// **Call**.
///
/// ```dart
/// KitoMapPlaceCard(
///   title: 'Java House, Valley Arcade',
///   subtitle: 'Coffee · Lavington',
///   rating: 4.6,
///   distance: '850 m',
///   tags: const ['Open now', 'Wi-Fi'],
///   actions: [
///     KitoMapPlaceAction(icon: Icons.directions_rounded, label: 'Directions', isPrimary: true, onPressed: go),
///     KitoMapPlaceAction(icon: Icons.call_rounded, label: 'Call', onPressed: call),
///   ],
///   onClose: () => setState(() => selected = null),
/// )
/// ```
class KitoMapPlaceCard extends StatelessWidget {
  /// Creates a card.
  const KitoMapPlaceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.place_rounded,
    this.image,
    this.rating,
    this.reviewCount,
    this.distance,
    this.tags = const [],
    this.actions = const [],
    this.onClose,
    this.tint,
  });

  /// A card for [pin], with its title, subtitle, icon and tint.
  KitoMapPlaceCard.fromPin(
    KitoMapPin pin, {
    Key? key,
    double? rating,
    int? reviewCount,
    String? distance,
    List<String> tags = const [],
    List<KitoMapPlaceAction> actions = const [],
    VoidCallback? onClose,
    ImageProvider? image,
  }) : this(
          key: key,
          title: pin.title,
          subtitle: pin.subtitle,
          icon: pin.style.icon ?? pin.icon ?? Icons.place_rounded,
          image: image ?? pin.style.image,
          rating: rating,
          reviewCount: reviewCount,
          distance: distance,
          tags: tags,
          actions: actions,
          onClose: onClose,
          tint: pin.tint,
        );

  /// "Java House".
  final String title;

  /// "Coffee · Lavington".
  final String? subtitle;

  /// The thumbnail's glyph when there's no [image].
  final IconData icon;

  /// A photo for the thumbnail.
  final ImageProvider? image;

  /// 0–5.
  final double? rating;

  /// Shown after the rating: "(212)".
  final int? reviewCount;

  /// "850 m".
  final String? distance;

  /// Small chips: "Open now", "Wi-Fi".
  final List<String> tags;

  /// Buttons along the bottom.
  final List<KitoMapPlaceAction> actions;

  /// Shows a close button.
  final VoidCallback? onClose;

  /// The accent; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = tint ?? theme.colors.primary;
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);
    final primary = actions.where((a) => a.isPrimary).toList();
    final secondary = actions.where((a) => !a.isPrimary).toList();
    return Material(
      color: theme.colors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(theme.radii.xl),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.spacing.lg, theme.spacing.sm,
            theme.spacing.lg, theme.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: theme.spacing.md),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(theme.radii.md),
                  image: image == null
                      ? null
                      : DecorationImage(image: image!, fit: BoxFit.cover),
                ),
                alignment: Alignment.center,
                child: image == null ? Icon(icon, color: accent) : null,
              ),
              SizedBox(width: theme.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.headline
                              .copyWith(color: theme.colors.onSurface)),
                    ),
                    if (subtitle != null)
                      Text(subtitle!,
                          style:
                              theme.typography.caption.copyWith(color: muted)),
                    if (rating != null || distance != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (rating != null)
                            Semantics(
                              label:
                                  'Rated ${rating!.toStringAsFixed(1)} out of 5${reviewCount == null ? '' : ', $reviewCount reviews'}',
                              excludeSemantics: true,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 16, color: Color(0xFFFFB400)),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                              text: rating!.toStringAsFixed(1),
                                              style: TextStyle(
                                                  color: theme.colors.onSurface,
                                                  fontWeight: FontWeight.w700)),
                                          if (reviewCount != null)
                                            TextSpan(
                                                text: ' ($reviewCount)',
                                                style: TextStyle(color: muted)),
                                        ]),
                                        style: theme.typography.caption,
                                      ),
                                    ),
                                  ]),
                            ),
                          if (distance != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.directions_walk_rounded,
                                  size: 14, color: muted),
                              Text(distance!,
                                  style: theme.typography.caption
                                      .copyWith(color: muted)),
                            ]),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: muted),
                ),
            ]),
            if (tags.isNotEmpty) ...[
              SizedBox(height: theme.spacing.md),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final t in tags)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(theme.radii.pill),
                    ),
                    child: Text(t,
                        style: theme.typography.caption.copyWith(
                            color: theme.colors.onSurface,
                            fontWeight: FontWeight.w600)),
                  ),
              ]),
            ],
            if (actions.isNotEmpty) ...[
              SizedBox(height: theme.spacing.lg),
              Row(children: [
                for (final a in primary)
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.only(end: theme.spacing.sm),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: _onColor(accent),
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                          textStyle: theme.typography.button,
                        ),
                        onPressed: a.onPressed,
                        icon: Icon(a.icon, size: 18),
                        label: Text(a.label),
                      ),
                    ),
                  ),
                for (final a in secondary)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: theme.spacing.sm),
                    child: Tooltip(
                      message: a.label,
                      child: Semantics(
                        button: true,
                        label: a.label,
                        excludeSemantics: true,
                        child: Material(
                          color: theme.colors.surfaceMuted,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: a.onPressed,
                            child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(a.icon,
                                    size: 20, color: theme.colors.onSurface)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

Color _onColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark
        ? Colors.white
        : Colors.black;
