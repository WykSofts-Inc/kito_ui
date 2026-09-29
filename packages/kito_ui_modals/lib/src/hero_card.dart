// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';

/// A card that expands into a full-screen story when tapped, App Store Today style: the card
/// face flies up to become the story's header (its corners easing square), the story rises in
/// below it, and closing flies it back into place.
///
/// [collapsed] is the card face — it should fill whatever box it's given, since it's drawn at
/// the card's size and at [expandedHeaderHeight] in the story. [expanded] is the story below.
///
/// ```dart
/// KitoModalHeroCard(
///   tag: story.id,
///   collapsed: (context) => StoryFace(story),
///   expanded: (context) => StoryBody(story),
/// )
/// ```
class KitoModalHeroCard extends StatelessWidget {
  /// Creates a card.
  const KitoModalHeroCard({
    super.key,
    required this.tag,
    required this.collapsed,
    required this.expanded,
    this.height = 380,
    this.expandedHeaderHeight = 440,
    this.radius = 26,
    this.closeLabel = 'Close',
    this.openHint = 'Opens the story',
  });

  /// Unique among the cards on screen; used for the flight.
  final Object tag;

  /// The card face, which is also the story's header.
  final WidgetBuilder collapsed;

  /// The story below the header.
  final WidgetBuilder expanded;

  /// The card's height.
  final double height;

  /// The header's height once expanded.
  final double expandedHeaderHeight;

  /// The card's corner radius.
  final double radius;

  /// The close button's screen-reader label.
  final String closeLabel;

  /// Read after the card's content by screen readers.
  final String openHint;

  /// Opens the story, as a tap on the card does.
  Future<void> open(BuildContext context) {
    final reduce = context.reduceMotion;
    return Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: reduce
          ? const Duration(milliseconds: 220)
          : const Duration(milliseconds: 520),
      reverseTransitionDuration: reduce
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 420),
      pageBuilder: (context, animation, _) =>
          _HeroStory(card: this, animation: animation, reduceMotion: reduce),
    ));
  }

  Widget _face(BuildContext context, double radius) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Builder(builder: collapsed),
      );

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return KitoModalTapTarget(
      onTap: () => open(context),
      semanticHint: openHint,
      pressScale: 0.97,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: HeroMode(
            enabled: !reduce,
            child: Hero(
              tag: _HeroTag(tag),
              flightShuttleBuilder: (flightContext, animation, direction,
                      fromContext, toContext) =>
                  AnimatedBuilder(
                animation: animation,
                builder: (context, _) =>
                    _face(context, ui.lerpDouble(radius, 0, animation.value)!),
              ),
              child: _face(context, radius),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _HeroTag {
  const _HeroTag(this.tag);
  final Object tag;

  @override
  bool operator ==(Object other) => other is _HeroTag && other.tag == tag;

  @override
  int get hashCode => Object.hash(_HeroTag, tag);
}

class _HeroStory extends StatelessWidget {
  const _HeroStory(
      {required this.card,
      required this.animation,
      required this.reduceMotion});

  final KitoModalHeroCard card;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final media = MediaQuery.of(context);
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final body = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0, 0.5, curve: Curves.easeIn));

    final story = Stack(children: [
      Positioned.fill(
        child: FadeTransition(
          opacity: fade,
          child: ColoredBox(color: theme.colors.background),
        ),
      ),
      Positioned.fill(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: card.expandedHeaderHeight,
                child: HeroMode(
                  enabled: !reduceMotion,
                  child: Hero(
                    tag: _HeroTag(card.tag),
                    child: Builder(builder: card.collapsed),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: body,
                builder: (context, child) => Opacity(
                  opacity: body.value,
                  child: Transform.translate(
                    offset: Offset(0, reduceMotion ? 0 : 40 * (1 - body.value)),
                    child: child,
                  ),
                ),
                child: DefaultTextStyle(
                  style: theme.typography.body
                      .copyWith(color: theme.colors.onBackground),
                  child: Builder(builder: card.expanded),
                ),
              ),
              SizedBox(height: media.padding.bottom),
            ],
          ),
        ),
      ),
      PositionedDirectional(
        top: media.padding.top + 8,
        end: 18,
        child: FadeTransition(
          opacity: body,
          child: KitoModalTapTarget(
            onTap: () => Navigator.of(context).maybePop(),
            semanticLabel: card.closeLabel,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: KitoSurface(
                  background: const KitoBackground.glass(opacity: 0.4),
                  radius: 17,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(Icons.close_rounded,
                        size: 18, color: theme.colors.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      onDismiss: () => Navigator.of(context).maybePop(),
      child: reduceMotion ? FadeTransition(opacity: fade, child: story) : story,
    );
  }
}
