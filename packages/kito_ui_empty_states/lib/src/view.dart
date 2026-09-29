// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'illustration.dart';
import 'illustration_view.dart';
import 'media.dart';

/// An empty, error or "nothing yet" state: media, a title, a message and actions, arranged by
/// [layout], with a staggered entrance.
///
/// ```dart
/// KitoEmptyStateView(
///   media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.cart),
///   title: 'Your cart is empty',
///   message: 'Everything you add shows up here.',
///   actions: [KitoEmptyStateAction(label: 'Start shopping', onPressed: openShop)],
/// )
/// ```
class KitoEmptyStateView extends StatefulWidget {
  /// Creates an empty state; every piece is optional.
  const KitoEmptyStateView({
    super.key,
    this.media = const KitoEmptyStateMedia.none(),
    this.title,
    this.message,
    this.actions = const [],
    this.actionsAxis = Axis.vertical,
    this.mediaSize = 160,
    this.layout = KitoEmptyStateLayout.standard,
    this.tint,
  });

  /// Nothing here yet.
  factory KitoEmptyStateView.noData({
    Key? key,
    String title = 'Nothing here yet',
    String? message,
    List<KitoEmptyStateAction> actions = const [],
    KitoEmptyStateLayout layout = KitoEmptyStateLayout.standard,
  }) =>
      KitoEmptyStateView(
        key: key,
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.inbox),
        title: title,
        message: message,
        actions: actions,
        layout: layout,
      );

  /// No results for a search.
  factory KitoEmptyStateView.noResults({
    Key? key,
    required String query,
    String message = 'Try a different search term.',
    List<KitoEmptyStateAction> actions = const [],
    KitoEmptyStateLayout layout = KitoEmptyStateLayout.standard,
  }) =>
      KitoEmptyStateView(
        key: key,
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.search),
        title: 'No results for “$query”',
        message: message,
        actions: actions,
        layout: layout,
      );

  /// No connection, with a Retry button.
  factory KitoEmptyStateView.offline({
    Key? key,
    VoidCallback? onRetry,
    String title = "You're offline",
    String message = 'Check your connection and try again.',
    KitoEmptyStateLayout layout = KitoEmptyStateLayout.standard,
  }) =>
      KitoEmptyStateView(
        key: key,
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.offline),
        title: title,
        message: message,
        actions: [
          if (onRetry != null)
            KitoEmptyStateAction(
                label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry)
        ],
        layout: layout,
      );

  /// Something failed, with a Retry button.
  factory KitoEmptyStateView.error({
    Key? key,
    String title = 'Something went wrong',
    String? message,
    VoidCallback? onRetry,
    KitoEmptyStateLayout layout = KitoEmptyStateLayout.standard,
  }) =>
      KitoEmptyStateView(
        key: key,
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.error),
        title: title,
        message: message,
        actions: [
          if (onRetry != null)
            KitoEmptyStateAction(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry)
        ],
        layout: layout,
      );

  /// What to show with the text.
  final KitoEmptyStateMedia media;

  /// The headline.
  final String? title;

  /// A line or two of explanation.
  final String? message;

  /// Buttons, first is the main one.
  final List<KitoEmptyStateAction> actions;

  /// Stack actions vertically (full width) or side by side (standard layout).
  final Axis actionsAxis;

  /// The media's size in the standard layout; compact is half, full screen 1.35×.
  final double mediaSize;

  /// How it's arranged.
  final KitoEmptyStateLayout layout;

  /// Overrides the accent (icon circle, backdrop); the illustration's lead colour otherwise.
  final Color? tint;

  @override
  State<KitoEmptyStateView> createState() => _KitoEmptyStateViewState();
}

class _KitoEmptyStateViewState extends State<KitoEmptyStateView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.duration = context.reduceMotion
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 900);
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Color _accent(KitoTheme theme) {
    if (widget.tint != null) return widget.tint!;
    final media = widget.media;
    if (media is KitoEmptyStateIllustrationMedia &&
        media.illustration.colors.isNotEmpty) {
      return media.illustration.colors.first;
    }
    return theme.colors.primary;
  }

  /// Fades and rises piece [step] (0 media, 1 text, 2 actions) in turn.
  Widget _enter(int step, Widget child) {
    final reduce = context.reduceMotion;
    final start = reduce ? 0.0 : step * 0.12;
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, math.min(1, start + 0.64),
          curve:
              reduce ? Curves.easeOut : const KitoSpringCurve(damping: 0.85)),
    );
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curve.value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, reduce ? 0 : 12 * (1 - curve.value)),
            child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return switch (widget.layout) {
      KitoEmptyStateLayout.standard => _standard(theme),
      KitoEmptyStateLayout.compact => _compact(theme),
      KitoEmptyStateLayout.inline => _inline(theme),
      KitoEmptyStateLayout.fullScreen => _fullScreen(theme),
    };
  }

  // MARK: Layouts

  Widget _standard(KitoTheme theme) {
    final media = _media(theme, 1);
    return Padding(
      padding: EdgeInsets.all(theme.spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (media != null) _enter(0, media),
          if (media != null) SizedBox(height: theme.spacing.md),
          _enter(1, _texts(theme, TextAlign.center)),
          if (widget.actions.isNotEmpty) ...[
            SizedBox(height: theme.spacing.lg),
            _enter(2, _actionsGroup(theme)),
          ],
        ],
      ),
    );
  }

  Widget _compact(KitoTheme theme) {
    final media = _media(theme, 0.5);
    return Padding(
      padding: EdgeInsets.all(theme.spacing.md),
      child: Row(
        children: [
          if (media != null) _enter(0, media),
          if (media != null) SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _enter(1, _texts(theme, TextAlign.start)),
                if (widget.actions.isNotEmpty) ...[
                  SizedBox(height: theme.spacing.sm),
                  _enter(
                    2,
                    Wrap(
                      spacing: theme.spacing.xs,
                      runSpacing: theme.spacing.xs,
                      children: [
                        for (final a in widget.actions)
                          _KitoEmptyStateButton(action: a, compact: true)
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inline(KitoTheme theme) {
    final accent = _accent(theme);
    final icon = switch (widget.media) {
      KitoEmptyStateIconMedia(:final icon) => icon,
      KitoEmptyStateIllustrationMedia(:final illustration) => illustration.icon,
      _ => null,
    };
    return _enter(
      0,
      CustomPaint(
        painter: _DashedBorderPainter(
            color: theme.colors.border, radius: theme.radii.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surfaceMuted.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(theme.radii.lg),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
                horizontal: theme.spacing.md, vertical: theme.spacing.xs),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  if (icon != null) ...[
                    ExcludeSemantics(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.14)),
                        child: Icon(icon, size: 17, color: accent),
                      ),
                    ),
                    SizedBox(width: theme.spacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null)
                          Text(widget.title!,
                              style: theme.typography.bodyEmphasized
                                  .copyWith(color: theme.colors.onBackground)),
                        if (widget.message != null)
                          Text(widget.message!,
                              style: theme.typography.caption.copyWith(
                                  color: theme.colors.onBackground
                                      .withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  for (final a in widget.actions)
                    _KitoEmptyStateTextButton(action: a),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullScreen(KitoTheme theme) {
    final accent = _accent(theme);
    final media = _media(theme, 1.35);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Color.alphaBlend(
                accent.withValues(alpha: 0.14), theme.colors.background),
            theme.colors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.lg),
          child: Column(
            children: [
              const Spacer(),
              if (media != null) _enter(0, media),
              if (media != null) SizedBox(height: theme.spacing.lg),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
                child: _enter(1, _texts(theme, TextAlign.center)),
              ),
              const Spacer(),
              if (widget.actions.isNotEmpty)
                _enter(
                  2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < widget.actions.length; i++) ...[
                        if (i > 0) SizedBox(height: theme.spacing.sm),
                        _KitoEmptyStateButton(action: widget.actions[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: Pieces

  Widget _texts(KitoTheme theme, TextAlign align) {
    final cross = align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final full = widget.layout == KitoEmptyStateLayout.fullScreen;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        if (widget.title != null)
          Semantics(
            header: true,
            child: Text(
              widget.title!,
              textAlign: align,
              style: (full ? theme.typography.display : theme.typography.title)
                  .copyWith(
                      color: theme.colors.onBackground,
                      fontSize: full ? 28 : 20),
            ),
          ),
        if (widget.title != null && widget.message != null)
          SizedBox(height: theme.spacing.xs),
        if (widget.message != null)
          Text(
            widget.message!,
            textAlign: align,
            style: theme.typography.body.copyWith(
                color: theme.colors.onBackground.withValues(alpha: 0.6)),
          ),
      ],
    );
  }

  Widget? _media(KitoTheme theme, double scale) {
    final size = widget.mediaSize * scale;
    final accent = widget.tint ?? theme.colors.primary;
    switch (widget.media) {
      case KitoEmptyStateNoMedia():
        return null;
      case KitoEmptyStateIconMedia(:final icon):
        final double circle = 88 * math.max(scale, 0.64);
        return ExcludeSemantics(
          child: KitoGlow(
            color: accent,
            radius: 16,
            intensity: 0.18,
            child: Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                      accent.withValues(alpha: 0.12), theme.colors.background)),
              child: Icon(icon,
                  size: 34 * math.max<double>(scale, 0.64),
                  color: accent.withValues(alpha: 0.8)),
            ),
          ),
        );
      case KitoEmptyStateIllustrationMedia(:final illustration):
        final tinted = widget.tint != null && illustration.colors.isEmpty
            ? illustration.tinted([widget.tint!])
            : illustration;
        return KitoEmptyStateIllustrationView(tinted, size: size * 1.15);
      case KitoEmptyStateImageMedia(:final image, :final semanticLabel):
        return SizedBox.square(
          dimension: size,
          child: Image(
            image: image,
            fit: BoxFit.contain,
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
          ),
        );
      case KitoEmptyStateWidgetMedia(:final child):
        return SizedBox.square(dimension: size, child: child);
    }
  }

  Widget _actionsGroup(KitoTheme theme) {
    final buttons = [
      for (final a in widget.actions) _KitoEmptyStateButton(action: a)
    ];
    if (widget.actionsAxis == Axis.horizontal) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: theme.spacing.sm,
        runSpacing: theme.spacing.sm,
        children: buttons,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(height: theme.spacing.sm),
            buttons[i],
          ],
        ],
      ),
    );
  }
}

/// A capsule button: primary black, secondary muted, destructive red.
class _KitoEmptyStateButton extends StatelessWidget {
  const _KitoEmptyStateButton({required this.action, this.compact = false});
  final KitoEmptyStateAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final (bg, fg) = switch (action.role) {
      KitoEmptyStateActionRole.primary => (
          theme.colors.primary,
          theme.colors.onPrimary
        ),
      KitoEmptyStateActionRole.secondary => (
          theme.colors.surfaceMuted,
          theme.colors.onBackground
        ),
      KitoEmptyStateActionRole.destructive => (
          theme.colors.danger,
          Colors.white
        ),
    };
    final style = (compact ? theme.typography.label : theme.typography.button)
        .copyWith(color: fg, fontWeight: FontWeight.w600);
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      onTap: action.onPressed,
      child: GestureDetector(
        onTap: action.onPressed,
        child: KitoPressable(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: compact ? 36 : 50, minWidth: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(999)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? theme.spacing.md : theme.spacing.xl,
                    vertical: compact ? theme.spacing.xs : theme.spacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (action.icon != null) ...[
                      Icon(action.icon, size: compact ? 16 : 18, color: fg),
                      SizedBox(width: theme.spacing.xs),
                    ],
                    Flexible(
                        child: Text(action.label,
                            style: style, textAlign: TextAlign.center)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KitoEmptyStateTextButton extends StatelessWidget {
  const _KitoEmptyStateTextButton({required this.action});
  final KitoEmptyStateAction action;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final color = action.role == KitoEmptyStateActionRole.destructive
        ? theme.colors.danger
        : theme.colors.primary;
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      onTap: action.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action.onPressed,
        child: KitoPressable(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Text(action.label,
                    style: theme.typography.button.copyWith(color: color)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.6), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
            metric.extractPath(distance, math.min(distance + 5, metric.length)),
            paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
